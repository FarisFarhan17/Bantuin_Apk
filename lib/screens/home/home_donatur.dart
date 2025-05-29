import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/header.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/saldo_card.dart';
import '../../widgets/menu_grid.dart';
import '../../widgets/donasi_card.dart';
import '../../services/firebase_service.dart';
import '../../models/donasi.dart';
import '../riwayat_donasi_page.dart'; // Import the history page

class HomeDonatur extends StatefulWidget {
  final int initialIndex;
  
  const HomeDonatur({
    super.key,
    this.initialIndex = 0,
  });

  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<HomeDonaturState>();
    if (state != null) {
      state.onNavBarTap(index);
    }
  }

  @override
  State<HomeDonatur> createState() => HomeDonaturState();
}

class HomeDonaturState extends State<HomeDonatur> {
  int saldo = 0;
  List<Donasi> donasiList = [];
  bool loading = true;
  late int _selectedIndex;

  static List<Widget> _widgetOptions = <Widget>[
    // Home Page Content
    SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Header(showSettings: true),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CustomSearchBar(),
          ),
          SizedBox(height: 16),
          // SaldoCard will be added here after loading data
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 95,
                    child: MenuGrid(onTap: (i) {}),
                  ),
                  SizedBox(height: 14),
                  Divider(thickness: 0.7, color: Colors.grey[300]),
                  SizedBox(height: 14),
                  Text(
                    'Donasi Pilihan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // DonasiCards will be added here after loading data
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    // Donasi Page Content (Placeholder)
    Center(
      child: Text(
        'Donasi Page'
      ),
    ),
    // Riwayat Page Content
    Container(
      color: Colors.white,
      child: RiwayatDonasiPage(),
    ),
    // Profile Page Content (Placeholder)
    Center(
      child: Text(
        'Profile Page'
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadData();
  }

  Future<void> _loadData() async {
    final service = FirebaseService();
    final s = await service.getSaldo();
    final d = await service.getDonasiList();
    setState(() {
      saldo = s.total;
      donasiList = d;
      loading = false;
      // Rebuild the Home page content with loaded data
      _widgetOptions[0] = SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Header(showSettings: true),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CustomSearchBar(),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SaldoCard(saldo: saldo, formatter: NumberFormat.decimalPattern('id')),
            ),
            SizedBox(height: 18),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 32, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 95,
                      child: MenuGrid(onTap: (i) {}),
                    ),
                    SizedBox(height: 14),
                    Divider(thickness: 0.7, color: Colors.grey[300]),
                    SizedBox(height: 14),
                    Text(
                      'Donasi Pilihan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...donasiList.map((d) => DonasiCard(
                          donasi: d,
                          formatter: NumberFormat.decimalPattern('id'),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // make background transparent
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 209, 239, 227), // light blue top
                    Color.fromARGB(255, 235, 255, 244), // very light blue bottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _widgetOptions.elementAt(_selectedIndex), // Display the selected page content
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onNavBarTap,
        selectedItemColor: Color(0xFF43e97b),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'Donasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
