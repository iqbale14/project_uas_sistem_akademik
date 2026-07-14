import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../data/local/db_academic.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();

  File? _imageFile;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  
  // Koordinat Kampus Dummy (contoh: Monas Jakarta)
  // Mahasiswa harus berada di dekat sini untuk presensi sukses
  final double _targetLatitude = -6.175392;
  final double _targetLongitude = 106.827153;
  final double _maxRadiusInMeters = 100.0; // Maksimal jarak 100 meter

  // Poin 8: Fitur Kamera untuk mengambil foto selfie
  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Mengutamakan kamera depan (selfie)
      imageQuality: 50, // Kompres ukuran agar SQLite tidak lambat
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Poin 9: Fitur GPS untuk mengambil koordinat saat ini
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah GPS perangkat aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi (GPS) Anda belum aktif!')),
      );
      setState(() => _isLoadingLocation = false);
      return;
    }

    // Cek izin akses GPS dari user
    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin akses lokasi ditolak!')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    // Dapatkan koordinat lokasi presisi
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    }
  }

  // Fungsi untuk memproses dan menyimpan Presensi
  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda wajib mengambil foto selfie bukti presensi!')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silahkan deteksi koordinat lokasi Anda terlebih dahulu!')),
      );
      return;
    }

    // Hitung jarak antara posisi mahasiswa dengan Kampus (Target)
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetLatitude,
      _targetLongitude,
    );

    bool isWithinRadius = distanceInMeters <= _maxRadiusInMeters;

    // Simpan data presensi ke database lokal SQLite
    final attendanceData = {
      'studentName': 'Mahasiswa Akademik (12345)',
      'subject': _subjectController.text,
      'imagePath': _imageFile!.path,
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'status': isWithinRadius ? 'Hadir (Valid)' : 'Hadir (Luar Radius)',
      'time': DateTime.now().toString().substring(0, 16),
    };

    await DBAacademic.instance.insertAttendance(attendanceData);

    if (!mounted) return;

    // Dialog Hasil Presensi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(
          isWithinRadius ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isWithinRadius ? Colors.green : Colors.orange,
          size: 64,
        ),
        content: Text(
          isWithinRadius
              ? 'Presensi BERHASIL!\nAnda berada di dalam radius kelas (${distanceInMeters.toStringAsFixed(1)} meter dari kampus).'
              : 'Presensi DITERIMA (Luar Radius)!\nJarak Anda: ${distanceInMeters.toStringAsFixed(1)} meter dari kampus (Batas: $_maxRadiusInMeters meter).',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Kelas Digital'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bagian Form Input Mata Kuliah
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah Saat Ini',
                  prefixIcon: const Icon(Icons.class_outlined),
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
              const SizedBox(height: 20),

              // Bagian Kamera (Poin 8)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Bukti Selfie Kelas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _imageFile == null
                          ? Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
                            ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _takeSelfie,
                        icon: const Icon(Icons.camera),
                        label: const Text('Ambil Selfie'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bagian GPS (Poin 9)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Verifikasi GPS Koordinat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _isLoadingLocation
                          ? const CircularProgressIndicator()
                          : _currentPosition == null
                              ? const Text('Koordinat GPS belum dideteksi.', style: TextStyle(color: Colors.grey))
                              : Column(
                                  children: [
                                    Text('Latitude: ${_currentPosition!.latitude}'),
                                    Text('Longitude: ${_currentPosition!.longitude}'),
                                  ],
                                ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Dapatkan Lokasi Sekarang'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Submit Utama
              ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'KIRIM PRESENSI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}