import 'package:sqflite_sqlcipher/sqflite.dart';
import 'local_database.dart';

/// Resolve slug ↔ id de categorias para o sync com a API.
///
/// IDs determinísticos das categorias do sistema (alinhados com a migration
/// `003_SeedSystemCategories.sql` do backend). Categorias customizadas têm id
/// dinâmico vindo do pull e ficam na tabela `categories.server_id`.
class CategoryLookup {
  CategoryLookup(this._db);

  final LocalDatabase _db;

  static const Map<String, int> systemSlugToId = {
    'food': 1,
    'trans': 2,
    'leisure': 3,
    'home': 4,
    'health': 5,
    'shop': 6,
    'income': 7,
    'other': 8,
  };

  static const Map<int, String> systemIdToSlug = {
    1: 'food',
    2: 'trans',
    3: 'leisure',
    4: 'home',
    5: 'health',
    6: 'shop',
    7: 'income',
    8: 'other',
  };

  /// Slug → id para envio ao backend.
  Future<int?> slugToId(String slug) async {
    final sys = systemSlugToId[slug];
    if (sys != null) return sys;

    final row = await _db.raw.query(
      'categories',
      columns: ['server_id'],
      where: 'slug = ?',
      whereArgs: [slug],
      limit: 1,
    );
    if (row.isEmpty) return null;
    return row.first['server_id'] as int?;
  }

  /// Id (da API) → slug para hidratar registros recebidos no pull.
  Future<String> idToSlug(int id) async {
    final sys = systemIdToSlug[id];
    if (sys != null) return sys;

    final row = await _db.raw.query(
      'categories',
      columns: ['slug'],
      where: 'server_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (row.isEmpty) return 'other';
    return row.first['slug'] as String;
  }

  /// Upsert de uma categoria recebida do servidor.
  Future<void> upsert({
    required int serverId,
    required String slug,
    required String label,
    String? icon,
    String? colorHex,
    String? bgHex,
    required String kind,
    required bool isSystem,
    String? userId,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.raw.insert(
      'categories',
      {
        'slug': slug,
        'server_id': serverId,
        'user_id': userId,
        'label': label,
        'icon': icon,
        'color_hex': colorHex,
        'bg_hex': bgHex,
        'kind': kind,
        'is_system': isSystem ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': now,
        'updated_at': now,
        '_sync_status': 'synced',
        '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
        '_server_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
