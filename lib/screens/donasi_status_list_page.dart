import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/donasi.dart';
import '../models/yayasan.dart';
import '../services/firebase_service.dart';
import 'donasi_status_page.dart';

class DonasiStatusListPage extends StatefulWidget {
  const DonasiStatusListPage({super.key});

  @override
  State<DonasiStatusListPage> createState() => _DonasiStatusListPageState();
}

class _DonasiStatusListPageState extends State<DonasiStatusListPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Donasi> _donations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    try {
      final donations = await _firebaseService.getDonasiStatusList();
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar donasi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Donasi Barang'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _donations.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada donasi barang',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _donations.length,
                  itemBuilder: (context, index) {
                    final donation = _donations[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navigate to DonasiStatusPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonasiStatusPage(
                                donasi: donation,
                                yayasan: Yayasan(
                                  name: donation.yayasan,
                                  address: '',
                                  lat: 0,
                                  lon: 0,
                                ),
                                items: [{
                                  'name': donation.judul.replaceAll('Donasi ', ''),
                                  'quantity': int.tryParse(donation.deskripsi.split(' ')[1]) ?? 0,
                                  'photo': donation.buktiImage != null ? File(donation.buktiImage!) : null,
                                }],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (donation.buktiImage != null)
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: MemoryImage(
                                            base64Decode(donation.buktiImage!),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          donation.judul,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          donation.deskripsi,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: donation.status == 'Konfirming'
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            donation.status,
                                            style: TextStyle(
                                              color: donation.status == 'Konfirming'
                                                  ? Colors.blue
                                                  : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 