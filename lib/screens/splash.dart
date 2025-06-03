import 'package:flutter/material.dart';
import 'package:cleanquest/screens/section.dart';// Ganti ini dengan file halaman utama Anda

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay untuk splash screen
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SectionPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ubah warna latar belakang sesuai kebutuhan
      body: Container(
        width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/suBackground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
                padding: const EdgeInsets.only(bottom: 60, top: 100),
                child: const Text(
                  'Clean Quest',
                  style: TextStyle(
                    fontSize: 45,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(85, 132, 122, 100),
                  ),
                ),
              ),// Menampilkan indikator pemuatan
          ],
        ),
      ),
    );
  }
}
