import 'dart:io';
import 'package:flutter/material.dart';
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
  // cores fixas
  static const Color _avatarPlaceholderBg = Color(0xFFE2DDFF);
  static const Color _avatarPlaceholderIcon = Color(0xFF616161);

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
      _favoriteContacts = _allContacts.where((c) => c.isFavorite).toList();
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
    final grouped = <String, List<Contact>>{};
    for (final c in list) {
      final letter = c.name.isNotEmpty ? c.name[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _avatarPlaceholderBg,
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
                      style: theme.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_allContacts.length} Contatos',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.settings, color: theme.iconTheme.color),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Favoritos',
                style: theme.textTheme.titleSmall!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        backgroundColor: _avatarPlaceholderBg,
                        backgroundImage:
                            fav.img.isNotEmpty ? FileImage(File(fav.img)) : null,
                        child: fav.img.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 28,
                                color: _avatarPlaceholderIcon,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
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
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : _visibleContacts.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum contato encontrado',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : _buildAlphaList(theme),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactPage(contact: null),
        backgroundColor: _avatarPlaceholderBg,
        child: const Icon(Icons.add, color: _avatarPlaceholderIcon),
      ),
    );
  }

  Widget _buildAlphaList(ThemeData theme) {
    final grouped = _groupByLetter(_visibleContacts);
    final letters = grouped.keys.toList()..sort();
    final total = letters.fold<int>(0, (sum, k) => sum + grouped[k]!.length + 1);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: total,
      itemBuilder: (context, index) {
        int running = 0;
        for (final letter in letters) {
          if (index == running) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                letter,
                style: theme.textTheme.titleMedium!
                    .copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            );
          }
          running++;
          final group = grouped[letter]!;
          if (index < running + group.length) {
            final item = group[index - running];
            final isLastInGroup = (index - running) == group.length - 1;
            return _contactTile(item, !isLastInGroup, theme);
          }
          running += group.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _contactTile(Contact item, bool showDivider, ThemeData theme) {
    final idx = _allContacts.indexWhere((c) => c.id == item.id);
    return GestureDetector(
      onTap: () => _showOptions(context, idx),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _avatarPlaceholderBg,
                  backgroundImage:
                      item.img.isNotEmpty ? FileImage(File(item.img)) : null,
                  child: item.img.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 28,
                          color: _avatarPlaceholderIcon,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: theme.textTheme.titleMedium),
                      Text(item.email, style: theme.textTheme.bodySmall),
                      Text(item.phone, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.more_vert, color: theme.iconTheme.color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptions(BuildContext context, int index) async {
    final contact = _allContacts[index];
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (_) => BottomSheet(
        onClosing: () {},
        builder: (_) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (contact.phone.isNotEmpty)
                TextButton(
                  onPressed: () {
                    launchUrlString('tel:${contact.phone}');
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Ligar',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showContactPage(contact: contact);
                },
                child: Text(
                  'Ver Detalhes',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () {
                  helper.deleteContact(contact.id!);
                  _loadContacts();
                  Navigator.pop(context);
                },
                child: Text(
                  'Deletar',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: Colors.red),
                ),
              ),
              const Divider(),
              TextButton(
                onPressed: () async {
                  contact.isFavorite = !contact.isFavorite;
                  await helper.updateOrCreateContact(contact);
                  await _loadContacts();
                  Navigator.pop(context);
                },
                child: Text(
                  contact.isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  style: theme.textTheme.bodyMedium,
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
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    await _loadUserProfile();
  }

  Future<void> _showContactPage({ Contact? contact }) async {
    await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (_) => ContactPage(contact: contact)),
    );
    await _loadContacts();
  }
}
