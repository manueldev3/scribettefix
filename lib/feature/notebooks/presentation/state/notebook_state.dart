import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';
import 'package:scribettefix/feature/notebooks/domain/repositories/notebooks_repository.dart';

part 'notebook_state.g.dart';

@riverpod
class NotebooksState extends _$NotebooksState {
  final repository = NotebooksRepository();

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
}
