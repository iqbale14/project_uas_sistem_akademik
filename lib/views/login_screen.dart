import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Nanti kita buat file dashboard ini setelah ini

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Poin 6: Widget Form (Kunci global untuk validasi form)
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _login() {
    // Validasi apakah inputan user sudah sesuai aturan
    if (_formKey.currentState!.validate()) {
      // Dummy Login Validation (Bisa dikembangkan dengan API nanti)
      if (_nimController.text == "2301111110068" && _passwordController.text == "admin123") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Berhasil! Selamat datang.')),
        );
        
        // Poin 3: Navigasi (Pindah ke Dashboard dan hapus halaman login dari stack)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIM atau Password salah! (Tips: 12345 / password)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      // Poin 1: Widget Layout (Center & SingleChildScrollView agar tidak error saat keyboard muncul)
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey, // Pasang form key di sini
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Icon Akademik
                const Icon(
                  Icons.school_rounded,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Bani Saleh Academic",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  "Silahkan login menggunakan NIM Anda",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Poin 2 & 6: Widget Form & Component (Input NIM)
                TextFormField(
                  controller: _nimController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NIM (Nomor Induk Mahasiswa)',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  // Validasi Input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIM tidak boleh kosong!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Poin 2 & 6: Widget Form & Component (Input Password)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  // Validasi Input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong!';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Tombol Login
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MASUK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}