import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/header.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/saldo_card.dart';
import '../../widgets/menu_grid.dart';
import '../../widgets/donasi_card.dart';
import '../../services/firebase_service.dart';
import '../../models/donasi.dart';
import '../chat_page.dart'; // Import the new chat page
import '../profile_page.dart'; // Import the new profile page
import '../donasi_list_page.dart'; // Import the new donasi list page
import '../donasi_status_list_page.dart'; // Import the new donasi status list page

class HomeDonatur extends StatefulWidget {
  final int initialIndex;
  final DonasiFilter? initialDonasiFilter; // Make it optional
  
  const HomeDonatur({
    super.key,
    this.initialIndex = 0,
    this.initialDonasiFilter, // Optional parameter
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

class HomeDonaturState extends State<HomeDonatur> with AutomaticKeepAliveClientMixin<HomeDonatur> {
  int saldo = 0;
  List<Donasi> donasiList = [];
  bool loading = true;
  late int _selectedIndex;
  late DonasiFilter _currentDonasiFilter;

  late PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentDonasiFilter = widget.initialDonasiFilter ?? DonasiFilter.aktif;
    _loadData();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) { // If switching to Donasi tab
        _currentDonasiFilter = DonasiFilter.aktif; // Reset to aktif
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      // Beranda Page Content
      RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
                        child: MenuGrid(
                          onTap: (i) {
                            if (i == 1) { // Status Donasi button
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonasiStatusListPage(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 14),
                      Divider(thickness: 0.7, color: Colors.grey[300]),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Donasi Pilihan',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Animate to Donasi tab (index 1)
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                               // State will be updated by onPageChanged
                            },
                            child: Text(
                              'Lihat semua >',
                              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...donasiList.map((d) => DonasiCard(
                            donasi: d,
                            formatter: NumberFormat.decimalPattern('id'),
                            showProgressPercentage: true,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Donasi Page Content
      DonasiListPage(initialFilter: _currentDonasiFilter),
      // Chat Page Content
      ChatPage(),
      // Profile Page Content
      ProfilePage(),
    ];
  }

  Future<void> _loadData() async {
    final service = FirebaseService();
    final s = await service.getSaldo();
    final d = await service.getDonasiList();
    setState(() {
      saldo = s.total;
      donasiList = d;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
          return true;
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                      Color.fromARGB(255, 209, 239, 227),
                      Color.fromARGB(255, 235, 255, 244),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                      if (index == 1) {
                         _currentDonasiFilter = DonasiFilter.aktif;
                      }
                    });
                  },
                  children: _buildWidgetOptions(),
                ),
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
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
