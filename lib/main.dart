import 'package:flutter/material.dart';
import 'screens/splash.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding sudah diinisialisasi
  await initializeDateFormatting('id_ID', null); // Inisialisasi data locale untuk Bahasa Indonesia
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
    );
  }
}
