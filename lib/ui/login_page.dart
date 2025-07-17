import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Perfil do usuário
  String _userName = '';
  String? _userPhotoPath;
  final _picker = ImagePicker();

  // Formulário
  final _formKey  = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  bool _obscure   = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName      = prefs.getString('username') ?? 'Usuário';
      _userPhotoPath = prefs.getString('userPhoto');
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('password') ?? '';

    if (_passCtrl.text == saved) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha incorreta')),
      );
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto do usuário
              GestureDetector(
                onTap: () async {
                  final file = await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('userPhoto', file.path);
                    setState(() => _userPhotoPath = file.path);
                  }
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: surface,
                  backgroundImage: _userPhotoPath != null
                      ? FileImage(File(_userPhotoPath!))
                      : null,
                  child: _userPhotoPath == null
                      ? Icon(Icons.person, size: 60, color: theme.iconTheme.color)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                'Bem-vindo, $_userName',
                style: theme.textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              // Formulário de senha
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Digite a senha' : null,
                ),
              ),
              const SizedBox(height: 32),
              // Botão Entrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Entrar',
                    style: theme.textTheme.titleMedium!
                        .copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
