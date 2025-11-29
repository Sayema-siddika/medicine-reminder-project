const axios = require('axios');

// Use environment variable for production, fallback to localhost for development
const ML_SERVICE_URL = process.env.ML_SERVICE_HOST 
  ? `https://${process.env.ML_SERVICE_HOST}` 
  : 'http://localhost:5001';

exports.predictAdherenceRisk = async (req, res) => {
  try {
    const { hour_of_day, day_of_week, num_daily_meds, past_adherence_rate, hours_since_last_dose } = req.body;
    
    const response = await axios.post(`${ML_SERVICE_URL}/predict`, {
      hour_of_day,
      day_of_week,
      num_daily_meds,
      past_adherence_rate,
      hours_since_last_dose
    }, {
      timeout: 10000, // 10 second timeout
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    res.json({
      success: true,
      data: response.data.prediction
    });
  } catch (error) {
    console.error('ML Service Error:', error.message);
    res.status(500).json({
      success: false,
      message: 'ML service unavailable: ' + error.message
    });
  }
};

exports.suggestOptimalTimes = async (req, res) => {
  try {
    const { num_daily_meds, past_adherence_rate } = req.body;
    
    const response = await axios.post(`${ML_SERVICE_URL}/suggest-times`, {
      num_daily_meds,
      past_adherence_rate
    }, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    res.json({
      success: true,
      data: response.data.suggested_times
    });
  } catch (error) {
    console.error('ML Service Error:', error.message);
    res.status(500).json({
      success: false,
      message: 'ML service unavailable: ' + error.message
    });
  }
};