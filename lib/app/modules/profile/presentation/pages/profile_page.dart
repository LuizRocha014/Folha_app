import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _biometricEnabled = false;
  bool _loadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final secure = Get.find<SecureStorageService>();
    final enabled = await secure.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _loadingBiometric = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final auth = Get.find<AuthController>();
    if (value) {
      final pwd = await _askPassword();
      if (pwd == null || pwd.isEmpty) return;
      final email = auth.user.value?.email ?? '';
      final ok = await auth.enableBiometric(email: email, password: pwd);
      if (!mounted) return;
      setState(() => _biometricEnabled = ok);
    } else {
      await auth.disableBiometric();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
    }
  }

  Future<String?> _askPassword() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FolhaColors.paper50,
        title: Text('Confirme sua senha', style: FolhaTypography.titleEditorial(size: 18)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Sua senha atual'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();
    final hasSync = Get.isRegistered<SyncManager>();

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
                  child: Text('Perfil', style: FolhaTypography.titleEditorial(size: 24)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Obx(() => FolhaAvatar(
                      name: auth.user.value?.fullName ?? 'Marina Alves',
                      size: 80,
                    )),
                const SizedBox(height: 12),
                Obx(() => Text(
                      auth.user.value?.fullName ?? 'Marina Alves',
                      style: FolhaTypography.titleEditorial(size: 26),
                    )),
                const SizedBox(height: 2),
                Obx(() => Text(
                      auth.user.value?.email ?? 'marina.alves@email.com',
                      style: FolhaTypography.bodySm.copyWith(fontSize: 13),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionCard(
            title: 'SEGURANÇA',
            children: [
              SwitchListTile(
                value: _biometricEnabled,
                onChanged: _loadingBiometric ? null : _toggleBiometric,
                title: Text('Login com biometria', style: FolhaTypography.body),
                subtitle: Text(
                  'Use sua digital ou Face ID pra entrar.',
                  style: FolhaTypography.bodySm.copyWith(fontSize: 12),
                ),
                secondary: const Icon(LucideIcons.fingerprint, size: 20),
                activeThumbColor: FolhaColors.forest700,
              ),
            ],
          ),

          if (hasSync)
            _SectionCard(
              title: 'SINCRONIZAÇÃO',
              children: [
                Obx(() {
                  final s = Get.find<SyncManager>();
                  return ListTile(
                    leading: Icon(
                      s.syncing.value ? LucideIcons.refreshCw : LucideIcons.cloud,
                      size: 20,
                      color: FolhaColors.ink700,
                    ),
                    title: Text(
                      s.syncing.value ? 'Sincronizando…' : 'Tudo em dia',
                      style: FolhaTypography.body,
                    ),
                    subtitle: Text(
                      s.lastSyncAt.value == null
                          ? 'Ainda não sincronizado'
                          : 'Última sync: ${_formatTime(s.lastSyncAt.value!)}',
                      style: FolhaTypography.bodySm.copyWith(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: s.syncing.value ? null : () => s.runFullSync(),
                    ),
                  );
                }),
              ],
            ),

          _SectionCard(
            title: 'CONTA',
            children: [
              ListTile(
                leading: const Icon(LucideIcons.wallet, size: 20),
                title: const Text('Contas e carteiras'),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                onTap: () => Get.toNamed(AppRoutes.accounts),
              ),
              ListTile(
                leading: const Icon(LucideIcons.creditCard, size: 20),
                title: const Text('Cartões de crédito'),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                onTap: () => Get.toNamed(AppRoutes.creditCards),
              ),
              ListTile(
                leading: const Icon(LucideIcons.target, size: 20),
                title: const Text('Metas'),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                onTap: () => Get.toNamed(AppRoutes.goals),
              ),
              ListTile(
                leading: const Icon(LucideIcons.pieChart, size: 20),
                title: const Text('Orçamentos'),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                onTap: () => Get.toNamed(AppRoutes.budgets),
              ),
              ListTile(
                leading: const Icon(LucideIcons.bell, size: 20),
                title: const Text('Notificações'),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                onTap: () => Get.toNamed(AppRoutes.notifications),
              ),
            ],
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: FolhaColors.paper50,
              border: Border.all(color: FolhaColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
