import 'package:flutter/material.dart';
import 'package:crud_firebase/models/donasi.dart'; // Import Donasi

class DisasterCampaignDetail extends StatelessWidget {
  final Donasi campaign;
  const DisasterCampaignDetail({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.judul),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Detail Kampanye: ${campaign.judul}'),
              Text('Status: ${campaign.status}'),
              Text('Tanggal Dibuat: ${campaign.timestamp.toLocal().toString().split(' ')[0]}'),
              // Add more campaign details here
            ],
          ),
        ),
      ),
    );
  }
}
