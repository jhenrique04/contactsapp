import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../helpers/contact_helper.dart';
import 'contact_page.dart';
import 'settings_page.dart';

enum OrderOptions { aToZ, zToA }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ContactHelper helper = ContactHelper();

  List<Contact> _allContacts      = [];
  List<Contact> _visibleContacts  = [];
  List<Contact> _favoriteContacts = [];

  OrderOptions orderOptions = OrderOptions.aToZ;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  String _userName      = '';
  String _userPhotoPath = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadUserProfile();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName      = prefs.getString('username') ?? 'Usuário';
      _userPhotoPath = prefs.getString('userPhoto') ?? '';
    });
  }

  Future<void> _loadContacts() async {
    final list = await helper.getAllContacts(orderOptions);
    setState(() {
      _allContacts      = list.cast<Contact>();
      _applyFilter();
      _favoriteContacts =
          _allContacts.where((c) => c.isFavorite).toList();
    });
  }

  void _onSearchChanged() {
    setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    _applyFilter();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _visibleContacts = List.from(_allContacts);
    } else {
      _visibleContacts = _allContacts.where((c) {
        return c.name.toLowerCase().contains(_query) ||
               c.email.toLowerCase().contains(_query) ||
               c.phone.toLowerCase().contains(_query);
      }).toList();
    }
  }

  Map<String, List<Contact>> _groupByLetter(List<Contact> list) {
    final Map<String, List<Contact>> grouped = {};
    for (final c in list) {
      final letter = c.name.isNotEmpty ? c.name[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        toolbarHeight: 120,
        flexibleSpace: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE2DDFF),
                  backgroundImage: _userPhotoPath.isNotEmpty
                      ? FileImage(File(_userPhotoPath)) as ImageProvider
                      : const AssetImage('assets/avatar_placeholder.png'),
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
                      '${_allContacts.length} Contatos',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_favoriteContacts.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Favoritos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _favoriteContacts.length,
                itemBuilder: (context, i) {
                  final fav = _favoriteContacts[i];
                  final idx = _allContacts.indexWhere((c) => c.id == fav.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _showOptions(context, idx),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE2DDFF),
                        backgroundImage: fav.img.isNotEmpty
                            ? FileImage(File(fav.img))
                            : null,
                        child: fav.img.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _allContacts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Você ainda não possui nenhum contato cadastrado.\n\n'
                        'Clique no botão de adicionar (+) para criar um novo contato.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  )
                : _visibleContacts.isEmpty
                    ? const Center(
                        child: Text('Nenhum contato encontrado'),
                      )
                    : _buildAlphaList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactPage(contact: null),
        backgroundColor:
            const Color.fromARGB(255, 80, 29, 199),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlphaList() {
    final grouped = _groupByLetter(_visibleContacts);
    final letters = grouped.keys.toList()..sort();
    final total = letters.fold<int>(
      0,
      (sum, k) => sum + grouped[k]!.length + 1,
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: total,
      itemBuilder: (context, index) {
        int running = 0;
        for (final letter in letters) {
          if (index == running) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
              child: Text(
                letter,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            );
          }
          running++;
          final group = grouped[letter]!;
          if (index < running + group.length) {
            final item = group[index - running];
            final showDivider =
                (index - running) != group.length - 1;
            return _contactTile(item, showDivider);
          }
          running += group.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _contactTile(Contact item, bool showDivider) {
    final idx = _allContacts.indexWhere((c) => c.id == item.id);
    return GestureDetector(
      onTap: () => _showOptions(context, idx),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE2DDFF),
                  backgroundImage: item.img.isNotEmpty
                      ? FileImage(File(item.img))
                      : null,
                  child: item.img.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.black,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w600)),
                      Text(item.email,
                          style: GoogleFonts.poppins(
                              fontSize: 14)),
                      Text(item.phone,
                          style: GoogleFonts.poppins(
                              fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert,
                    color: Colors.black),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 0,
            ),
        ],
      ),
    );
  }

  Future<void> _showOptions(BuildContext context, int index) async {
    final contact = _allContacts[index];
    showModalBottomSheet(
      context: context,
      builder: (_) => BottomSheet(
        onClosing: () {},
        builder: (_) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              if (contact.phone.isNotEmpty)
                TextButton(
                  onPressed: () {
                    launchUrlString('tel:${contact.phone}');
                    Navigator.pop(context);
                  },
                  child: Text('Ligar',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Color.fromARGB(255, 80, 29, 199))),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showContactPage(contact: contact);
                },
                child: Text('Ver Detalhes',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  helper.deleteContact(contact.id!);
                  _loadContacts();
                  Navigator.pop(context);
                },
                child: Text('Deletar',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.red)),
              ),
              const Divider(),
              TextButton(
                onPressed: () async {
                  contact.isFavorite =
                      !contact.isFavorite;
                  await helper.updateOrCreateContact(
                      contact);
                  await _loadContacts();
                  Navigator.pop(context);
                },
                child: Text(
                  contact.isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Color.fromARGB(255, 80, 29, 199)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const SettingsPage()),
    );
    await _loadUserProfile();
  }

  Future<void> _showContactPage({ Contact? contact }) async {
    await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
          builder: (_) => ContactPage(contact: contact)),
    );
    // sempre recarrega ao voltar
    await _loadContacts();
  }
}
