import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/donation_history_entry.dart';

class RiwayatDonasiPage extends StatefulWidget {
  const RiwayatDonasiPage({super.key});

  @override
  State<RiwayatDonasiPage> createState() => _RiwayatDonasiPageState();
}

class _RiwayatDonasiPageState extends State<RiwayatDonasiPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<DonationHistoryEntry>> _donationHistoryFuture;
  final NumberFormat formatter = NumberFormat.decimalPattern('id');

  @override
  void initState() {
    super.initState();
    _donationHistoryFuture = _firebaseService.getDonationHistory('donatur_1'); // Fetch history for donatur_1
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Donasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<DonationHistoryEntry>>(
        future: _donationHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}')); // Error message
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada riwayat donasi.')); // No history message
          } else {
            final donationHistory = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: donationHistory.length,
              itemBuilder: (context, index) {
                final entry = donationHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.donasiTitle,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jumlah Donasi: Rp ${formatter.format(entry.amount)}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Status: ${entry.status}', // Display status
                          style: TextStyle(fontSize: 14, color: entry.status == 'Pending' ? Colors.orange : Colors.green), // Style status text
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(entry.timestamp)}', // Formatted timestamp
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
} 