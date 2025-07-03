import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donasi.dart';
import '../services/firebase_service.dart';
import '../screens/home/home_donatur.dart';
import 'donasi_list_page.dart';

class NominalDonasiPage extends StatefulWidget {
  final int donationAmount;
  final NumberFormat formatter;
  final Donasi donasi;
  final int currentSaldo;

  const NominalDonasiPage({
    super.key,
    required this.donationAmount,
    required this.formatter,
    required this.donasi,
    required this.currentSaldo,
  });

  @override
  State<NominalDonasiPage> createState() => _NominalDonasiPageState();
}

class _NominalDonasiPageState extends State<NominalDonasiPage> {
  final FirebaseService _firebaseService = FirebaseService();

  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing Donation...'),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text(
                'Terima kasih atas Donasi anda!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                // Close the success dialog
                Navigator.of(context).pop();
                
                // Pop all the way back to the main page
                Navigator.of(context).popUntil((route) => route.isFirst);
                
                // Replace the current page with HomeDonatur showing riwayat tab
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomeDonatur(
                      initialIndex: 1,
                      initialDonasiFilter: DonasiFilter.riwayat,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Donasi Gagal'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processDonation() async {
    // Check if campaign has ended (sisaHari == 0)
    if (widget.donasi.sisaHari == 0) {
      _showErrorDialog('Kampanye telah berakhir. Donasi tidak dapat dilakukan.');
      return;
    }

    try {
      await _firebaseService.deductSaldo(widget.donationAmount);

      await _firebaseService.addDonationHistory(
        donasiId: widget.donasi.id,
        donasiTitle: widget.donasi.judul,
        amount: widget.donationAmount,
        timestamp: DateTime.now(),
      );

      await _firebaseService.updateDonasiCollectedAmount(
        donasiId: widget.donasi.id,
        amount: widget.donationAmount,
      );

      _showSuccessDialog();
    } catch (e) {
      print('Donation processing failed: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showErrorDialog('Donasi gagal: ${e.toString()}');
    }
  }

  void _showConfirmationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Donasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda akan berdonasi sebesar:'),
              SizedBox(height: 8),
              Text(
                'Rp ${widget.formatter.format(widget.donationAmount)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 16),
              Text('Saldo E-money Anda saat ini:'),
              SizedBox(height: 8),
              Text(
                'Rp ${widget.formatter.format(widget.currentSaldo)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 16),
              Text('Apakah Anda yakin ingin melanjutkan donasi?'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Lanjutkan'),
              onPressed: () {
                Navigator.of(context).pop();
                _showLoadingDialog();
                _processDonation();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nominal Donasi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan berdonasi sebesar:',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Rp ${widget.formatter.format(widget.donationAmount)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 24),
            Text(
              'Saldo E-money Anda:',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Rp ${widget.formatter.format(widget.currentSaldo)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            if (widget.donasi.sisaHari == 0)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kampanye telah berakhir. Donasi tidak dapat dilakukan.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: Container()),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.donasi.sisaHari == 0 
                      ? Colors.grey[400] 
                      : Color(0xFF43e97b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  foregroundColor: Colors.white,
                ),
                onPressed: widget.donasi.sisaHari == 0 
                    ? null 
                    : () {
                        if (widget.donationAmount > widget.currentSaldo) {
                          _showErrorDialog('Saldo tidak mencukupi.');
                        } else {
                           _showConfirmationDialog();
                        }
                      },
                child: Text(
                  widget.donasi.sisaHari == 0 ? 'Kampanye Berakhir' : 'Lanjutkan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 