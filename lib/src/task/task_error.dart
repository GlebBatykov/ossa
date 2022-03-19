part of theater_task.task;

class TaskError {
  final Object object;

  final StackTrace stackTrace;

  TaskError(this.object, this.stackTrace);
}
