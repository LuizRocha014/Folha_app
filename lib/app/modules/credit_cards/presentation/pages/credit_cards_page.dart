import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../controllers/credit_cards_controller.dart';
import 'add_credit_card_sheet.dart';

class CreditCardsPage extends GetView<CreditCardsController> {
  const CreditCardsPage({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: FolhaColors.forest900.withValues(alpha: 0.45),
      builder: (_) => const AddCreditCardSheet(),
    );
  }

  void _confirmArchive(BuildContext context, CreditCardEntity card) {
    Get.dialog(
      AlertDialog(
        backgroundColor: FolhaColors.paper100,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Arquivar cartão', style: FolhaTypography.titleEditorial(size: 18)),
        content: Text(
          'Tem certeza que quer arquivar o cartão "${card.name}"? Ele some da lista mas continua no histórico.',
          style: FolhaTypography.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FolhaColors.terra700),
            onPressed: () {
              Get.back();
              controller.archive(card.id);
            },
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      appBar: AppBar(
        backgroundColor: FolhaColors.paper100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FolhaColors.ink900),
          onPressed: Get.back,
        ),
        title: Text('Cartões', style: FolhaTypography.titleEditorial(size: 22)),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return _EmptyState(onAdd: () => _openAddSheet(context));
        }
        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final card = controller.items[i];
              return _CardTile(
                card: card,
                onArchive: () => _confirmArchive(context, card),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: FolhaColors.forest700,
        foregroundColor: FolhaColors.paper50,
        onPressed: () => _openAddSheet(context),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(
          'Novo cartão',
          style: FolhaTypography.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FolhaColors.paper50,
          ),
        ),
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
          Icon(LucideIcons.creditCard, size: 56, color: FolhaColors.ink400),
          const SizedBox(height: 16),
          Text(
            'Sem cartões cadastrados.',
            style: FolhaTypography.titleEditorial(size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Adicione cartões pra acompanhar limite, fechamento e vencimento.',
            textAlign: TextAlign.center,
            style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
          ),
          const SizedBox(height: 20),
          FolhaButton(
            label: 'Cadastrar cartão',
            size: FolhaButtonSize.md,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onArchive});
  final CreditCardEntity card;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FolhaColors.forest700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.creditCard, size: 18, color: FolhaColors.paper50),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.brand.toUpperCase()}'
                      '${card.lastFour != null ? ' · **** ${card.lastFour}' : ''}',
                      style: FolhaTypography.bodySm.copyWith(
                        fontSize: 12,
                        color: FolhaColors.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                FolhaFormatters.brl(card.creditLimit),
                style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaBox(
                  label: 'FECHAMENTO',
                  value: 'dia ${card.closingDay}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetaBox(
                  label: 'VENCIMENTO',
                  value: 'dia ${card.dueDay}',
                ),
              ),
              const SizedBox(width: 10),
              FolhaIconBtn(
                icon: LucideIcons.trash2,
                variant: FolhaIconBtnVariant.soft,
                size: 36,
                onPressed: onArchive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaBox extends StatelessWidget {
  const _MetaBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FolhaColors.paper100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: FolhaTypography.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
