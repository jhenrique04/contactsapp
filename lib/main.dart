// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/register_page.dart';
import 'ui/login_page.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

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
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Tela de loading enquanto decide qual página mostrar
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Se algo deu errado, exibimos um placeholder de erro
        final startPage = snapshot.data ??
            const Scaffold(
              body: Center(child: Text('Erro ao carregar a página inicial')),
            );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.poppinsTextTheme(),
            primaryColor: const Color(0xFFE2DDFF),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: const Color(0xFFE2DDFF),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                overlayColor:
                    MaterialStateProperty.all(const Color(0x22000000)),
              ),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          home: startPage,
          routes: {
            '/register': (_) => const RegisterPage(),
            '/login': (_)    => const LoginPage(),
            '/home': (_)     => const HomePage(),
          },
        );
      },
    );
  }
}
