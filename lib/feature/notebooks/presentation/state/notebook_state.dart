import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';
import 'package:scribettefix/feature/notebooks/domain/repositories/notebooks_repository.dart';
import 'package:scribettefix/feature/notes/domain/repositories/note_repository.dart';

part 'notebook_state.g.dart';

@riverpod
class NotebooksState extends _$NotebooksState {
  final repository = NotebooksRepository();
  final noteRepository = NotesRepository();

  Future<List<Notebook>> _fetch() async {
    final result = await repository.getNotebooks();
    return result.fold(
      (_) => <Notebook>[],
      (res) => res,
    );
  }

  @override
  FutureOr<List<Notebook>> build() {
    return _fetch();
  }

  Future<void> insertName(String name) async {
    state = const AsyncLoading();
    await repository.insertName(name);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> rename(
    String notebookName, {
    required String title,
  }) async {
    state = const AsyncLoading();
    await repository.rename(
      notebookName,
      title: title,
    );
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> moveToFolder(FileEntity file, Notebook notebook) async {
    state = const AsyncLoading();
    await noteRepository.moveFolder(file, notebook);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> delete(String title) async {
    state = const AsyncLoading();
    await repository.delete(title);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> deleteNote(FileEntity file) async {
    state = const AsyncLoading();
    await noteRepository.delete(file.title);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
