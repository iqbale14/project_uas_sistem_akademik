import 'package:flutter/material.dart';
import '../data/local/db_academic.dart';
import '../data/models/assignment_model.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  // Poin 6: Kunci global untuk Form Validation
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  // Fungsi untuk menampilkan date picker (Poin 2: Widget Component)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        // Format tanggal sederhana: YYYY-MM-DD
        _dueDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Fungsi untuk menyimpan data ke SQLite
  Future<void> _saveAssignment() async {
    if (_formKey.currentState!.validate()) {
      final newAssignment = AssignmentModel(
        title: _titleController.text,
        subject: _subjectController.text,
        description: _descriptionController.text,
        dueDate: _dueDateController.text,
      );

      // Poin 5: Menyimpan ke SQLite secara lokal
      await DBAacademic.instance.insertAssignment(newAssignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas berhasil disimpan secara lokal!')),
        );
        // Poin 3: Navigasi kembali ke halaman utama (Dashboard) sambil memberi sinyal reload
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Tugas Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Poin 1: Widget Layout dengan SingleChildScrollView agar responsif saat keyboard muncul
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul Form
              const Text(
                "Detail Tugas Kuliah",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Isi formulir di bawah ini untuk mencatat tugas kuliah baru Anda ke dalam database lokal perangkat.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 1. Input Judul Tugas (Poin 6: Form Field)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas',
                  prefixIcon: const Icon(Icons.assignment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tugas tidak boleh kosong!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Input Nama Mata Kuliah (Poin 6: Form Field)
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah',
                  prefixIcon: const Icon(Icons.book),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama mata kuliah tidak boleh kosong!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Input Deadline (Poin 2 & 6: Custom component dengan DatePicker)
              TextFormField(
                controller: _dueDateController,
                readOnly: true, // User wajib memilih lewat date picker
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Tenggat Waktu (Deadline)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap pilih tanggal tenggat waktu!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Input Deskripsi Tugas (Poin 6: Form Field multiline)
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Tugas',
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi tugas wajib diisi!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Tugas
              ElevatedButton.icon(
                onPressed: _saveAssignment,
                icon: const Icon(Icons.save),
                label: const Text(
                  'SIMPAN TUGAS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}