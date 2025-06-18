import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/saldo.dart';
import '../models/donasi.dart';
import '../models/donation_history_entry.dart';
import '../models/user_admin.dart';
import '../models/item_donation_entry.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/chat_message.dart';

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
  final _storage = FirebaseStorage.instance;
  
  // Static variable to store current logged-in user
  static User? _currentUser;
  
  // Getter for current user
  static User? get currentUser => _currentUser;
  
  // Set current user
  static void setCurrentUser(User user) {
    _currentUser = user;
  }
  
  // Clear current user (logout)
  static void clearCurrentUser() {
    _currentUser = null;
  }

  Future<Saldo> getSaldo() async {
    final userId = currentUser?.userId ?? 'donatur_1'; // Fallback to default if no user logged in
    final doc = await _db.collection('saldo').doc(userId).get();
    if (!doc.exists) {
      await _db.collection('saldo').doc(userId).set({'total': 100000});
      return Saldo(id: userId, total: 100000);
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
  Future<void> deductSaldo(int amount) async {
    final userId = currentUser?.userId ?? 'donatur_1';
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
    required String donasiId,
    required String donasiTitle,
    required int amount,
    required DateTime timestamp,
  }) async {
    final userId = currentUser?.userId ?? 'unknown_user';
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
  Future<List<DonationHistoryEntry>> getDonationHistory() async {
    final userId = currentUser?.userId ?? 'unknown_user';
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
      final userId = currentUser?.userId ?? 'donatur_1';
      
      // Try both field names to handle the transition
      final newFieldSnapshot = await _db
          .collection('user_donations_items')
          .where('userId', isEqualTo: userId)
          .get();

      final oldFieldSnapshot = await _db
          .collection('user_donations_items')
          .where('user_id', isEqualTo: userId)
          .get();
      
      // Combine both results
      final allDocs = [...newFieldSnapshot.docs, ...oldFieldSnapshot.docs];
      
      // Remove duplicates based on document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }
      
      final uniqueDonations = uniqueDocs.values.toList();

      // Convert item donations to Donasi objects
      final donations = uniqueDonations.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        
        final donasi = Donasi(
          id: doc.id,
          judul: data['donasi_title'] ?? 'Donasi ${data['item_name'] ?? 'Barang'}',
          yayasan: data['yayasan_name'] ?? 'Donasi Barang',
          deskripsi: 'Jumlah: ${data['quantity'] ?? 0} ${data['item_name'] ?? 'barang'} (lat:${data['yayasan_lat'] ?? 0},lon:${data['yayasan_lon'] ?? 0})',
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
        
        return donasi;
      }).toList();

      // Sort by timestamp (newest first)
      donations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return donations;
    } catch (e) {
      print('Error getting donation status list: $e');
      return [];
    }
  }

  // Method to add item donation
  Future<void> addItemDonation({
    required String donasiId,
    required String itemName,
    required int quantity,
    String? buktiBase64,
    required String yayasanName,
    required String yayasanAddress,
    required double yayasanLat,
    required double yayasanLon,
  }) async {
    final userId = currentUser?.userId ?? 'unknown_user';
    try {
      await _db.collection('user_donations_items').add({
        'userId': userId,
        'donasi_id': donasiId,
        'item_name': itemName,
        'quantity': quantity,
        'bukti_image': buktiBase64,
        'yayasan_name': yayasanName,
        'yayasan_address': yayasanAddress,
        'yayasan_lat': yayasanLat,
        'yayasan_lon': yayasanLon,
        'status': 'Proses', // Set initial status to Proses
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

  // User registration (sign up)
  Future<void> registerUser({
    required String username,
    required String password,
  }) async {
    // Check if username already exists
    final snapshot = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      throw Exception('Username already exists');
    }
    
    // Generate a unique userId
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${username}';
    
    await _db.collection('users').add({
      'userId': userId,
      'username': username,
      'password': password,
    });
  }

  // User login (sign in)
  Future<User?> loginUser({
    required String username,
    required String password,
  }) async {
    final snapshot = await _db.collection('users')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final user = User.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      // Set current user when login is successful
      setCurrentUser(user);
      return user;
    }
    return null;
  }

  // Chat methods
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final snapshot = await _db.collection('chat_rooms').orderBy('lastMessageTime', descending: true).get();
      return snapshot.docs.map((doc) => ChatRoom.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatRoomId) async {
    try {
      final snapshot = await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    required bool isAdmin,
    String? imageUrl,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      final senderId = isAdmin ? 'admin' : (currentUser?.userId ?? 'unknown');
      final senderName = isAdmin ? 'Admin' : (currentUser?.username ?? 'Unknown User');

      final chatMessage = ChatMessage(
        id: '',
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
        isAdmin: isAdmin,
        imageUrl: imageUrl,
      );

      // Send message first
      await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(chatMessage.toMap());

      // Update chat room with last message (separate operation to avoid conflicts)
      try {
        final lastMessageText = imageUrl != null ? '📷 Gambar' : message;
        await _db.collection('chat_rooms').doc(chatRoomId).update({
          'lastMessage': lastMessageText,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          'hasUnreadMessages': !isAdmin, // Mark as unread if message is from user
        });
      } catch (updateError) {
        print('Error updating chat room: $updateError');
        // Don't throw here, message was sent successfully
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Method to upload chat image
  Future<String> uploadChatImage(File imageFile) async {
    try {
      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();
      // Convert to base64 string
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error processing chat image: $e');
      throw e;
    }
  }

  Future<String> createOrGetChatRoom() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if chat room already exists for this user
      final existingRooms = await _db
          .collection('chat_rooms')
          .where('userId', isEqualTo: currentUser.userId)
          .limit(1)
          .get();

      if (existingRooms.docs.isNotEmpty) {
        return existingRooms.docs.first.id;
      }

      // Create new chat room
      final chatRoom = ChatRoom(
        id: '',
        userId: currentUser.userId,
        userName: currentUser.username,
        lastMessageTime: DateTime.now(),
        lastMessage: '',
        hasUnreadMessages: false,
      );

      final docRef = await _db.collection('chat_rooms').add(chatRoom.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating chat room: $e');
      throw e;
    }
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> markChatRoomAsRead(String chatRoomId) async {
    try {
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'hasUnreadMessages': false,
      });
    } catch (e) {
      print('Error marking chat room as read: $e');
    }
  }

  // Method to upload campaign image to Firebase Storage
  Future<String> uploadCampaignImage(File imageFile, {Function(double)? onProgress}) async {
    try {
      final userId = currentUser?.userId ?? 'unknown_user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'campaign_${userId}_$timestamp.jpg';
      
      // Create a reference to the campaign images folder
      final storageRef = _storage.ref().child('campaign_images/$fileName');
      
      // Set metadata for faster processing
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // 1 year cache
      );
      
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Get file size to ensure it's not empty
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      
      print('Uploading image: $fileName, size: ${fileSize} bytes');
      
      // Upload the file with metadata and timeout
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Listen to upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      // Get the download URL with timeout (30 seconds)
      final snapshot = await uploadTask.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - please check your internet connection');
        },
      );
      
      print('Upload completed, getting download URL...');
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading campaign image: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('object-not-found')) {
        throw Exception('Firebase Storage not configured properly. Please check your Firebase project settings.');
      } else if (e.toString().contains('permission-denied')) {
        throw Exception('Upload permission denied. Please check Firebase Storage rules.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Upload failed: ${e.toString()}');
      }
    }
  }

  // Method to upload campaign image as base64 in Firestore (FREE alternative)
  Future<String> uploadCampaignImageAsBase64(File imageFile) async {
    try {
      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();
      // Convert to base64 string
      final base64String = base64Encode(bytes);
      
      // Store in Firestore as a document
      final userId = currentUser?.userId ?? 'unknown_user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docId = 'campaign_image_${userId}_$timestamp';
      
      await _db.collection('campaign_images').doc(docId).set({
        'imageData': base64String,
        'userId': userId,
        'timestamp': timestamp,
        'contentType': 'image/jpeg',
        'fileName': 'campaign_${userId}_$timestamp.jpg',
      });
      
      // Return a reference to the document
      return 'firestore://campaign_images/$docId';
    } catch (e) {
      print('Error storing image as base64: $e');
      throw Exception('Failed to store image: ${e.toString()}');
    }
  }

  // Method to get image from base64 stored in Firestore
  Future<String> getImageFromBase64(String imageRef) async {
    try {
      if (imageRef.startsWith('firestore://')) {
        final docId = imageRef.replaceFirst('firestore://campaign_images/', '');
        final doc = await _db.collection('campaign_images').doc(docId).get();
        
        if (doc.exists) {
          final data = doc.data()!;
          return data['imageData'] as String;
        } else {
          throw Exception('Image not found');
        }
      } else {
        // If it's a regular URL, return as is
        return imageRef;
      }
    } catch (e) {
      print('Error getting image from base64: $e');
      throw e;
    }
  }

  // Update user profile picture (gambar) as base64 string
  Future<void> updateUserProfilePicture(String base64Image) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    await _db.collection('users').doc(user.id).update({'gambar': base64Image});
    // Update local user object
    setCurrentUser(User(
      id: user.id,
      userId: user.userId,
      username: user.username,
      password: user.password,
      gambar: base64Image,
    ));
  }

  // Fetch user data (including gambar)
  Future<User?> fetchCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.id).get();
    if (!doc.exists) return null;
    return User.fromMap(doc.id, doc.data()!);
  }

  static Future<void> logout() async {
    clearCurrentUser();
  }
} 