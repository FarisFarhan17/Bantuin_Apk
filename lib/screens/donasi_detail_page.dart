import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donasi.dart';
import '../widgets/donation_options_sheet.dart';

class DonasiDetailPage extends StatelessWidget {
  final Donasi donasi;
  final NumberFormat formatter = NumberFormat.decimalPattern('id');
  DonasiDetailPage({super.key, required this.donasi});

  @override
  Widget build(BuildContext context) {
    double progressDana = donasi.terkumpul / (donasi.target == 0 ? 1 : donasi.target);
    final String gambarUrl = (donasi.gambar.trim().isNotEmpty)
        ? donasi.gambar
        : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  gambarUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(donasi.judul, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(donasi.deskripsi, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text('${formatter.format(donasi.jumlahDonasi)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Donasi', style: TextStyle(fontSize: 14, color: Colors.black)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Target Dana', style: TextStyle(fontWeight: FontWeight.w500)),
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
                          Text('Target: Rp ${formatter.format(donasi.target)}', style: TextStyle(fontSize: 13)),
                          Text('Terkumpul: Rp ${formatter.format(donasi.terkumpul)}', style: TextStyle(fontSize: 13, color: Colors.green)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Informasi Penggalangan Dana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: Colors.blue, size: 28),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(donasi.penggalang, style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(donasi.verifikasi ? 'Identitas terverifikasi' : 'Belum terverifikasi', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Cerita Penggalangan Dana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Text(
                        donasi.cerita,
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 16),
                      Text('Barang yang Dibutuhkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ...donasi.barang.map((b) {
                        double progressBarang = b.terkumpul / (b.target == 0 ? 1 : b.target);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progressBarang > 1 ? 1 : progressBarang,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(progressBarang == 0 ? Colors.grey : Colors.green),
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Target: ${formatter.format(b.target)}', style: TextStyle(fontSize: 13)),
                                  Text('Terkumpul: ${formatter.format(b.terkumpul)}', style: TextStyle(fontSize: 13, color: Colors.green)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 50, 187, 95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16.0),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: DonationOptionsSheet(
                    donasi: donasi,
                    formatter: formatter,
                  ),
                ),
              );
            },
            child: Text('Donasi sekarang'),
          ),
        ),
      ),
    );
  }
} 