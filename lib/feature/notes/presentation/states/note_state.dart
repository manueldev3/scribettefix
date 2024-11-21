import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/notes/domain/entities/note.dart';
import 'package:scribettefix/feature/notes/domain/repositories/note_repository.dart';

part 'note_state.g.dart';

@riverpod
class NoteState extends _$NoteState {
  final repository = NotesRepository();

  @override
  FutureOr<List<Note>> build() async {
    return repository.fetch();
  }

  Future<void> add({
    required String content,
    required String notebook,
    required String title,
    required String date,
  }) async {
    state = const AsyncLoading();
    await repository.add(
      content: content,
      notebook: notebook,
      title: title,
      date: date,
    );
    state = await AsyncValue.guard(repository.fetch);
  }

  Future<void> syncNotesWithSQLite() async {
    await repository.syncNotesWithSQLite();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.fetch);
  }
}
