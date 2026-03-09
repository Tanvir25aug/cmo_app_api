const { body, validationResult } = require('express-validator');
const { errorResponse } = require('./response');

// Validation middleware to check for errors
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return errorResponse(res, 'Validation failed', 400, errors.array());
  }
  next();
};

// Register validation rules
const validateRegister = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers and underscores'),

  body('email')
    .trim()
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),

  body('fullName')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Full name cannot exceed 100 characters'),

  body('phone')
    .optional()
    .trim()
    .matches(/^[0-9+\-\s()]+$/)
    .withMessage('Please provide a valid phone number'),

  validate
];

// Login validation rules (accepts username or email)
const validateLogin = [
  body('password')
    .notEmpty()
    .withMessage('Password is required'),

  // Custom validation to ensure at least username or email is provided
  body().custom((value, { req }) => {
    if (!req.body.username && !req.body.email) {
      throw new Error('Username or email is required');
    }
    return true;
  }),

  validate
];

// CMO validation rules
const validateCMO = [
  body('customerName')
    .trim()
    .notEmpty()
    .withMessage('Customer name is required')
    .isLength({ max: 100 })
    .withMessage('Customer name cannot exceed 100 characters'),

  body('mobileNumber')
    .trim()
    .notEmpty()
    .withMessage('Mobile number is required')
    .matches(/^[0-9+\-\s()]+$/)
    .withMessage('Please provide a valid mobile number'),

  body('email')
    .optional()
    .trim()
    .isEmail()
    .withMessage('Please provide a valid email'),

  body('oldMeterType')
    .optional()
    .isIn(['1P', '3P'])
    .withMessage('Old meter type must be either 1P or 3P'),

  body('status')
    .optional()
    .isIn(['draft', 'pending', 'uploaded', 'approved', 'rejected'])
    .withMessage('Invalid status value'),

  validate
];

// Change password validation
const validateChangePassword = [
  body('oldPassword')
    .notEmpty()
    .withMessage('Current password is required'),

  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('New password must be at least 6 characters long'),

  validate
];

module.exports = {
  validate,
  validateRegister,
  validateLogin,
  validateCMO,
  validateChangePassword
};
