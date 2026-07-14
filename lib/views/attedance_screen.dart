import 'dart:io';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../data/local/db_academic.dart';

File? _imageFile;
Position? _currentPosition;

bool _isLoadingLocation = false;

final double _targetLatitude = -6.253288;
final double _targetLongitude = 107.003105;

final double _maxRadiusInMeters = 100;

double _distance = 0;

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
  
final double _targetLatitude = -6.253288;
final double _targetLongitude = 107.003105;
final double _maxRadiusInMeters = 100.0;

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
      _distance = Geolocator.distanceBetween(
  position.latitude,
  position.longitude,
  _targetLatitude,
  _targetLongitude,
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
  void dispose() {
    _subjectController.dispose();
    super.dispose();
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
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [

        const Text(
          "Verifikasi GPS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: _getCurrentLocation,
          icon: const Icon(Icons.location_searching),
          label: const Text("Ambil Lokasi"),
        ),

        const SizedBox(height: 15),

        if (_isLoadingLocation)
          const CircularProgressIndicator(),

        if (_currentPosition != null) ...[

          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                initialZoom: 18,
              ),
              children: [

                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.presensi",
                ),

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _targetLatitude,
                        _targetLongitude,
                      ),
                      radius: _maxRadiusInMeters,
                      useRadiusInMeter: true,
                      color: Colors.green.withOpacity(.25),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

                MarkerLayer(
                  markers: [

                    Marker(
                      point: LatLng(
                        _targetLatitude,
                        _targetLongitude,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),

                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Latitude : ${_currentPosition!.latitude}",
          ),

          Text(
            "Longitude : ${_currentPosition!.longitude}",
          ),

          Text(
            "Akurasi : ${_currentPosition!.accuracy.toStringAsFixed(1)} meter",
          ),

          Text(
            "Jarak ke Kampus : ${_distance.toStringAsFixed(1)} meter",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Chip(
            backgroundColor:
                _distance <= _maxRadiusInMeters
                    ? Colors.green
                    : Colors.red,
            label: Text(
              _distance <= _maxRadiusInMeters
                  ? "✓ Dalam Radius"
                  : "✗ Di Luar Radius",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ]
      ],
    ),
  ),
),

              const SizedBox(height: 12),

ElevatedButton.icon(
  onPressed: _getCurrentLocation,
  icon: const Icon(Icons.my_location),
  label: const Text('Dapatkan Lokasi Sekarang'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
),

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