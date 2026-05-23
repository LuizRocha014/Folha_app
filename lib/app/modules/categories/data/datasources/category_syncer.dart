import '../../../../../core/database/category_lookup.dart';
import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import 'category_remote_datasource.dart';

class CategorySyncer implements EntitySyncer {
  CategorySyncer({required this.remote, required this.lookup});

  final CategoryRemoteDataSource remote;
  final CategoryLookup lookup;

  @override
  String get entityName => 'categories';

  @override
  int get order => 20;

  @override
  Future<void> pullAll() async {
    final raws = await remote.listRaw();
    for (final json in raws) {
      await lookup.upsert(
        serverId: json['id'] as int,
        slug: json['slug'] as String,
        label: (json['label'] as String?) ?? '',
        icon: json['icon'] as String?,
        colorHex: json['colorHex'] as String?,
        bgHex: json['bgHex'] as String?,
        kind: (json['kind'] as String?) ?? 'expense',
        isSystem: (json['isSystem'] as bool?) ?? false,
        userId: json['userId'] as String?,
        sortOrder: (json['sortOrder'] as int?) ?? 0,
      );
    }
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    // Por ora a UI não cria categorias customizadas — só sistema (read-only).
    // Quando habilitar, implementar POST/PUT/DELETE aqui.
  }
}
