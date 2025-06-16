class Donasi {
  final String id;
  final String judul;
  final String yayasan;
  final String deskripsi;
  final int target;
  final int terkumpul;
  final String gambar;
  final List<BarangDonasi> barang;
  final String cerita;
  final String penggalang;
  final bool verifikasi;
  final int jumlahDonasi;
  final String lokasi;
  final int sisaHari;
  final String status;
  final String? buktiImage;

  Donasi({
    required this.id,
    required this.judul,
    required this.yayasan,
    required this.deskripsi,
    required this.target,
    required this.terkumpul,
    required this.gambar,
    required this.barang,
    required this.cerita,
    required this.penggalang,
    required this.verifikasi,
    required this.jumlahDonasi,
    required this.lokasi,
    required this.sisaHari,
    required this.status,
    this.buktiImage,
  });

  factory Donasi.fromMap(String id, Map<String, dynamic> data) {
    return Donasi(
      id: id,
      judul: data['judul'] ?? '',
      yayasan: data['yayasan'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      target: data['target'] ?? 0,
      terkumpul: data['terkumpul'] ?? 0,
      gambar: data['gambar'] ?? '',
      barang: (data['barang'] as List<dynamic>? ?? []).map((b) => BarangDonasi.fromMap(b)).toList(),
      cerita: data['cerita'] ?? '',
      penggalang: data['penggalang'] ?? '',
      verifikasi: data['verifikasi'] ?? false,
      jumlahDonasi: data['jumlah_donasi'] ?? 0,
      lokasi: data['lokasi'] ?? '',
      sisaHari: data['sisa_hari'] ?? 0,
      status: data['status'] ?? 'Proses',
      buktiImage: data['bukti_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'yayasan': yayasan,
      'deskripsi': deskripsi,
      'target': target,
      'terkumpul': terkumpul,
      'gambar': gambar,
      'barang': barang.map((b) => b.toMap()).toList(),
      'cerita': cerita,
      'penggalang': penggalang,
      'verifikasi': verifikasi,
      'jumlah_donasi': jumlahDonasi,
      'lokasi': lokasi,
      'sisa_hari': sisaHari,
      'status': status,
      'bukti_image': buktiImage,
    };
  }
}

class BarangDonasi {
  final String nama;
  final int target;
  final int terkumpul;

  BarangDonasi({required this.nama, required this.target, required this.terkumpul});

  factory BarangDonasi.fromMap(Map<String, dynamic> data) {
    return BarangDonasi(
      nama: data['nama'] ?? '',
      target: data['target'] ?? 0,
      terkumpul: data['terkumpul'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'target': target,
      'terkumpul': terkumpul,
    };
  }
} 