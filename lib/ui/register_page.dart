import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _pass1Ctrl  = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  final _picker     = ImagePicker();

  bool _obscure     = true;
  String? _photoPath;

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _photoPath = file.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _nameCtrl.text.trim());
    await prefs.setString('password', _pass1Ctrl.text);
    if (_photoPath != null) {
      await prefs.setString('userPhoto', _photoPath!);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
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
              // Avatar / Foto do usuário
              GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: surface,
                  backgroundImage:
                      _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? Icon(Icons.add_a_photo, size: 60, color: theme.iconTheme.color)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                'Cadastro',
                style: theme.textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie sua conta',
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              // Formulário
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nome
                    TextFormField(
                      controller: _nameCtrl,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Seu nome',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null,
                    ),
                    const SizedBox(height: 24),
                    // Senha
                    TextFormField(
                      controller: _pass1Ctrl,
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Digite a senha';
                        if (v.length < 4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Confirmar senha
                    TextFormField(
                      controller: _pass2Ctrl,
                      obscureText: _obscure,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirme a senha';
                        if (v != _pass1Ctrl.text) return 'Senhas não coincidem';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Salvar',
                          style: theme.textTheme.titleMedium!
                              .copyWith(color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
