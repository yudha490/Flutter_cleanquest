import 'package:flutter/material.dart';
import 'package:cleanquest/screens/profile.dart';

class EditProfileScreen extends StatelessWidget {
  final int userId;

  const EditProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: 'Bambang Pamungkas');
    final TextEditingController emailController =
        TextEditingController(text: 'Bambang_p@gmail.com');
    final TextEditingController phoneController =
        TextEditingController(text: '081234123412');

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileScreen(userId: 12345)),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ➤ Gambar background
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // ➤ Avatar profile
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
                      backgroundColor: const Color.fromRGBO(85, 132, 122, 0.97),
                      child: const Icon(Icons.camera_alt,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ➤ Form
          Container(
            margin: const EdgeInsets.only(top: 350), // ➤ Digeser lebih ke bawah
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: const Color.fromRGBO(85, 132, 122, 0.97),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              children: [
                _buildTextField(label: 'Nama', controller: nameController),
                const SizedBox(height: 10),
                _buildTextField(label: 'Email', controller: emailController),
                const SizedBox(height: 10),
                _buildTextField(
                    label: 'No. Handphone', controller: phoneController),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Tanggal Lahir',
                  hintText: 'Tidak bisa diubah',
                  enabled: false,
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
