part of theater_task.isolate;

class IsolateError {
  final Object object;

  final StackTrace stackTrace;

  IsolateError(this.object, this.stackTrace);
}
