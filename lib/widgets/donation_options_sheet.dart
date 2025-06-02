import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donasi.dart';
import '../screens/nominal_donasi_page.dart';
import '../services/firebase_service.dart';

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
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  String? selectedDonationType;
  
  // Goods donation related state
  Map<String, int> itemQuantities = {};
  Map<String, bool> itemSelected = {};

  @override
  void initState() {
    super.initState();
    // Initialize itemSelected and itemQuantities based on available items
    for (var item in widget.donasi.barang) {
      itemSelected[item.nama] = false;
      itemQuantities[item.nama] = 0;
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
      otherAmountController.text = widget.formatter.format(amount);
    });
  }

  void setOtherAmount(String value) {
    // Remove any non-digit characters and format
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      selectedAmount = int.tryParse(cleanValue) ?? 0;
      // Update the text field with formatted value
      if (cleanValue.isNotEmpty) {
        otherAmountController.text = widget.formatter.format(selectedAmount);
        // Move cursor to end
        otherAmountController.selection = TextSelection.fromPosition(
          TextPosition(offset: otherAmountController.text.length),
        );
      }
    });
  }

  void toggleItemSelection(String itemName, bool? selected) {
    setState(() {
      itemSelected[itemName] = selected ?? false;
      if (!(selected ?? false)) {
        itemQuantities[itemName] = 0;
      }
    });
  }

  void updateItemQuantity(String itemName, int quantity) {
    if (quantity < 0) {
      return;
    }
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

  Future<void> _processLanjutkan() async {
    if (selectedDonationType == 'money') {
      if (selectedAmount < 1000) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final saldo = await _firebaseService.getSaldo();
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NominalDonasiPage(
              donationAmount: selectedAmount,
              formatter: widget.formatter,
              donasi: widget.donasi,
              currentSaldo: saldo.total,
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch saldo: ${e.toString()}')),
        );
      }
    } else if (selectedDonationType == 'goods') {
      // Check if at least one item is selected
      bool hasSelectedItems = itemSelected.values.any((selected) => selected);
      if (!hasSelectedItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih minimal satu barang untuk didonasikan')),
        );
        return;
      }

      // TODO: Implement goods donation processing
      print('Processing goods donation...');
    }
  }

  Widget _buildDonationTypeSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            'Pilih Jenis Donasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedDonationType == 'money' ? Colors.green : Colors.grey[300],
                  foregroundColor: selectedDonationType == 'money' ? Colors.white : Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    selectedDonationType = 'money';
                  });
                },
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 32),
                    SizedBox(height: 8),
                    Text('Donasi Dana'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedDonationType == 'goods' ? Colors.green : Colors.grey[300],
                  foregroundColor: selectedDonationType == 'goods' ? Colors.white : Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    selectedDonationType = 'goods';
                  });
                },
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 32),
                    SizedBox(height: 8),
                    Text('Donasi Barang'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoneyDonation() {
    final List<int> donationAmounts = [5000, 10000, 20000, 50000];
    return Column(
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
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: donationAmounts.take(2).map((amount) {
                final int value = amount;
                return Expanded(
                  child: Padding(
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
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: donationAmounts.skip(2).take(2).map((amount) {
                final int value = amount;
                return Expanded(
                  child: Padding(
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
        ),
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
        Text(
          'Min. donasi sebesar Rp${widget.formatter.format(1000)}',
          style: TextStyle(
            fontSize: 12,
            color: selectedAmount > 0 && selectedAmount < 1000 ? Colors.red : Colors.grey
          ),
        ),
      ],
    );
  }

  Widget _buildGoodsDonation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Pilih Barang yang Ingin Didonasikan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 16),
        ...widget.donasi.barang.map((item) {
          final itemName = item.nama;
          final isSelected = itemSelected[itemName] ?? false;
          final currentQuantity = itemQuantities[itemName] ?? 0;
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
              if (isSelected) ...[
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Text('Target: ${widget.formatter.format(item.target)}, Terkumpul: ${widget.formatter.format(item.terkumpul)}'),
                ),
              ],
              SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedDonationType == null) ...[
              _buildDonationTypeSelection(),
            ] else if (selectedDonationType == 'money') ...[
              _buildMoneyDonation(),
            ] else if (selectedDonationType == 'goods') ...[
              _buildGoodsDonation(),
            ],
            SizedBox(height: 24),
            if (selectedDonationType != null) ...[
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
                  onPressed: _isLoading ? null : _processLanjutkan,
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Lanjutkan Donasi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 