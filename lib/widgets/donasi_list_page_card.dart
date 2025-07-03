import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/donasi.dart';
import '../screens/donasi_detail_page.dart';
import '../services/firebase_service.dart';
import 'campaign_image.dart';

class DonasiListPageCard extends StatelessWidget {
  final Donasi donasi;
  final NumberFormat formatter;
  final bool showProgressPercentage;

  const DonasiListPageCard({
    super.key,
    required this.donasi,
    required this.formatter,
    this.showProgressPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    double progressDana = donasi.terkumpul / (donasi.target == 0 ? 1 : donasi.target);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonasiDetailPage(donasi: donasi),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0), // Adjust horizontal padding
        child: ColoredBox( // Add ColoredBox to control background
          color: Colors.transparent, // Make background transparent
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar (Left side)
              CampaignImage(
                imageRef: donasi.gambar,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              SizedBox(width: 12), // Space between image and text
              Expanded( // Text content (Right side)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donasi.judul,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2, // Limit title lines if necessary
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          donasi.yayasan,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        SizedBox(width: 4),
                        // Simple ORG badge placeholder
                        Container(
                           padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                           decoration: BoxDecoration(
                             color: Colors.blue[100],
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text('ORG', style: TextStyle(fontSize: 9, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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
                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            if (donasi.sisaHari == 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                margin: EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Text(
                                  'BERAKHIR',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              donasi.sisaHari == 0 ? 'Selesai' : 'Sisa hari: ${donasi.sisaHari}',
                              style: TextStyle(
                                fontSize: 12, 
                                color: donasi.sisaHari == 0 ? Colors.grey[600] : Colors.red, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String gambar) {
    if (gambar.startsWith('http') || gambar.startsWith('https')) {
      return Image.network(
        gambar,
        height: 100, // Fixed height
        width: 100,  // Fixed width
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
      );
    } else if (gambar.startsWith('firestore://')) {
      return FutureBuilder<String>(
        future: FirebaseService().getImageFromBase64(gambar),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 100,
              width: 100,
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            try {
              final Uint8List bytes = base64Decode(snapshot.data!);
              return Image.memory(
                bytes,
                height: 100,
                width: 100,
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
      // Handle base64 image
      final List<String> parts = gambar.split(',');
      if (parts.length > 1) {
        try {
          final String base64Data = parts[1];
          final Uint8List bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            height: 100,
            width: 100,
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
      height: 100,
      width: 100,
      color: Colors.grey[300],
      child: Icon(
        Icons.image,
        size: 30,
        color: Colors.grey[600],
      ),
    );
  }
} 