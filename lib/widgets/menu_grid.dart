import 'package:flutter/material.dart';
import '../screens/create_campaign_page.dart';

class MenuGrid extends StatelessWidget {
  final void Function(int) onTap;
  const MenuGrid({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color blue = Color(0xFF2986CC);
    final List<Map<String, dynamic>> menu = [
      {'icon': Icons.volunteer_activism, 'label': 'Donasi', 'color': blue},
      {'icon': Icons.assignment_turned_in, 'label': 'Status Donasi', 'color': blue},
      {'icon': Icons.info_outline, 'label': 'Informan', 'color': blue},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
      ),
      itemCount: menu.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            if (i == 2) { // Adjusted index for 'Informan' button
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCampaignPage(),
                ),
              );
            } else {
              onTap(i);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: menu[i]['color'].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: menu[i]['color'].withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(menu[i]['icon'], color: menu[i]['color'], size: 28),
              ),
              SizedBox(height: 8),
              Text(menu[i]['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }
} 