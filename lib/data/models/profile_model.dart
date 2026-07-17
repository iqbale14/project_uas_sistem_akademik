class ProfileModel {
  final int? id;
  final String name;
  final String npm;
  final String kelas;
  final String jurusan;
  final String? photoBase64;

  ProfileModel({
    this.id,
    required this.name,
    required this.npm,
    required this.kelas,
    required this.jurusan,
    this.photoBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'npm': npm,
      'kelas': kelas,
      'jurusan': jurusan,
      'photoBase64': photoBase64,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      npm: map['npm'] as String,
      kelas: map['kelas'] as String,
      jurusan: map['jurusan'] as String,
      photoBase64: map['photoBase64'] as String?,
    );
  }
}
