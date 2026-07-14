import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum memuat file env
  WidgetsFlutterBinding.ensureInitialized();

  // Jika menjalankan di desktop (Windows/Linux/Mac), inisialisasi
  // sqflite_common_ffi supaya `databaseFactory` global tersedia.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load(fileName: ".env"); // Memuat file keamanan .env
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAcademic Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Set halaman utama ke LoginScreen
    );
  }
}