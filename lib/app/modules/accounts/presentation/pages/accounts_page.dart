import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/account_entity.dart';
import '../controllers/accounts_controller.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AccountsController>();
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      appBar: AppBar(
        backgroundColor: FolhaColors.paper100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FolhaColors.ink900),
          onPressed: Get.back,
        ),
        title: Text('Contas', style: FolhaTypography.titleEditorial(size: 22)),
      ),
      body: Obx(() {
        if (ctrl.loading.value && ctrl.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.items.isEmpty) {
          return _EmptyState(
            onAdd: () => _showCreateSheet(context, ctrl),
          );
        }
        return RefreshIndicator(
          onRefresh: ctrl.refreshList,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            itemCount: ctrl.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AccountTile(account: ctrl.items[i]),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FolhaColors.forest700,
        foregroundColor: FolhaColors.paper50,
        onPressed: () => _showCreateSheet(context, Get.find<AccountsController>()),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AccountsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FolhaColors.paper100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CreateAccountSheet(controller: ctrl),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final AccountEntity account;

  static const _kindLabels = {
    'checking': 'Conta corrente',
    'savings': 'Poupança',
    'cash': 'Carteira',
    'investment': 'Investimento',
    'other': 'Outro',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FolhaColors.forest200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(LucideIcons.wallet, size: 20, color: FolhaColors.forest700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  _kindLabels[account.kind] ?? account.kind,
                  style: FolhaTypography.bodySm.copyWith(fontSize: 12, color: FolhaColors.fgMuted),
                ),
              ],
            ),
          ),
          Text(
            FolhaFormatters.brl(account.initialBalance),
            style: FolhaTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: FolhaColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet, size: 56, color: FolhaColors.ink400),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conta ainda.',
            style: FolhaTypography.titleEditorial(size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sua primeira conta pra começar a registrar movimentos.',
            textAlign: TextAlign.center,
            style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
          ),
          const SizedBox(height: 20),
          FolhaButton(
            label: 'Criar conta',
            size: FolhaButtonSize.md,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _CreateAccountSheet extends StatefulWidget {
  const _CreateAccountSheet({required this.controller});
  final AccountsController controller;

  @override
  State<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<_CreateAccountSheet> {
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _initialBalance = TextEditingController();
  String _kind = 'checking';

  static const _kinds = [
    ('checking', 'Conta corrente'),
    ('savings', 'Poupança'),
    ('cash', 'Carteira'),
    ('investment', 'Investimento'),
    ('other', 'Outro'),
  ];

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FolhaColors.ink200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Nova conta', style: FolhaTypography.titleEditorial(size: 22)),
          ),
          const SizedBox(height: 16),
          FolhaField(
            label: 'Nome',
            child: FolhaInput(
              controller: _name,
              hintText: 'Ex: Nubank',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          FolhaField(
            label: 'Instituição (opcional)',
            child: FolhaInput(controller: _institution, hintText: 'Ex: Nu Pagamentos'),
          ),
          const SizedBox(height: 12),
          FolhaField(
            label: 'Saldo inicial',
            child: FolhaInput(
              controller: _initialBalance,
              hintText: '0,00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TIPO',
              style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kinds.map((k) {
              final active = _kind == k.$1;
              return GestureDetector(
                onTap: () => setState(() => _kind = k.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? FolhaColors.forest700 : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? FolhaColors.forest700 : FolhaColors.border,
                    ),
                  ),
                  child: Text(
                    k.$2,
                    style: FolhaTypography.bodySm.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active ? FolhaColors.paper50 : FolhaColors.ink900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FolhaButton(
            label: 'Criar conta',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            onPressed: _valid
                ? () async {
                    final v = double.tryParse(_initialBalance.text.replaceAll(',', '.')) ?? 0;
                    final ok = await widget.controller.create(
                      name: _name.text.trim(),
                      kind: _kind,
                      institution: _institution.text.trim().isEmpty
                          ? null
                          : _institution.text.trim(),
                      initialBalance: v,
                    );
                    if (ok && context.mounted) Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
