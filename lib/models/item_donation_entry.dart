import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDonationEntry {
  final String id;
  final String donasiId;
  final String userId;
  final String itemName;
  final int quantity;
  final String? buktiBase64;
  final String yayasanName;
  final String yayasanAddress;
  final double yayasanLat;
  final double yayasanLon;
  final String status;
  final DateTime createdAt;

  ItemDonationEntry({
    required this.id,
    required this.donasiId,
    required this.userId,
    required this.itemName,
    required this.quantity,
    this.buktiBase64,
    required this.yayasanName,
    required this.yayasanAddress,
    required this.yayasanLat,
    required this.yayasanLon,
    required this.status,
    required this.createdAt,
  });

  factory ItemDonationEntry.fromMap(String id, Map<String, dynamic> data) {
    return ItemDonationEntry(
      id: id,
      donasiId: data['donasi_id'] ?? '',
      userId: data['user_id'] ?? '',
      itemName: data['item_name'] ?? '',
      quantity: data['quantity'] ?? 0,
      buktiBase64: data['bukti_image'],
      yayasanName: data['yayasan_name'] ?? '',
      yayasanAddress: data['yayasan_address'] ?? '',
      yayasanLat: (data['yayasan_lat'] ?? 0.0).toDouble(),
      yayasanLon: (data['yayasan_lon'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Proses',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
} 