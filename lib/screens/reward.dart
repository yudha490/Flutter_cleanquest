import 'package:flutter/material.dart';
import 'home_page.dart'; // Pastikan HomeScreen diimport dengan benar
import 'profile.dart'; // Pastikan ProfileScreen diimport dengan benar
import 'cash_tab.dart';
import 'voucher_tab.dart';
import '../services/api_service.dart'; // Import ApiService
import '../models/user.dart'; // Import User model

class RewardScreen extends StatefulWidget {
  final int userId;

  RewardScreen({required this.userId});

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final TextEditingController _customAmountController = TextEditingController();
  int _currentIndex = 1; // Set the default selected index to 1 (Reward tab)
  late ApiService _apiService;
  int _userPoints = 0; // State untuk menyimpan poin pengguna

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    try {
      User user = await _apiService.getUserData(widget.userId);
      setState(() {
        _userPoints = user.points;
      });
    } catch (e) {
      print('Error fetching user points: $e');
      // Handle error, maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat poin pengguna: $e')),
      );
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(userId: widget.userId)),
          );
        } else if (index == 1) {
          // Stay on the current RewardScreen
          // No need to pushReplacement if already on the same screen
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Reward',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Background Image Layer
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Points Display at the Top
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL POIN',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '$_userPoints Poin', // Menampilkan poin dari state
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // TabBar and TabBarView
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              bottom: 0, // Disesuaikan agar tidak tumpang tindih dengan bottom nav bar
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: const Color.fromRGBO(85, 132, 122, 0.97),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Tukar Uang"),
                      Tab(text: "Tukar Voucher"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        CashTab(
                            customAmountController: _customAmountController,
                            userId: widget.userId, // Pass userId
                            onPointsUpdated: _fetchUserPoints, // Pass callback
                        ),
                        VoucherTab(
                            userId: widget.userId, // Pass userId
                            onPointsUpdated: _fetchUserPoints, // Pass callback
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }
}

