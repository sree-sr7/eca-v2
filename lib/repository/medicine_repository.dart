import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../database/db_helper.dart';

class MedicineRepository {
  final DBHelper _dbHelper;
  final int userId;

  MedicineRepository({
    required DBHelper dbHelper,
    required this.userId,
  }) : _dbHelper = dbHelper;

  // Add a new medicine to the database
  Future<bool> insertMedicine(Medicine medicine) async {
    try {
      print('Inserting medicine: ${medicine.name} for user $userId');

      // Convert TimeOfDay to a storable string format
      final timeString = medicine.timeOfDay != null
          ? '${medicine.timeOfDay!.hour.toString().padLeft(2, '0')}:${medicine.timeOfDay!.minute.toString().padLeft(2, '0')}'
          : '';

      // Print the actual data being sent to the database
      print('Insert payload: name=${medicine.name}, dosage=${medicine.dosage}, time=$timeString');
      print('Notes: ${medicine.notes}');

      // Now proceed with insertion using the DBHelper
      final medicationId = await _dbHelper.insertMedication(
        userId: userId,
        name: medicine.name,
        dosage: medicine.dosage,
        reminderTime: timeString,
        frequency: medicine.frequency,
        stock: medicine.stock,
        date: medicine.expiryDate.toIso8601String(),
        scheduleType: medicine.scheduleType, // Use the actual scheduleType
        notes: medicine.notes ?? '', // Store actual notes
      );

      print('Medicine inserted with ID: $medicationId');
      return medicationId > 0;
    } catch (e) {
      print('Error inserting medicine: $e');
      print('Stack trace: ${StackTrace.current}');

      // Try to recover by retrying the insertion
      try {
        return await _retryInsertMedicine(medicine);
      } catch (retryError) {
        print('Retry insertion failed: $retryError');
        return false;
      }
    }
  }

  // Helper method to retry insertion
  Future<bool> _retryInsertMedicine(Medicine medicine) async {
    try {
      print('Retrying medicine insertion');

      final timeString = medicine.timeOfDay != null
          ? '${medicine.timeOfDay!.hour.toString().padLeft(2, '0')}:${medicine.timeOfDay!.minute.toString().padLeft(2, '0')}'
          : '';

      final medicationId = await _dbHelper.insertMedication(
        userId: userId,
        name: medicine.name,
        dosage: medicine.dosage,
        reminderTime: timeString,
        frequency: medicine.frequency,
        stock: medicine.stock,
        date: medicine.expiryDate.toIso8601String(),
        scheduleType: medicine.scheduleType,
        notes: medicine.notes ?? '',
      );

      print('Medicine inserted on retry with ID: $medicationId');
      return medicationId > 0;
    } catch (e) {
      print('Retry insertion also failed: $e');
      return false;
    }
  }

  // Update an existing medicine in the database
  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      print('Updating medicine: ${medicine.name} (${medicine.id})');

      final timeString = medicine.timeOfDay != null
          ? '${medicine.timeOfDay!.hour.toString().padLeft(2, '0')}:${medicine.timeOfDay!.minute.toString().padLeft(2, '0')}'
          : '';

