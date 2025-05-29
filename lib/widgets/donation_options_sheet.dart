import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'dart:io'; // Removed dart:io as it's only used for File
// import 'package:image_picker/image_picker.dart'; // Removed image_picker
import '../models/donasi.dart';
import '../screens/nominal_donasi_page.dart'; // Import the new page
import '../services/firebase_service.dart'; // Import FirebaseService

class DonationOptionsSheet extends StatefulWidget {
  final Donasi donasi;
  final NumberFormat formatter;

  const DonationOptionsSheet({super.key, required this.donasi, required this.formatter});

  @override
  State<DonationOptionsSheet> createState() => _DonationOptionsSheetState();
}

class _DonationOptionsSheetState extends State<DonationOptionsSheet> {
  int selectedAmount = 0;
  TextEditingController otherAmountController = TextEditingController();
  bool donateItems = false;
  Map<String, int> itemQuantities = {}; // item id -> quantity
  Map<String, bool> itemSelected = {}; // item id -> selected
  // Map<String, File?> itemPhotos = {}; // item id -> photo file - Removed image picker related state
  // final ImagePicker _picker = ImagePicker(); // Removed ImagePicker instance
  bool _isLoading = false; // Add loading state
  final FirebaseService _firebaseService = FirebaseService(); // Instantiate FirebaseService

  @override
  void initState() {
    super.initState();
    // Initialize itemSelected and itemQuantities based on available items
    for (var item in widget.donasi.barang) {
      itemSelected[item.nama] = false;
      itemQuantities[item.nama] = 0;
      // itemPhotos[item.nama] = null; // Removed image picker related initialization
    }
  }

  @override
  void dispose() {
    otherAmountController.dispose();
    super.dispose();
  }

  void selectAmount(int amount) {
    setState(() {
      selectedAmount = amount;
      otherAmountController.clear();
    });
  }

  void setOtherAmount(String value) {
    setState(() {
      selectedAmount = int.tryParse(value) ?? 0;
    });
  }

  void toggleDonateItems(bool? value) {
    setState(() {
      donateItems = value ?? false;
    });
  }

  void toggleItemSelection(String itemName, bool? selected) {
    setState(() {
      itemSelected[itemName] = selected ?? false;
      if (!(selected ?? false)) {
        itemQuantities[itemName] = 0;
        // itemPhotos[itemName] = null; // Removed image picker related logic
      }
    });
  }

  void updateItemQuantity(String itemName, int quantity) {
    final item = widget.donasi.barang.firstWhere((b) => b.nama == itemName);
    if (quantity > (item.target - item.terkumpul)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Melebihi batas! Target sisa: ${widget.formatter.format(item.target - item.terkumpul)}')),
      );
      quantity = item.target - item.terkumpul;
    }
    setState(() {
      itemQuantities[itemName] = quantity;
    });
  }

  // Removed pickImage function
  // Removed showImagePickerOptions function

  Future<void> _processLanjutkan() async {
    if (selectedAmount <= 0) {
      // Show an error or message if no amount is selected
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or enter a donation amount.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final saldo = await _firebaseService.getSaldo(); // Fetch saldo
      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      // Navigate to NominalDonasiPage, passing the fetched saldo and donasi object
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NominalDonasiPage(
            donationAmount: selectedAmount,
            formatter: widget.formatter,
            donasi: widget.donasi,
            currentSaldo: saldo.total, // Pass the fetched saldo
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      // Show an error message if fetching saldo fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch saldo: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> donationAmounts = [5000, 10000, 20000, 50000];

    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Jumlah Donasi Dana',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Column( // Use Column to arrange rows vertically
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: donationAmounts.take(2).map((amount) { // Take the first two amounts
                    final int value = amount;
                    return Expanded( // Use Expanded to make buttons take equal space
                      child: Padding( // Add padding between buttons
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedAmount == value ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedAmount == value ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => selectAmount(value),
                          child: Text('Rp ${widget.formatter.format(value)}'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8), // Add spacing between rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: donationAmounts.skip(2).take(2).map((amount) { // Skip first two and take the next two
                    final int value = amount;
                    return Expanded( // Use Expanded to make buttons take equal space
                      child: Padding( // Add padding between buttons
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedAmount == value ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedAmount == value ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => selectAmount(value),
                          child: Text('Rp ${widget.formatter.format(value)}'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ), // Close Column for buttons
            SizedBox(height: 16),
            Text('Nominal Donasi Lainnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Text(
                    'Rp ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  Expanded(
                    child: TextField(
                      controller: otherAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textAlign: TextAlign.right,
                      onChanged: setOtherAmount,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text('Min. donasi sebesar Rp${widget.formatter.format(1000)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ingin donasi barang?', style: TextStyle(fontSize: 16)),
                Switch(
                  value: donateItems,
                  onChanged: toggleDonateItems,
                ),
              ],
            ),
            if (donateItems) ...[
              SizedBox(height: 16),
              Text('Pilih Barang yang Ingin Didonasikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              ...widget.donasi.barang.map((item) {
                final itemName = item.nama;
                final isSelected = itemSelected[itemName] ?? false;
                final currentQuantity = itemQuantities[itemName] ?? 0;
                // final photoFile = itemPhotos[itemName]; // Removed image picker related variable
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (selected) => toggleItemSelection(itemName, selected),
                        ),
                        Expanded(child: Text(itemName)),
                        if (isSelected) ...[
                          SizedBox(width: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: () => updateItemQuantity(itemName, currentQuantity - 1),
                              ),
                              Text('$currentQuantity'),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline),
                                onPressed: () => updateItemQuantity(itemName, currentQuantity + 1),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    // Removed image picker related UI
                    // if (isSelected) ...[
                    //   SizedBox(height: 8),
                    //   Row(children: [
                    //     SizedBox(48),
                    //     Text('Target: ${widget.formatter.format(item.target)}, Terkumpul: ${widget.formatter.format(item.terkumpul)}'),
                    //   ],),
                    //   SizedBox(height: 8),
                    //   Row(children: [
                    //     SizedBox(48),
                    //     photoFile == null
                    //         ? ElevatedButton(
                    //             onPressed: () => showImagePickerOptions(itemName),
                    //             child: Text('Ambil Foto/Gallery'),
                    //           )
                    //         : Row(
                    //             children: [
                    //               Icon(Icons.check_circle, color: Colors.green),
                    //               SizedBox(width: 8),
                    //               Text('Foto dipilih'),
                    //             ],
                    //           ),
                    //   ],),
                    // ],
                    SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 50, 187, 95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _processLanjutkan, // Disable button when loading
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Lanjutkan Donasi'), // Show loading indicator in button
              ),
            ),
          ],
        ),
      ),
    );
  }
} 