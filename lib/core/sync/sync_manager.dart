import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../network/connectivity_service.dart';
import 'entity_syncer.dart';
import 'outbox_repository.dart';

/// Orquestra push (outbox → API) e pull (API → banco local) de todas as entidades.
///
/// Comportamento:
/// - `runFullSync()` faz push completo + pull completo em ordem por `EntitySyncer.order`.
/// - `runPushOnly()` só drena outbox (chamado quando volta conectividade).
/// - Listen automático em `ConnectivityService.onChanged`: quando volta online,
///   dispara `runPushOnly()` em background.
class SyncManager extends GetxService {
  SyncManager({
    required this.outbox,
    required this.connectivity,
    required this.syncers,
    this.reconcilePending,
  });

  final OutboxRepository outbox;
  final ConnectivityService connectivity;
  final List<EntitySyncer> syncers;

  /// Hook opcional rodado antes de cada drain do outbox. Reenfileira registros
  /// locais pendentes que ficaram sem entrada no outbox (ver `PendingReconciler`).
  /// Idempotente e barato — seguro chamar em todo push/sync.
  final Future<void> Function()? reconcilePending;

  /// Hook opcional rodado APÓS um full sync (já com `syncing=false`), p/ ex.
  /// materializar parcelas vencidas. Roda em toda sincronização completa,
  /// inclusive a disparada quando a conexão volta.
  Future<void> Function()? afterSync;

  final RxBool syncing = false.obs;
  final Rxn<DateTime> lastSyncAt = Rxn<DateTime>();
  final RxnString lastError = RxnString();

  StreamSubscription<bool>? _connSub;

  void start() {
    _connSub?.cancel();
    _connSub = connectivity.onChanged.listen((online) {
      if (online && !syncing.value) {
        // Ao voltar online: sync completo (push + pull) p/ enviar o que ficou
        // pendente E baixar mudanças feitas em outros dispositivos.
        runFullSync();
      }
    });
  }

  Future<void> stop() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  /// Drena outbox + pull de todas as entidades, em ordem.
  Future<void> runFullSync() async {
    if (!connectivity.isOnline) return;
    if (syncing.value) return;
    syncing.value = true;
    lastError.value = null;

    try {
      await _safeReconcile();
      await _drainOutbox();

      final ordered = [...syncers]..sort((a, b) => a.order.compareTo(b.order));
      for (final syncer in ordered) {
        try {
          await syncer.pullAll();
        } catch (e, st) {
          developer.log('pullAll ${syncer.entityName}', name: 'SyncManager', error: e, stackTrace: st);
          lastError.value = '${syncer.entityName}: $e';
        }
      }
      lastSyncAt.value = DateTime.now();
      await outbox.purgeOld();
    } finally {
      syncing.value = false;
    }

    // Pós-sync (com syncing já false p/ não bloquear o push que ele dispara).
    await _safeAfterSync();
  }

  Future<void> _safeAfterSync() async {
    final hook = afterSync;
    if (hook == null) return;
    try {
      await hook();
    } catch (e, st) {
      developer.log('afterSync', name: 'SyncManager', error: e, stackTrace: st);
    }
  }

  /// Só drena outbox (mais rápido — usado quando volta online).
  Future<void> runPushOnly() async {
    if (!connectivity.isOnline) return;
    if (syncing.value) return;
    syncing.value = true;
    try {
      await _safeReconcile();
      await _drainOutbox();
    } finally {
      syncing.value = false;
    }
  }

  Future<void> _safeReconcile() async {
    final hook = reconcilePending;
    if (hook == null) return;
    try {
      await hook();
    } catch (e, st) {
      developer.log('reconcilePending', name: 'SyncManager', error: e, stackTrace: st);
    }
  }

  /// Drena o outbox respeitando a ORDEM de dependência entre entidades
  /// (`EntitySyncer.order`): cada entidade é totalmente drenada antes da
  /// próxima. Assim um cartão (order 30) sempre é enviado antes de uma
  /// transação (order 60) que o referencia — independentemente da ordem de
  /// inserção no outbox. Isso evita o FK `FK_FOLHA_Tx_card` no servidor.
  Future<void> _drainOutbox() async {
    final syncerByName = {for (final s in syncers) s.entityName: s};
    final ordered = [...syncers]..sort((a, b) => a.order.compareTo(b.order));

    for (final syncer in ordered) {
      await _drainEntity(syncer);
    }

    // Entradas órfãs (entidade sem syncer registrado) — descarta.
    final orphans = (await outbox.pending(limit: 200))
        .where((e) => !syncerByName.containsKey(e.entity))
        .toList();
    for (final entry in orphans) {
      await outbox.markProcessed(entry.id);
    }
  }

  Future<void> _drainEntity(EntitySyncer syncer) async {
    while (true) {
      final pending = await outbox.pending(entity: syncer.entityName, limit: 50);
      if (pending.isEmpty) break;

      var progressed = false;
      for (final entry in pending) {
        try {
          await syncer.pushEntry(entry);
          await outbox.markProcessed(entry.id);
          progressed = true;
        } catch (e, st) {
          developer.log('pushEntry ${entry.entity} id=${entry.entityId}', name: 'SyncManager', error: e, stackTrace: st);
          await outbox.markFailed(entry.id, e.toString());
          // Descarta após 5 tentativas para não travar a fila eternamente.
          if (entry.attempts + 1 >= 5) {
            await outbox.markProcessed(entry.id);
            progressed = true;
          }
        }
      }

      // Se nada avançou (todas falharam sem atingir o limite de tentativas),
      // para — evita loop apertado batendo no servidor. Reentra no próximo sync.
      if (!progressed) break;
    }
  }
}
