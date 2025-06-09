// Tubees_PPB/lib/screens/edit_profile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'package:cleanquest/screens/profile.dart'; // Pastikan path ini benar
import '../services/api_service.dart'; // Pastikan path ini benar
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final int? userId;

  const EditProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  User? user;
  late ApiService apiService;
  bool isLoading = true;
  int? _currentUserId;

  DateTime? _selectedBirthDate;

  static const Color _primaryGreen = Color.fromRGBO(85, 132, 122, 0.97);

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    if (widget.userId != null) {
      _currentUserId = widget.userId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('currentUserId');
      String? token = prefs.getString('authToken');
      if (token != null) {
        print('Stored Auth Token: $token');
      } else {
        print('No Auth Token found.');
      }
    }

    print('DEBUG_EDIT_PROFILE: _currentUserId in _initializeUserData: $_currentUserId');

    if (!mounted) return;

    if (_currentUserId != null) {
      fetchData(_currentUserId!);
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID pengguna tidak ditemukan. Harap login kembali.')),
        );
      }
    }
  }

  Future<void> fetchData(int userIdToFetch) async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedUser = await apiService.getUserData(userIdToFetch);
      if (!mounted) return;
      setState(() {
        user = fetchedUser;
        _selectedBirthDate = user!.birthDate;

        _nameController = TextEditingController(text: user!.username);
        _emailController = TextEditingController(text: user!.email);
        _phoneController = TextEditingController(text: user!.phoneNumber);
        _birthDateController = TextEditingController(
          text: _selectedBirthDate != null
              ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
              : 'Pilih Tanggal Lahir',
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      if (!mounted) return;
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        user!.birthDate = picked;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    print('DEBUG_EDIT_PROFILE: _currentUserId at start of _saveProfileChanges: $_currentUserId');

    if (user == null || _currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengguna tidak tersedia untuk disimpan.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    user!.username = _nameController.text;
    user!.email = _emailController.text;
    user!.phoneNumber = _phoneController.text;

    try {
      print('DEBUG_EDIT_PROFILE: Sending user data:');
      print('  Username: ${_nameController.text}');
      print('  Email: ${_emailController.text}');
      print('  Phone Number: ${_phoneController.text}');
      print('  Birth Date (DateTime obj): ${_selectedBirthDate?.toIso8601String()}');

      await apiService.updateUserData(
        username: user!.username,
        email: user!.email,
        phoneNumber: user!.phoneNumber,
        birthDate: user!.birthDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan!')),
      );

      // ADDED: Create a local variable to safely hold _currentUserId before navigation
      final int? userIdForNavigation = _currentUserId;
      print('DEBUG_EDIT_PROFILE: userIdForNavigation before navigation: $userIdForNavigation');

      // ADDED: Crucial check: Ensure userIdForNavigation is not null before navigating
      if (userIdForNavigation != null) {
        print('DEBUG_EDIT_PROFILE: Navigating with non-null userId: $userIdForNavigation'); // NEW DEBUG PRINT
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Pastikan ProfileScreen memang membutuhkan int non-nullable.
            // Jika ProfileScreen bisa menerima int?, Anda bisa hapus tanda '!'
            // Tapi berdasarkan error, sepertinya ProfileScreen butuh int.
            builder: (context) => ProfileScreen(userId: userIdForNavigation),
          ),
        );
      } else {
        print('DEBUG_EDIT_PROFILE: userIdForNavigation is null, showing error snackbar.'); // NEW DEBUG PRINT
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID pengguna tidak ditemukan setelah penyimpanan. Mohon login kembali.')),
        );
      }

    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryGreen,
          ),
        ),
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
            onPressed: _saveProfileChanges,
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

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
                    backgroundColor: Colors.black,
                  ),
                  const CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: _primaryGreen,
                      child: const Icon(Icons.camera_alt,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 350),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: _primaryGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              children: [
                _buildTextField(label: 'Nama', controller: _nameController),
                const SizedBox(height: 10),
                _buildTextField(label: 'Email', controller: _emailController),
                const SizedBox(height: 10),
                _buildTextField(label: 'No. Handphone', controller: _phoneController),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Lahir', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _birthDateController,
                          enabled: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Pilih Tanggal Lahir',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    required TextEditingController controller,
    String? hintText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}