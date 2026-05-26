import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../models/credit_card_installment_model.dart';
import 'credit_card_installment_local_datasource.dart';
import 'credit_card_installment_remote_datasource.dart';

/// Syncer dos planos de parcelamento. Ordem 35 — depois de credit_cards(30),
/// já que cada parcelamento referencia um cartão (FK no servidor), e antes de
/// transactions(60).
class CreditCardInstallmentSyncer implements EntitySyncer {
  CreditCardInstallmentSyncer({required this.remote, required this.local});

  final CreditCardInstallmentRemoteDataSource remote;
  final CreditCardInstallmentLocalDataSource local;

  @override
  String get entityName => 'credit_card_installments';

  @override
  int get order => 35;

  @override
  Future<void> pullAll() async {
    final raws = await remote.listRaw();
    final models = raws.map(CreditCardInstallmentModel.fromApiJson).toList();
    await local.upsertManyPreservingPending(models);
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    switch (entry.operation) {
      case 'create':
        final item = await local.getById(entry.entityId);
        if (item == null) return;
        final res = await remote.create(item.toApiCreateJson());
        // Backend mantém o id do cliente — sem swap.
        await local.upsertSynced(CreditCardInstallmentModel.fromApiJson(res));
        break;
      case 'update':
        final item = await local.getById(entry.entityId);
        if (item == null) return;
        final res = await remote.update(entry.entityId, item.toApiUpdateJson());
        await local.upsertSynced(CreditCardInstallmentModel.fromApiJson(res));
        break;
      case 'delete':
        await remote.delete(entry.entityId);
        await local.delete(entry.entityId);
        break;
    }
  }
}
