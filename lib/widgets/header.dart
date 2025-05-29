import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final bool showSettings;
  const Header({super.key, this.showSettings = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hai Faris!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.mail_outline, size: 28, color: Colors.blueGrey),
                onPressed: () {},
              ),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color.fromARGB(255, 54, 186, 148),
                child: showSettings
                    ? Icon(Icons.settings, color: Colors.white, size: 28)
                    : Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 