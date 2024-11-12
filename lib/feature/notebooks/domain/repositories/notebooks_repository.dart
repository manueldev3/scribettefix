import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:scribettefix/core/repositories/database_repository.dart';
import 'package:scribettefix/feature/auth/domain/repositories/auth_repository.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';

class NotebooksRepository extends DatabaseRepository {
  final authRepository = AuthRepository();

  Future<Either<String, List<Notebook>>> getNotebooks() async {
    try {
      final currentUser = authRepository.auth.currentUser;

      if (currentUser == null) {
        return const Right(<Notebook>[]);
      }

      final notebooksQuery = await db.getNotebooks();

      final notebooks = <Notebook>[];

      for (final json in notebooksQuery) {
        final files = await db.getFiles(json['id']);
        notebooks.add(
          Notebook.fromJson({
            ...json,
            'files': files,
          }),
        );
      }

      return right(notebooks);
    } catch (error, stackTrace) {
      log(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );
      return Left(error.toString());
    }
  }

  Future<Either<String, void>> insertName(String name) async {
    try {
      await db.insertNotebook(name);
      return right(null);
    } catch (error, stackTrace) {
      log(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );
      return Left(error.toString());
    }
  }
}
