const express = require('express');
const router = express.Router();
const {
  addMedication,
  getMedications,
  updateMedication,
  deleteMedication,
  logAdherence,
  getTodayReminders
} = require('../controllers/medicationController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect); // All routes protected

router.post('/', addMedication);
router.get('/', getMedications);
router.put('/:id', updateMedication);
router.delete('/:id', deleteMedication);
router.post('/log', logAdherence);
router.get('/reminders/today', getTodayReminders);

module.exports = router;