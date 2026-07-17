import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum memuat file env
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop sqflite initialization removed — app now uses SharedPreferences

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