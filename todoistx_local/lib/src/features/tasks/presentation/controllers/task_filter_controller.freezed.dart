// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_filter_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$TaskFilterState {
  String? get projectId => throw _privateConstructorUsedError;
  String? get tagId => throw _privateConstructorUsedError;
  int? get priority => throw _privateConstructorUsedError;
  GroupBy get groupBy => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TaskFilterStateCopyWith<TaskFilterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskFilterStateCopyWith<$Res> {
  factory $TaskFilterStateCopyWith(
          TaskFilterState value, $Res Function(TaskFilterState) then) =
      _$TaskFilterStateCopyWithImpl<$Res, TaskFilterState>;
  @useResult
  $Res call({String? projectId, String? tagId, int? priority, GroupBy groupBy});
}

/// @nodoc
class _$TaskFilterStateCopyWithImpl<$Res, $Val extends TaskFilterState>
    implements $TaskFilterStateCopyWith<$Res> {
  _$TaskFilterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = freezed,
    Object? tagId = freezed,
    Object? priority = freezed,
    Object? groupBy = null,
  }) {
    return _then(_value.copyWith(
      projectId: freezed == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagId: freezed == tagId
          ? _value.tagId
          : tagId // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
      groupBy: null == groupBy
          ? _value.groupBy
          : groupBy // ignore: cast_nullable_to_non_nullable
              as GroupBy,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_TaskFilterStateCopyWith<$Res>
    implements $TaskFilterStateCopyWith<$Res> {
  factory _$$_TaskFilterStateCopyWith(
          _$_TaskFilterState value, $Res Function(_$_TaskFilterState) then) =
      __$$_TaskFilterStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? projectId, String? tagId, int? priority, GroupBy groupBy});
}

/// @nodoc
class __$$_TaskFilterStateCopyWithImpl<$Res>
    extends _$TaskFilterStateCopyWithImpl<$Res, _$_TaskFilterState>
    implements _$$_TaskFilterStateCopyWith<$Res> {
  __$$_TaskFilterStateCopyWithImpl(
      _$_TaskFilterState _value, $Res Function(_$_TaskFilterState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = freezed,
    Object? tagId = freezed,
    Object? priority = freezed,
    Object? groupBy = null,
  }) {
    return _then(_$_TaskFilterState(
      projectId: freezed == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagId: freezed == tagId
          ? _value.tagId
          : tagId // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
      groupBy: null == groupBy
          ? _value.groupBy
          : groupBy // ignore: cast_nullable_to_non_nullable
              as GroupBy,
    ));
  }
}

/// @nodoc

class _$_TaskFilterState implements _TaskFilterState {
  const _$_TaskFilterState(
      {this.projectId,
      this.tagId,
      this.priority,
      this.groupBy = GroupBy.none});

  @override
  final String? projectId;
  @override
  final String? tagId;
  @override
  final int? priority;
  @override
  @JsonKey()
  final GroupBy groupBy;

  @override
  String toString() {
    return 'TaskFilterState(projectId: $projectId, tagId: $tagId, priority: $priority, groupBy: $groupBy)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_TaskFilterState &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.tagId, tagId) || other.tagId == tagId) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.groupBy, groupBy) || other.groupBy == groupBy));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, projectId, tagId, priority, groupBy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_TaskFilterStateCopyWith<_$_TaskFilterState> get copyWith =>
      __$$_TaskFilterStateCopyWithImpl<_$_TaskFilterState>(this, _$identity);
}

abstract class _TaskFilterState implements TaskFilterState {
  const factory _TaskFilterState(
      {final String? projectId,
      final String? tagId,
      final int? priority,
      final GroupBy groupBy}) = _$_TaskFilterState;

  @override
  String? get projectId;
  @override
  String? get tagId;
  @override
  int? get priority;
  @override
  GroupBy get groupBy;
  @override
  @JsonKey(ignore: true)
  _$$_TaskFilterStateCopyWith<_$_TaskFilterState> get copyWith =>
      throw _privateConstructorUsedError;
}
