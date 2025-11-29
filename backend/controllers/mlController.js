const axios = require('axios');

const ML_SERVICE_URL = 'http://localhost:5001';

exports.predictAdherenceRisk = async (req, res) => {
  try {
    const { hour_of_day, day_of_week, num_daily_meds, past_adherence_rate, hours_since_last_dose } = req.body;
    
    const response = await axios.post(`${ML_SERVICE_URL}/predict`, {
      hour_of_day,
      day_of_week,
      num_daily_meds,
      past_adherence_rate,
      hours_since_last_dose
    });
    
    res.json({
      success: true,
      data: response.data.prediction
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.suggestOptimalTimes = async (req, res) => {
  try {
    const { num_daily_meds, past_adherence_rate } = req.body;
    
    const response = await axios.post(`${ML_SERVICE_URL}/suggest-times`, {
      num_daily_meds,
      past_adherence_rate
    });
    
    res.json({
      success: true,
      data: response.data.suggested_times
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};