import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class UserAuthPage extends StatefulWidget {
  const UserAuthPage({Key? key}) : super(key: key);

  @override
  State<UserAuthPage> createState() => _UserAuthPageState();
}

class _UserAuthPageState extends State<UserAuthPage> {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FirebaseService firebaseService = FirebaseService();
  bool isLoading = false;

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    try {
      final user = await firebaseService.loginUser(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (user != null) {
        // Navigate to home or dashboard
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau password salah!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleSignUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      await firebaseService.registerUser(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan masuk.')),
      );
      setState(() {
        isLogin = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(24),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: 200),
                  const SizedBox(height: 8),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLogin ? null : toggleMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLogin ? Colors.blue[800] : Colors.blue[100],
                            foregroundColor: isLogin ? Colors.white : Colors.blue[800],
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text('Masuk'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLogin ? toggleMode : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLogin ? Colors.blue[100] : Colors.blue[800],
                            foregroundColor: isLogin ? Colors.blue[800] : Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text('Daftar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan Nama Pengguna',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      border: const UnderlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      ),
                    ),
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : isLogin
                              ? handleLogin
                              : handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isLogin ? 'Masuk' : 'Daftar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? 'Apakah belum punya akun? ' : 'Apakah sudah punya akun? '),
                      GestureDetector(
                        onTap: toggleMode,
                        child: Text(
                          isLogin ? 'Daftar' : 'Masuk',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 