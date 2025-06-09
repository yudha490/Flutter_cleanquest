import 'package:cleanquest/screens/riwayat_misi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'edit_profile.dart'; // Pastikan path ini benar
import 'home_page.dart';   // Pastikan path ini benar
import 'reward.dart';      // Pastikan path ini benar
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/user_mission.dart'; // Pastikan model ini ada
import 'package:shared_preferences/shared_preferences.dart';
import 'section.dart'; // Pastikan path ini benar

class ProfileScreen extends StatefulWidget {
  final int userId; // userId ini mungkin tidak digunakan langsung untuk fetching di ApiService

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user; // Mengubah menjadi nullable
  late ApiService apiService;
  List<UserMission> activeUserMissions = []; // Menyimpan UserMission yang aktif
  int completedMissionsCount = 0;
  int totalMissionsCount = 0;
  bool isLoading = true;
  bool hasError = false; // Menandakan apakah terjadi error saat fetching data

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    fetchData(); // Panggil fungsi untuk mengambil data profil
    _getTokenAndPrint(); // Untuk debugging token
  }

  Future<void> _getTokenAndPrint() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token != null) {
      print('Stored Auth Token: $token');
    } else {
      print('No Auth Token found.');
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      hasError = false; // Reset status error sebelum fetch data baru
    });
    try {
      // PENTING: Mengambil data user yang sedang login menggunakan token
      // API service getUserData sekarang dirancang untuk mengambil user dari token,
      // sehingga parameter userId di sini bisa diabaikan atau diisi null.
      final fetchedUser = await apiService.getUserData(widget.userId); // <--- Ini yang mengambil data user

      // Jika fetchedUser bisa null (misal jika token expired atau tidak ada user), tangani.
      if (fetchedUser == null) {
        throw Exception("Data pengguna tidak dapat dimuat (token mungkin tidak valid atau user tidak ditemukan).");
      }

      print('DEBUG_PROFILE_SCREEN: User data fetched successfully. User ID: ${fetchedUser.id}');

      // Mengambil misi aktif untuk user ini
      final fetchedActiveUserMissions = await apiService.getMissions();
      // Hitung jumlah total misi dan misi yang sudah diselesaikan
      final completed = fetchedActiveUserMissions
          .where((um) => um.status == 'selesai')
          .length;

      setState(() {
        user = fetchedUser; // Isi objek user dengan data yang berhasil diambil
        activeUserMissions = fetchedActiveUserMissions;
        totalMissionsCount = activeUserMissions.length;
        completedMissionsCount = completed;
        isLoading = false;
        hasError = false; // Pastikan ini false jika fetch sukses
      });
    } catch (e) {
      print('ERROR_PROFILE_SCREEN: Error fetching data: $e'); // Log error yang lebih jelas
      setState(() {
        isLoading = false;
        hasError = true; // Set hasError menjadi true jika ada error
        user = null; // Pastikan objek user null jika terjadi error
        // Juga set count ke 0 jika error
        completedMissionsCount = 0;
        totalMissionsCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data profil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilkan layar loading penuh
    if (isLoading) {
      print('DEBUG_PROFILE_SCREEN: Building: Loading screen.');
      return Container(
        color: Colors.white, // Menutupi seluruh layar saat loading
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Tampilkan layar error jika ada kesalahan atau user null setelah loading
    if (hasError || user == null) {
      print('DEBUG_PROFILE_SCREEN: Building: Error or user is null. Displaying error UI.');
      return Scaffold(
        backgroundColor: const Color.fromARGB(235, 255, 255, 255),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              const Text('Gagal memuat profil.', style: TextStyle(color: Colors.red, fontSize: 18)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: fetchData, // Tombol coba lagi
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await apiService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SectionPage()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(), // Navigasi bawah tetap ada
      );
    }

    // 3. Jika tidak loading dan tidak ada error (user pasti tidak null), tampilkan konten utama
    print('DEBUG_PROFILE_SCREEN: Building: User data available for rendering.');
    print('DEBUG_PROFILE_SCREEN: User ID for display: ${user!.id}');
    print('DEBUG_PROFILE_SCREEN: User Username for display: ${user!.username}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(235, 255, 255, 255),
      body: Stack(
        children: [
          // Layer 1: Gambar latar belakang
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Layer 2: Konten utama aplikasi
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 1),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0, top: 10.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(userId: widget.userId), // <--- Tidak perlu userId di sini
                            ),
                          ).then((_) => fetchData()); // Refresh data setelah kembali
                        },
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Color.fromRGBO(85, 132, 122, 0.969), fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE0DDFB),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user!.username, // user dipastikan tidak null di sini
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressIndicator(),
                      _buildPointsIndicator(), // Memanggil widget pembantu yang sekarang tangguh
                    ],
                  ),
                  const SizedBox(height: 60),
                  Card(
                    color: const Color.fromARGB(255, 244, 244, 244),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(icon: Icons.assignment, title: 'Riwayat Misi', onTap: () { 
                          print('Navigasi ke Riwayat Misi'); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RiwayatMisiScreen(userId: widget.userId),
                            ),
                          );
                          }
                        ),
                        _buildListTile(icon: Icons.help_outline, title: 'Pusat Bantuan', onTap: () { print('Navigasi ke Pusat Bantuan'); }),
                        _buildListTile(icon: Icons.description_outlined, title: 'Syarat dan Ketentuan', onTap: () { print('Navigasi ke Syarat dan Ketentuan'); }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() { isLoading = true; });
                      final success = await apiService.logout();
                      setState(() { isLoading = false; });
                      if (success) {
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SectionPage()), (route) => false);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout gagal. Coba lagi.'),));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                      backgroundColor: const Color.fromRGBO(85, 132, 122, 0.97),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Log Out', style: TextStyle(color: Colors.white),),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Navigasi bawah selalu terlihat
    );
  }

  // --- Widget Pembantu ---

  Widget _buildListTile({required IconData icon, required String title, VoidCallback? onTap,}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 26),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),)),
            const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment, color: Colors.teal),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completedMissionsCount/$totalMissionsCount Misi',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Telah Dikerjakan', style: TextStyle(color: Colors.teal, fontSize: 12),),
            ],
          ),
        ],
      ),
    );
  }

  // KEMBALI KE _buildPointsIndicator()
  Widget _buildPointsIndicator() {
    // Tambahkan pengecekan null di sini secara eksplisit
    if (user == null) {
      print('DEBUG_PROFILE_SCREEN: _buildPointsIndicator: user is null, showing 0 points.');
      return Container( // Mengembalikan container default jika user null
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              '0 Poin', // Default 0 poin jika user null
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    // Jika user tidak null, tampilkan poinnya
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            '${user!.points} Poin', // user! aman di sini karena sudah dicek di atas
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // KEMBALI KE _buildBottomNavBar()
  Widget _buildBottomNavBar() {
    // Tambahkan pengecekan null di sini secara eksplisit
    if (user == null) {
      print('DEBUG_PROFILE_SCREEN: _buildBottomNavBar: user is null, using default ID 0.');
      return Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: 2,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey[600],
            onTap: (index) {
              // Jika user null, default ke ID 0 untuk navigasi
              int userIdToUse = 0; // Default ID jika user null
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(userId: userIdToUse)),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RewardScreen(userId: userIdToUse)),
                );
              } else if (index == 2) { /* stay on profile */ }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Reward',),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      );
    }

    // Jika user tidak null, tampilkan navbar seperti biasa
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: 2, // Ini adalah index untuk ProfileScreen
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen(userId: user!.id)), // user! aman di sini
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => RewardScreen(userId: user!.id)), // user! aman di sini
              );
            } else if (index == 2) { /* stay on profile */ }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Reward',),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}