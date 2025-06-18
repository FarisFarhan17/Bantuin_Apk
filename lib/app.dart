import 'package:flutter/material.dart';
import 'package:crud_firebase/screens/home/home_donatur.dart';
import 'package:crud_firebase/screens/landing_page.dart';
import 'package:crud_firebase/screens/auth/user_auth_page.dart';
import 'package:crud_firebase/screens/admin_chat_list_page.dart';
import 'package:crud_firebase/screens/user_chat_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bantuln',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeDonatur(),
        '/auth': (context) => const UserAuthPage(),
        '/admin-chat': (context) => const AdminChatListPage(),
        '/user-chat': (context) => const UserChatPage(),
      },
    );
  }
} 