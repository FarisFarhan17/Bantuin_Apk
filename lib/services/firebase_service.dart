import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saldo.dart';
import '../models/donasi.dart';
import '../models/donation_history_entry.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;

  Future<Saldo> getSaldo() async {
    final doc = await _db.collection('saldo').doc('donatur_1').get();
    if (!doc.exists) {
      await _db.collection('saldo').doc('donatur_1').set({'total': 100000});
      return Saldo(id: 'donatur_1', total: 100000);
    }
    return Saldo.fromMap(doc.id, doc.data()!);
  }

  // New method to deduct saldo
  Future<void> deductSaldo(String userId, int amount) async {
    final saldoRef = _db.collection('saldo').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(saldoRef);
      if (!snapshot.exists) {
        throw Exception("User saldo does not exist!");
      }
      final newTotal = snapshot.data()!['total'] - amount;
      if (newTotal < 0) {
        throw Exception("Insufficient saldo");
      }
      transaction.update(saldoRef, {'total': newTotal});
    });
  }

  // New method to add donation history
  Future<void> addDonationHistory({
    required String userId,
    required String donasiId,
    required String donasiTitle,
    required int amount,
    required String status,
    required DateTime timestamp,
  }) async {
    await _db.collection('user_donations').add({
      'userId': userId,
      'donasiId': donasiId,
      'donasiTitle': donasiTitle,
      'amount': amount,
      'status': status,
      'timestamp': timestamp.toIso8601String(), // Store timestamp as string
    });
  }

  // New method to update donation collected amount and donor count
  Future<void> updateDonasiCollectedAmount({
    required String donasiId,
    required int amount,
  }) async {
    final donasiRef = _db.collection('donasi').doc(donasiId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(donasiRef);
      if (!snapshot.exists) {
        throw Exception("Donasi document does not exist!");
      }
      final currentTerkumpul = snapshot.data()!['terkumpul'] ?? 0;
      final currentJumlahDonasi = snapshot.data()!['jumlah_donasi'] ?? 0;
      transaction.update(donasiRef, {
        'terkumpul': currentTerkumpul + amount,
        'jumlah_donasi': currentJumlahDonasi + 1,
      });
    });
  }

  // New method to get donation history for a user
  Future<List<DonationHistoryEntry>> getDonationHistory(String userId) async {
    final snapshot = await _db
        .collection('user_donations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true) // Order by timestamp
        .get();
    return snapshot.docs.map((doc) => DonationHistoryEntry.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<Donasi>> getDonasiList() async {
    final snapshot = await _db.collection('donasi').get();
    if (snapshot.docs.isEmpty) {
      await _db.collection('donasi').doc('donasi_1').set({
        'judul': 'Bantu Korban Banjir Bandang Ternate',
        'yayasan': 'Simpul Setara',
        'deskripsi': 'Solidaritas Bantu Korban Banjir Bandang Ternate!',
        'target': 150000000,
        'terkumpul': 0,
        'gambar': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        'barang': [
          {'nama': 'Selimut', 'target': 100, 'terkumpul': 0},
          {'nama': 'Beras', 'target': 200, 'terkumpul': 0},
          {'nama': 'Mie Instan', 'target': 300, 'terkumpul': 0},
          {'nama': 'Air Mineral', 'target': 400, 'terkumpul': 0},
        ],
        'cerita': 'Kepala Pusat Data, Informasi, dan Komunikasi Kebencanaan Badan Nasional Penanggulangan Bencana (BNPB) Abdul Muhari, dalam keterangan tertulisnya, menuturkan bencana banjir bandang ternate, ini bermula dari hujan dengan intensitas tinggi yang mengguyur wilayah Ternate, Minggu (25/8) pukul 03.30 WIT.',
        'penggalang': 'Simpul Setara',
        'verifikasi': true,
        'jumlah_donasi': 0,
        'lokasi': 'Ternate',
        'sisa_hari': 100,
      });
      return [Donasi(
        id: 'donasi_1',
        judul: 'Bantu Korban Banjir Bandang Ternate',
        yayasan: 'Simpul Setara',
        deskripsi: 'Solidaritas Bantu Korban Banjir Bandang Ternate!',
        target: 150000000,
        terkumpul: 0,
        gambar: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        barang: [
          BarangDonasi(nama: 'Selimut', target: 100, terkumpul: 0),
          BarangDonasi(nama: 'Beras', target: 200, terkumpul: 0),
          BarangDonasi(nama: 'Mie Instan', target: 300, terkumpul: 0),
          BarangDonasi(nama: 'Air Mineral', target: 400, terkumpul: 0),
        ],
        cerita: 'Kepala Pusat Data, Informasi, dan Komunikasi Kebencanaan Badan Nasional Penanggulangan Bencana (BNPB) Abdul Muhari, dalam keterangan tertulisnya, menuturkan bencana banjir bandang ternate, ini bermula dari hujan dengan intensitas tinggi yang mengguyur wilayah Ternate, Minggu (25/8) pukul 03.30 WIT.',
        penggalang: 'Simpul Setara',
        verifikasi: true,
        jumlahDonasi: 0,
        lokasi: 'Ternate',
        sisaHari: 100,
      )];
    }
    return snapshot.docs.map((doc) => Donasi.fromMap(doc.id, doc.data())).toList();
  }
} 