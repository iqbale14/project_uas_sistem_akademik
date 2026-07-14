import 'package:flutter/material.dart';
import '../data/remote/api_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _apiService.fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat pengumuman:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pengumuman terbaru.'));
          }

          final announcements = snapshot.data!;

          // Poin 4 & 7: Menampilkan list data yang didapat dari REST API
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final post = announcements[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'PENGUMUMAN #${post['id']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        post['title'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
  post['body'],
  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
  textAlign: TextAlign.justify, // <--- Diubah menggunakan TextAlign agar rapi kiri-kanan
),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}