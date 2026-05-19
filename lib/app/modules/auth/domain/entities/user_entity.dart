import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? cpf;
  final DateTime? birthDate;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.cpf,
    this.birthDate,
  });

  String get firstName => fullName.split(' ').first;

  /// Saudação contextual (bom dia / boa tarde / boa noite).
  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  List<Object?> get props => [id, fullName, email, cpf, birthDate];
}
