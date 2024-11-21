import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';
import 'package:scribettefix/feature/notes/domain/entities/note.dart';

class NotesRepository extends FirebaseRepository {
  final dbHelper = DatabaseHelper();

  Future<List<Note>> fetch() async {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return <Note>[];
    }

    final snapshot = await collection(Collection.users)
        .doc(currentUser.email)
        .collection(Collection.notes.name)
        .get();

    if (snapshot.size == 0) {
      return <Note>[];
    }

    return List<Note>.from(
      snapshot.docs.map(
        (doc) {
          final json = doc.data();
          return Note.fromJson(json);
        },
      ),
    );
  }

  Future<void> syncNotesWithSQLite() async {
    List<Note> notes = await fetch();

    if (notes.isNotEmpty) {
      final dbHelper = DatabaseHelper();

      for (var note in notes) {
        String notebookName = note.notebook;
        String title = note.title;
        String content = note.content;
        String date = note.date;

        bool notebookExists = await dbHelper.notebookExists(notebookName);

        if (!notebookExists) {
          await dbHelper.insertNotebook(notebookName);
        }

        var notebookId = await dbHelper.getNotebookIdByName(notebookName);

        bool noteAlreadyExists = await dbHelper.noteExists(title);

        if (!noteAlreadyExists) {
          await dbHelper.insertFile(
            notebookId: notebookId!,
            title: title,
            content: content,
            date: date,
          );
        } else {}
      }
    } else {}
  }

  Future<void> add({
    required String content,
    required String notebook,
    required String title,
    required String date,
  }) async {
    String? email = auth.currentUser?.email;

    if (email != null) {
      await FirebaseFirestore.instance
          .collection(Collection.users.name)
          .doc(email)
          .collection(Collection.notes.name)
          .add({
        'notebook': notebook,
        'title': title,
        'content': content,
        'date': date,
      });
    } else {}
  }

  Future<void> moveFolder(FileEntity file, Notebook notebook) async {
    await dbHelper.moveNotebook(file.title, notebook.id);

    final email = auth.currentUser?.email;
    final notesCollection = firestore
        .collection(
          'users',
        )
        .doc(email)
        .collection('notes');

    final querySnapshot = await notesCollection
        .where('title', isEqualTo: file.title)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot noteDoc = querySnapshot.docs.first;

      await notesCollection.doc(noteDoc.id).update({
        'notebook': notebook.name,
      });
    }
  }

  Future<void> delete(String title) async {
    await dbHelper.deleteNoteByTitle(title);

    final email = auth.currentUser?.email;

    if (email != null) {
      final notesCollection = firestore
          .collection(
            "users",
          )
          .doc(email)
          .collection("notes");
      final recordingsSnapshot = await notesCollection.get();

      if (recordingsSnapshot.docs.isNotEmpty) {
        for (final document in recordingsSnapshot.docs) {
          String dbTitle = document.get("title").trim().replaceAll("\n", "");

          if (title == dbTitle) {
            await notesCollection.doc(document.id).delete();
          }
        }
      }
    }
  }
}
