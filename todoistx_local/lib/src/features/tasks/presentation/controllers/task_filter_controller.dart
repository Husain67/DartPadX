import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_filter_controller.freezed.dart';

enum GroupBy { none, project, priority, dueDate }

@freezed
class TaskFilterState with _$TaskFilterState {
  const factory TaskFilterState({
    String? projectId,
    String? tagId,
    int? priority,
    @Default(GroupBy.none) GroupBy groupBy,
  }) = _TaskFilterState;
}

class TaskFilterController extends StateNotifier<TaskFilterState> {
  TaskFilterController() : super(const TaskFilterState());

  void setProject(String? projectId) {
    state = state.copyWith(projectId: projectId);
  }

  void setTag(String? tagId) {
    state = state.copyWith(tagId: tagId);
  }

  void setPriority(int? priority) {
    state = state.copyWith(priority: priority);
  }

  void setGroupBy(GroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void clearFilters() {
    state = const TaskFilterState();
  }
}

final taskFilterProvider = StateNotifierProvider<TaskFilterController, TaskFilterState>((ref) {
  return TaskFilterController();
});
