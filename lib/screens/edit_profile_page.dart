import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();
  File? _profileImageFile;
  String? _profileImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = await FirebaseService().fetchCurrentUser();
    if (user != null) {
      _namaController.text = user.username;
      _profileImageBase64 = user.gambar;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _profileImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _simpanProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Update nama jika berubah
        // Update gambar jika ada
        if (_profileImageBase64 != null) {
          await FirebaseService().updateUserProfilePicture(_profileImageBase64!);
        }
        // Update password jika diisi
        if (_passwordController.text.isNotEmpty) {
          // TODO: Implementasi update password ke Firestore sesuai backend Anda
          // Contoh: await FirebaseService().updateUserPassword(_passwordController.text);
        }
        // TODO: Implementasi update nama jika ingin disimpan ke Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile berhasil disimpan!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profile: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileAvatar() {
    if (_profileImageFile != null) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey[200],
        backgroundImage: FileImage(_profileImageFile!),
      );
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey[200],
        backgroundImage: MemoryImage(base64Decode(_profileImageBase64!)),
      );
    } else {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, size: 48, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6F1FB),
      appBar: AppBar(
        backgroundColor: Color(0xFFE6F1FB),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildProfileAvatar(),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    // Tidak perlu validasi jika kosong
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _konfirmasiPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) {
                      // Hanya validasi jika password diisi
                      if (_passwordController.text.isNotEmpty) {
                        if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                        if (value != _passwordController.text) return 'Password tidak sama';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF43e97b),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading ? CircularProgressIndicator() : Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 