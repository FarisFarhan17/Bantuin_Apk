import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/donasi.dart';
import '../screens/nominal_donasi_page.dart';
import '../services/firebase_service.dart';
import '../widgets/yayasan_selection_sheet.dart';

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
  String? selectedDeliveryType;
  
  // Goods donation related state
  Map<String, int> itemQuantities = {};
  Map<String, bool> itemSelected = {};
  Map<String, File?> itemPhotos = {};
  final ImagePicker _picker = ImagePicker();

  // Add step tracking
  int _currentStep = 0; // 0: donation type, 1: goods selection, 2: delivery type

  @override
  void initState() {
    super.initState();
    // Initialize itemSelected and itemQuantities based on available items
    for (var item in widget.donasi.barang) {
      itemSelected[item.nama] = false;
      itemQuantities[item.nama] = 0;
      itemPhotos[item.nama] = null;
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
        itemPhotos[itemName] = null;
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

  Future<void> pickImage(String itemName, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          itemPhotos[itemName] = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void showImagePickerOptions(String itemName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(itemName, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(itemName, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNextStep() {
    if (selectedDonationType == 'money') {
      if (selectedAmount < 1000) {
        return;
      }
      _processMoneyDonation();
    } else if (selectedDonationType == 'goods') {
      if (_currentStep == 1) {
        // Validate goods selection
        bool hasSelectedItems = itemSelected.values.any((selected) => selected);
        if (!hasSelectedItems) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pilih minimal satu barang untuk didonasikan')),
          );
          return;
        }

        // Check if all selected items have photos
        List<String> itemsWithoutPhotos = [];
        itemSelected.forEach((itemName, selected) {
          if (selected && itemPhotos[itemName] == null) {
            itemsWithoutPhotos.add(itemName);
          }
        });

        if (itemsWithoutPhotos.isNotEmpty) {
          return;
        }

        // Check if all selected items have quantity > 0
        List<String> itemsWithZeroQuantity = [];
        itemSelected.forEach((itemName, selected) {
          if (selected && (itemQuantities[itemName] ?? 0) <= 0) {
            itemsWithZeroQuantity.add(itemName);
          }
        });

        if (itemsWithZeroQuantity.isNotEmpty) {
          return;
        }

        setState(() {
          _currentStep = 2;
          selectedDeliveryType = null;
        });
      } else if (_currentStep == 2) {
        if (selectedDeliveryType == null) {
          return;
        }

        Navigator.pop(context, {
          'items': itemSelected.entries
              .where((entry) => entry.value)
              .map((entry) => {
                    'name': entry.key,
                    'quantity': itemQuantities[entry.key],
                    'photo': itemPhotos[entry.key],
                  })
              .toList(),
          'delivery_type': selectedDeliveryType,
        });
      }
    }
  }

  void _handleDonationTypeSelection(String type) {
    setState(() {
      selectedDonationType = type;
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelectedItems = selectedDonationType == 'goods' && 
        _currentStep == 1 && 
        itemSelected.values.any((selected) => selected);

    return WillPopScope(
      onWillPop: () async {
        if (selectedDonationType == 'goods' && _currentStep == 1) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Batalkan Donasi?'),
              content: Text('Apakah Anda yakin ingin membatalkan donasi barang?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Ya'),
                ),
              ],
            ),
          );
          
          if (shouldPop == true) {
            // Reset the sheet state
            setState(() {
              selectedDonationType = null;
              _currentStep = 0;
              itemSelected.clear();
              itemQuantities.clear();
              itemPhotos.clear();
              // Reinitialize the state
              for (var item in widget.donasi.barang) {
                itemSelected[item.nama] = false;
                itemQuantities[item.nama] = 0;
                itemPhotos[item.nama] = null;
              }
            });
            return true;
          }
          return false;
        }
        return true;
      },
      child: Container(
        height: hasSelectedItems ? MediaQuery.of(context).size.height * 0.9 : null,
        padding: EdgeInsets.all(16),
        child: hasSelectedItems
            ? Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentStep == 0) ...[
                            _buildDonationTypeSelection(),
                          ] else if (selectedDonationType == 'money') ...[
                            _buildMoneyDonation(),
                          ] else if (selectedDonationType == 'goods') ...[
                            if (_currentStep == 1) ...[
                              _buildGoodsDonation(),
                            ] else if (_currentStep == 2) ...[
                              _buildDeliveryTypeSelection(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_currentStep > 0 && _currentStep < 2) ...[
                    SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _handleNextStep,
                        child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.white) 
                          : Text('Lanjutkan Donasi'),
                      ),
                    ),
                  ],
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) ...[
                      _buildDonationTypeSelection(),
                    ] else if (selectedDonationType == 'money') ...[
                      _buildMoneyDonation(),
                    ] else if (selectedDonationType == 'goods') ...[
                      if (_currentStep == 1) ...[
                        _buildGoodsDonation(),
                      ] else if (_currentStep == 2) ...[
                        _buildDeliveryTypeSelection(),
                      ],
                    ],
                    SizedBox(height: 24),
                    if (_currentStep > 0 && _currentStep < 2) ...[
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
                          onPressed: _isLoading ? null : _handleNextStep,
                          child: _isLoading 
                            ? CircularProgressIndicator(color: Colors.white) 
                            : Text('Lanjutkan Donasi'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
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
                onPressed: () => _handleDonationTypeSelection('money'),
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
                onPressed: () => _handleDonationTypeSelection('goods'),
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
    // Check if all selected items have photos
    List<String> itemsWithoutPhotos = [];
    itemSelected.forEach((itemName, selected) {
      if (selected && itemPhotos[itemName] == null) {
        itemsWithoutPhotos.add(itemName);
      }
    });

    // Check for items with zero quantity
    List<String> itemsWithZeroQuantity = [];
    itemSelected.forEach((itemName, selected) {
      if (selected && (itemQuantities[itemName] ?? 0) <= 0) {
        itemsWithZeroQuantity.add(itemName);
      }
    });

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
        if (itemsWithoutPhotos.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Foto wajib diisi untuk barang:',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...itemsWithoutPhotos.map((itemName) => Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: Text(
                    '• $itemName',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                )).toList(),
              ],
            ),
          ),
        if (itemsWithZeroQuantity.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Minimal harus donasi 1 barang:',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...itemsWithZeroQuantity.map((itemName) => Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: Text(
                    '• $itemName',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                )).toList(),
              ],
            ),
          ),
        ...widget.donasi.barang.map((item) {
          final itemName = item.nama;
          final isSelected = itemSelected[itemName] ?? false;
          final currentQuantity = itemQuantities[itemName] ?? 0;
          final photoFile = itemPhotos[itemName];
          final progress = item.terkumpul / item.target;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (selected) => toggleItemSelection(itemName, selected),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Target: ${widget.formatter.format(item.target)}, Terkumpul: ${widget.formatter.format(item.terkumpul)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: () => updateItemQuantity(itemName, currentQuantity - 1),
                              ),
                              Text(
                                '$currentQuantity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto Barang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '*Wajib',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (photoFile == null)
                              AspectRatio(
                                aspectRatio: 4/3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => showImagePickerOptions(itemName),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 32,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Ambil Foto/Gallery',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              AspectRatio(
                                aspectRatio: 4/3,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(photoFile),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => showImagePickerOptions(itemName),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  itemPhotos[itemName] = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDeliveryTypeSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            'Pilih Metode Pengiriman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedDeliveryType == 'drop_off' ? Colors.green : Colors.grey[300],
                  foregroundColor: selectedDeliveryType == 'drop_off' ? Colors.white : Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    selectedDeliveryType = 'drop_off';
                  });
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => YayasanSelectionSheet(
                      onYayasanSelected: (yayasan) {
                        Navigator.pop(context, {
                          'items': itemSelected.entries
                              .where((entry) => entry.value)
                              .map((entry) => {
                                    'name': entry.key,
                                    'quantity': itemQuantities[entry.key],
                                    'photo': itemPhotos[entry.key],
                                  })
                              .toList(),
                          'delivery_type': selectedDeliveryType,
                          'yayasan': yayasan,
                        });
                      },
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.delivery_dining, size: 32),
                    SizedBox(height: 8),
                    Text('Drop Off'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedDeliveryType == 'pick_up' ? Colors.green : Colors.grey[300],
                  foregroundColor: selectedDeliveryType == 'pick_up' ? Colors.white : Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    selectedDeliveryType = 'pick_up';
                  });
                  Navigator.pop(context, {
                    'items': itemSelected.entries
                        .where((entry) => entry.value)
                        .map((entry) => {
                              'name': entry.key,
                              'quantity': itemQuantities[entry.key],
                              'photo': itemPhotos[entry.key],
                            })
                        .toList(),
                    'delivery_type': selectedDeliveryType,
                  });
                },
                child: Column(
                  children: [
                    Icon(Icons.local_shipping, size: 32),
                    SizedBox(height: 8),
                    Text('Pick Up'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _processMoneyDonation() async {
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
  }
} 