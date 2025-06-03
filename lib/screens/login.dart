import 'package:flutter/material.dart';
import 'package:cleanquest/screens/register.dart';
import 'home_page.dart';
import 'package:cleanquest/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  double scale = 1.0;
  double opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title
              Container(
                padding: const EdgeInsets.only(bottom: 60, top: 100),
                child: const Text(
                  'Clean Quest',
                  style: TextStyle(
                    fontSize: 45,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // Email Field
              _buildTextField(label: "Email", controller: emailController),

              const SizedBox(height: 10),

              // Password Field
              _buildTextField(
                label: "Password",
                isPassword: true,
                controller: passwordController,
              ),

              const SizedBox(height: 30),

              // Login Button
              _buildLoginButton(),

              const SizedBox(height: 250),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Belum memiliki akun? ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Daftar",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method for TextField
  Widget _buildTextField({
    required String label,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 15, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
        ),
        Container(
          height: 42,
          width: 350,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  // Login button with animation
  Widget _buildLoginButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.9;
          opacity = 0.7;
        });
      },
      onTapUp: (_) {
        setState(() {
          scale = 1.0;
          opacity = 1.0;
        });
        FocusScope.of(context).unfocus();
        _login();
      },
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Image.asset(
            'assets/images/button.png',
          ),
        ),
      ),
    );
  }

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password harus terdiri dari minimal 8 karakter')),
      );
      return;
    }

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success']) {
        print('Login berhasil: ${response['message']}');
        int userId = response['user_id'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
        );
      } else {
        // REVISI: Penanganan error yang lebih detail
        String errorMessage = 'Login gagal';
        if (response.containsKey('message')) { // Untuk pesan error generik dari ApiService
          errorMessage = response['message'].toString();
        } else if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
          final backendResponse = response['data'] as Map<String, dynamic>;
          if (backendResponse.containsKey('message')) {
            errorMessage = backendResponse['message'].toString();
          }
          if (backendResponse.containsKey('errors')) {
            final errors = backendResponse['errors'] as Map<String, dynamic>;
            errors.forEach((field, messages) {
              errorMessage += '\n${field.toUpperCase()}: ${(messages as List).join(', ')}';
            });
          }
        }

        print('Login gagal: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error selama login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Coba lagi nanti')),
      );
    }
  }
}

