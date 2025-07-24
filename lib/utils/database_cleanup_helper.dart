import '../services/database_migration_service.dart';

/// Helper class to perform database cleanup operations
/// This is a utility class that can be called during app initialization
/// to ensure the database is cleaned up properly
class DatabaseCleanupHelper {
  static final DatabaseMigrationService _migrationService =
      DatabaseMigrationService();

  /// Performs database cleanup during app initialization
  /// Returns true if cleanup was successful, false otherwise
  static Future<bool> performInitialCleanup() async {
    try {
      print('Starting database cleanup...');

      // Perform complete migration with backup, cleanup, and verification
      final success = await _migrationService.performCompleteMigration();

      if (success) {
        print('Database cleanup completed successfully');

        // Log remaining tables for verification
        final remainingTables = await _migrationService.getAllTables();
        print('Remaining tables: $remainingTables');

        return true;
      } else {
        print('Database cleanup failed');
        return false;
      }
    } catch (e) {
      print('Error during database cleanup: $e');
      return false;
    }
  }

  /// Verifies that the database cleanup was successful
  /// Can be called to check the current state of the database
  static Future<bool> verifyDatabaseState() async {
    try {
      final allTables = await _migrationService.getAllTables();

      // List of tables that should NOT exist after cleanup
      const removedTables = [
        'caregiver_assignments',
        'careplans',
        'payment',
        'caregiver_feedback',
      ];

      // List of tables that SHOULD exist after cleanup
      const essentialTables = [
        'users',
        'medications',
        'appointments',
        'notifications',
        'offline_sync_log',
        'caregiver',
      ];

      // Check that removed tables don't exist
      for (String tableName in removedTables) {
        if (allTables.contains(tableName)) {
          print(
            'ERROR: Table $tableName should have been removed but still exists',
          );
          return false;
        }
      }

      // Check that essential tables still exist
      for (String tableName in essentialTables) {
        if (!allTables.contains(tableName)) {
          print('ERROR: Essential table $tableName is missing');
          return false;
        }
      }

      print('Database state verification successful');
      print('Current tables: $allTables');
      return true;
    } catch (e) {
      print('Error during database state verification: $e');
      return false;
    }
  }

  /// Gets a summary of the current database state
  static Future<Map<String, dynamic>> getDatabaseSummary() async {
    try {
      final allTables = await _migrationService.getAllTables();

      return {
        'total_tables': allTables.length,
        'tables': allTables,
        'cleanup_completed': await _migrationService.verifyCleanup(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
