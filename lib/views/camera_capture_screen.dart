import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Layar kamera live yang jalan di HP (Android/iOS) MAUPUN di Web (via
/// package `camera_web`, yang otomatis dipakai Flutter saat build web).
///
/// Berbeda dengan `image_picker` (yang di web hanya membuka file-input /
/// tidak selalu bisa akses kamera langsung), package `camera` membuka
/// stream video asli dari kamera device / browser lewat izin
/// getUserMedia(), sehingga bisa dipakai untuk preview + capture di kedua
/// platform.
///
/// Return value: `Uint8List?` (bytes gambar hasil jepretan), di-pop lewat
/// `Navigator.pop(context, bytes)`.
class CameraCaptureScreen extends StatefulWidget {
  final CameraLensDirection preferredDirection;

  const CameraCaptureScreen({
    super.key,
    this.preferredDirection = CameraLensDirection.front,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage =
              'Tidak ada kamera yang terdeteksi.\nPastikan perangkat memiliki kamera '
              'dan izin kamera sudah diizinkan di browser/HP.';
          _isInitializing = false;
        });
        return;
      }

      _cameras = cameras;
      final preferredIndex = _cameras.indexWhere(
        (c) => c.lensDirection == widget.preferredDirection,
      );
      _selectedCameraIndex = preferredIndex != -1 ? preferredIndex : 0;

      await _initController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal mengakses kamera: $e\n\nDi Web: pastikan situs diakses lewat '
            'HTTPS/localhost dan izin kamera browser diizinkan.\n'
            'Di HP: pastikan izin kamera aplikasi sudah diaktifkan.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initController(CameraDescription description) async {
    final previousController = _controller;

    final newController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _controller = newController;
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await newController.initialize();
      await previousController?.dispose();
      if (!mounted) return;
      setState(() => _isInitializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal menginisialisasi kamera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final XFile file = await controller.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ambil Foto Presensi'),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Ganti kamera',
              icon: const Icon(Icons.cameraswitch),
              onPressed: _isInitializing ? null : _switchCamera,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _setupCameras,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (_isInitializing || controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),

        // Tombol shutter
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _capture,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white54, width: 4),
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.black87, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
