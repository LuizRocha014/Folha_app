import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({super.key});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  TransactionEntity? _tx;
  // Origem do movimento: nome do cartão ou da conta. `null` enquanto carrega.
  String? _sourceLabel;
  IconData _sourceIcon = LucideIcons.wallet;

  @override
  void initState() {
    super.initState();
    _tx = Get.arguments as TransactionEntity?;
    if (_tx != null) _resolveSource(_tx!);
  }

  Future<void> _resolveSource(TransactionEntity tx) async {
    if (!Get.isRegistered<LocalDatabase>()) return;
    final db = Get.find<LocalDatabase>();
    try {
      if (tx.creditCardId != null) {
        final rows = await db.raw.query(
          'credit_cards',
          columns: ['name', 'last_four'],
          where: 'id = ?',
          whereArgs: [tx.creditCardId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final name = rows.first['name'] as String? ?? 'Cartão';
          final last4 = rows.first['last_four'] as String?;
          if (mounted) {
            setState(() {
              _sourceIcon = LucideIcons.creditCard;
              _sourceLabel = last4 != null ? '$name · **** $last4' : name;
            });
          }
          return;
        }
      }
      if (tx.accountId != null) {
        final rows = await db.raw.query(
          'accounts',
          columns: ['name', 'institution'],
          where: 'id = ?',
          whereArgs: [tx.accountId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final name = rows.first['name'] as String? ?? 'Conta';
          final inst = rows.first['institution'] as String?;
          if (mounted) {
            setState(() {
              _sourceIcon = LucideIcons.wallet;
              _sourceLabel = (inst != null && inst.isNotEmpty) ? '$name · $inst' : name;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _sourceLabel = '—');
    } catch (_) {
      if (mounted) setState(() => _sourceLabel = '—');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = _tx;
    if (tx == null) {
      return const Scaffold(body: Center(child: Text('Movimento não encontrado.')));
    }
    final cat = FolhaCategoryStyles.of(tx.category);
    final isIncome = tx.isIncome;
    final hasNote = tx.note != null && tx.note!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 60),
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
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DETALHE DO MOVIMENTO',
                        style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: cat.bg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(cat.icon, size: 28, color: cat.color),
                    ),
                    const SizedBox(height: 14),
                    if (tx.place.trim().isNotEmpty) ...[
                      Text(
                        tx.place.toUpperCase(),
                        style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      tx.description,
                      textAlign: TextAlign.center,
                      style: FolhaTypography.titleEditorial(size: 26),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      FolhaFormatters.brl(tx.value, sign: isIncome),
                      style: FolhaTypography.currencyDisplay(
                        size: 56,
                        color: isIncome ? FolhaColors.forest500 : FolhaColors.ink900,
                      ),
                    ),
                  ],
                ),
              ),

              // Meta rows (dados reais)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: FolhaColors.paper50,
                    border: Border.all(color: FolhaColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _MetaRow(
                        icon: LucideIcons.calendar,
                        label: 'Data',
                        value: FolhaFormatters.fullDate(tx.when),
                      ),
                      _MetaRow(
                        icon: LucideIcons.circle,
                        label: 'Categoria',
                        valueWidget: FolhaBadge(
                          label: cat.label,
                          color: cat.color,
                          bg: cat.bg,
                          small: true,
                        ),
                        divider: true,
                      ),
                      _MetaRow(
                        icon: _sourceIcon,
                        label: tx.creditCardId != null ? 'Cartão' : 'Conta',
                        value: _sourceLabel ?? 'Carregando…',
                        divider: true,
                      ),
                      _MetaRow(
                        icon: isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        label: 'Tipo',
                        value: isIncome ? 'Entrada' : 'Saída',
                        divider: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Notes (só quando existe nota real)
              if (hasNote)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FolhaEyebrow(label: 'Anotação', padding: EdgeInsets.zero),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FolhaColors.paper50,
                          border: Border.all(color: FolhaColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tx.note!,
                          style: FolhaTypography.titleEditorial(
                            size: 14,
                            color: FolhaColors.fgMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool divider;
  const _MetaRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: divider ? FolhaColors.divider : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FolhaColors.ink400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: FolhaTypography.bodySm.copyWith(fontSize: 13)),
          ),
          valueWidget ??
              Flexible(
                child: Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: FolhaTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
