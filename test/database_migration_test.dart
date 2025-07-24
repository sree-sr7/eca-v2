import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/services/database_migration_service.dart';
import 'package:login_app/utils/database_cleanup_helper.dart';

void main() {
  group('DatabaseMigrationService Tests', () {
    late DatabaseMigrationService migrationService;

    setUp(() {
      migrationService = DatabaseMigrationService();
    });

    test('should successfully perform database cleanup', () async {
      // Get initial table list
      final initialTables = await migrationService.getAllTables();
      debugPrint('Initial tables: $initialTables');

      // Perform cleanup
      final cleanupResult = await migrationService.performDatabaseCleanup();

      expect(cleanupResult, isTrue);

      // Verify cleanup
      final verificationResult = await migrationService.verifyCleanup();
      expect(verificationResult, isTrue);
    });

    test('should verify that removed tables no longer exist', () async {
      // List of tables that should be removed
      const removedTables = [
        'caregiver_assignments',
        'careplans',
        'payment',
        'caregiver_feedback',
      ];

      // Get current tables
      final currentTables = await migrationService.getAllTables();

      // Verify none of the removed tables exist
      for (String tableName in removedTables) {
        expect(
          currentTables.contains(tableName),
          isFalse,
          reason: 'Table $tableName should have been removed',
        );
      }
    });

    test('should retain essential tables after cleanup', () async {
      // List of tables that should remain
      const essentialTables = [
        'users',
        'medications',
        'appointments',
        'notifications',
        'offline_sync_log',
        'caregiver',
      ];

      // Get current tables
      final currentTables = await migrationService.getAllTables();

      // Verify essential tables still exist
      for (String tableName in essentialTables) {
        expect(
          currentTables.contains(tableName),
          isTrue,
          reason: 'Essential table $tableName should be retained',
        );
      }
    });

    test('should perform complete migration successfully', () async {
      final migrationResult = await migrationService.performCompleteMigration();
      expect(migrationResult, isTrue);
    });

    test('should backup table data before cleanup', () async {
      final backup = await migrationService.backupTablesData();

      // Backup should be a map (even if empty)
      expect(backup, isA<Map<String, List<Map<String, dynamic>>>>());

      // Should contain entries for each table that was backed up
      debugPrint('Backup contains ${backup.length} tables');
    });
  });

  group('DatabaseCleanupHelper Tests', () {
    test('should perform initial cleanup successfully', () async {
      final result = await DatabaseCleanupHelper.performInitialCleanup();
      expect(result, isTrue);
    });

    test('should verify database state correctly', () async {
      final result = await DatabaseCleanupHelper.verifyDatabaseState();
      expect(result, isTrue);
    });

    test('should provide database summary', () async {
      final summary = await DatabaseCleanupHelper.getDatabaseSummary();

      expect(summary, isA<Map<String, dynamic>>());
      expect(summary.containsKey('total_tables'), isTrue);
      expect(summary.containsKey('tables'), isTrue);
      expect(summary.containsKey('cleanup_completed'), isTrue);
      expect(summary.containsKey('timestamp'), isTrue);

      debugPrint('Database summary: $summary');
    });
  });
}
