import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/donasi.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final _judulController = TextEditingController();
  final _yayasanController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _targetController = TextEditingController();
  final _ceritaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _sisaHariController = TextEditingController();
  
  // Image state
  File? _imageFile;
  bool _hasCustomImage = false;
  
  // Barang list
  final List<Map<String, dynamic>> _barangList = [];
  final _barangNamaController = TextEditingController();
  final _barangTargetController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _judulController.dispose();
    _yayasanController.dispose();
    _deskripsiController.dispose();
    _targetController.dispose();
    _ceritaController.dispose();
    _lokasiController.dispose();
    _sisaHariController.dispose();
    _barangNamaController.dispose();
    _barangTargetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _hasCustomImage = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _addBarang() {
    if (_barangNamaController.text.isNotEmpty && _barangTargetController.text.isNotEmpty) {
      setState(() {
        _barangList.add({
          'nama': _barangNamaController.text,
          'target': int.parse(_barangTargetController.text),
          'terkumpul': 0,
        });
        _barangNamaController.clear();
        _barangTargetController.clear();
      });
    }
  }

  void _removeBarang(int index) {
    setState(() {
      _barangList.removeAt(index);
    });
  }

  Future<void> _submitCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    if (_barangList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tambahkan minimal satu barang yang dibutuhkan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Use a default image URL instead of base64
      final String imageUrl = _hasCustomImage 
          ? 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80'
          : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';
      
      final campaignData = {
        'judul': _judulController.text,
        'yayasan': _yayasanController.text,
        'deskripsi': _deskripsiController.text,
        'target': int.parse(_targetController.text),
        'terkumpul': 0,
        'gambar': imageUrl,
        'barang': _barangList,
        'cerita': _ceritaController.text,
        'penggalang': 'Informan',
        'verifikasi': false,
        'admin_verifikasi': false,
        'jumlah_donasi': 0,
        'lokasi': _lokasiController.text,
        'sisa_hari': int.parse(_sisaHariController.text),
        'status': 'Proses',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': FirebaseService.currentUser?.userId ?? 'unknown_user',
      };

      await _db.collection('donasi').add(campaignData);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campaign berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSubmitting) return false;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Buat Campaign Baru'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: _isSubmitting 
            ? null 
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      Center(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _pickImage,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: NetworkImage('https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80'),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: _imageFile == null
                                ? Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Campaign Details
                      Text('Detail Campaign', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _judulController,
                        decoration: InputDecoration(
                          labelText: 'Judul Campaign',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        enabled: !_isSubmitting,
                        validator: (value) => value?.isEmpty ?? true ? 'Judul tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _yayasanController,
                        decoration: InputDecoration(
                          labelText: 'Nama Yayasan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        enabled: !_isSubmitting,
                        validator: (value) => value?.isEmpty ?? true ? 'Nama yayasan tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _deskripsiController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        enabled: !_isSubmitting,
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true ? 'Deskripsi tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _targetController,
                        decoration: InputDecoration(
                          labelText: 'Target Dana (Rp)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Target dana tidak boleh kosong';
                          if (int.tryParse(value!) == null) return 'Masukkan angka yang valid';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _lokasiController,
                        decoration: InputDecoration(
                          labelText: 'Lokasi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        enabled: !_isSubmitting,
                        validator: (value) => value?.isEmpty ?? true ? 'Lokasi tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _sisaHariController,
                        decoration: InputDecoration(
                          labelText: 'Sisa Hari',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Sisa hari tidak boleh kosong';
                          if (int.tryParse(value!) == null) return 'Masukkan angka yang valid';
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Barang Section
                      Text('Barang yang Dibutuhkan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barangNamaController,
                              decoration: InputDecoration(
                                labelText: 'Nama Barang',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_isSubmitting,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _barangTargetController,
                              decoration: InputDecoration(
                                labelText: 'Target Jumlah',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _addBarang,
                            child: Icon(Icons.add),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Barang List
                      ..._barangList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final barang = entry.value;
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(barang['nama']),
                            subtitle: Text('Target: ${barang['target']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: _isSubmitting ? null : () => _removeBarang(index),
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 24),

                      // Cerita Section
                      Text('Cerita Penggalangan Dana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _ceritaController,
                        decoration: InputDecoration(
                          labelText: 'Cerita',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        enabled: !_isSubmitting,
                        maxLines: 5,
                        validator: (value) => value?.isEmpty ?? true ? 'Cerita tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitCampaign,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Buat Campaign', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
} 