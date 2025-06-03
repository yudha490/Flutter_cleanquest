import 'package:flutter/material.dart';
import 'package:cleanquest/services/api_service.dart';
import 'package:cleanquest/models/user.dart'; // Import User model

class CashTab extends StatefulWidget {
  final TextEditingController customAmountController;
  final int userId; // Tambahkan userId
  final VoidCallback onPointsUpdated; // Callback untuk update poin di parent

  CashTab({
    required this.customAmountController,
    required this.userId,
    required this.onPointsUpdated,
  });

  @override
  _CashTabState createState() => _CashTabState();
}

class _CashTabState extends State<CashTab> {
  String? selectedPaymentMethod;
  String? _selectedNominal;
  int _requiredPoints = 0;
  late ApiService _apiService;
  int _currentUserPoints = 0; // Poin pengguna saat ini

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchCurrentUserPoints();
  }

  Future<void> _fetchCurrentUserPoints() async {
    try {
      User user = await _apiService.getUserData(widget.userId);
      setState(() {
        _currentUserPoints = user.points;
      });
    } catch (e) {
      print('Error fetching current user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xEDEDED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentOption('assets/images/gopay.png', 'GoPay'),
            const SizedBox(height: 20),
            const Text(
              'Nominal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNominalOptions(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(
              thickness: 1,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Penukaran',
                        style: TextStyle(fontSize: 16),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '$_requiredPoints',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_validateInputs(context)) {
                            showRewardDialog(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(85, 132, 122, 0.969),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child: const Text(
                          'Tukar',
                          style: TextStyle(color: Colors.white),
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

  bool _validateInputs(BuildContext context) {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tolong pilih metode pembayaran!')),
      );
      return false;
    }

    if (_selectedNominal == null && widget.customAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tolong pilih nominal atau masukkan nominal custom!')),
      );
      return false;
    }

    int? nominalAmount = int.tryParse(widget.customAmountController.text.replaceAll(RegExp(r'\D'), ''));
    if (nominalAmount == null || nominalAmount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal minimal Rp 5.000 untuk penukaran!')),
      );
      return false;
    }

    // Perhitungan poin yang dibutuhkan
    int calculatedRequiredPoints = nominalAmount ~/ 10; // 100 poin per 1000 IDR (1 poin = 10 IDR)

    if (_currentUserPoints < calculatedRequiredPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin Anda tidak mencukupi!')),
      );
      return false;
    }

    return true;
  }

  void showRewardDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    // Ambil email dari data user yang terautentikasi
    String userEmail = '';
    _apiService.getUserData(widget.userId).then((user) {
      userEmail = user.email;
      phoneController.text = user.phoneNumber; // Isi nomor telepon dari data user
    }).catchError((e) {
      print('Error getting user email: $e');
    });


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Masukkan Informasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                String phone = phoneController.text.trim();
                int? balance = int.tryParse(widget.customAmountController.text.replaceAll(RegExp(r'\D'), ''));

                if (phone.isNotEmpty && balance != null && balance >= 5000) {
                  bool success = await _apiService.submitReward(
                    phone: phone,
                    email: userEmail,
                    balance: balance,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Berhasil menyimpan data!' : 'Gagal menyimpan data!'),
                    ),
                  );
                  if (success) {
                    Navigator.pop(context);
                    widget.onPointsUpdated(); // Panggil callback untuk update poin di RewardScreen
                    _fetchCurrentUserPoints(); // Refresh poin di CashTab
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pastikan semua informasi valid dan nominal minimal Rp 5000'),
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption(String assetPath, String title) {
    bool isSelected = selectedPaymentMethod == title;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = isSelected ? null : title;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromRGBO(85, 132, 122, 0.969)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color.fromRGBO(85, 132, 122, 0.969)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Image.asset(assetPath, width: 40),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNominalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            children: [
              _buildNominalButton('Rp 5.000', 500), // Poin yang dibutuhkan
              _buildNominalButton('Rp 10.000', 1000),
              _buildNominalButton('Rp 30.000', 3000),
              _buildNominalButton('Rp 50.000', 5000),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.customAmountController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _selectedNominal = null; // Hapus pilihan nominal button
              if (value.isNotEmpty) {
                int? nominal = int.tryParse(value.replaceAll(RegExp(r'\D'), '')); // Hapus non-digit
                if (nominal != null && nominal >= 5000) {
                  _requiredPoints = nominal ~/ 10; // 100 poin per 1000 IDR
                } else {
                  _requiredPoints = 0;
                }
              } else {
                _requiredPoints = 0;
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'Masukkan nominal lain',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Minimal Rp 5.000 untuk penukaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color.fromARGB(255, 84, 84, 84),
          ),
        ),
      ],
    );
  }

  Widget _buildNominalButton(String text, int points) {
    bool isSelected = _selectedNominal == text;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedNominal = null;
            widget.customAmountController.clear();
            _requiredPoints = 0;
          } else {
            _selectedNominal = text;
            widget.customAmountController.text = text.replaceAll(RegExp(r'\D'), ''); // Hanya angka
            _requiredPoints = points;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromRGBO(85, 132, 122, 0.969)
            : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.grey.shade300),
        elevation: 2,
      ),
      child: Text(text),
    );
  }
}

