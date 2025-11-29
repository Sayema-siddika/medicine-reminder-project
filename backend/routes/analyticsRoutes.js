const express = require('express');
const router = express.Router();
const {
  getAdherenceStats,
  getAdherencePatterns
} = require('../controllers/analyticsController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/adherence', getAdherenceStats);
router.get('/patterns', getAdherencePatterns);

module.exports = router;