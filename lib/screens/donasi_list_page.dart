import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/donasi.dart'; // Assuming this is your model for active donations
import '../models/donation_history_entry.dart'; // Assuming this is your model for history entries

import '../widgets/donasi_list_page_card.dart'; // Import the new DonasiListPageCard

enum DonasiFilter { aktif, riwayat }

class DonasiListPage extends StatefulWidget {
  final DonasiFilter initialFilter;
  const DonasiListPage({
    super.key,
    this.initialFilter = DonasiFilter.aktif,
  });

  @override
  State<DonasiListPage> createState() => _DonasiListPageState();
}

class _DonasiListPageState extends State<DonasiListPage> {
  late DonasiFilter _currentFilter;
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Donasi>> _activeDonasiFuture;
  late Future<List<DonationHistoryEntry>> _donationHistoryFuture;
  final NumberFormat formatter = NumberFormat.decimalPattern('id');
  List<Donasi> _donasiList = [];
  List<Donasi> _filteredDonasiList = [];
  final TextEditingController _locationFilterController = TextEditingController();

  // Filter state variables
  String _selectedTimeFilter = 'Terbaru'; // Default time filter
  String _selectedLocationFilter = 'Semua Provinsi'; // Default location filter
  final List<String> _timeFilterOptions = ['Terbaru', 'Terurgent'];
  final List<String> _locationFilterOptions = ['Semua Provinsi', 'Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'Sumatra Utara', 'Sulawesi Selatan']; // Example provinces

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _loadData();
    _locationFilterController.addListener(_onLocationFilterChanged);
  }

