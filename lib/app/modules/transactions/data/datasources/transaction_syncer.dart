import '../../../../../core/database/category_lookup.dart';
import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_meta_repository.dart';
import '../models/transaction_model.dart';
import 'transaction_local_datasource.dart';
import 'transaction_remote_datasource.dart';

class TransactionSyncer implements EntitySyncer {
  TransactionSyncer({
    required this.remote,
    required this.local,
    required this.categories,
    required this.meta,
  });

  final TransactionRemoteDataSource remote;
  final TransactionLocalDataSource local;
  final CategoryLookup categories;
  final SyncMetaRepository meta;

  @override
  String get entityName => 'transactions';

  @override
  int get order => 60;

  @override
  Future<void> pullAll() async {
    final since = await meta.readLastPulledAt(entityName);
    final raws = await remote.listRaw(skip: 0, take: 500, modifiedSince: since);
    final pulledAt = DateTime.now().toUtc();

    final models = <TransactionModel>[];
    for (final json in raws) {
      final categoryId = json['categoryId'] as int?;
      final slug = categoryId == null ? 'other' : await categories.idToSlug(categoryId);
      models.add(TransactionModel.fromApiJson(json, categorySlug: slug));
    }

    if (since == null) {
      await local.replaceSyncedSet(models);
    } else {
      await local.upsertMany(models);
    }
    await meta.markPulled(entityName, pulledAt);
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    switch (entry.operation) {
      case 'create':
        await _pushCreate(entry);
        break;
      case 'update':
        await _pushUpdate(entry);
        break;
      case 'delete':
        await _pushDelete(entry);
        break;
    }
  }

  Future<void> _pushCreate(OutboxEntry entry) async {
    final localTx = await local.getById(entry.entityId);
    if (localTx == null) return;
    final categoryId = await categories.slugToId(localTx.category);
    if (categoryId == null) {
      throw StateError('Categoria "${localTx.category}" sem id local — rode pull de categorias.');
    }
    final created = await remote.create(localTx.toApiCreateJson(categoryId: categoryId));
    final newId = created['id'] as String;
    final slug = await categories.idToSlug(created['categoryId'] as int);
    await local.swapId(entry.entityId, newId);
    await local.upsertSynced(TransactionModel.fromApiJson(created, categorySlug: slug));
  }

  Future<void> _pushUpdate(OutboxEntry entry) async {
    final localTx = await local.getById(entry.entityId);
    if (localTx == null) return;
    final categoryId = await categories.slugToId(localTx.category);
    if (categoryId == null) {
      throw StateError('Categoria sem id local: ${localTx.category}');
    }
    final updated = await remote.update(entry.entityId, localTx.toApiUpdateJson(categoryId: categoryId));
    final slug = await categories.idToSlug(updated['categoryId'] as int);
    await local.upsertSynced(TransactionModel.fromApiJson(updated, categorySlug: slug));
  }

  Future<void> _pushDelete(OutboxEntry entry) async {
    await remote.delete(entry.entityId);
    await local.delete(entry.entityId);
  }
}
