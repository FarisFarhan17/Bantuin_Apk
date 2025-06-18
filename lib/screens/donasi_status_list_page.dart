import 'package:flutter/material.dart';
import 'dart:io';
import '../models/donasi.dart';
import '../models/yayasan.dart';
import '../services/firebase_service.dart';
import 'donasi_status_page.dart';
import 'package:geolocator/geolocator.dart';

class DonasiStatusListPage extends StatefulWidget {
  const DonasiStatusListPage({super.key});

  @override
  State<DonasiStatusListPage> createState() => _DonasiStatusListPageState();
}

class _DonasiStatusListPageState extends State<DonasiStatusListPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Donasi> _donations = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
      });

      await _loadDonations();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDonations() async {
    try {
      final donations = await _firebaseService.getDonasiStatusList();
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading donations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _refreshData() async {
    await _loadDonations();
  }

  @override
  Widget build(BuildContext context) {
    // Group donations by date
    final Map<String, List<Donasi>> groupedDonations = {};
    for (var donation in _donations) {
      final dateGroup = _getDateGroup(donation.timestamp);
      if (!groupedDonations.containsKey(dateGroup)) {
        groupedDonations[dateGroup] = [];
      }
      groupedDonations[dateGroup]!.add(donation);
    }

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
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: groupedDonations.length,
                    itemBuilder: (context, index) {
                      final dateGroup = groupedDonations.keys.elementAt(index);
                      final donations = groupedDonations[dateGroup]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateGroup,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          ...donations.map((donation) {
                            // Extract lat/lon from deskripsi
                            double lat = 0;
                            double lon = 0;
                            try {
                              final latMatch = RegExp(r'lat:([-\d.]+)').firstMatch(donation.deskripsi);
                              final lonMatch = RegExp(r'lon:([-\d.]+)').firstMatch(donation.deskripsi);
                              
                              if (latMatch != null && lonMatch != null) {
                                lat = double.parse(latMatch.group(1)!);
                                lon = double.parse(lonMatch.group(1)!);
                              }
                            } catch (e) {
                              print('Error parsing coordinates: $e');
                            }
                            
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DonasiStatusPage(
                                        donasi: donation,
                                        yayasan: Yayasan(
                                          name: donation.yayasan,
                                          address: donation.lokasi,
                                          lat: lat,
                                          lon: lon,
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              donation.judul,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(donation.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              donation.status,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        donation.yayasan,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                          SizedBox(width: 4),
                                          Text(
                                            '${donation.timestamp.hour.toString().padLeft(2, '0')}:${donation.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (_currentPosition != null) ...[
                                            SizedBox(width: 16),
                                            Icon(Icons.location_on, size: 14, color: Colors.blue),
                                            SizedBox(width: 4),
                                            Text(
                                              '${_calculateDistance(lat, lon).toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  double _calculateDistance(double lat, double lon) {
    if (_currentPosition == null) return 0;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    ) / 1000; // Convert to kilometers
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Proses':
        return Colors.orange;
      case 'Konfirming':
        return Colors.blue;
      case 'Terverifikasi':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 