import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaldoCard extends StatelessWidget {
  final int saldo;
  final NumberFormat formatter;
  const SaldoCard({super.key, required this.saldo, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('E-Saldo', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 4),
              Text(
                'Rp ${formatter.format(saldo)}',
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 28,
            child: Icon(Icons.account_balance_wallet, color: Colors.green, size: 32),
          ),
        ],
      ),
    );
  }
} 