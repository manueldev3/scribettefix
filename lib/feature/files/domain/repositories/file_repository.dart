import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:scribettefix/core/repositories/database_repository.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';

class FileRepository extends DatabaseRepository {
  Future<Either<String, List<FileEntity>>> getFiles(int notebookId) async {
    try {
      final files = await db.getFiles(notebookId);

      return right(
        List<FileEntity>.from(
          files.map(
            (fileJson) {
              return FileEntity.fromJson(fileJson);
            },
          ),
        ),
      );
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