  @override
  void didUpdateWidget(DonasiListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _currentFilter = widget.initialFilter;
      });
    }
  }

  @override
  void dispose() {
    _locationFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _activeDonasiFuture = _firebaseService.getDonasiList();
    _donationHistoryFuture = _firebaseService.getDonationHistory('donatur_1'); // Replace with dynamic user ID
    // We will handle the UI update once the futures complete in the FutureBuilder
  }

  void _onFilterChanged(DonasiFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  void _onLocationFilterChanged() {
    // No need to call _filterDonations() here, as it's called in the FutureBuilder
  }

  void _filterDonations() {
    String query = _locationFilterController.text.toLowerCase();
    List<Donasi> filteredBySearch = _donasiList.where((donasi) =>
        donasi.lokasi.toLowerCase().contains(query)
    ).toList();

    List<Donasi> filteredByTimeAndLocation = filteredBySearch.where((donasi) {
      // Apply location filter
      if (_selectedLocationFilter != 'Semua Provinsi' && donasi.lokasi != _selectedLocationFilter) {
        return false;
      }

      // Apply time filter
      // TODO: Implement Terurgent logic based on sisaHari or a dedicated deadline field
      if (_selectedTimeFilter == 'Terbaru') {
        // Assuming donasiList is already sorted by timestamp (newest first) from Firebase
        return true;
      } else if (_selectedTimeFilter == 'Terurgent') {
        // This requires a due date or sisaHari in the Donasi model
        // For now, we'll just return true, actual urgent sorting will be implemented later
        return true; // Placeholder for urgent logic
      }

      return true; // Include if no filters exclude it
    }).toList();

    // Apply time filter sorting after filtering
    if (_selectedTimeFilter == 'Terbaru') {
      // Assuming Firebase query handles this, but sorting locally just in case or if no timestamp field in model
      // filteredByTimeAndLocation.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Requires timestamp field
       // For now, assuming the list from firebase is already sorted newest first
    } else if (_selectedTimeFilter == 'Terurgent') {
       // Requires a field to sort by urgency (e.g., sisaHari ascending)
       filteredByTimeAndLocation.sort((a, b) => a.sisaHari.compareTo(b.sisaHari)); // Sort by sisaHari ascending
    }

    setState(() {
      _filteredDonasiList = filteredByTimeAndLocation;
    });
  }

  void _applyTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      // No need to close menu here, drawer will be closed by Navigator.pop
    });
    _filterDonations(); // Re-filter data
    Navigator.pop(context); // Close the drawer after applying filter
  }

  void _applyLocationFilter(String filter) {
    setState(() {
      _selectedLocationFilter = filter;
      // No need to close menu here, drawer will be closed by Navigator.pop
    });
    _filterDonations(); // Re-filter data
    Navigator.pop(context); // Close the drawer after applying filter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter by Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _timeFilterOptions.map((filter) => FilterChip(
                    label: Text(filter),
                    selected: _selectedTimeFilter == filter,
                    onSelected: (bool selected) {
                      if (selected) {
                        _applyTimeFilter(filter);
                      }
                    },
                  )).toList(),
                ),
                SizedBox(height: 16),
                Text('Filter by Lokasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _locationFilterOptions.map((filter) => FilterChip(
                    label: Text(filter),
                    selected: _selectedLocationFilter == filter,
                    onSelected: (bool selected) {
                      if (selected) {
                        _applyLocationFilter(filter);
                      }
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Wrap search bar and filter buttons in a Container for background
          Container(
            color: Color.fromARGB(255, 183, 239, 208), // Light color from Home page gradient
            child: Column( // Use a Column to arrange the search bar and filter buttons
              children: [
                // Search bar with filter icon (above filter buttons) - Swapped position
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationFilterController,
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan lokasi...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none, // Fixed linter error
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Adjust vertical padding here
                          ),
                          onChanged: (value) => _filterDonations(),
                        ),
                      ),
                      SizedBox(width: 16), // Space between search and filter
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green, // Explicitly set the green color
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.filter_list, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Aktif/Riwayat Filter Buttons (below search bar) - Swapped position
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: FilterButton(
                          label: 'Aktif',
                          isSelected: _currentFilter == DonasiFilter.aktif,
                          onTap: () => _onFilterChanged(DonasiFilter.aktif),
                        ),
                      ),
                      SizedBox(width: 16), // Space between buttons
                      Expanded(
                        child: FilterButton(
                          label: 'Riwayat',
                          isSelected: _currentFilter == DonasiFilter.riwayat,
                          onTap: () => _onFilterChanged(DonasiFilter.riwayat),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                if (_currentFilter == DonasiFilter.aktif) {
                  return FutureBuilder<List<Donasi>>(
                    future: _activeDonasiFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading active donations: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Tidak ada donasi aktif.'));
                      }

                      _donasiList = snapshot.data!;
                      // Apply filtering directly based on current state without calling setState
                      String query = _locationFilterController.text.toLowerCase();
                      _filteredDonasiList = _donasiList.where((donasi) {
                        // Apply location filter
                        if (query.isNotEmpty && !donasi.lokasi.toLowerCase().contains(query)) {
                          return false;
                        }
                        // Apply time filter (Terurgent sorting is applied after filtering)
                        // The 'Terbaru' filter doesn't exclude items, just affects sorting.
                        return true; // Include all items for now, sorting handled later.
                      }).toList();

                      // Apply time filter sorting after filtering
                      if (_selectedTimeFilter == 'Terurgent') {
                         _filteredDonasiList.sort((a, b) => a.sisaHari.compareTo(b.sisaHari));
                      }

                      return Container( // Wrap ListView.builder with Container
                        color: Colors.grey[100], // Consistent grey background here
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding
                          itemCount: _filteredDonasiList.length,
                          itemBuilder: (context, index) {
                            final donasi = _filteredDonasiList[index];
                            return DonasiListPageCard(
                              donasi: donasi,
                              formatter: formatter,
                            );
                          },
                        ),
                      );
                    },
                  );
                } else { // Riwayat Filter
                  return FutureBuilder<List<DonationHistoryEntry>>(
                    future: _donationHistoryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading history: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Belum ada riwayat donasi.'));
                      } else {
                        final donationHistory = snapshot.data!;
                        return Container( // Wrap ListView.builder with Container
                          color: Colors.grey[100], // Consistent grey background here
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding
                            itemCount: donationHistory.length,
                            itemBuilder: (context, index) {
                              final entry = donationHistory[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 2.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.donasiTitle,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Jumlah Donasi: Rp ${formatter.format(entry.amount)}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Status: ${entry.status}', // Display status
                                        style: TextStyle(fontSize: 14, color: entry.status == 'Pending' ? Colors.orange : Colors.green), // Style status text
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(entry.timestamp)}', // Formatted timestamp
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green)
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.green,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
} 