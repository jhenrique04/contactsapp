// lib/ui/settings_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _picker      = ImagePicker();

  bool _obscure       = true;
  bool _loading       = true;
  String _savedPassword = '';
  String? _photoPath;
  String _userName     = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPassword  = prefs.getString('password')  ?? '';
    _userName       = prefs.getString('username')  ?? '';
    _nameCtrl.text  = _userName;
    _photoPath      = prefs.getString('userPhoto');
    setState(() => _loading = false);
  }

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
    await prefs.setString(
      'password',
      _newCtrl.text.isEmpty ? _savedPassword : _newCtrl.text,
    );
    if (_photoPath != null) {
      await prefs.setString('userPhoto', _photoPath!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados atualizados!')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 120,
        flexibleSpace: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _photoPath != null
                        ? FileImage(File(_photoPath!))
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: _photoPath == null
                        ? const Icon(Icons.add_a_photo, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configurações',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Nome
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                style: GoogleFonts.poppins(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null,
              ),
              const SizedBox(height: 24),

              // Senha atual
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                style: GoogleFonts.poppins(),
                validator: (v) {
                  if (v == null || v != _savedPassword) {
                    return 'Senha atual incorreta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Nova senha
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Nova senha (opcional)',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                style: GoogleFonts.poppins(),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 4) {
                    return 'Mínimo 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Confirmar nova senha
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                style: GoogleFonts.poppins(),
                validator: (v) {
                  if (_newCtrl.text.isNotEmpty && v != _newCtrl.text) {
                    return 'Senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Licenças
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text('Licenças', style: GoogleFonts.poppins()),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Meus Contatos',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
