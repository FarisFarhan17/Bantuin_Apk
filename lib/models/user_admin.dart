class UserAdmin {
  final String id;
  final String email;
  final String password;

  UserAdmin({
    required this.id,
    required this.email,
    required this.password,
  });

  factory UserAdmin.fromMap(String id, Map<String, dynamic> map) {
    return UserAdmin(
      id: id,
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }
} 