import 'package:intl/intl.dart';

class CaregiverAssignment {
  final int? assignmentId;
  final int userId;
  final int caregiverId;
  final int careplanId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  // Additional fields for UI display
  String? caregiverName;
  String? careplanName;
  double? monthlyRate;

  CaregiverAssignment({
    this.assignmentId,
    required this.userId,
    required this.caregiverId,
    required this.careplanId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.caregiverName,
    this.careplanName,
    this.monthlyRate,
  });

  // Create from database map
  factory CaregiverAssignment.fromMap(Map<String, dynamic> map) {
    return CaregiverAssignment(
      assignmentId: map['assignment_id'],
      userId: map['user_id'],
      caregiverId: map['caregiver_id'],
      careplanId: map['careplan_id'],
      status: map['status'] ?? 'Active',
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    return {
      if (assignmentId != null) 'assignment_id': assignmentId,
      'user_id': userId,
      'caregiver_id': caregiverId,
      'careplan_id': careplanId,
      'status': status,
      'start_date': formatter.format(startDate),
      'end_date': formatter.format(endDate),
    };
  }

  // Check if assignment is active based on current date
  bool get isActive {
    final now = DateTime.now();
    return status == 'Active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Calculate days remaining in the assignment
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  // Calculate assignment duration in days
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  // Get formatted date strings
  String get formattedStartDate => DateFormat('MMM d, yyyy').format(startDate);
  String get formattedEndDate => DateFormat('MMM d, yyyy').format(endDate);
}