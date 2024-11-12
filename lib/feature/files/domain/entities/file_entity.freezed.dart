// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileEntity _$FileEntityFromJson(Map<String, dynamic> json) {
  return _FileEntity.fromJson(json);
}

/// @nodoc
mixin _$FileEntity {
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  int get notebookId => throw _privateConstructorUsedError;

  /// Serializes this FileEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileEntityCopyWith<FileEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileEntityCopyWith<$Res> {
  factory $FileEntityCopyWith(
          FileEntity value, $Res Function(FileEntity) then) =
      _$FileEntityCopyWithImpl<$Res, FileEntity>;
  @useResult
  $Res call({String title, String content, String date, int notebookId});
}

/// @nodoc
class _$FileEntityCopyWithImpl<$Res, $Val extends FileEntity>
    implements $FileEntityCopyWith<$Res> {
  _$FileEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = null,
    Object? date = null,
    Object? notebookId = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      notebookId: null == notebookId
          ? _value.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileEntityImplCopyWith<$Res>
    implements $FileEntityCopyWith<$Res> {
  factory _$$FileEntityImplCopyWith(
          _$FileEntityImpl value, $Res Function(_$FileEntityImpl) then) =
      __$$FileEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String content, String date, int notebookId});
}

/// @nodoc
class __$$FileEntityImplCopyWithImpl<$Res>
    extends _$FileEntityCopyWithImpl<$Res, _$FileEntityImpl>
    implements _$$FileEntityImplCopyWith<$Res> {
  __$$FileEntityImplCopyWithImpl(
      _$FileEntityImpl _value, $Res Function(_$FileEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = null,
    Object? date = null,
    Object? notebookId = null,
  }) {
    return _then(_$FileEntityImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      notebookId: null == notebookId
          ? _value.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileEntityImpl implements _FileEntity {
  _$FileEntityImpl(
      {required this.title,
      required this.content,
      required this.date,
      required this.notebookId});

  factory _$FileEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileEntityImplFromJson(json);

  @override
  final String title;
  @override
  final String content;
  @override
  final String date;
  @override
  final int notebookId;

  @override
  String toString() {
    return 'FileEntity(title: $title, content: $content, date: $date, notebookId: $notebookId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileEntityImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.notebookId, notebookId) ||
                other.notebookId == notebookId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, content, date, notebookId);

  /// Create a copy of FileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileEntityImplCopyWith<_$FileEntityImpl> get copyWith =>
      __$$FileEntityImplCopyWithImpl<_$FileEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileEntityImplToJson(
      this,
    );
  }
}

abstract class _FileEntity implements FileEntity {
  factory _FileEntity(
      {required final String title,
      required final String content,
      required final String date,
      required final int notebookId}) = _$FileEntityImpl;

  factory _FileEntity.fromJson(Map<String, dynamic> json) =
      _$FileEntityImpl.fromJson;

  @override
  String get title;
  @override
  String get content;
  @override
  String get date;
  @override
  int get notebookId;

  /// Create a copy of FileEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileEntityImplCopyWith<_$FileEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
