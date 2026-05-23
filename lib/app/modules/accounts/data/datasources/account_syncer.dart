import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_meta_repository.dart';
import '../models/account_model.dart';
import 'account_local_datasource.dart';
import 'account_remote_datasource.dart';

class AccountSyncer implements EntitySyncer {
  AccountSyncer({
    required this.remote,
    required this.local,
    required this.meta,
  });

  final AccountRemoteDataSource remote;
  final AccountLocalDataSource local;
  final SyncMetaRepository meta;

  @override
  String get entityName => 'accounts';

  @override
  int get order => 10;

  @override
  Future<void> pullAll() async {
    final since = await meta.readLastPulledAt(entityName);
    final raws = await remote.listRaw(modifiedSince: since);
    final pulledAt = DateTime.now().toUtc();

    final models = raws.map(AccountModel.fromApiJson).toList();
    if (since == null) {
      await local.replaceSyncedSet(models);
    } else {
      await local.upsertMany(models);
    }
    await meta.markPulled(entityName, pulledAt);
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    final acc = await local.getById(entry.entityId);
    if (acc == null) return;

    switch (entry.operation) {
      case 'create':
        final res = await remote.create(acc.toApiCreateJson());
        await local.swapId(entry.entityId, res['id'] as String);
        break;
      case 'update':
        final res = await remote.update(entry.entityId, acc.toApiUpdateJson());
        await local.upsertSynced(AccountModel.fromApiJson(res));
        break;
      case 'delete':
        await remote.archive(entry.entityId);
        await local.delete(entry.entityId);
        break;
    }
  }
}
