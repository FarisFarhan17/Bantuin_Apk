import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/donasi.dart';
import '../models/yayasan.dart';
import '../services/firebase_service.dart';
import 'donasi_status_page.dart';
import 'dart:math' as math;
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
      print('Loaded donations:');
      for (var donation in donations) {
        print('Donation:');
        print('ID: ${donation.id}');
        print('Yayasan: ${donation.yayasan}');
        print('Lokasi: ${donation.lokasi}');
        print('Deskripsi: ${donation.deskripsi}');
      }
      
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
                    print('Building donation card for:');
                    print('Yayasan: ${donation.yayasan}');
                    print('Lokasi: ${donation.lokasi}');
                    print('Deskripsi: ${donation.deskripsi}');
                    
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
                    
                    print('Extracted coordinates:');
                    print('Lat: $lat');
                    print('Lon: $lon');
                    
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
                                      color: donation.status == 'Proses' 
                                          ? Colors.orange 
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      donation.status,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      donation.yayasan,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.map, size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${donation.lokasi} (${_calculateDistance(lat, lon).toStringAsFixed(1)} km)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                donation.deskripsi.split(' (')[0],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
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

  double _calculateDistance(double lat, double lon) {
    if (_currentPosition == null) return 0;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    ) / 1000; // Convert to kilometers
  }
}

extension on double {
  double toRadians() {
    return this * (math.pi / 180);
  }
} 