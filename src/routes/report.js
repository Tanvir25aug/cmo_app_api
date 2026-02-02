const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authenticate } = require('../middleware/auth');

// All report routes require authentication
router.use(authenticate);

/**
 * @route   GET /reports/dashboard
 * @desc    Get complete dashboard data (all stats in one call)
 * @access  Protected (Admin)
 */
router.get('/dashboard', reportController.getDashboardData);

/**
 * @route   GET /reports/cmo-statistics
 * @desc    Get CMO statistics from SQL Server
 * @access  Protected (Admin)
 */
router.get('/cmo-statistics', reportController.getCMOStatistics);

/**
 * @route   GET /reports/user-statistics
 * @desc    Get user statistics
 * @access  Protected (Admin)
 */
router.get('/user-statistics', reportController.getUserStatistics);

/**
 * @route   GET /reports/top-users
 * @desc    Get top users by CMO count
 * @access  Protected (Admin)
 * @query   limit - Number of users to return (default: 5)
 */
router.get('/top-users', reportController.getTopUsers);

/**
 * @route   GET /reports/weekly-data
 * @desc    Get CMO count for last 7 days
 * @access  Protected (Admin)
 */
router.get('/weekly-data', reportController.getWeeklyData);

/**
 * @route   GET /reports/customer-count
 * @desc    Get total customer count
 * @access  Protected (Admin)
 */
router.get('/customer-count', reportController.getCustomerCount);

module.exports = router;