      // Try to parse the id directly
      final medicationId = int.tryParse(medicine.id);
      if (medicationId != null) {
        print('Updating with ID: $medicationId');
        final result = await _dbHelper.updateMedication(
          medicationId,
          {
            'name': medicine.name,
            'dosage': medicine.dosage,
            'frequency': medicine.frequency,
            'reminder_time': timeString,
            'date': medicine.expiryDate.toIso8601String(),
            'notes': medicine.notes ?? '', // Store actual notes
            'taken': medicine.isTaken ? 1 : 0,
            'stock': medicine.stock,
            'schedule_type': medicine.scheduleType,
          },
        );
        print('Medicine updated with ID: $medicationId, result: $result');
        return result > 0;
      } else {
        // If we can't parse the id, try to find the medication by other means
        print('Could not parse ID, searching for medicine by name and dosage');
        final allMeds = await getAllMedicines();
        final existingMed = allMeds.firstWhere(
              (m) => m.name == medicine.name && m.dosage == medicine.dosage,
          orElse: () => throw Exception('Medicine not found'),
        );

        // Use the id we found to update
        final parsedId = int.parse(existingMed.id);
        print('Found medicine with ID: $parsedId');
        final result = await _dbHelper.updateMedication(
          parsedId,
          {
            'name': medicine.name,
            'dosage': medicine.dosage,
            'frequency': medicine.frequency,
            'reminder_time': timeString,
            'date': medicine.expiryDate.toIso8601String(),
            'notes': medicine.notes ?? '', // Store actual notes
            'taken': medicine.isTaken ? 1 : 0,
            'stock': medicine.stock,
            'schedule_type': medicine.scheduleType,
          },
        );
        print('Medicine updated with found ID: $parsedId, result: $result');
        return result > 0;
      }
    } catch (e) {
      print('Error updating medicine: $e');
      return false;
    }
  }

  // Delete a medicine from the database
  Future<bool> deleteMedicine(String id) async {
    try {
      print('Attempting to delete medicine with ID: $id');
      final medicationId = int.tryParse(id);
      if (medicationId != null) {
        final result = await _dbHelper.deleteMedication(medicationId);
        print('Medicine deleted with ID: $medicationId, result: $result');
        return result > 0;
      }

      print('Could not parse medicine id: $id');
      return false;
    } catch (e) {
      print('Error deleting medicine: $e');
      return false;
    }
  }

  // Get all medicines from the database for the current user
  Future<List<Medicine>> getAllMedicines() async {
    try {
      print('Getting all medicines for user $userId');

      final medicationsData = await _dbHelper.getMedications(userId);
      print('Retrieved ${medicationsData.length} medications from database');

      if (medicationsData.isEmpty) {
        print('No medications found in database for user $userId');
        return [];
      }

      final medicines = medicationsData.map((data) {
        // Parse time string to TimeOfDay
        TimeOfDay? timeOfDay;
        final timeString = data['reminder_time'] as String? ?? '';
        if (timeString.isNotEmpty) {
          final timeParts = timeString.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              timeOfDay = TimeOfDay(hour: hour, minute: minute);
            }
          }
        }

        // Parse the date string
        DateTime expiryDate;
        try {
          expiryDate = DateTime.parse(data['date'] as String);
        } catch (e) {
          // Use a default expiry date if parsing fails
          print('Error parsing date: $e');
          expiryDate = DateTime.now().add(const Duration(days: 365));
        }

        // Get the actual notes content
        final notes = data['notes'] as String?;

        return Medicine(
          id: data['medication_id'].toString(),
          name: data['name'] as String,
          dosage: data['dosage'] as String,
          frequency: data['frequency'] as String,
          stock: data['stock'] as int? ?? 0,
          expiryDate: expiryDate,
          timeOfDay: timeOfDay,
          notes: notes, // Store actual notes
          color: Colors.blue, // Use default color from app theme
          icon: Icons.medication, // Use default icon
          isTaken: (data['taken'] as int?) == 1,
          scheduleType: data['schedule_type'] as String? ?? 'daily',
        );
      }).toList();

      print('Processed ${medicines.length} medicines from database data');
      return medicines;
    } catch (e) {
      print('Error getting all medicines: $e');
      return [];
    }
  }

  // Get a specific medicine by ID
  Future<Medicine?> getMedicineById(String id) async {
    try {
      print('Getting medicine by ID: $id');
      final medicationId = int.tryParse(id);
      if (medicationId == null) {
        print('Could not parse medicine ID: $id');
        return null;
      }

      final data = await _dbHelper.getMedicationById(medicationId);
      if (data == null) {
        print('No medicine found with ID: $medicationId');
        return null;
      }

      // Parse time string to TimeOfDay
      TimeOfDay? timeOfDay;
      final timeString = data['reminder_time'] as String? ?? '';
      if (timeString.isNotEmpty) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          if (hour != null && minute != null) {
            timeOfDay = TimeOfDay(hour: hour, minute: minute);
          }
        }
      }

      // Parse the date string
      DateTime expiryDate;
      try {
        expiryDate = DateTime.parse(data['date'] as String);
      } catch (e) {
        // Use a default expiry date if parsing fails
        print('Error parsing date: $e');
        expiryDate = DateTime.now().add(const Duration(days: 365));
      }

      // Get the actual notes
      final notes = data['notes'] as String?;

      return Medicine(
        id: data['medication_id'].toString(),
        name: data['name'] as String,
        dosage: data['dosage'] as String,
        frequency: data['frequency'] as String,
        stock: data['stock'] as int? ?? 0,
        expiryDate: expiryDate,
        timeOfDay: timeOfDay,
        notes: notes, // Store actual notes
        color: Colors.blue, // Use default color from app theme
        icon: Icons.medication, // Use default icon
        isTaken: (data['taken'] as int?) == 1,
        scheduleType: data['schedule_type'] as String? ?? 'daily',
      );
    } catch (e) {
      print('Error getting medicine by ID: $e');
      return null;
    }
  }

  // Update the 'taken' status of a medicine
  Future<bool> updateMedicineTakenStatus(String id, bool isTaken) async {
    try {
      print('Updating medicine taken status for ID: $id, isTaken: $isTaken');
      final medicationId = int.tryParse(id);
      if (medicationId == null) {
        print('Could not parse medicine ID: $id');
        return false;
      }

      final result = await _dbHelper.updateMedicationStatus(medicationId, isTaken);
      print('Medicine taken status updated for ID: $medicationId, result: $result');
      return result > 0;
    } catch (e) {
      print('Error updating medicine taken status: $e');
      return false;
    }
  }

  // Get all medicines that are low in stock (less than 10)
  Future<List<Medicine>> getLowStockMedicines() async {
    final allMedicines = await getAllMedicines();
    return allMedicines.where((medicine) => medicine.stock < 10).toList();
  }

  // Get all medicines that are expiring soon (less than 30 days)
  Future<List<Medicine>> getSoonExpiringMedicines() async {
    final allMedicines = await getAllMedicines();
    final now = DateTime.now();
    return allMedicines.where((medicine) {
      final difference = medicine.expiryDate.difference(now).inDays;
      return difference <= 30 && difference >= 0;
    }).toList();
  }

  // Get all medicines due for today
  Future<List<Medicine>> getTodaysMedicines() async {
    final allMedicines = await getAllMedicines();
    return allMedicines.where((medicine) {
      // Check if medicine should be taken today based on frequency
      bool isDueToday = false;

      switch (medicine.frequency.toLowerCase()) {
        case 'daily':
        case 'twice daily':
        case 'three times daily':
        case 'as needed':
          isDueToday = true;
          break;
        default:
          isDueToday = true;
          break;
      }

      return isDueToday && !medicine.isTaken;
    }).toList();
  }
}