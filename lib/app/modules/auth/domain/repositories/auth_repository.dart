import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required DateTime birthDate,
  });

  Future<Either<Failure, bool>> verifyEmailCode({required String code});

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> currentUser();
}
