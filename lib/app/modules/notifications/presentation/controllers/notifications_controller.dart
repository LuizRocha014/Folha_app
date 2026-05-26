import 'dart:async';

import 'package:get/get.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsController extends GetxController {
  NotificationsController({
    required this.local,
    required this.outbox,
    required this.syncManager,
  });

  final NotificationLocalDataSource local;
  final OutboxRepository outbox;
  final SyncManager syncManager;

  final RxList<NotificationEntity> items = <NotificationEntity>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    try {
      final list = await local.list();
      items.assignAll(list);
    } finally {
      loading.value = false;
    }
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<void> markRead(NotificationModel n) async {
    await local.markRead(n.id);
    final idx = items.indexWhere((it) => it.id == n.id);
    if (idx >= 0) {
      items[idx] = NotificationModel(
        id: n.id,
        userId: n.userId,
        kind: n.kind,
        title: n.title,
        body: n.body,
        scheduledFor: n.scheduledFor,
        isRead: true,
        createdAt: n.createdAt,
      );
    }
    // Enfileira no outbox — o NotificationSyncer faz o POST /read quando online
    // (offline-safe). Sai da fila só após o servidor confirmar.
    await outbox.enqueue(
      entity: 'notifications',
      entityId: n.id,
      operation: OutboxOperation.update,
      payload: const {'isRead': true},
    );
    unawaited(syncManager.runPushOnly());
  }
}
