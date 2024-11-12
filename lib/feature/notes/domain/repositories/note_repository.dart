import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';
import 'package:scribettefix/feature/notes/domain/entities/note.dart';

class NotesRepository extends FirebaseRepository {
  Future<Either<String, List<Note>>> getNotes() async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        return const Right(<Note>[]);
      }

      final snapshot = await collection(Collection.users)
          .doc(currentUser.email)
          .collection(Collection.notes.name)
          .get();

      if (snapshot.size == 0) {
        return const Right(<Note>[]);
      }

      return Right(
        List<Note>.from(
          snapshot.docs.map(
            (doc) {
              final json = doc.data();
              return Note.fromJson(json);
            },
          ),
        ),
      );
    } on FirebaseException catch (error) {
      log(
        error.code,
        error: error.message,
        stackTrace: error.stackTrace,
      );
      return Left(error.toString());
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
