import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/donasi.dart'; // Assuming Donasi model is needed for campaign data

class CampaignStatistics extends StatefulWidget {
  const CampaignStatistics({super.key});

  @override
  State<CampaignStatistics> createState() => _CampaignStatisticsState();
}

class _CampaignStatisticsState extends State<CampaignStatistics> {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  int _totalCampaigns = 0;
  int _activeCampaigns = 0;
  int _totalDonors = 0;
  double _totalDonations = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCampaignStatistics();
  }

  Future<void> _fetchCampaignStatistics() async {
    try {
      final List<Donasi> campaigns = await _firebaseService.getDonasiList();
      final filteredCampaigns = campaigns.where((campaign) {
        final campaignDate = campaign.timestamp; // Assuming timestamp exists in Donasi model
        return campaignDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               campaignDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      setState(() {
        _totalCampaigns = filteredCampaigns.length;
        _activeCampaigns = filteredCampaigns.where((campaign) => campaign.status == 'Proses' || campaign.status == 'Aktif' || campaign.status == 'Terverifikasi').length; // Assuming 'Proses', 'Aktif', or 'Terverifikasi' means active
        
        // Calculate total donations and total donors
        _totalDonations = filteredCampaigns.fold(0.0, (sum, campaign) => sum + (campaign.terkumpul ?? 0));
        
        // This part needs more specific Firebase queries or a way to get unique donors
        // For now, I'll count the sum of jumlahDonasi from all campaigns
        _totalDonors = filteredCampaigns.fold(0, (sum, campaign) => sum + (campaign.jumlahDonasi ?? 0));
      });
    } catch (e) {
      print('Error fetching campaign statistics: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  Future<void> _selectDateRange() async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
    );
    if (pickedStartDate != null) {
      final DateTime? pickedEndDate = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: pickedStartDate,
        lastDate: DateTime.now(),
        helpText: 'Select End Date',
      );
      if (pickedEndDate != null) {
        setState(() {
          _startDate = pickedStartDate;
          _endDate = pickedEndDate;
        });
        _fetchCampaignStatistics();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF56B289),
        title: const Text(
          'Statistik Kampanye',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Lihat statistik kampanye dan donasi',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDateRange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildStatisticCard(
                    icon: Icons.campaign,
                    iconColor: Colors.green,
                    value: _totalCampaigns.toString(),
                    label: 'Total Kampanye',
                  ),
                  _buildStatisticCard(
                    icon: Icons.trending_up,
                    iconColor: Colors.purple,
                    value: _activeCampaigns.toString(),
                    label: 'Kampanye Aktif',
                  ),
                  _buildStatisticCard(
                    icon: Icons.volunteer_activism,
                    iconColor: Colors.orange,
                    value: 'Rp ${NumberFormat('#,##0', 'id_ID').format(_totalDonations)}',
                    label: 'Total Donasi',
                  ),
                  _buildStatisticCard(
                    icon: Icons.people,
                    iconColor: Colors.deepPurple,
                    value: _totalDonors.toString(),
                    label: 'Total Donatur',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
