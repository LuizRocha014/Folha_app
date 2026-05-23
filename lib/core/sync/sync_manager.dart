import 'dart:async';
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
  });

  final OutboxRepository outbox;
  final ConnectivityService connectivity;
  final List<EntitySyncer> syncers;

  final RxBool syncing = false.obs;
  final Rxn<DateTime> lastSyncAt = Rxn<DateTime>();
  final RxnString lastError = RxnString();

  StreamSubscription<bool>? _connSub;

  void start() {
    _connSub?.cancel();
    _connSub = connectivity.onChanged.listen((online) {
      if (online && !syncing.value) {
        // Fire-and-forget — não trava UI.
        runPushOnly();
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
      await _drainOutbox();

      final ordered = [...syncers]..sort((a, b) => a.order.compareTo(b.order));
      for (final syncer in ordered) {
        try {
          await syncer.pullAll();
        } catch (e) {
          lastError.value = '${syncer.entityName}: $e';
        }
      }
      lastSyncAt.value = DateTime.now();
      await outbox.purgeOld();
    } finally {
      syncing.value = false;
    }
  }

  /// Só drena outbox (mais rápido — usado quando volta online).
  Future<void> runPushOnly() async {
    if (!connectivity.isOnline) return;
    if (syncing.value) return;
    syncing.value = true;
    try {
      await _drainOutbox();
    } finally {
      syncing.value = false;
    }
  }

  Future<void> _drainOutbox() async {
    final syncerByName = {for (final s in syncers) s.entityName: s};

    while (true) {
      final pending = await outbox.pending(limit: 50);
      if (pending.isEmpty) break;

      for (final entry in pending) {
        final syncer = syncerByName[entry.entity];
        if (syncer == null) {
          // Sem syncer — descarta (entrada órfã).
          await outbox.markProcessed(entry.id);
          continue;
        }
        try {
          await syncer.pushEntry(entry);
          await outbox.markProcessed(entry.id);
        } catch (e) {
          await outbox.markFailed(entry.id, e.toString());
          // Para evitar loop infinito em erros persistentes, descartamos após 5 tentativas.
          if (entry.attempts + 1 >= 5) {
            await outbox.markProcessed(entry.id);
          }
        }
      }
    }
  }
}
