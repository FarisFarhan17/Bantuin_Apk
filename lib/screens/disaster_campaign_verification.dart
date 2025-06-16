import 'package:flutter/material.dart';
import 'package:crud_firebase/widgets/search_bar.dart';
import 'package:crud_firebase/models/donasi.dart';
import 'package:crud_firebase/services/firebase_service.dart';

class DisasterCampaignVerification extends StatefulWidget {
  const DisasterCampaignVerification({super.key});

  @override
  State<DisasterCampaignVerification> createState() => _DisasterCampaignVerificationState();
}

class _DisasterCampaignVerificationState extends State<DisasterCampaignVerification> {
  String selectedFilter = 'All';
  late FirebaseService _firebaseService;
  List<Donasi> _allCampaigns = [];
  List<Donasi> _filteredCampaigns = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _fetchCampaigns();
    _searchController.addListener(_filterCampaigns);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    try {
      final campaigns = await _firebaseService.getDonasiList();
      setState(() {
        _allCampaigns = campaigns;
        _filterCampaigns();
      });
    } catch (e) {
      print('Error fetching campaigns: $e');
      // Handle error, maybe show a snackbar
    }
  }

  void _filterCampaigns() {
    List<Donasi> campaignsToFilter = _allCampaigns;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      campaignsToFilter = campaignsToFilter.where((campaign) {
        final query = _searchController.text.toLowerCase();
        return campaign.judul.toLowerCase().contains(query) ||
               campaign.deskripsi.toLowerCase().contains(query) ||
               campaign.lokasi.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (selectedFilter == 'All') {
      _filteredCampaigns = campaignsToFilter;
    } else if (selectedFilter == 'Pending') {
      _filteredCampaigns = campaignsToFilter.where((campaign) => campaign.adminVerified == false && campaign.status == 'Proses').toList();
    } else if (selectedFilter == 'Verified') {
      _filteredCampaigns = campaignsToFilter.where((campaign) => campaign.adminVerified == true && campaign.status == 'Terverifikasi').toList();
    } else if (selectedFilter == 'Rejected') {
      _filteredCampaigns = campaignsToFilter.where((campaign) => campaign.adminVerified == false && campaign.status == 'Ditolak').toList();
    }
    setState(() {});
  }

  Future<void> _updateCampaignVerificationStatus(String donasiId, bool isVerified) async {
    try {
      await _firebaseService.updateDonasiCampaignStatus(
        donasiId: donasiId,
        verifikasi: isVerified,
        status: isVerified ? 'Terverifikasi' : 'Ditolak',
      );
      _fetchCampaigns(); // Refresh the list after update
    } catch (e) {
      print('Error updating campaign status: $e');
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Kampanye'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(controller: _searchController,),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('All'),
                  _buildFilterButton('Pending'),
                  _buildFilterButton('Verified'),
                  _buildFilterButton('Rejected'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCampaigns.isEmpty
                  ? const Center(child: Text('No campaigns found.'))
                  : ListView.builder(
                      itemCount: _filteredCampaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = _filteredCampaigns[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              // Navigate to campaign detail page if needed
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          campaign.judul,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: campaign.adminVerified
                                              ? Colors.green[100]
                                              : (campaign.status == 'Ditolak'
                                                  ? Colors.red[100]
                                                  : Colors.orange[100]),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          campaign.adminVerified
                                              ? 'Verified'
                                              : (campaign.status == 'Ditolak'
                                                  ? 'Rejected'
                                                  : 'Pending'),
                                          style: TextStyle(
                                            color: campaign.adminVerified
                                                ? Colors.green[700]
                                                : (campaign.status == 'Ditolak'
                                                    ? Colors.red[700]
                                                    : Colors.orange[700]),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(campaign.lokasi),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${campaign.timestamp.day} ${campaign.timestamp.month} ${campaign.timestamp.year}'), // Format date
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    campaign.deskripsi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  if (!campaign.adminVerified && campaign.status != 'Ditolak')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            _updateCampaignVerificationStatus(
                                                campaign.id, true);
                                          },
                                          child: const Text('Verify'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _updateCampaignVerificationStatus(
                                                campaign.id, false);
                                          },
                                          child: const Text('Reject'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = selectedFilter == text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = text;
            _filterCampaigns();
          });
        },
        selectedColor: const Color(0xFFE8F5E9), // Light green
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
          ),
        ),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
        ),
        avatar: isSelected
            ? const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50))
            : null,
      ),
    );
  }
}
