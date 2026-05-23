import '../../../../../core/database/category_lookup.dart';
import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_meta_repository.dart';
import '../models/bill_model.dart';
import 'bill_local_datasource.dart';
import 'bill_remote_datasource.dart';

class BillSyncer implements EntitySyncer {
  BillSyncer({
    required this.remote,
    required this.local,
    required this.categories,
    required this.meta,
  });

  final BillRemoteDataSource remote;
  final BillLocalDataSource local;
  final CategoryLookup categories;
  final SyncMetaRepository meta;

  @override
  String get entityName => 'bills';

  @override
  int get order => 50;

  @override
  Future<void> pullAll() async {
    final since = await meta.readLastPulledAt(entityName);
    final raws = await remote.listRaw(modifiedSince: since);
    final pulledAt = DateTime.now().toUtc();

    final models = <BillModel>[];
    for (final json in raws) {
      final categoryId = json['categoryId'] as int?;
      final slug = categoryId == null ? null : await categories.idToSlug(categoryId);
      models.add(BillModel.fromApiJson(json, categorySlug: slug));
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
    final bill = await local.getById(entry.entityId);
    if (bill == null) return;
    final categoryId = bill.categorySlug == null ? null : await categories.slugToId(bill.categorySlug!);

    switch (entry.operation) {
      case 'create':
        final res = await remote.create(bill.toApiCreateJson(categoryId: categoryId));
        await local.swapId(entry.entityId, res['id'] as String);
        break;
      case 'update':
        final res = await remote.update(entry.entityId, bill.toApiUpdateJson(categoryId: categoryId));
        await local.upsertSynced(BillModel.fromApiJson(res, categorySlug: bill.categorySlug));
        break;
      case 'delete':
        await remote.delete(entry.entityId);
        await local.delete(entry.entityId);
        break;
    }
  }
}
