import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'dart:convert'; // For base64 decoding
import '../models/item_donation_entry.dart'; // New import

class DonationVerification extends StatefulWidget {
  const DonationVerification({super.key});

  @override
  State<DonationVerification> createState() => _DonationVerificationState();
}

class _DonationVerificationState extends State<DonationVerification> {
  final FirebaseService _firebaseService = FirebaseService();
  List<ItemDonationEntry> _konfirmingDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKonfirmingDonations();
  }

  Future<void> _fetchKonfirmingDonations() async {
    try {
      final donations = await _firebaseService.getKonfirmingItemDonations();
      setState(() {
        _konfirmingDonations = donations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching konfirming donations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyDonation(ItemDonationEntry donation) async {
    try {
      // Update item donation status to 'Terverifikasi'
      await _firebaseService.updateItemDonationStatus(
        itemDonationId: donation.id,
        status: 'Terverifikasi',
      );

      // Update the collected amount in the main Donasi campaign
      await _firebaseService.updateItemDonasiCollectedAmount(
        donasiId: donation.donasiId,
        itemName: donation.itemName,
        quantity: donation.quantity,
      );

      // Increment the total number of donations for the campaign
      await _firebaseService.updateDonasiCollectedAmount(
        donasiId: donation.donasiId,
        amount: 0, // Pass 0 as amount since we are only interested in incrementing jumlah_donasi
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donasi barang berhasil diverifikasi!')),
      );
      _fetchKonfirmingDonations(); // Refresh the list
      Navigator.pop(context, true); // Signal successful verification back to the previous screen
    } catch (e) {
      print('Error verifying donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memverifikasi donasi barang: $e')),
      );
    }
  }

  Future<void> _rejectDonation(ItemDonationEntry donation) async {
    try {
      // Update item donation status to 'Ditolak'
      await _firebaseService.updateItemDonationStatus(
        itemDonationId: donation.id,
        status: 'Ditolak',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donasi barang berhasil ditolak.')),
      );
      _fetchKonfirmingDonations(); // Refresh the list
    } catch (e) {
      print('Error rejecting donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak donasi barang: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Bukti Donasi Barang'),
        backgroundColor: const Color(0xFF56B289),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _konfirmingDonations.isEmpty
              ? const Center(child: Text('Tidak ada donasi barang yang perlu diverifikasi.'))
              : ListView.builder(
                  itemCount: _konfirmingDonations.length,
                  itemBuilder: (context, index) {
                    final donation = _konfirmingDonations[index];
                    ImageProvider? imageProvider;
                    if (donation.buktiBase64 != null && donation.buktiBase64!.isNotEmpty) {
                      try {
                        imageProvider = MemoryImage(base64Decode(donation.buktiBase64!));
                      } catch (e) {
                        print('Error decoding image: $e');
                        imageProvider = null;
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID Donasi: ${donation.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Nama Barang: ${donation.itemName}'),
                            Text('Jumlah: ${donation.quantity}'),
                            Text('Yayasan: ${donation.yayasanName}'),
                            Text('Alamat Yayasan: ${donation.yayasanAddress}'),
                            const SizedBox(height: 10),
                            if (imageProvider != null)
                              Image(
                                image: imageProvider,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                              ) 
                            else
                              const Text('Tidak ada bukti gambar tersedia.'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _rejectDonation(donation),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Tolak', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _verifyDonation(donation),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('Verifikasi', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 