import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show min, max;

class Yayasan {
  final String name;
  final String address;
  final double lat;
  final double lon;
  final double? distance;
  final double? rating;
  final int? stars;

  Yayasan({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    this.distance,
    this.rating,
    this.stars,
  });

  LatLng get position => LatLng(lat, lon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Yayasan &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          // Consider locations within ~10 meters as the same
          (lat - other.lat).abs() < 0.0001 &&
          (lon - other.lon).abs() < 0.0001;

  @override
  int get hashCode => name.hashCode ^ (lat * 10000).round() ^ (lon * 10000).round();
}

class YayasanSelectionSheet extends StatefulWidget {
  final Function(Yayasan) onYayasanSelected;

  const YayasanSelectionSheet({
    Key? key,
    required this.onYayasanSelected,
  }) : super(key: key);

  @override
  State<YayasanSelectionSheet> createState() => _YayasanSelectionSheetState();
}

class _YayasanSelectionSheetState extends State<YayasanSelectionSheet> {
  List<Yayasan> _yayasanList = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  Yayasan? _selectedYayasan;
  bool _showMap = false;
  final MapController _mapController = MapController();

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
          _error = 'Lokasi tidak aktif. Aktifkan GPS Anda.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Izin lokasi ditolak.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print('Current Location: ${position.latitude}, ${position.longitude}');
      setState(() {
        _currentPosition = position;
      });

      await _fetchNearbyYayasan();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _error = 'Gagal mendapatkan lokasi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyYayasan() async {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    final query = '[out:json][timeout:25];node["name"~"yayasan",i](around:5000,$lat,$lon);out body;';
    print('Query: $query');

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        print('Found ${elements.length} elements');

        // Use a Map to prevent duplicates, using name as key
        final yayasanMap = <String, Yayasan>{};

        for (final element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'];
          final lat = element['lat'];
          final lon = element['lon'];

          if (name == null || lat == null || lon == null) continue;

          // Get rating information
          double? rating;
          int? stars;

          // Try to get rating from various OSM tags
          if (tags['rating'] != null) {
            rating = double.tryParse(tags['rating'].toString());
          } else if (tags['review:rating'] != null) {
            rating = double.tryParse(tags['review:rating'].toString());
          } else if (tags['amenity:rating'] != null) {
            rating = double.tryParse(tags['amenity:rating'].toString());
          }

          // Try to get stars
          if (tags['stars'] != null) {
            stars = int.tryParse(tags['stars'].toString());
          }

          // Calculate distance from user's location
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat.toDouble(),
            lon.toDouble(),
          ) / 1000; // Convert to kilometers

          print('Found yayasan: $name at $lat, $lon (${distance.toStringAsFixed(1)} km)');
          if (rating != null) print('Rating: $rating');
          if (stars != null) print('Stars: $stars');

          final yayasan = Yayasan(
            name: name,
            address: _buildAddress(tags),
            lat: lat.toDouble(),
            lon: lon.toDouble(),
            distance: distance,
            rating: rating,
            stars: stars,
          );

          // Only add if we don't have this yayasan yet or if this one is closer
          if (!yayasanMap.containsKey(name) || 
              (yayasanMap[name]?.distance ?? double.infinity) > distance) {
            yayasanMap[name] = yayasan;
          }
        }

        // Convert Map values to List and sort by distance
        final yayasanList = yayasanMap.values.toList()
          ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

        setState(() {
          _yayasanList = yayasanList;
          _isLoading = false;
        });
      } else {
        print('Error response: ${response.body}');
        setState(() {
          _error = 'Gagal mengambil data yayasan: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching yayasan: $e');
      setState(() {
        _error = 'Error mengambil data yayasan: $e';
        _isLoading = false;
      });
    }
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (tags['addr:postcode'] != null) parts.add(tags['addr:postcode']);

    return parts.isEmpty ? 'Alamat tidak tersedia' : parts.join(', ');
  }

  void _selectYayasan(Yayasan yayasan) {
    print('Selected yayasan: ${yayasan.name}');
    setState(() {
      _selectedYayasan = yayasan;
      _showMap = true;
    });
  }

  LatLngBounds? _getBounds() {
    if (_currentPosition == null || _selectedYayasan == null) return null;
    
    final bounds = LatLngBounds(
      LatLng(
        min(_currentPosition!.latitude, _selectedYayasan!.lat),
        min(_currentPosition!.longitude, _selectedYayasan!.lon),
      ),
      LatLng(
        max(_currentPosition!.latitude, _selectedYayasan!.lat),
        max(_currentPosition!.longitude, _selectedYayasan!.lon),
      ),
    );
    
    // Add padding to the bounds
    final padding = 0.002; // Approximately 200 meters
    return LatLngBounds(
      LatLng(bounds.south - padding, bounds.west - padding),
      LatLng(bounds.north + padding, bounds.east + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _getBounds();
    
    return WillPopScope(
      onWillPop: () async {
        if (_showMap) {
          setState(() {
            _showMap = false;
            _selectedYayasan = null;
          });
          return false;
        }
        return true;
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Yayasan Terdekat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_showMap)
                    Spacer(),
                  if (_showMap)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showMap = false;
                          _selectedYayasan = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            if (_showMap && _selectedYayasan != null)
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: bounds?.center ?? _selectedYayasan!.position,
                    initialZoom: bounds != null ? 13 : 15,
                    onMapReady: () {
                      if (bounds != null) {
                        _mapController.move(bounds.center, 13);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        Marker(
                          point: _selectedYayasan!.position,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Mencari yayasan terdekat...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: Icon(Icons.refresh),
                        label: Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_yayasanList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, color: Colors.grey, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada yayasan ditemukan dalam radius 5km',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: Icon(Icons.refresh),
                        label: Text('Cari Lagi'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _yayasanList.length,
                  itemBuilder: (context, index) {
                    final yayasan = _yayasanList[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.location_on, color: Colors.blue),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        yayasan.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (yayasan.rating != null || yayasan.stars != null)
                                        Row(
                                          children: [
                                            Icon(Icons.star, size: 16, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text(
                                              yayasan.stars != null
                                                  ? '${yayasan.stars} bintang'
                                                  : '${yayasan.rating?.toStringAsFixed(1)}/5',
                                              style: TextStyle(
                                                color: Colors.amber[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (yayasan.address != 'Alamat tidak tersedia')
                              Row(
                                children: [
                                  Icon(Icons.home, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      yayasan.address,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Jarak: ${yayasan.distance?.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _selectYayasan(yayasan),
                                      icon: Icon(Icons.map, color: Colors.blue),
                                      tooltip: 'Lihat di Peta',
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        widget.onYayasanSelected(yayasan);
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.check, size: 18),
                                      label: Text('Pilih'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}