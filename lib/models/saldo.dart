class Saldo {
  final int total;
  final String id;

  Saldo({required this.id, required this.total});

  factory Saldo.fromMap(String id, Map<String, dynamic> data) {
    return Saldo(
      id: id,
      total: data['total'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
    };
  }
} 