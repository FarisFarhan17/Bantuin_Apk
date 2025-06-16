import 'package:flutter/material.dart';
import 'package:crud_firebase/screens/home/home_donatur.dart'; // Import HomeDonatur

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light grey background
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) { // Swiping up
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeDonatur()),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white, // White background for the top section
                child: Center(
                  child: Text(
                    'Selamat Datang !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[200], // Light blue background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png', // Updated path to your logo
                              height: 200,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Bantuln bersama semua dermawan akan menyalurkan donasi kepada korban bencana melalui donasi dana dan barang yang sangat berguna bagi para korban bencana.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 50),
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 80,
                              color: Colors.blue[900],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 