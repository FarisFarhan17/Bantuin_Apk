import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saldo.dart';
import '../models/donasi.dart';
import '../models/donation_history_entry.dart';
import '../models/user_admin.dart';
import '../models/item_donation_entry.dart';
import 'dart:io';
import 'dart:convert';

// New model for item donations for verification
// class ItemDonationEntry {
//   final String id;
//   final String donasiId;
//   final String userId;
//   final String itemName;
//   final int quantity;
//   final String? buktiBase64;
//   final String yayasanName;
//   final String yayasanAddress;
//   final double yayasanLat;
//   final double yayasanLon;
//   final String status;
//   final DateTime createdAt;

//   ItemDonationEntry({
//     required this.id,
//     required this.donasiId,
//     required this.userId,
//     required this.itemName,
//     required this.quantity,
//     this.buktiBase64,
//     required this.yayasanName,
//     required this.yayasanAddress,
//     required this.yayasanLat,
//     required this.yayasanLon,
//     required this.status,
//     required this.createdAt,
//   });

//   factory ItemDonationEntry.fromMap(String id, Map<String, dynamic> data) {
//     return ItemDonationEntry(
//       id: id,
//       donasiId: data['donasi_id'] ?? '',
//       userId: data['user_id'] ?? '',
//       itemName: data['item_name'] ?? '',
//       quantity: data['quantity'] ?? 0,
//       buktiBase64: data['bukti_image'],
//       yayasanName: data['yayasan_name'] ?? '',
//       yayasanAddress: data['yayasan_address'] ?? '',
//       yayasanLat: (data['yayasan_lat'] ?? 0.0).toDouble(),
//       yayasanLon: (data['yayasan_lon'] ?? 0.0).toDouble(),
//       status: data['status'] ?? 'Proses',
//       createdAt: (data['created_at'] as Timestamp).toDate(),
//     );
//   }
// }

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

  // Method to get item donations with 'Konfirming' status
  Future<List<ItemDonationEntry>> getKonfirmingItemDonations() async {
    try {
      final snapshot = await _db
          .collection('user_donations_items')
          .where('status', isEqualTo: 'Konfirming')
          .get();
      return snapshot.docs.map((doc) => ItemDonationEntry.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error getting konfirming item donations: $e');
      return [];
    }
  }

  // New method to update item donation status
  Future<void> updateItemDonationStatus({
    required String itemDonationId,
    required String status,
  }) async {
    try {
      await _db.collection('user_donations_items').doc(itemDonationId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating item donation status: $e');
      throw e;
    }
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

  // New method to update collected amount for a specific item within a donasi
  Future<void> updateItemDonasiCollectedAmount({
    required String donasiId,
    required String itemName,
    required int quantity,
  }) async {
    final donasiRef = _db.collection('donasi').doc(donasiId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(donasiRef);
      if (!snapshot.exists) {
        throw Exception("Donasi document does not exist!");
      }

      final data = snapshot.data()!;
      List<dynamic> barangList = data['barang'] ?? [];
      
      // Find and update the specific item
      List<Map<String, dynamic>> updatedBarangList = [];
      bool itemFound = false;
      for (var item in barangList) {
        if (item['nama'] == itemName) {
          updatedBarangList.add({
            ...item,
            'terkumpul': (item['terkumpul'] ?? 0) + quantity,
          });
          itemFound = true;
        } else {
          updatedBarangList.add(item);
        }
      }

      if (!itemFound) {
        print('Warning: Item $itemName not found in donasi $donasiId');
      }

      transaction.update(donasiRef, {
        'barang': updatedBarangList,
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
    // This method should retrieve ALL campaigns, regardless of admin verification status,
    // so the admin can see pending ones.
    final snapshot = await _db.collection('donasi').get();
    if (snapshot.docs.isEmpty) {
      // This block for initial dummy data
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
        'admin_verifikasi': false, // Set to false for pending admin verification
        'jumlah_donasi': 0,
        'lokasi': 'Ternate',
        'sisa_hari': 100,
        'status': 'Proses', // Set status to Proses for dummy data
        'timestamp': DateTime.now().millisecondsSinceEpoch,
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
        adminVerified: false, // Set to false for pending admin verification
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
          adminVerified: data['admin_verifikasi'] ?? false,
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
    try {
      await _db.collection('user_donations_items').add({
        'user_id': userId,
        'donasi_id': donasiId,
        'item_name': itemName,
        'quantity': quantity,
        'bukti_image': buktiBase64,
        'yayasan_name': yayasanName,
        'yayasan_address': yayasanAddress,
        'yayasan_lat': yayasanLat,
        'yayasan_lon': yayasanLon,
        'status': 'Konfirming', // Initial status for item donations awaiting verification
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding item donation: $e');
      throw e;
    }
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

  Future<void> updateDonasiCampaignStatus({
    required String donasiId,
    required String status,
  }) async {
    try {
      await _db.collection('donasi').doc(donasiId).update({
        'admin_verifikasi': status == 'Terverifikasi',
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating campaign verification status: $e');
      throw e;
    }
  }
} 