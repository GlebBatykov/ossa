part of ossa.task;

class TaskError {
  final Object object;

  final StackTrace stackTrace;

  TaskError(this.object, this.stackTrace);
}
