import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaldoCard extends StatefulWidget {
  final int saldo;
  final NumberFormat formatter;
  const SaldoCard({super.key, required this.saldo, required this.formatter});

  @override
  _SaldoCardState createState() => _SaldoCardState();
}

class _SaldoCardState extends State<SaldoCard> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadBalanceVisibility();
  }

  Future<void> _loadBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = prefs.getBool('isBalanceVisible') ?? true;
    });
  }

  Future<void> _toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
    prefs.setBool('isBalanceVisible', _isBalanceVisible);
  }

  void _onTopUpTap() {
    print('Top-up tapped!');
  }

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
              Row(
                children: [
                  Text(
                    _isBalanceVisible ? 'Rp ${widget.formatter.format(widget.saldo)}' : 'Rp XXXXX',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBalanceVisibility,
                    child: Icon(
                      _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 28,
                child: Icon(Icons.account_balance_wallet, color: Colors.green, size: 32),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _onTopUpTap,
                child: Text(
                  'Top-up',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 