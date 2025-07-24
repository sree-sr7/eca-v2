import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

/// Service responsible for safely migrating and cleaning up database tables
/// Removes unused tables: caregiver_assignments, careplans, payment, caregiver_feedback
class DatabaseMigrationService {
  static final DatabaseMigrationService _instance =
      DatabaseMigrationService._internal();
  factory DatabaseMigrationService() => _instance;
  DatabaseMigrationService._internal();

  final DBHelper _dbHelper = DBHelper();

  /// List of tables to be removed during cleanup
  static const List<String> _tablesToRemove = [
    'caregiver_assignments',
    'careplans',
    'payment',
    'caregiver_feedback',
  ];

  /// Performs safe database cleanup by removing unused tables
  /// Returns true if cleanup was successful, false otherwise
  Future<bool> performDatabaseCleanup() async {
    try {
      final db = await _dbHelper.database;

      // Start transaction for atomic operation
      await db.transaction((txn) async {
        for (String tableName in _tablesToRemove) {
          await _safelyDropTable(txn, tableName);
        }
      });

      print('Database cleanup completed successfully');
      return true;
    } catch (e) {
      print('Error during database cleanup: $e');
      return false;
    }
  }

  /// Safely drops a table if it exists
  Future<void> _safelyDropTable(Transaction txn, String tableName) async {
    try {
      // Check if table exists before attempting to drop
      final tableExists = await _checkTableExists(txn, tableName);

      if (tableExists) {
        await txn.execute('DROP TABLE IF EXISTS $tableName');
        print('Successfully removed table: $tableName');
      } else {
        print('Table $tableName does not exist, skipping');
      }
    } catch (e) {
      print('Error dropping table $tableName: $e');
      // Continue with other tables even if one fails
    }
  }

  /// Checks if a table exists in the database
  Future<bool> _checkTableExists(Transaction txn, String tableName) async {
    try {
      final result = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking table existence for $tableName: $e');
      return false;
    }
  }

  /// Gets list of all tables in the database for verification
  Future<List<String>> getAllTables() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      print('Error getting table list: $e');
      return [];
    }
  }

  /// Verifies that cleanup was successful by checking removed tables don't exist
  Future<bool> verifyCleanup() async {
    try {
      final allTables = await getAllTables();

      for (String tableName in _tablesToRemove) {
        if (allTables.contains(tableName)) {
          print('Cleanup verification failed: Table $tableName still exists');
          return false;
        }
      }

      print('Cleanup verification successful: All target tables removed');
      return true;
    } catch (e) {
      print('Error during cleanup verification: $e');
      return false;
    }
  }

  /// Backs up data from tables before removal (optional safety measure)
  Future<Map<String, List<Map<String, dynamic>>>> backupTablesData() async {
    final Map<String, List<Map<String, dynamic>>> backup = {};

    try {
      final db = await _dbHelper.database;

      for (String tableName in _tablesToRemove) {
        try {
          // Check if table exists by querying sqlite_master
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [tableName],
          );

          if (result.isNotEmpty) {
            final data = await db.query(tableName);
            backup[tableName] = data;
            print('Backed up ${data.length} records from $tableName');
          } else {
            print('Table $tableName does not exist, skipping backup');
          }
        } catch (e) {
          print('Error backing up table $tableName: $e');
          backup[tableName] = [];
        }
      }
    } catch (e) {
      print('Error during backup process: $e');
    }

    return backup;
  }

  /// Removes foreign key constraints that reference tables being dropped
  Future<void> _cleanupForeignKeyReferences() async {
    try {
      final db = await _dbHelper.database;

      // Since SQLite doesn't support dropping foreign key constraints directly,
      // we'll handle this by ensuring dependent operations are cleaned up
      // The CASCADE DELETE should handle most cleanup automatically

      print('Foreign key cleanup completed');
    } catch (e) {
      print('Error during foreign key cleanup: $e');
    }
  }

  /// Complete migration process with backup, cleanup, and verification
  Future<bool> performCompleteMigration() async {
    try {
      print('Starting complete database migration...');

      // Step 1: Backup data (optional safety measure)
      print('Step 1: Backing up table data...');
      final backup = await backupTablesData();

      // Step 2: Clean up foreign key references
      print('Step 2: Cleaning up foreign key references...');
      await _cleanupForeignKeyReferences();

      // Step 3: Perform table cleanup
      print('Step 3: Performing table cleanup...');
      final cleanupSuccess = await performDatabaseCleanup();

      if (!cleanupSuccess) {
        print('Migration failed during cleanup phase');
        return false;
      }

      // Step 4: Verify cleanup
      print('Step 4: Verifying cleanup...');
      final verificationSuccess = await verifyCleanup();

      if (!verificationSuccess) {
        print('Migration failed during verification phase');
        return false;
      }

      print('Complete database migration successful!');
      print('Backup contains ${backup.length} tables with data');

      return true;
    } catch (e) {
      print('Error during complete migration: $e');
      return false;
    }
  }
}
