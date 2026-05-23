import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.displayName,
    super.avatarUrl,
    super.currencyCode,
    super.cpf,
    super.birthDate,
  });

  /// Constrói a partir do payload `LoginResponse` da Folha.Api (snake-ish camelCase).
  factory UserModel.fromLoginResponse(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
    );
  }

  /// Constrói a partir de `UserDto` em /api/users/me.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      currencyCode: (json['currencyCode'] as String?) ?? 'BRL',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'currencyCode': currencyCode,
      };

  /// Row do banco local (`users` table).
  factory UserModel.fromRow(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      email: row['email'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      displayName: (row['display_name'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      currencyCode: (row['currency_code'] as String?) ?? 'BRL',
    );
  }
}
