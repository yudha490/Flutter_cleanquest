import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'package:cleanquest/screens/profile.dart'; // Pastikan path ini benar
import '../services/api_service.dart'; // Pastikan path ini benar
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  // userId bisa diberikan, atau akan diambil dari SharedPreferences
  final int? userId; // Kini nullable, karena mungkin tidak diberikan dari luar

  const EditProfileScreen({Key? key, this.userId}) : super(key: key); // Ubah menjadi this.userId

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  User? user;
  late ApiService apiService;
  bool isLoading = true;
  int? _currentUserId; // Untuk menyimpan ID user yang sebenarnya akan diedit

  DateTime? _selectedBirthDate;

  static const Color _primaryGreen = Color.fromRGBO(85, 132, 122, 0.97);

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController; // Untuk tampilan tanggal lahir

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _initializeUserData(); // Panggil fungsi inisialisasi data user
  }

  // Fungsi untuk menginisialisasi data user (ambil ID & fetch data)
  Future<void> _initializeUserData() async {
    // Jika userId diberikan melalui constructor, gunakan itu
    if (widget.userId != null) {
      _currentUserId = widget.userId;
    } else {
      // Jika tidak, coba ambil dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('currentUserId'); // Pastikan kamu menyimpan ini saat login
      String? token = prefs.getString('authToken'); // Untuk debugging
      if (token != null) {
        print('Stored Auth Token: $token');
      } else {
        print('No Auth Token found.');
      }
    }

    print('DEBUG_EDIT_PROFILE: _currentUserId in _initializeUserData: $_currentUserId');

    if (_currentUserId != null) {
      fetchData(_currentUserId!);
    } else {
      // Handle case where no userId is available (e.g., not logged in)
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna tidak ditemukan. Harap login kembali.')),
      );
      // Mungkin arahkan ke halaman login
      // Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Fungsi untuk mengambil data user dari API (memerlukan userId)
  Future<void> fetchData(int userIdToFetch) async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedUser = await apiService.getUserData(userIdToFetch);
      setState(() {
        user = fetchedUser;
        _selectedBirthDate = user!.birthDate;

        // Inisialisasi controllers dengan data user
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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  // Fungsi untuk menampilkan DatePicker dan memilih tanggal
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
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked); // Update text field
        user!.birthDate = picked; // Update di objek user
      });
    }
  }

  // Fungsi untuk menyimpan perubahan data user
  Future<void> _saveProfileChanges() async {
    print('DEBUG_EDIT_PROFILE: _currentUserId at start of _saveProfileChanges: $_currentUserId');

    if (user == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengguna tidak tersedia untuk disimpan.')),
      );
      return;
    }

    setState(() {
      isLoading = true; // Tampilkan loading saat menyimpan
    });

    // Update objek user dengan data dari controllers
    user!.username = _nameController.text;
    user!.email = _emailController.text;
    user!.phoneNumber = _phoneController.text;
    // _selectedBirthDate sudah diupdate saat date picker dipilih

    try {

       // --- DEBUGGING DATA YANG DIKIRIM ---
      print('DEBUG_EDIT_PROFILE: Sending user data:');
      print('  Username: ${_nameController.text}');
      print('  Email: ${_emailController.text}');
      print('  Phone Number: ${_phoneController.text}');
      print('  Birth Date (DateTime obj): ${_selectedBirthDate?.toIso8601String()}'); // Format ISO 8601 untuk cek
      // --- AKHIR DEBUGGING ---
      // Panggil API service untuk update data user
      await apiService.updateUserData(
        username: user!.username,
        email: user!.email,
        phoneNumber: user!.phoneNumber,
        birthDate: user!.birthDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan!')),
      );

      // --- DEBUGGING _currentUserId ---
      print('DEBUG_EDIT_PROFILE: _currentUserId before navigation: $_currentUserId');
      // --- AKHIR DEBUGGING ---

      // Setelah berhasil disimpan, kembali ke ProfileScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: _currentUserId!),
        ),
      );
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    }
  }

  @override
  void dispose() {
    // Pastikan untuk membuang controllers saat widget di-dispose
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan CircularProgressIndicator jika data masih loading atau user null
    if (isLoading || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryGreen,
          ),
        ),
      );
    }

    // Menggunakan controllers yang sudah diinisialisasi di fetchData
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
            onPressed: _saveProfileChanges, // Panggil fungsi save perubahan
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

          // Avatar profile dengan ikon kamera
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
                    // Tambahkan NetworkImage jika ada URL profil picture di user model
                    // backgroundImage: user?.profilePictureUrl != null
                    //     ? NetworkImage(user!.profilePictureUrl!)
                    //     : null,
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

          // Bagian Form (input data)
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
                // Field untuk Tanggal Lahir dengan DatePicker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Lahir', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _birthDateController, // Gunakan controller khusus tanggal
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

  // Widget pembantu untuk membuat TextField
  Widget _buildTextField({
    required String label,
    required TextEditingController controller, // Ubah ke required
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