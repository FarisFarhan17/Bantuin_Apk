class DonationHistoryEntry {
  final String id;
  final String userId;
  final String donasiId;
  final String donasiTitle;
  final int amount;
  final DateTime timestamp;

  DonationHistoryEntry({
    required this.id,
    required this.userId,
    required this.donasiId,
    required this.donasiTitle,
    required this.amount,
    required this.timestamp,
  });

  factory DonationHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    return DonationHistoryEntry( 
      id: id,
      userId: map['userId'] ?? '',
      donasiId: map['donasiId'] ?? '',
      donasiTitle: map['donasiTitle'] ?? '',
      amount: map['amount'] ?? 0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
} 