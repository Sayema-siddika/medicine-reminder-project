const mongoose = require('mongoose');

const adherenceLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  medicationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Medication',
    required: true
  },
  scheduledTime: {
    type: Date,
    required: true
  },
  takenTime: Date,
  status: {
    type: String,
    enum: ['taken', 'missed', 'skipped'],
    required: true
  },
  notes: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('AdherenceLog', adherenceLogSchema);