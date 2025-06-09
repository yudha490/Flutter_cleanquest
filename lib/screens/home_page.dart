import 'package:cleanquest/screens/profile.dart';
import 'package:cleanquest/screens/reward.dart';
import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../models/user.dart';
import '../models/user_mission.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  late ApiService apiService;
  List<UserMission> activeUserMissions = [];
  int completedMissionsCount = 0;
  int totalMissionsCount = 0;
  bool isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      _errorMessage = '';
      user = null;
    });
    try {
      final fetchedUser = await apiService.getUserData(widget.userId);
      final fetchedActiveUserMissions = await apiService.getMissions();

      // REVISI: Hitung misi yang statusnya 'selesai'
      final completed = fetchedActiveUserMissions.where((um) => um.status == 'selesai').length;

      setState(() {
        user = fetchedUser;
        activeUserMissions = fetchedActiveUserMissions;
        totalMissionsCount = activeUserMissions.length;
        completedMissionsCount = completed;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
        user = null;
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    }
  }

  void _showSubmitDialog(BuildContext context, UserMission userMission) {
    final TextEditingController _linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim Bukti Misi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan link video bukti pengerjaan misi:'),
            const SizedBox(height: 10),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                hintText: 'Contoh: http://youtube.com/link-video-anda',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              final String proofUrl = _linkController.text.trim();

              if (proofUrl.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link bukti tidak boleh kosong!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              try {
                bool success = await apiService.submitMissionProof(
                  userMissionId: userMission.id,
                  proofUrl: proofUrl,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bukti misi berhasil disubmit! Status: Pending.'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Color.fromRGBO(76, 175, 80, 1),
                    ),
                  );
                  fetchData(); // Refresh data setelah submit
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengirim bukti misi. Coba lagi!'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('Error submitting proof: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : user == null
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/background.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 66),
                                Text(
                                  'Halo ${user!.username}!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildUserStats(),
                                const SizedBox(height: 32),
                                const Text(
                                  'Misi Hari Ini',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMissionList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildUserStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIndicator(),
        const SizedBox(width: 16),
        _buildPointsIndicator(),
      ],
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
              const Text(
                'Telah Dikerjakan',
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            '${user?.points ?? 0} Poin',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    if (activeUserMissions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada misi aktif hari ini.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeUserMissions.length,
      itemBuilder: (context, index) {
        final userMission = activeUserMissions[index];
        final mission = userMission.mission;

        if (mission == null) {
          return const SizedBox.shrink();
        }

        return _buildMissionCard(mission, userMission);
      },
    );
  }

  Widget _buildMissionCard(Mission mission, UserMission userMission) {
    // Tentukan warna dan teks badge berdasarkan status
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (userMission.status) {
      case 'selesai':
        badgeColor = Colors.green;
        badgeText = 'Selesai';
        badgeIcon = Icons.check;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'Pending';
        badgeIcon = Icons. hourglass_empty; // Atau icon lain yang sesuai
        break;
      case 'belum dikerjakan':
      default:
        badgeColor = Colors.grey;
        badgeText = 'Belum Dikerjakan';
        badgeIcon = Icons.circle_outlined;
        break;
    }

    return GestureDetector(
      onTap: () {
        // REVISI: Hanya izinkan submit jika statusnya 'belum dikerjakan'
        if (userMission.status == 'belum dikerjakan') {
          _showSubmitDialog(context, userMission);
        } else if (userMission.status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misi ini sedang dalam peninjauan (Pending).'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        } else if (userMission.status == 'selesai') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misi ini sudah selesai!'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: Image.network(
                      mission.imageUrl ?? 'https://placehold.co/600x400/cccccc/333333?text=No+Image',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                // REVISI: Tampilkan badge status berdasarkan nilai 'status'
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(badgeIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.points}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) {
          // Stay on Home screen
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RewardScreen(userId: user!.id)),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(userId: user!.id)),
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
}

