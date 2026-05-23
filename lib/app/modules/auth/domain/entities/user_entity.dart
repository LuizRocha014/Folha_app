import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String displayName;
  final String? avatarUrl;
  final String currencyCode;
  // legados — mantidos para o fluxo de signup (UI atual coleta esses dados)
  final String? cpf;
  final DateTime? birthDate;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.displayName,
    this.avatarUrl,
    this.currencyCode = 'BRL',
    this.cpf,
    this.birthDate,
  });

  String get firstName {
    if (displayName.trim().isNotEmpty) return displayName.split(' ').first;
    return fullName.split(' ').first;
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  List<Object?> get props => [id, email, fullName, displayName, avatarUrl, currencyCode];
}
