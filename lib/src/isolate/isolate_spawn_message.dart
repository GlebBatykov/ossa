part of ossa.isolate;

class IsolateSpawnMessage {
  final SendPort supervisorMessagePort;

  final SendPort supervisorErrorPort;

  final dynamic Function(TaskContext) action;

  IsolateSpawnMessage(
      this.supervisorMessagePort, this.supervisorErrorPort, this.action);
}
