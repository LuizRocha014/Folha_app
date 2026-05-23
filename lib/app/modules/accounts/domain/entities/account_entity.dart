import 'package:equatable/equatable.dart';

class AccountEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String kind; // checking | savings | cash | investment | other
  final String? institution;
  final String? icon;
  final String? colorHex;
  final double initialBalance;
  final String currencyCode;
  final bool isArchived;
  final bool includeInTotal;
  final int sortOrder;
  final String syncStatus;

  const AccountEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    this.institution,
    this.icon,
    this.colorHex,
    this.initialBalance = 0,
    this.currencyCode = 'BRL',
    this.isArchived = false,
    this.includeInTotal = true,
    this.sortOrder = 0,
    this.syncStatus = 'synced',
  });

  @override
  List<Object?> get props => [
        id, userId, name, kind, institution, icon, colorHex,
        initialBalance, currencyCode, isArchived, includeInTotal, sortOrder, syncStatus,
      ];
}
