const AdherenceLog = require('../models/AdherenceLog');
const Medication = require('../models/Medication');

// Get Adherence Statistics
exports.getAdherenceStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const query = { userId: req.user.id };
    
    if (startDate && endDate) {
      query.scheduledTime = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const logs = await AdherenceLog.find(query);

    const stats = {
      total: logs.length,
      taken: logs.filter(l => l.status === 'taken').length,
      missed: logs.filter(l => l.status === 'missed').length,
      skipped: logs.filter(l => l.status === 'skipped').length
    };

    stats.adherenceRate = stats.total > 0 
      ? ((stats.taken / stats.total) * 100).toFixed(2) 
      : 0;

    res.json({ success: true, data: stats });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get Adherence Patterns
exports.getAdherencePatterns = async (req, res) => {
  try {
    const logs = await AdherenceLog.find({ userId: req.user.id })
      .populate('medicationId', 'name')
      .sort({ scheduledTime: -1 })
      .limit(100);

    // Group by day of week
    const dayPattern = Array(7).fill(0).map(() => ({ taken: 0, total: 0 }));
    
    logs.forEach(log => {
      const day = new Date(log.scheduledTime).getDay();
      dayPattern[day].total++;
      if (log.status === 'taken') dayPattern[day].taken++;
    });

    const patterns = dayPattern.map((day, index) => ({
      day: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][index],
      adherenceRate: day.total > 0 ? ((day.taken / day.total) * 100).toFixed(2) : 0
    }));

    res.json({ success: true, data: patterns });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};