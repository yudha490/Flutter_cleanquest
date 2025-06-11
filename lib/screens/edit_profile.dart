import 'package:flutter/material.dart';
import 'package:cleanquest/services/api_service.dart'; // Import ApiService
import 'package:cleanquest/models/user.dart'; // Import User model
import 'package:intl/intl.dart'; // For date formatting

class EditProfileScreen extends StatefulWidget {
  final int userId; // Menerima userId dari ProfileScreen

  const EditProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late ApiService _apiService;
  User? _currentUser;
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _apiService.getUserData(widget.userId);
      if (mounted) {
        setState(() {
          _currentUser = user!;
          _usernameController.text = user.username;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber;
          _birthDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(user.birthDate);
          _selectedDate = user.birthDate; // Set initial selected date
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentUser = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil pengguna: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return; // Add mounted check before async operations

    // Basic frontend validation
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi!')));
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dataToUpdate = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'birth_date': _birthDateController.text,
      };

      if (_passwordController.text.isNotEmpty) {
        dataToUpdate['password'] = _passwordController.text;
        dataToUpdate['password_confirmation'] = _confirmPasswordController.text;
      }

      final response = await _apiService.updateUserProfile(dataToUpdate);

      if (!mounted) return; // Add mounted check after async operations

      if (response['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
        Navigator.pop(
          context,
          true,
        ); // Pop with true to indicate success for refresh
      } else {
        String errorMessage = 'Gagal memperbarui profil.';
        if (response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          final backendResponse = response['data'] as Map<String, dynamic>;
          if (backendResponse.containsKey('message')) {
            errorMessage = backendResponse['message'].toString();
          }
          if (backendResponse.containsKey('errors')) {
            final errors = backendResponse['errors'] as Map<String, dynamic>;
            errors.forEach((field, messages) {
              errorMessage +=
                  '\n${field.toUpperCase()}: ${(messages as List).join(', ')}';
            });
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(235, 255, 255, 255),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(235, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile, // Panggil _saveProfile
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gambar background
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Avatar profile
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE0DDFB),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        print("ara bau eek");
                      },
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color.fromRGBO(
                          85,
                          132,
                          122,
                          0.97,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          Container(
            margin: const EdgeInsets.only(top: 350),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(85, 132, 122, 0.97),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              children: [
                _buildTextField(label: 'Nama', controller: _usernameController),
                const SizedBox(height: 10),
                _buildTextField(label: 'Email', controller: _emailController),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'No. Handphone',
                  controller: _phoneController,
                ),
                const SizedBox(height: 10),
                _buildDateField(
                  context,
                  label: 'Tanggal Lahir',
                  controller: _birthDateController,
                ), // REVISI: Gunakan _buildDateField
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Password Baru (opsional)',
                  controller: _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Konfirmasi Password Baru',
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    bool enabled = true,
    bool isPassword = false, // Tambahkan parameter isPassword
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword, // Gunakan isPassword
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // Widget untuk input tanggal lahir
  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: true, // Membuat field tidak bisa diketik manual
          onTap: () =>
              _selectDate(context), // Memanggil date picker saat ditekan
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.calendar_today), // Icon kalender
          ),
        ),
      ],
    );
  }
}
