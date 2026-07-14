import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assignment_model.dart';

class DBAacademic {
  // Membuat instance singleton agar database hanya terbuka satu kali di aplikasi
  static final DBAacademic instance = DBAacademic._init();
  static Database? _database;

  DBAacademic._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('academic.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Membuat tabel saat database pertama kali dibuat
  Future _createDB(Database db, int version) async {
   await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentName TEXT NOT NULL,
        subject TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  // Fungsi untuk menyimpan Presensi ke SQLite
  Future<int> insertAttendance(Map<String, dynamic> attendanceData) async {
    final db = await instance.database;
    return await db.insert('attendance', attendanceData);
  }

  // 1. Fungsi CREATE (Tambah data tugas)
  Future<int> insertAssignment(AssignmentModel assignment) async {
    final db = await instance.database;
    return await db.insert('assignments', assignment.toMap());
  }

  // 2. Fungsi READ (Ambil semua data tugas)
  Future<List<AssignmentModel>> getAllAssignments() async {
    final db = await instance.database;
    final result = await db.query('assignments', orderBy: 'id DESC');

    return result.map((json) => AssignmentModel.fromMap(json)).toList();
  }

  // 3. Fungsi UPDATE (Ubah data tugas jika diperlukan)
  Future<int> updateAssignment(AssignmentModel assignment) async {
    final db = await instance.database;
    return await db.update(
      'assignments',
      assignment.toMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  // 4. Fungsi DELETE (Hapus data tugas)
  Future<int> deleteAssignment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'assignments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Menutup database jika aplikasi ditutup
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}