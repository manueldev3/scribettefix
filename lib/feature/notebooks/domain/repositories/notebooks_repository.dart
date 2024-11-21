import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/core/repositories/database_repository.dart';
import 'package:scribettefix/feature/auth/domain/repositories/auth_repository.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';

class NotebooksRepository extends DatabaseRepository {
  final authRepository = AuthRepository();
  final dbHelper = DatabaseHelper();

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

  Future<void> rename(
    String notebookName, {
    required String title,
  }) async {
    if (notebookName.isNotEmpty && notebookName != "(Not Assignment)") {
      await dbHelper.renameNotebook(
        title,
        notebookName,
      );
    }
  }

  Future<void> delete(String title) async {
    await DatabaseHelper().deleteNotebook(title);
    final String? email = authRepository.auth.currentUser?.email;
    final myNotesCollection = authRepository.firestore
        .collection('users')
        .doc(email)
        .collection('notes');

    final recordingsSnapshot = await myNotesCollection.get();

    if (recordingsSnapshot.docs.isNotEmpty) {
      for (final document in recordingsSnapshot.docs) {
        String notebookTitle =
            document.get("notebook").trim().replaceAll("\n", "");

        if (notebookTitle == title) {
          await myNotesCollection.doc(document.id).delete();
        }
      }
    }
  }
}
