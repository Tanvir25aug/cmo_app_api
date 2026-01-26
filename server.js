require('dotenv').config();
const app = require('./src/app');
const { testConnection } = require('./src/config/database');
const { syncDatabase } = require('./src/models');
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';

// Startup function
const startServer = async () => {
  try {
    // Test database connection
    await testConnection();

    // Sync database models
    // Set force: true to drop and recreate tables (WARNING: deletes all data)
    // Set force: false to only create tables if they don't exist
    // COMMENTED OUT: Tables are created manually via SQL script
    // await syncDatabase(false);

    // Start server
    app.listen(PORT, HOST, () => {
      logger.info(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║               🚀 CMO API Server Started                   ║
║                                                           ║
║  Environment:  ${process.env.NODE_ENV?.toUpperCase().padEnd(42)}║
║  Server:       http://${HOST}:${PORT}${' '.repeat(30)}║
║  API Endpoint: http://${HOST}:${PORT}${process.env.API_PREFIX || '/api'}${' '.repeat(21)}║
║  Health Check: http://${HOST}:${PORT}${process.env.API_PREFIX || '/api'}/health${' '.repeat(14)}║
║                                                           ║
║  Database:     ${process.env.DB_NAME}${' '.repeat(29)}║
║  DB Server:    ${process.env.DB_SERVER}${' '.repeat(29)}║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
      `);

      console.log(`✅ Server is ready to accept connections`);
      console.log(`📡 Press Ctrl+C to stop the server\n`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  process.exit(0);
});

// Start the server
startServer();
