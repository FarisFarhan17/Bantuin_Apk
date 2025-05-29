import 'package:flutter/material.dart';
import 'screens/home/home_donatur.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Donasi',
      home: HomeDonatur(),
      debugShowCheckedModeBanner: false,
    );
  }
} 