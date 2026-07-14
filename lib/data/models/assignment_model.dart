class AssignmentModel {
  final int? id;
  final String title;
  final String subject;
  final String description;
  final String dueDate;

  AssignmentModel({
    this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueDate,
  });

  // Mengubah objek Dart menjadi Map (Format yang dimengerti SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'dueDate': dueDate,
    };
  }

  // Mengubah Map dari SQLite kembali menjadi objek Dart
  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      description: map['description'],
      dueDate: map['dueDate'],
    );
  }
}