import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static IconData _iconFor(String kind) => switch (kind) {
        'bill_due' || 'bill_overdue' => LucideIcons.fileText,
        'budget_warning' || 'budget_exceeded' => LucideIcons.alertTriangle,
        'goal_milestone' || 'goal_reached' => LucideIcons.target,
        'insight' => LucideIcons.sparkles,
        _ => LucideIcons.bell,
      };

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationsController>();
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      appBar: AppBar(
        backgroundColor: FolhaColors.paper100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FolhaColors.ink900),
          onPressed: Get.back,
        ),
        title: Text('Notificações', style: FolhaTypography.titleEditorial(size: 22)),
      ),
      body: Obx(() {
        if (ctrl.loading.value && ctrl.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bell, size: 56, color: FolhaColors.ink400),
                  const SizedBox(height: 16),
                  Text('Nada por aqui.', style: FolhaTypography.titleEditorial(size: 20)),
                  const SizedBox(height: 6),
                  Text(
                    'Avisos de contas, metas e orçamentos vão aparecer aqui.',
                    textAlign: TextAlign.center,
                    style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: ctrl.refreshList,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: ctrl.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = ctrl.items[i];
              return _NotificationTile(
                notification: n,
                onTap: () => ctrl.markRead(n as NotificationModel),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm', 'pt_BR');
    final unread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: unread ? FolhaColors.paper50 : FolhaColors.paper100,
          border: Border.all(
            color: unread ? FolhaColors.forest200 : FolhaColors.border,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FolhaColors.forest200,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                NotificationsPage._iconFor(notification.kind),
                size: 18,
                color: FolhaColors.forest700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: FolhaTypography.body.copyWith(
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        df.format(notification.createdAt),
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: FolhaColors.fgMuted,
                        ),
                      ),
                    ],
                  ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      style: FolhaTypography.bodySm.copyWith(
                        fontSize: 13,
                        color: FolhaColors.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
