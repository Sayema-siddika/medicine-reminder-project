const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true
  },
  phone: String,
  age: Number,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// ✅ FIX: Removed 'next' parameter to prevent "next is not a function" error
userSchema.pre('save', async function() {
  // If password is not modified, simply return (exit function)
  if (!this.isModified('password')) return;

  // Hash the password
  this.password = await bcrypt.hash(this.password, 10);
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);