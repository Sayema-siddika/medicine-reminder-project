const express = require('express');
const router = express.Router();
const { predictAdherenceRisk, suggestOptimalTimes } = require('../controllers/mlController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.post('/predict-risk', predictAdherenceRisk);
router.post('/suggest-times', suggestOptimalTimes);

module.exports = router;