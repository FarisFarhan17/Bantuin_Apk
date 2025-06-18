import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/header.dart';
import '../../widgets/saldo_card.dart';
import '../../widgets/menu_grid.dart';
import '../../widgets/donasi_card.dart';
import '../../services/firebase_service.dart';
import '../../models/donasi.dart';
import '../chat_page.dart'; // Import the new chat page
// import '../profile_page.dart'; // Import the new profile page
import '../donasi_list_page.dart'; // Import the new donasi list page
import '../donasi_status_list_page.dart'; // Import the new donasi status list page
import '../admin_login_page.dart'; // Import the new AdminLoginPage
import '../user_chat_page.dart';
import '../donasi_detail_page.dart'; // Import the new DonasiDetailPage
import '../edit_profile_page.dart'; // Import the new EditProfilePage
import '../auth/user_auth_page.dart';
import 'dart:convert';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  List<Widget> _buildWidgetOptions(String username) {
    return <Widget>[
      // Beranda Page Content
      RefreshIndicator(
        onRefresh: _refreshData,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB3D8F7), // top light blue
                Color(0xFFE6F1FB), // bottom very light blue
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Header(showSettings: false, onProfileTap: () => _scaffoldKey.currentState?.openEndDrawer(), username: username),
                ),
                SizedBox(height: 12),
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
                                style: TextStyle(fontSize: 14, color: Color(0xFF2986CC), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        ...donasiList.map((d) => DonasiCard(
                              donasi: d,
                              formatter: NumberFormat.decimalPattern('id'),
                              showProgressPercentage: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonasiDetailPage(donasi: d),
                                  ),
                                );
                              },
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Donasi Page Content
      DonasiListPage(initialFilter: _currentDonasiFilter),
      // Chat Page Content
      UserChatPage(),
      // Profile Page Content
      AdminLoginPage(),
    ];
  }

  Future<void> _loadData() async {
    final service = FirebaseService();
    final s = await service.getSaldo();
    final d = await service.getDonasiList();
    setState(() {
      saldo = s.total;
      donasiList = d.where((donasi) => donasi.adminVerified).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final username = FirebaseService.currentUser?.username ?? 'Pengguna';
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
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
        ),
        endDrawer: _ProfileDrawer(username: username),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : Container(
                width: double.infinity,
                height: double.infinity,
                color: Color(0xFFE6F1FB),
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
                  children: _buildWidgetOptions(username),
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: onNavBarTap,
          selectedItemColor: Color(0xFF2986CC),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake),
              label: 'Donasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDrawer extends StatelessWidget {
  final String username;
  const _ProfileDrawer({Key? key, required this.username}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      backgroundColor: Color(0xFFE6F1FB), // Soft blue background
      child: Column(
        children: [
          SizedBox(height: 48),
          // Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Color(0xFF2986CC), Color(0xFF6EC1E4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Row(
                  children: [
                    (FirebaseService.currentUser?.gambar != null && FirebaseService.currentUser!.gambar!.isNotEmpty)
                      ? CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.white,
                          backgroundImage: MemoryImage(base64Decode(FirebaseService.currentUser!.gambar!)),
                        )
                      : Icon(Icons.account_circle, size: 54, color: Colors.white),
                    SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 28),
          // Data Diri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.person_outline, color: Color(0xFF2986CC)),
                title: Text('Data Diri', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2986CC))),
                trailing: Icon(Icons.chevron_right, color: Color(0xFF2986CC)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                  );
                },
                splashColor: Color(0xFF6EC1E4).withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          // Chat Admin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: Color(0xFF2986CC)),
                title: Text('Chat Admin', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2986CC))),
                trailing: Icon(Icons.chevron_right, color: Color(0xFF2986CC)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserChatPage()),
                  );
                },
                splashColor: Color(0xFF6EC1E4).withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
            child: Center(
              child: TextButton(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Konfirmasi Logout'),
                      content: Text('Apakah Anda yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout == true) {
                    await FirebaseService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => UserAuthPage()),
                        (route) => false,
                      );
                    }
                  }
                },
                child: Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Versi 1.0.0',
              style: TextStyle(color: Color(0xFF6EC1E4), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
