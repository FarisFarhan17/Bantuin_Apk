import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saldo.dart';
import '../models/donasi.dart';
import '../models/donation_history_entry.dart';
import '../models/user_admin.dart';
import 'dart:io';
import 'dart:convert';

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
    required DateTime timestamp,
  }) async {
    await _db.collection('user_donations').add({
      'userId': userId,
      'donasiId': donasiId,
      'donasiTitle': donasiTitle,
      'amount': amount,
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
        status: 'Proses',
        timestamp: DateTime.now(),
      )];
    }
    return snapshot.docs.map((doc) => Donasi.fromMap(doc.id, doc.data())).toList();
  }

  Future<String> uploadBuktiDonasi(File buktiFile) async {
    try {
      // Read the file as bytes
      final bytes = await buktiFile.readAsBytes();
      // Convert to base64 string
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error processing bukti donasi: $e');
      throw e;
    }
  }

  Future<void> updateDonasiStatus({
    required String donasiId,
    required String status,
    String? buktiBase64,
  }) async {
    try {
      await _db.collection('user_donations_items').doc(donasiId).update({
        'status': status,
        if (buktiBase64 != null) 'bukti_image': buktiBase64,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating donation status: $e');
      throw e;
    }
  }

  Future<List<Donasi>> getDonasiStatusList() async {
    try {
      // First, get all donations for the user without status filter
      final allDonationsSnapshot = await _db
          .collection('user_donations_items')
          .where('user_id', isEqualTo: 'donatur_1')
          .get();

      print('Total donations found: ${allDonationsSnapshot.docs.length}');
      
      // Print each donation's data for debugging
      for (var doc in allDonationsSnapshot.docs) {
        print('Donation ID: ${doc.id}');
        print('Raw Data: ${doc.data()}');
      }

      // Now get the filtered donations
      final itemDonationsSnapshot = await _db
          .collection('user_donations_items')
          .where('user_id', isEqualTo: 'donatur_1')
          .where('status', whereIn: ['Proses', 'Konfirming'])
          .get();

      print('Filtered donations found: ${itemDonationsSnapshot.docs.length}');

      // Convert item donations to Donasi objects
      final donations = itemDonationsSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing donation data:');
        print(data);
        
        final donasi = Donasi(
          id: doc.id,
          judul: data['donasi_title'] ?? 'Donasi ${data['item_name']}',
          yayasan: data['yayasan_name'] ?? 'Donasi Barang',
          deskripsi: 'Jumlah: ${data['quantity']} ${data['item_name']} (lat:${data['yayasan_lat']},lon:${data['yayasan_lon']})',
          target: 0,
          terkumpul: 0,
          gambar: data['bukti_image'] ?? '',
          barang: [],
          cerita: '',
          penggalang: '',
          verifikasi: true,
          jumlahDonasi: 0,
          lokasi: data['yayasan_address'] ?? '',
          sisaHari: 0,
          status: data['status'] ?? 'Proses',
          buktiImage: data['bukti_image'],
          timestamp: data['created_at'] != null 
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now(),
        );
        
        print('Created Donasi object:');
        print('Yayasan: ${donasi.yayasan}');
        print('Lokasi: ${donasi.lokasi}');
        print('Deskripsi: ${donasi.deskripsi}');
        
        return donasi;
      }).toList();

      return donations;
    } catch (e) {
      print('Error getting donation status list: $e');
      return [];
    }
  }

  // Method to add item donation
  Future<void> addItemDonation({
    required String userId,
    required String donasiId,
    required String itemName,
    required int quantity,
    String? buktiBase64,
    required String yayasanName,
    required String yayasanAddress,
    required double yayasanLat,
    required double yayasanLon,
  }) async {
    print('Adding item donation with yayasan data:');
    print('Name: $yayasanName');
    print('Address: $yayasanAddress');
    print('Lat: $yayasanLat');
    print('Lon: $yayasanLon');

    final donationData = {
      'user_id': userId,
      'donasi_id': donasiId,
      'item_name': itemName,
      'quantity': quantity,
      'bukti_image': buktiBase64,
      'status': 'Proses',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'donasi_title': 'Donasi $itemName',
      'donasi_description': 'Jumlah: $quantity $itemName',
      'yayasan_name': yayasanName,
      'yayasan_address': yayasanAddress,
      'yayasan_lat': yayasanLat,
      'yayasan_lon': yayasanLon,
    };

    print('Donation data to be stored:');
    print(donationData);

    await _db.collection('user_donations_items').add(donationData);
  }

  Future<void> addAdminUser(UserAdmin adminUser) async {
    await _db.collection('admin_users').add(adminUser.toMap());
  }

  Future<UserAdmin?> getAdminUser(String email) async {
    final snapshot = await _db
        .collection('admin_users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return UserAdmin.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }
} 