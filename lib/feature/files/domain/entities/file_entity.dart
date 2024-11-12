import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_entity.freezed.dart';
part 'file_entity.g.dart';

@freezed
class FileEntity with _$FileEntity {
  factory FileEntity({
    required String title,
    required String content,
    required String date,
    required int notebookId,
  }) = _FileEntity;

  factory FileEntity.fromJson(Map<String, dynamic> json) =>
      _$FileEntityFromJson(json);
}
