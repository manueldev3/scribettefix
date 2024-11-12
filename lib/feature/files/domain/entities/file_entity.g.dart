// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileEntityImpl _$$FileEntityImplFromJson(Map<String, dynamic> json) =>
    _$FileEntityImpl(
      title: json['title'] as String,
      content: json['content'] as String,
      date: json['date'] as String,
      notebookId: (json['notebookId'] as num).toInt(),
    );

Map<String, dynamic> _$$FileEntityImplToJson(_$FileEntityImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'date': instance.date,
      'notebookId': instance.notebookId,
    };
