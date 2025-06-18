import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/donasi.dart';
import '../screens/donasi_detail_page.dart';
import '../services/firebase_service.dart';
import 'campaign_image.dart';

class DonasiCard extends StatelessWidget {
  final Donasi donasi;
  final NumberFormat formatter;
  final bool showProgressPercentage;
  final VoidCallback onTap;

  const DonasiCard({
    super.key,
    required this.donasi,
    required this.formatter,
    this.showProgressPercentage = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressDana = donasi.target > 0 ? donasi.terkumpul / donasi.target : 0.0;
    final progressBarang = donasi.barang.isNotEmpty 
        ? donasi.barang.map((barang) => barang.terkumpul / barang.target).reduce((a, b) => a + b) / donasi.barang.length 
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: CampaignImage(
                imageRef: donasi.gambar,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(donasi.judul, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(donasi.deskripsi, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  SizedBox(height: 12),
                  // Progress bar dana
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressDana > 1 ? 1 : progressDana,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressDana == 0 ? Colors.grey : Colors.green),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terkumpul: Rp ${formatter.format(donasi.terkumpul)}',
                        style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sisa hari: ${donasi.sisaHari}',
                        style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String gambar) {
    if (gambar.startsWith('http') || gambar.startsWith('https')) {
      return Image.network(
        gambar,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
      );
    } else if (gambar.startsWith('firestore://')) {
      return FutureBuilder<String>(
        future: FirebaseService().getImageFromBase64(gambar),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            try {
              final Uint8List bytes = base64Decode(snapshot.data!);
              return Image.memory(
                bytes,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
              );
            } catch (e) {
              return _buildDefaultImage();
            }
          } else {
            return _buildDefaultImage();
          }
        },
      );
    } else if (gambar.startsWith('data:image')) {
      final List<String> parts = gambar.split(',');
      if (parts.length > 1) {
        try {
          final String base64 = parts[1];
          final Uint8List bytes = base64Decode(base64);
          return Image.memory(
            bytes,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
          );
        } catch (e) {
          return _buildDefaultImage();
        }
      }
    }
    return _buildDefaultImage();
  }

  Widget _buildDefaultImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.image,
        size: 50,
        color: Colors.grey[600],
      ),
    );
  }
} 