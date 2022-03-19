part of theater_task.task;

abstract class TaskEvent {}

class TaskInitialized extends TaskEvent {
  final SendPort isolateSendPort;

  TaskInitialized(this.isolateSendPort);
}

class TaskStarted extends TaskEvent {}

class TaskCompleted extends TaskEvent {
  final dynamic result;

  TaskCompleted(this.result);
}
