import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:project_uas_sistem_akademik/data/local/db_academic.dart';
import 'package:project_uas_sistem_akademik/data/models/assignment_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert and read assignments from local database', () async {
    final assignment = AssignmentModel(
      title: 'UAS Pemrograman Mobile',
      subject: 'Pemrograman Mobile',
      description: 'Membuat aplikasi Flutter',
      dueDate: '2026-07-20',
    );

    final id = await DBAacademic.instance.insertAssignment(assignment);
    expect(id, greaterThan(0));

    final assignments = await DBAacademic.instance.getAllAssignments();
    expect(assignments, isNotEmpty);
    expect(assignments.any((item) => item.title == assignment.title), isTrue);
  });
}
