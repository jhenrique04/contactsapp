import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:contacts/ui/home_page.dart';  // para OrderOptions

const String contactTable   = 'contactTable';
const String idColumn       = 'idColumn';
const String nameColumn     = 'nameColumn';
const String emailColumn    = 'emailColumn';
const String phoneColumn    = 'phoneColumn';
const String imgColumn      = 'imgColumn';
const String favoriteColumn = 'favoriteColumn';

class ContactHelper {
  static final _instance = ContactHelper._internal();
  factory ContactHelper() => _instance;
  ContactHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/contactsnew.db';

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $contactTable(
            $idColumn       INTEGER PRIMARY KEY AUTOINCREMENT,
            $nameColumn     TEXT,
            $emailColumn    TEXT,
            $phoneColumn    TEXT,
            $imgColumn      TEXT,
            $favoriteColumn INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // adiciona coluna favoriteColumn mantendo dados antigos
          await db.execute('''
            ALTER TABLE $contactTable
            ADD COLUMN $favoriteColumn INTEGER DEFAULT 0
          ''');
        }
      },
    );
  }

  Future<int> deleteContact(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      contactTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateOrCreateContact(Contact contact) async {
    final dbClient = await db;
    final map = contact.toMap(includeId: false);
    if (contact.id == null || contact.id == 0) {
      return await dbClient.insert(
        contactTable,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      return await dbClient.update(
        contactTable,
        map,
        where: '$idColumn = ?',
        whereArgs: [contact.id],
      );
    }
  }

  Future<List<Contact>> getAllContacts(OrderOptions order) async {
    final dbClient = await db;
    final orderBy = order == OrderOptions.aToZ ? 'ASC' : 'DESC';
    final listMap = await dbClient.rawQuery(
      'SELECT * FROM $contactTable '
      'ORDER BY $nameColumn COLLATE NOCASE $orderBy',
    );
    return listMap.map((m) => Contact.fromMap(m)).toList();
  }

  Future<int?> getNumber() async {
    final dbClient = await db;
    return Sqflite.firstIntValue(
      await dbClient.rawQuery('SELECT COUNT(*) FROM $contactTable'),
    );
  }

  Future close() async {
    final dbClient = await db;
    await dbClient.close();
  }
}

class Contact {
  int? id;
  String name;
  String email;
  String phone;
  String img;          // caminho para a foto
  bool isFavorite;     // novo campo

  Contact({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.img,
    this.isFavorite = false,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map[idColumn] as int?,
      name: map[nameColumn] as String?    ?? '',
      email: map[emailColumn] as String?  ?? '',
      phone: map[phoneColumn] as String?  ?? '',
      img: map[imgColumn] as String?      ?? '',
      isFavorite: (map[favoriteColumn] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final m = <String, dynamic>{
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
      imgColumn: img,
      favoriteColumn: isFavorite ? 1 : 0,
    };
    if (includeId && id != null && id! > 0) {
      m[idColumn] = id;
    }
    return m;
  }

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, email: $email, '
           'phone: $phone, img: $img, isFavorite: $isFavorite}';
  }

  /// Para atualizar apenas alguns campos
  Contact copyWith({
    int?    id,
    String? name,
    String? email,
    String? phone,
    String? img,
    bool?   isFavorite,
  }) {
    return Contact(
      id:         id ?? this.id,
      name:       name ?? this.name,
      email:      email ?? this.email,
      phone:      phone ?? this.phone,
      img:        img ?? this.img,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
