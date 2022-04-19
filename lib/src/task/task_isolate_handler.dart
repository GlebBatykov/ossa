part of ossa.task;

class TaskIsolateHandler {
  final IsolateContext _isolateContext;

  final TaskActionCallback _action;

  TaskIsolateHandler(
      IsolateContext isolateContext, dynamic Function(TaskContext) action)
      : _isolateContext = isolateContext,
        _action = action {
    _isolateContext.actions.listen(_handleAction);
  }

  void start(TaskStart action) async {
    _isolateContext.supervisorMessagePort.send(TaskStarted());

    var context = TaskContext(action.data);

    var result = await _action.call(context);

    _isolateContext.supervisorMessagePort.send(TaskCompleted(result));
  }

  void _handleAction(TaskAction action) {
    if (action is TaskStart) {
      start(action);
    }
  }
}
