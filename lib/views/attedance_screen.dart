import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../data/local/db_academic.dart';
import 'camera_capture_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();

  // Foto disimpan sebagai bytes (Uint8List) supaya kompatibel di HP
  // maupun Web (dart:io File tidak berfungsi di Flutter Web).
  Uint8List? _imageBytes;

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  double _distance = 0;

  // Titik lokasi kampus (target presensi)
  final double _targetLatitude = -6.253288;
  final double _targetLongitude = 107.003105;
  final double _maxRadiusInMeters = 100.0;

  bool get _isWithinRadius => _distance <= _maxRadiusInMeters;

  // ------------------------------------------------------------------
  // KAMERA (mendukung kamera HP & kamera Web/browser via package `camera`)
  // ------------------------------------------------------------------
  Future<void> _openLiveCamera() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(
          preferredDirection: CameraLensDirection.front,
        ),
      ),
    );

    if (result != null) {
      setState(() => _imageBytes = result);
    }
  }

  // Alternatif: pilih foto dari galeri (fallback jika kamera device
  // bermasalah / tidak tersedia).
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // ------------------------------------------------------------------
  // LOKASI GPS
  // ------------------------------------------------------------------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    // Cek apakah GPS perangkat aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi (GPS) Anda belum aktif!')),
      );
      setState(() => _isLoadingLocation = false);
      return;
    }

    // Cek izin akses GPS dari user
    LocationPermission permission = await Geolocator.checkPermission();
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
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi ditolak permanen. Aktifkan lewat pengaturan perangkat.'),
        ),
      );
      setState(() => _isLoadingLocation = false);
      return;
    }

    // Dapatkan koordinat lokasi presisi
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _targetLatitude,
        _targetLongitude,
      );

      setState(() {
        _currentPosition = position;
        _distance = distance;
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

  // ------------------------------------------------------------------
  // SUBMIT PRESENSI
  // ------------------------------------------------------------------
  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
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

    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetLatitude,
      _targetLongitude,
    );
    final isWithinRadius = distanceInMeters <= _maxRadiusInMeters;

    // Foto disimpan sebagai base64 di kolom TEXT `imagePath`, agar sama-sama
    // berfungsi baik di SQLite mobile/desktop maupun bila suatu saat
    // disinkronkan ke backend melalui JSON/API.
    final attendanceData = {
      'studentName': 'Mahasiswa Akademik (12345)',
      'subject': _subjectController.text,
      'imagePath': base64Encode(_imageBytes!),
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'status': isWithinRadius ? 'Hadir (Valid)' : 'Hadir (Luar Radius)',
      'time': DateTime.now().toString().substring(0, 16),
    };

    await DBAacademic.instance.insertAttendance(attendanceData);

    if (!mounted) return;

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
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah Saat Ini',
                  prefixIcon: const Icon(Icons.class_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama mata kuliah tidak boleh kosong!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildCameraCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 20),

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

  // ------------------------------------------------------------------
  // WIDGET: Kartu Kamera
  // ------------------------------------------------------------------
  Widget _buildCameraCard() {
    return Card(
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
            _imageBytes == null
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
                    child: Image.memory(
                      _imageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openLiveCamera,
                    icon: const Icon(Icons.camera),
                    label: const Text('Buka Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // WIDGET: Kartu Lokasi + Peta
  // ------------------------------------------------------------------
  Widget _buildLocationCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Verifikasi GPS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(_currentPosition == null ? 'Ambil Lokasi' : 'Perbarui Lokasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            if (_isLoadingLocation) const CircularProgressIndicator(),

            if (_currentPosition != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      initialZoom: 17,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.project_uas_sistem_akademik',
                      ),

                      // Garis penghubung antara lokasi user & kampus,
                      // supaya jarak terlihat jelas secara visual di peta.
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              LatLng(_targetLatitude, _targetLongitude),
                            ],
                            strokeWidth: 3,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),

                      // Radius area presensi yang valid di sekitar kampus
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(_targetLatitude, _targetLongitude),
                            radius: _maxRadiusInMeters,
                            useRadiusInMeter: true,
                            color: Colors.green.withValues(alpha: .20),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_targetLatitude, _targetLongitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.school, size: 36, color: Colors.blue),
                          ),
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.person_pin_circle,
                              size: 42,
                              color: _isWithinRadius ? Colors.green.shade700 : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latitude  : ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                        Text('Longitude : ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                        Text('Akurasi   : ${_currentPosition!.accuracy.toStringAsFixed(1)} m'),
                        Text(
                          'Jarak ke Kampus : ${_distance.toStringAsFixed(1)} m',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: _isWithinRadius ? Colors.green : Colors.red,
                    label: Text(
                      _isWithinRadius ? '✓ Dalam Radius' : '✗ Di Luar Radius',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
