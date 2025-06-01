import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Diperlukan untuk formatting tanggal Indonesia

// Import untuk layar-layar aplikasi
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() async {
  // Memastikan Flutter binding telah terinisialisasi sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data formatting untuk locale Indonesia ('id_ID')
  // Ini penting agar DateFormat dapat bekerja dengan benar untuk locale tersebut.
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Drying Rack',
      debugShowCheckedModeBanner: false, // Menyembunyikan banner debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Mengaktifkan Material 3 design
        // Pertimbangkan untuk menambahkan kustomisasi tema lebih lanjut di sini,
        // seperti fontFamily, appBarTheme, elevatedButtonTheme, dll.
        // Contoh:
        // appBarTheme: const AppBarTheme(
        //   elevation: 0, // AppBar yang lebih flat
        //   centerTitle: true,
        // ),
      ),
      initialRoute: '/', // Rute awal aplikasi
      routes: {
        // Definisi rute-rute aplikasi
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // Untuk proyek yang lebih besar, pertimbangkan menggunakan
        // static const String routeName pada setiap kelas layar
        // untuk menghindari string literal di sini.
        // Contoh: LoginScreen.routeName: (context) => const LoginScreen(),
      },
    );
  }
}