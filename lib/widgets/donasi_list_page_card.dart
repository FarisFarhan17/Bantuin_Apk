import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donasi.dart';
import '../screens/donasi_detail_page.dart';

class DonasiListPageCard extends StatelessWidget {
  final Donasi donasi;
  final NumberFormat formatter;

  const DonasiListPageCard({
    super.key,
    required this.donasi,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    double progressDana = donasi.terkumpul / (donasi.target == 0 ? 1 : donasi.target);
    final String gambarUrl = (donasi.gambar.trim().isNotEmpty)
        ? donasi.gambar
        : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80'; // Default image

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
              Image.network(
                gambarUrl,
                height: 100, // Fixed height
                width: 100,  // Fixed width
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
                        Text(
                          'Sisa hari: ${donasi.sisaHari}',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
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
} 