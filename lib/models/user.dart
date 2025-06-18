class User {
  final String id;
  final String userId;
  final String username;
  final String password;
  final String? gambar;

  User({
    required this.id,
    required this.userId,
    required this.username,
    required this.password,
    this.gambar,
  });

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      gambar: map['gambar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'password': password,
      if (gambar != null) 'gambar': gambar,
    };
  }
} 