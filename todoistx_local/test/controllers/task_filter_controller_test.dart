import 'package:flutter_test/flutter_test.dart';
import 'package:todoistx_local/src/features/tasks/presentation/controllers/task_filter_controller.dart';

void main() {
  group('TaskFilterController', () {
    test('initial state is correct', () {
      final controller = TaskFilterController();
      expect(controller.state, const TaskFilterState());
    });

    test('setProject updates the state correctly', () {
      final controller = TaskFilterController();
      controller.setProject('p1');
      expect(controller.state, const TaskFilterState(projectId: 'p1'));
    });

    test('setTag updates the state correctly', () {
      final controller = TaskFilterController();
      controller.setTag('t1');
      expect(controller.state, const TaskFilterState(tagId: 't1'));
    });

    test('setPriority updates the state correctly', () {
      final controller = TaskFilterController();
      controller.setPriority(2);
      expect(controller.state, const TaskFilterState(priority: 2));
    });

    test('setGroupBy updates the state correctly', () {
      final controller = TaskFilterController();
      controller.setGroupBy(GroupBy.project);
      expect(controller.state, const TaskFilterState(groupBy: GroupBy.project));
    });

    test('clearFilters resets the state', () {
      final controller = TaskFilterController();
      controller.setProject('p1');
      controller.setGroupBy(GroupBy.priority);
      controller.clearFilters();
      expect(controller.state, const TaskFilterState());
    });
  });
}
