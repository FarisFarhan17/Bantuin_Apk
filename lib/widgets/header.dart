import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final bool showSettings;
  final VoidCallback? onProfileTap;
  final String username;
  const Header({super.key, this.showSettings = false, this.onProfileTap, required this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hai $username!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.mail_outline, size: 28, color: Colors.blueGrey),
                onPressed: () {},
              ),
              SizedBox(width: 8),
              IconButton(
                icon: showSettings
                    ? Icon(Icons.settings, color: Colors.blueGrey, size: 28)
                    : Icon(Icons.person, color: Colors.blueGrey, size: 28),
                onPressed: onProfileTap,
                splashRadius: 28,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 