const Medication = require('../models/Medication');
const AdherenceLog = require('../models/AdherenceLog');

// Add Medication
exports.addMedication = async (req, res) => {
  try {
    const medication = await Medication.create({
      ...req.body,
      userId: req.user.id
    });

    res.status(201).json({ success: true, data: medication });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get All Medications
exports.getMedications = async (req, res) => {
  try {
    const medications = await Medication.find({ 
      userId: req.user.id,
      isActive: true 
    });

    res.json({ success: true, data: medications });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update Medication
exports.updateMedication = async (req, res) => {
  try {
    const medication = await Medication.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      req.body,
      { new: true }
    );

    if (!medication) {
      return res.status(404).json({ message: 'Medication not found' });
    }

    res.json({ success: true, data: medication });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete Medication
exports.deleteMedication = async (req, res) => {
  try {
    const medication = await Medication.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { isActive: false },
      { new: true }
    );

    if (!medication) {
      return res.status(404).json({ message: 'Medication not found' });
    }

    res.json({ success: true, message: 'Medication deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Log Adherence
exports.logAdherence = async (req, res) => {
  try {
    const { medicationId, scheduledTime, status, takenTime, notes } = req.body;

    const log = await AdherenceLog.create({
      userId: req.user.id,
      medicationId,
      scheduledTime,
      takenTime: status === 'taken' ? takenTime || new Date() : null,
      status,
      notes
    });

    res.status(201).json({ success: true, data: log });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get Today's Reminders
exports.getTodayReminders = async (req, res) => {
  try {
    const medications = await Medication.find({
      userId: req.user.id,
      isActive: true
    });

    const today = new Date();
    const reminders = [];

    medications.forEach(med => {
      med.times.forEach(time => {
        const [hours, minutes] = time.split(':');
        const reminderTime = new Date(today);
        reminderTime.setHours(parseInt(hours), parseInt(minutes), 0);

        reminders.push({
          medicationId: med._id,
          medicationName: med.name,
          dosage: med.dosage,
          time: time,
          scheduledDateTime: reminderTime
        });
      });
    });

    res.json({ success: true, data: reminders });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};