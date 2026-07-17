import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local/db_academic.dart';
import '../data/models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  String? _photoBase64;
  Uint8List? _photoBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DBAacademic.instance.getProfile();
    if (profile != null) {
      _nameController.text = profile.name;
      _npmController.text = profile.npm;
      _kelasController.text = profile.kelas;
      _jurusanController.text = profile.jurusan;
      if (profile.photoBase64 != null && profile.photoBase64!.isNotEmpty) {
        setState(() {
          _photoBase64 = profile.photoBase64;
          _photoBytes = base64Decode(profile.photoBase64!);
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final encoded = base64Encode(bytes);

    setState(() {
      _photoBase64 = encoded;
      _photoBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = ProfileModel(
        name: _nameController.text,
        npm: _npmController.text,
        kelas: _kelasController.text,
        jurusan: _jurusanController.text,
        photoBase64: _photoBase64,
      );
      await DBAacademic.instance.saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                      child: _photoBytes == null
                          ? const Icon(Icons.person, size: 64, color: Colors.white)
                          : null,
                    ),
                    FloatingActionButton.small(
                      onPressed: _showImageSourceDialog,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _npmController,
                decoration: InputDecoration(
                  labelText: 'NPM',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NPM harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kelasController,
                decoration: InputDecoration(
                  labelText: 'Kelas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kelas harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jurusanController,
                decoration: InputDecoration(
                  labelText: 'Jurusan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jurusan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SIMPAN PROFIL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unggah Foto Profil'),
        content: const Text('Pilih metode untuk mengambil atau memilih foto profil.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Kamera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Galeri'),
          ),
        ],
      ),
    );
  }
}
