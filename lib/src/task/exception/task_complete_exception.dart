part of ossa.task;

class TaskCompleteException implements Exception {
  final Object object;

  final StackTrace stackTrace;

  TaskCompleteException(this.object, this.stackTrace);

  @override
  String toString() {
    return object.toString() + '\n' + stackTrace.toString();
  }
}
