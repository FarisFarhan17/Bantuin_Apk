import 'package:flutter/material.dart';
import 'package:crud_firebase/screens/home/home_donatur.dart';
import 'package:crud_firebase/screens/landing_page.dart';

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
    );
  }
} 