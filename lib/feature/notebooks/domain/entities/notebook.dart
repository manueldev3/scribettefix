import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';

part 'notebook.freezed.dart';
part 'notebook.g.dart';

@freezed
class Notebook with _$Notebook {
  factory Notebook({
    required int id,
    required String name,
    required List<FileEntity> files,
  }) = _Notebook;

  factory Notebook.fromJson(Map<String, dynamic> json) =>
      _$NotebookFromJson(json);
}
