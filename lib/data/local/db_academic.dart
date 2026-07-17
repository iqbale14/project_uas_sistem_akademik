import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment_model.dart';
import '../models/profile_model.dart';

class DBAacademic {
  static final DBAacademic instance = DBAacademic._init();

  DBAacademic._init();

  Future<List<AssignmentModel>> getAllAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('assignments');
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => AssignmentModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> insertAssignment(AssignmentModel assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();
    final id = assignment.id ?? DateTime.now().millisecondsSinceEpoch;

    final entry = AssignmentModel(
      id: id,
      title: assignment.title,
      subject: assignment.subject,
      description: assignment.description,
      dueDate: assignment.dueDate,
    );

    assignments.insert(0, entry);
    await prefs.setString(
      'assignments',
      jsonEncode(assignments.map((item) => item.toMap()).toList()),
    );
    return id;
  }

  Future<int> updateAssignment(AssignmentModel assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();
    final index = assignments.indexWhere((item) => item.id == assignment.id);
    if (index == -1) return 0;

    assignments[index] = assignment;
    await prefs.setString(
      'assignments',
      jsonEncode(assignments.map((item) => item.toMap()).toList()),
    );
    return 1;
  }

  Future<int> deleteAssignment(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();
    final filtered = assignments.where((item) => item.id != id).toList();
    await prefs.setString(
      'assignments',
      jsonEncode(filtered.map((item) => item.toMap()).toList()),
    );
    return assignments.length - filtered.length;
  }

  Future<int> saveProfile(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile', jsonEncode(profile.toMap()));
    return profile.id ?? 1;
  }

  Future<ProfileModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('profile');
    if (raw == null || raw.isEmpty) return null;
    return ProfileModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }
// --- KODE BARU UNTUK ABSENSI (ATTENDANCE) ---

  // Fungsi untuk mengambil semua data absensi yang tersimpan
  Future<List<dynamic>> getAllAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('attendance');
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list;
    // Catatan: Jika Anda sudah punya AttendanceModel, ubah baris di atas menjadi:
    // return list.map((item) => AttendanceModel.fromMap(Map<String, dynamic>.from(item))).toList();
  }

  // Fungsi insertAttendance yang dicari oleh file attedance_screen.dart Anda
  Future<int> insertAttendance(Map<String, dynamic> attendanceData) async {
    final prefs = await SharedPreferences.getInstance();
    final attendanceList = await getAllAttendance();

    // Buat ID unik berdasarkan waktu saat ini jika belum ada ID-nya
    final id = attendanceData['id'] ?? DateTime.now().millisecondsSinceEpoch;
    attendanceData['id'] = id;

    // Masukkan data baru ke baris paling atas
    attendanceList.insert(0, attendanceData);

    // Simpan kembali list yang baru ke SharedPreferences
    await prefs.setString(
      'attendance',
      jsonEncode(attendanceList),
    );

    return id;
  }
}
