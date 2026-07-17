class ApiService {
  Future<List<dynamic>> fetchAnnouncements() async {
    // Simulasi loading jaringan selama 1 detik
    await Future.delayed(const Duration(seconds: 1));

    // 👇 DI SINI tempat kamu bisa bebas mengubah isi pengumuman kampusmu!
    return [
      {
        "id": 1,
        "title": "Jadwal Pelaksanaan UAS Semester Genap 2026",
        "body": "Diberitahukan kepada seluruh mahasiswa bahwa Ujian Akhir Semester (UAS) akan dilaksanakan mulai tanggal 20 Juli 2026 secara luring di kampus."
      },
      {
        "id": 2,
        "title": "Pengingat Batas Akhir Presensi Kehadiran",
        "body": "Batas minimum kehadiran mahasiswa untuk dapat mengikuti UAS adalah 75%. Silahkan lakukan pengecekan riwayat presensi Anda secara berkala."
      },
      {
        "id": 3,
        "title": "Pendaftaran Beasiswa Berprestasi Dibuka",
        "body": "Pendaftaran Beasiswa Akademik semester ganjil kini telah dibuka. Silahkan kumpulkan berkas persyaratan ke bagian kemahasiswaan gedung A."
      }
    ];
  }
}