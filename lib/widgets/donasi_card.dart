import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donasi.dart';
import '../screens/donasi_detail_page.dart';

class DonasiCard extends StatelessWidget {
  final Donasi donasi;
  final NumberFormat formatter;
  final bool showProgressPercentage;
  const DonasiCard({super.key, required this.donasi, required this.formatter, this.showProgressPercentage = false});

    @override
  Widget build(BuildContext context) {
    double progressDana = donasi.terkumpul / (donasi.target == 0 ? 1 : donasi.target);
    final String gambarUrl = (donasi.gambar.trim().isNotEmpty)
        ? donasi.gambar
        : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonasiDetailPage(donasi: donasi),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                gambarUrl,
                height: 150,
                width: double.infinity,
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
} 