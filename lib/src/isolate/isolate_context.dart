part of ossa.isolate;

class IsolateContext {
  final ReceivePort _receivePort;

  final StreamController<TaskAction> _actionController =
      StreamController.broadcast();

  final SendPort supervisorErrorPort;

  final Stream _receiveStream;

  final SendPort supervisorMessagePort;

  Stream<TaskAction> get actions => _actionController.stream;

  IsolateContext(ReceivePort receivePort, this.supervisorMessagePort,
      this.supervisorErrorPort)
      : _receivePort = receivePort,
        _receiveStream = receivePort.asBroadcastStream() {
    _receiveStream.listen((event) {
      if (event is TaskAction) {
        _actionController.sink.add(event);
      }
    });
  }

  Future<void> dispose() async {
    await _actionController.close();
    _receivePort.close();
  }
}
