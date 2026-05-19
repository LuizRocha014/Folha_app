import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _rows = [
    (icon: LucideIcons.settings, label: 'Configurações', value: null),
    (icon: LucideIcons.bell, label: 'Notificações', value: null),
    (
      icon: LucideIcons.creditCard,
      label: 'Contas conectadas',
      value: '2',
    ),
    (icon: LucideIcons.target, label: 'Metas e orçamentos', value: null),
    (icon: LucideIcons.pieChart, label: 'Relatórios', value: null),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                FolhaIconBtn(
                  icon: LucideIcons.chevronLeft,
                  variant: FolhaIconBtnVariant.soft,
                  tooltip: 'Voltar',
                  onPressed: () => shell.goTo(0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Perfil',
                    style: FolhaTypography.titleEditorial(size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Obx(
                  () => FolhaAvatar(
                    name: auth.user.value?.fullName ?? 'Marina Alves',
                    size: 80,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Text(
                    auth.user.value?.fullName ?? 'Marina Alves',
                    style: FolhaTypography.titleEditorial(size: 26),
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    auth.user.value?.email ?? 'marina.alves@email.com',
                    style: FolhaTypography.bodySm.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: FolhaColors.paper50,
                border: Border.all(color: FolhaColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(_rows.length, (i) {
                  final row = _rows[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: i < _rows.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: FolhaColors.divider,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              row.icon,
                              size: 20,
                              color: FolhaColors.ink700,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                row.label,
                                style: FolhaTypography.body.copyWith(
                                  fontSize: 14,
                                  color: FolhaColors.ink900,
                                ),
                              ),
                            ),
                            if (row.value != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  row.value!,
                                  style: FolhaTypography.bodySm.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: FolhaColors.ink400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: FolhaButton(
              label: 'Sair da conta',
              variant: FolhaButtonVariant.danger,
              size: FolhaButtonSize.md,
              fullWidth: true,
              onPressed: () async {
                await auth.logout();
                Get.offAllNamed(AppRoutes.welcome);
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  'FOLHA · V1.0',
                  style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                ),
                const SizedBox(height: 4),
                Text(
                  'sua vida financeira, escrita com clareza',
                  style: FolhaTypography.titleEditorial(
                    size: 14,
                    color: FolhaColors.ink400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
