import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/register_page.dart';
import 'ui/login_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialPage;

  Future<Widget> _chooseStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('password');
    return (saved == null || saved.isEmpty)
      ? const RegisterPage()
      : const LoginPage();
  }

  @override
  void initState() {
    super.initState();
    _initialPage = _chooseStartPage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialPage,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // --- Tema claro ---
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF501DC7),
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF501DC7),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.light().textTheme,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF501DC7),
              centerTitle: true,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF501DC7),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // --- Tema escuro ---
          darkTheme: ThemeData.dark().copyWith(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF501DC7),
            scaffoldBackgroundColor: Colors.grey[900],
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF501DC7),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[850],
              centerTitle: true,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF501DC7),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),

          // Segue o modo do sistema Android/iOS
          themeMode: ThemeMode.system,

          home: snap.data,
        );
      },
    );
  }
}
