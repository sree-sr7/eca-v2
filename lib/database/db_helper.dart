import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static Database? _database;
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat timeFormatter = DateFormat('HH:mm');
  static const int DATABASE_VERSION = 2; // Increased version number

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'elderly_care.db');

    return openDatabase(
      dbPath,
      version: DATABASE_VERSION, // Use the constant
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Users Table
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name VARCHAR(100) NOT NULL,
        last_name TEXT NOT NULL,
        age INTEGER NOT NULL,
        phone_number VARCHAR(15) NOT NULL,
        email VARCHAR(100) NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) CHECK(role IN ('elderly','caregiver','admin')),
        caregiver_id INTEGER,
        date_of_birth TEXT,
        gender TEXT,
        blood_group TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        address TEXT,
        relationship TEXT,
        chronic_conditions TEXT,
        allergies TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_synced_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (caregiver_id) REFERENCES users(user_id)
      )
    ''');

    // Create Medications Table
    await db.execute('''
      CREATE TABLE medications (
        medication_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name VARCHAR(100) NOT NULL,
        dosage VARCHAR(50) NOT NULL,
        reminder_time TIME NOT NULL,
        frequency VARCHAR(50) NOT NULL,
        stock INTEGER DEFAULT 0,
        last_updated DATETIME,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        notes TEXT,
        taken INTEGER DEFAULT 0,
        date TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // Create Appointments Table
    await db.execute('''
      CREATE TABLE appointments (
        appointment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        doctor_name VARCHAR(100) NOT NULL,
        date VARCHAR(100) NOT NULL,
        time DATE NOT NULL,
        status VARCHAR(100) NOT NULL,
        specialty TEXT,
        location TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // Create Notifications Table
    await db.execute('''
      CREATE TABLE notifications (
        notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        caregiver_id INTEGER,
        medication_id INTEGER,
        appointment_id INTEGER,
        message TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        status TEXT CHECK(status IN ('Unread','Read')) DEFAULT 'Unread',
        sos_latitude REAL,
        sos_longitude REAL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (caregiver_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (medication_id) REFERENCES medications(medication_id) ON DELETE CASCADE,
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
      )
    ''');

    // Create Careplans Table
    await db.execute('''
      CREATE TABLE careplans (
        careplan_id INTEGER PRIMARY KEY AUTOINCREMENT,
        careplan_name TEXT,
        description TEXT,
        monthly_rate REAL NOT NULL
      )
    ''');

    // Create Caregiver Assignments Table
    await db.execute('''
      CREATE TABLE caregiver_assignments (
        assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        caregiver_id INTEGER NOT NULL,
        careplan_id INTEGER NOT NULL,
        status TEXT CHECK(status IN ('Active','Inactive','Completed')) DEFAULT 'Active',
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (caregiver_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (careplan_id) REFERENCES careplans(careplan_id) ON DELETE CASCADE
      )
    ''');

    // Create Payment Table
    await db.execute('''
      CREATE TABLE payment (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        careplan_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT CHECK(status IN ('Paid','Pending','Failed')) DEFAULT 'Pending',
        paid_at DATETIME,
        transaction_id TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (careplan_id) REFERENCES careplans(careplan_id) ON DELETE CASCADE
      )
    ''');

    // Create Offline Sync Log Table
    await db.execute('''
      CREATE TABLE offline_sync_log (
        sync_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        status TEXT CHECK(status IN ('Pending','Synced','Failed')) DEFAULT 'Pending',
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        last_attempt TEXT,
        error_message TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // Create Caregiver Feedback Table
    await db.execute('''
      CREATE TABLE caregiver_feedback (
        feedback_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        caregiver_id INTEGER NOT NULL,
        rating INTEGER CHECK(rating BETWEEN 1 AND 5),
        review TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (caregiver_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // Create Caregiver Table
    await db.execute('''
      CREATE TABLE caregiver (
        caregiver_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        qualification TEXT NOT NULL,
        experience INTEGER NOT NULL,
        specialization TEXT NOT NULL,
        availability TEXT NOT NULL,
        assigned_status TEXT DEFAULT 'unassigned',
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // Insert Default Admin
    await db.insert('users', {
      'first_name': 'Admin',
      'last_name': 'User',
      'age': 30,
      'email': 'admin@eca.com',
      'phone_number': '1234567890',
      'password': '***REMOVED***',
      'role': 'admin'
    });
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // If upgrading from version 1 to version 2, add the age column if it doesn't exist
      try {
        // Check if age column exists
        var result = await db.rawQuery("PRAGMA table_info(users)");
        bool hasAgeColumn = false;
        for (var column in result) {
          if (column['name'] == 'age') {
            hasAgeColumn = true;
            break;
          }
        }

        if (!hasAgeColumn) {
          await db.execute("ALTER TABLE users ADD COLUMN age INTEGER DEFAULT 0 NOT NULL");
        }
      } catch (e) {
        print("Error during upgrade: $e");
      }
    }
  }

  // Helper methods for date and time formatting
  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return dateFormatter.format(parsedDate);
    } catch (e) {
      final possibleFormats = [
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('yyyy/MM/dd'),
        DateFormat('dd-MM-yyyy'),
      ];

      for (var format in possibleFormats) {
        try {
          final parsedDate = format.parse(date);
          return dateFormatter.format(parsedDate);
        } catch (_) {
          // Continue to next format
        }
      }
      return date; // Return original if we can't parse it
    }
  }

  String formatTime(String time) {
    try {
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].split(' ')[0]);
          final timeObj = DateTime(2022, 1, 1, hour, minute);
          return timeFormatter.format(timeObj);
        }
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  // USER OPERATIONS
  Future<int> insertUser({
    required String firstName,
    required String lastName,
    required int age,
    required String phoneNumber,
    required String email,
    required String password,
    required String role,
    int? caregiverId,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? relationship,
    String? chronicConditions,
    String? allergies,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> existingUsers = await db.query(
        'users',
        where: "email = ?",
        whereArgs: [email]
    );

    if (existingUsers.isNotEmpty) {
      return Future.error("User with this email already exists");
    }

    final formattedDob = dateOfBirth != null ? formatDate(dateOfBirth) : null;
    return await db.insert('users', {
      "first_name": firstName,
      "last_name": lastName,
      "age": age,
      "phone_number": phoneNumber,
      "email": email,
      "password": password,
      "role": role,
      "caregiver_id": caregiverId,
      "date_of_birth": formattedDob,
      "gender": gender,
      "blood_group": bloodGroup,
      "emergency_contact_name": emergencyContactName,
      "emergency_contact_phone": emergencyContactPhone,
      "address": address,
      "relationship": relationship,
      "chronic_conditions": chronicConditions,
      "allergies": allergies,
      "created_at": DateTime.now().toIso8601String(),
      "last_synced_at": DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'users',
        where: "email = ?",
        whereArgs: [email]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'users',
        where: "user_id = ?",
        whereArgs: [userId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(int userId, Map<String, dynamic> updatedData) async {
    final db = await database;
    if (updatedData.containsKey("date_of_birth")) {
      updatedData["date_of_birth"] = formatDate(updatedData["date_of_birth"]);
    }
    updatedData["last_synced_at"] = DateTime.now().toIso8601String();
    return await db.update('users', updatedData, where: "user_id = ?", whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final db = await database;
    return await db.query('users', where: "role = ?", whereArgs: [role]);
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete('users', where: "user_id = ?", whereArgs: [userId]);
  }

  // MEDICATION OPERATIONS
  Future<int> insertMedication({
    required int userId,
    required String name,
    required String dosage,
    required String reminderTime,
    required String frequency,
    required int stock,
    required String date,
    required String scheduleType,
    String? notes,
  }) async {
    final db = await database;
    final formattedDate = formatDate(date);
    final formattedTime = formatTime(reminderTime);

    return await db.insert('medications', {
      "user_id": userId,
      "name": name,
      "dosage": dosage,
      "reminder_time": formattedTime,
      "frequency": frequency,
      "stock": stock,
      "date": formattedDate,
      "schedule_type": scheduleType,
      "last_updated": DateTime.now().toIso8601String(),
      "notes": notes,
      "taken": 0,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMedications(int userId) async {
    final db = await database;
    return await db.query('medications', where: "user_id = ?", whereArgs: [userId]);
  }

  Future<Map<String, dynamic>?> getMedicationById(int medicationId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'medications',
        where: "medication_id = ?",
        whereArgs: [medicationId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateMedication(int medicationId, Map<String, dynamic> updatedData) async {
    final db = await database;
    if (updatedData.containsKey("date")) {
      updatedData["date"] = formatDate(updatedData["date"]);
    }
    if (updatedData.containsKey("reminder_time")) {
      updatedData["reminder_time"] = formatTime(updatedData["reminder_time"]);
    }
    updatedData["last_updated"] = DateTime.now().toIso8601String();
    return await db.update('medications', updatedData, where: "medication_id = ?", whereArgs: [medicationId]);
  }

  Future<int> updateMedicationStatus(int medicationId, bool taken) async {
    final db = await database;
    return await db.update(
      'medications',
      {
        "taken": taken ? 1 : 0,
        "last_updated": DateTime.now().toIso8601String()
      },
      where: "medication_id = ?",
      whereArgs: [medicationId],
    );
  }

  Future<int> deleteMedication(int medicationId) async {
    final db = await database;
    return await db.delete('medications', where: "medication_id = ?", whereArgs: [medicationId]);
  }

  // APPOINTMENT OPERATIONS
  Future<int> insertAppointment({
    required int userId,
    required String doctorName,
    required String date,
    required String time,
    required String status,
    String? specialty,
    String? location,
    String? notes,
  }) async {
    final db = await database;
    final formattedDate = formatDate(date);
    final formattedTime = formatTime(time);

    return await db.insert('appointments', {
      "user_id": userId,
      "doctor_name": doctorName,
      "date": formattedDate,
      "time": formattedTime,
      "status": status,
      "specialty": specialty,
      "location": location,
      "notes": notes,
    });
  }

  Future<List<Map<String, dynamic>>> getAppointments(int userId) async {
    final db = await database;
    return await db.query('appointments', where: "user_id = ?", whereArgs: [userId]);
  }

  Future<Map<String, dynamic>?> getAppointmentById(int appointmentId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'appointments',
        where: "appointment_id = ?",
        whereArgs: [appointmentId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateAppointment({
    required int appointmentId,
    required String doctorName,
    required String date,
    required String time,
    String? specialty,
    String? location,
    String? notes,
  }) async {
    final db = await database;
    final formattedDate = formatDate(date);
    final formattedTime = formatTime(time);

    return await db.update(
        'appointments',
        {
          "doctor_name": doctorName,
          "date": formattedDate,
          "time": formattedTime,
          "specialty": specialty,
          "location": location,
          "notes": notes,
        },
        where: "appointment_id = ?",
        whereArgs: [appointmentId]
    );
  }

  Future<int> deleteAppointment(int appointmentId) async {
    final db = await database;
    return await db.delete('appointments', where: "appointment_id = ?", whereArgs: [appointmentId]);
  }

  // NOTIFICATION OPERATIONS
  Future<int> insertNotification({
    required int userId,
    int? caregiverId,
    int? medicationId,
    int? appointmentId,
    required String message,
    double? sosLatitude,
    double? sosLongitude,
  }) async {
    final db = await database;

    return await db.insert('notifications', {
      "user_id": userId,
      "caregiver_id": caregiverId,
      "medication_id": medicationId,
      "appointment_id": appointmentId,
      "message": message,
      "created_at": DateTime.now().toIso8601String(),
      "status": "Unread",
      "sos_latitude": sosLatitude,
      "sos_longitude": sosLongitude,
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final db = await database;
    return await db.query('notifications', where: "user_id = ?", whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getCaregiverNotifications(int caregiverId) async {
    final db = await database;
    return await db.query('notifications', where: "caregiver_id = ?", whereArgs: [caregiverId]);
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {"status": "Read"},
      where: "notification_id = ?",
      whereArgs: [notificationId],
    );
  }

  Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    return await db.delete('notifications', where: "notification_id = ?", whereArgs: [notificationId]);
  }

  Future<int> insertNotificationMap(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification);
  }

  Future<int> updateNotification(int notificationId, Map<String, dynamic> notification) async {
    final db = await database;
    return await db.update(
      'notifications',
      notification,
      where: 'notification_id = ?',
      whereArgs: [notificationId],
    );
  }

// Get all active caregivers for a user
  Future<List<Map<String, dynamic>>> getActiveCaregiversForUser(int userId) async {
    final db = await database;

    // Join with caregiver_assignments to get caregivers assigned to this user
    final List<Map<String, dynamic>> caregivers = await db.rawQuery('''
    SELECT u.* FROM users u
    INNER JOIN caregiver_assignments ca ON u.user_id = ca.caregiver_id
    WHERE ca.user_id = ? AND ca.status = 'Active'
    AND datetime('now') BETWEEN datetime(ca.start_date) AND datetime(ca.end_date)
  ''', [userId]);

    return caregivers;
  }

// Get the most recent SOS notification for a user
  Future<Map<String, dynamic>?> getMostRecentSOSNotification(int userId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'notifications',
      where: 'user_id = ? AND sos_latitude IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

// Get all unread SOS notifications
  // Get all unread SOS notifications
  Future<List<Map<String, dynamic>>> getUnreadSOSNotifications(int caregiverId) async {
    final db = await database;

    if (caregiverId == 0) {
      // Get all unread SOS notifications
      return await db.query(
        'notifications',
        where: 'sos_latitude IS NOT NULL',
        orderBy: 'created_at DESC',
      );
    } else {
      // Get notifications for a specific caregiver
      return await db.query(
        'notifications',
        where: 'caregiver_id = ? AND status = ? AND sos_latitude IS NOT NULL',
        whereArgs: [caregiverId, 'Unread'],
        orderBy: 'created_at DESC',
      );
    }
  }

  // CAREPLAN OPERATIONS
  Future<int> insertCareplan({
    required String careplanName,
    required String description,
    required double monthlyRate,
  }) async {
    final db = await database;

    return await db.insert('careplans', {
      "careplan_name": careplanName,
      "description": description,
      "monthly_rate": monthlyRate,
    });
  }

  Future<List<Map<String, dynamic>>> getCareplans() async {
    final db = await database;
    return await db.query('careplans');
  }

  Future<Map<String, dynamic>?> getCareplanById(int careplanId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'careplans',
        where: "careplan_id = ?",
        whereArgs: [careplanId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCareplan(int careplanId, Map<String, dynamic> updatedData) async {
    final db = await database;
    return await db.update('careplans', updatedData, where: "careplan_id = ?", whereArgs: [careplanId]);
  }

  Future<int> deleteCareplan(int careplanId) async {
    final db = await database;
    return await db.delete('careplans', where: "careplan_id = ?", whereArgs: [careplanId]);
  }

  // CAREGIVER ASSIGNMENT OPERATIONS
  Future<int> insertCaregiverAssignment({
    required int userId,
    required int caregiverId,
    required int careplanId,
    required String startDate,
    required String endDate,
    String status = 'Active',
  }) async {
    final db = await database;
    final formattedStartDate = formatDate(startDate);
    final formattedEndDate = formatDate(endDate);

    return await db.insert('caregiver_assignments', {
      "user_id": userId,
      "caregiver_id": caregiverId,
      "careplan_id": careplanId,
      "start_date": formattedStartDate,
      "end_date": formattedEndDate,
      "status": status,
    });
  }

  Future<List<Map<String, dynamic>>> getCaregiverAssignments(int userId) async {
    final db = await database;
    return await db.query('caregiver_assignments', where: "user_id = ?", whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getCaregiverClients(int caregiverId) async {
    final db = await database;
    return await db.query('caregiver_assignments', where: "caregiver_id = ?", whereArgs: [caregiverId]);
  }

  Future<int> updateCaregiverAssignment(int assignmentId, Map<String, dynamic> updatedData) async {
    final db = await database;
    if (updatedData.containsKey("start_date")) {
      updatedData["start_date"] = formatDate(updatedData["start_date"]);
    }
    if (updatedData.containsKey("end_date")) {
      updatedData["end_date"] = formatDate(updatedData["end_date"]);
    }
    return await db.update('caregiver_assignments', updatedData, where: "assignment_id = ?", whereArgs: [assignmentId]);
  }

  Future<int> deleteCaregiverAssignment(int assignmentId) async {
    final db = await database;
    return await db.delete('caregiver_assignments', where: "assignment_id = ?", whereArgs: [assignmentId]);
  }

  // PAYMENT OPERATIONS
  Future<int> insertPayment({
    required int userId,
    required int careplanId,
    required double amount,
    required String transactionId,
    required String paymentMethod,
    String status = 'Pending',
    String? paidAt,
  }) async {
    final db = await database;

    return await db.insert('payment', {
      "user_id": userId,
      "careplan_id": careplanId,
      "amount": amount,
      "transaction_id": transactionId,
      "payment_method": paymentMethod,
      "status": status,
      "paid_at": paidAt,
    });
  }

  Future<List<Map<String, dynamic>>> getPayments(int userId) async {
    final db = await database;
    return await db.query('payment', where: "user_id = ?", whereArgs: [userId]);
  }

  Future<Map<String, dynamic>?> getPaymentById(int paymentId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'payment',
        where: "payment_id = ?",
        whereArgs: [paymentId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updatePayment(int paymentId, Map<String, dynamic> updatedData) async {
    final db = await database;
    return await db.update('payment', updatedData, where: "payment_id = ?", whereArgs: [paymentId]);
  }

  Future<int> deletePayment(int paymentId) async {
    final db = await database;
    return await db.delete('payment', where: "payment_id = ?", whereArgs: [paymentId]);
  }

  // OFFLINE SYNC LOG OPERATIONS
  Future<int> insertSyncLog({
    required int userId,
    required String tableName,
    required int recordId,
    required String operation,
  }) async {
    final db = await database;

    return await db.insert('offline_sync_log', {
      "user_id": userId,
      "table_name": tableName,
      "record_id": recordId,
      "operation": operation,
      "status": "Pending",
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncLogs() async {
    final db = await database;
    return await db.query('offline_sync_log', where: "status = ?", whereArgs: ["Pending"]);
  }

  Future<int> updateSyncLogStatus(int syncId, String status, {String? errorMessage}) async {
    final db = await database;
    return await db.update(
      'offline_sync_log',
      {
        "status": status,
        "last_attempt": DateTime.now().toIso8601String(),
        "error_message": errorMessage,
      },
      where: "sync_id = ?",
      whereArgs: [syncId],
    );
  }

  // CAREGIVER FEEDBACK OPERATIONS
  Future<int> insertCaregiverFeedback({
    required int userId,
    required int caregiverId,
    required int rating,
    String? review,
  }) async {
    final db = await database;

    return await db.insert('caregiver_feedback', {
      "user_id": userId,
      "caregiver_id": caregiverId,
      "rating": rating,
      "review": review,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCaregiverFeedbacks(int caregiverId) async {
    final db = await database;
    return await db.query('caregiver_feedback', where: "caregiver_id = ?", whereArgs: [caregiverId]);
  }

  Future<double> getCaregiverAverageRating(int caregiverId) async {
    final db = await database;
    final result = await db.rawQuery(
        '''
      SELECT AVG(rating) as average_rating 
      FROM caregiver_feedback 
      WHERE caregiver_id = ?
      ''',
        [caregiverId]
    );

    return result.first['average_rating'] == null
        ? 0.0
        : double.parse(result.first['average_rating'].toString());
  }

  // CAREGIVER PROFILE OPERATIONS
  Future<int> insertCaregiverProfile({
    required int userId,
    required String qualification,
    required int experience,
    required String specialization,
    required String availability,
    String assignedStatus = 'unassigned',
  }) async {
    final db = await database;

    return await db.insert('caregiver', {
      "user_id": userId,
      "qualification": qualification,
      "experience": experience,
      "specialization": specialization,
      "availability": availability,
      "assigned_status": assignedStatus,
    });
  }

  Future<Map<String, dynamic>?> getCaregiverProfile(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'caregiver',
        where: "user_id = ?",
        whereArgs: [userId]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCaregiverProfile(int caregiverId, Map<String, dynamic> updatedData) async {
    final db = await database;
    return await db.update('caregiver', updatedData, where: "caregiver_id = ?", whereArgs: [caregiverId]);
  }

  Future<List<Map<String, dynamic>>> getAvailableCaregivers() async {
    final db = await database;
    return await db.query('caregiver', where: "assigned_status = ?", whereArgs: ["unassigned"]);
  }

  // ENHANCED SYNC LOG OPERATIONS
  Future<int> insertOfflineSyncLog(Map<String, dynamic> syncLog) async {
    final db = await database;
    return await db.insert('offline_sync_log', syncLog);
  }

  // Update a sync log entry
  Future<int> updateSyncLog(int syncId, Map<String, dynamic> syncLog) async {
    final db = await database;
    return await db.update(
      'offline_sync_log',
      syncLog,
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
  }

  // Get failed sync log entries
  Future<List<Map<String, dynamic>>> getFailedSyncLogs() async {
    final db = await database;
    return await db.query(
      'offline_sync_log',
      where: 'status = ?',
      whereArgs: ['Failed'],
      orderBy: 'timestamp ASC',
    );
  }

  // Get a notification by ID
  Future<Map<String, dynamic>?> getNotificationById(int notificationId) async {
    final db = await database;
    final result = await db.query(
      'notifications',
      where: 'notification_id = ?',
      whereArgs: [notificationId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Force database recreation (for troubleshooting)
  Future<void> recreateDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'elderly_care.db');

    // Close existing connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the file
    await deleteDatabase(dbPath);

    // Reinitialize the database
    _database = await _initDB();
  }

  // Close Database Connection
  Future<void> closeDB() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}