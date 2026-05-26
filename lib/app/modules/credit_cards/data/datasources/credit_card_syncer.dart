import '../../../../../core/sync/entity_syncer.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../models/credit_card_model.dart';
import 'credit_card_local_datasource.dart';
import 'credit_card_remote_datasource.dart';

/// Syncer de cartões de crédito — push (outbox → API) + pull (API → local).
///
/// Substitui o antigo `CreditCardSyncer` read-only (que tinha `pushEntry` vazio):
/// os cartões criados no app nunca chegavam ao servidor, e qualquer transação
/// referenciando o cartão estourava o FK `FK_FOLHA_Tx_card` no INSERT.
///
/// Ordem 30 (cartões antes de transactions=60). O `id` é gerado no cliente e
/// aceito pelo backend, então não há swap pós-create.
class CreditCardSyncer implements EntitySyncer {
  CreditCardSyncer({required this.remote, required this.local});

  final CreditCardRemoteDataSource remote;
  final CreditCardLocalDataSource local;

  @override
  String get entityName => 'credit_cards';

  @override
  int get order => 30;

  @override
  Future<void> pullAll() async {
    final raws = await remote.listRaw();
    final models = raws.map(CreditCardModel.fromApiJson).toList();
    await local.upsertManyPreservingPending(models);
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    switch (entry.operation) {
      case 'create':
        final card = await local.getById(entry.entityId);
        if (card == null) return;
        final res = await remote.create(card.toApiCreateJson());
        // Backend mantém o id do cliente — sem swap; só marca como synced.
        await local.upsertSynced(CreditCardModel.fromApiJson(res));
        break;
      case 'update':
        final card = await local.getById(entry.entityId);
        if (card == null) return;
        final res = await remote.update(entry.entityId, card.toApiUpdateJson());
        await local.upsertSynced(CreditCardModel.fromApiJson(res));
        break;
      case 'delete':
        await remote.archive(entry.entityId);
        await local.delete(entry.entityId);
        break;
    }
  }
}
