part of ossa.isolate;

class IsolateSupervisor {
  final StreamController<TaskEvent> _messageController =
      StreamController.broadcast();

  final StreamController<IsolateError> _errorController =
      StreamController.broadcast();

  final StreamController<TaskEvent> _eventController =
      StreamController.broadcast();

  Isolate? _isolate;

  final ReceivePort _receivePort = ReceivePort();

  final ReceivePort _errorReceivePort = ReceivePort();

  late final Stream _receiveStream;

  SendPort? _isolateSendPort;

  final dynamic Function(TaskContext) _action;

  final Queue _messageQueue = Queue();

  bool _isInitialized = false;

  bool _isPaused = false;

  bool _isDisposed = false;

  Capability? _resumeCapability;

  bool get isInitialized => _isInitialized;

  bool get isPaused => _isPaused;

  bool get isDisposed => _isDisposed;

  Stream<IsolateError> get errors => _errorController.stream;

  Stream<TaskEvent> get messages => _messageController.stream;

  IsolateSupervisor(dynamic Function(TaskContext) action,
      {void Function(IsolateError)? onError})
      : _action = action {
    if (onError != null) {
      _errorController.stream.listen(onError);
    }

    _receiveStream = _receivePort.asBroadcastStream();

    _receiveStream.listen((message) => _handleMessage(message));

    _errorReceivePort.listen((message) {
      if (message is IsolateError) {
        _errorController.sink.add(message);
      }
    });

    _eventController.stream.listen((event) {
      if (event is TaskCompleted) {
        _messageController.sink.add(event);
      }
    });
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      var spawnMessage = IsolateSpawnMessage(
          _receivePort.sendPort, _errorReceivePort.sendPort, _action);

      _isolate = await Isolate.spawn(_isolateEntryPoint, spawnMessage,
          errorsAreFatal: false);

      var event = await _eventController.stream
              .firstWhere((element) => element is TaskInitialized)
          as TaskInitialized;

      _isolateSendPort = event.isolateSendPort;
      _isInitialized = true;
      _sendMessageQueue();
    }
  }

  Future<void> start(Map<String, dynamic> data) async {
    _isolateSendPort!.send(TaskStart(data));

    await _eventController.stream
        .firstWhere((element) => element is TaskStarted);
  }

  void _handleMessage(dynamic message) {
    if (message is TaskEvent) {
      _eventController.sink.add(message);
    }
  }

  static void _isolateEntryPoint(IsolateSpawnMessage message) {
    runZonedGuarded(() async {
      var receivePort = ReceivePort();

      try {
        var context = IsolateContext(receivePort, message.supervisorMessagePort,
            message.supervisorErrorPort);

        TaskIsolateHandler(context, message.action);
      } catch (_) {
        rethrow;
      } finally {
        message.supervisorMessagePort
            .send(TaskInitialized(receivePort.sendPort));
      }
    }, (object, stackTrace) {
      message.supervisorErrorPort.send(IsolateError(object, stackTrace));
    });
  }

  Future<void> pause() async {
    if (_isolate != null && _isInitialized && !_isPaused) {
      _resumeCapability = _isolate!.pause(_isolate!.pauseCapability);

      _isPaused = true;
    }
  }

  Future<void> resume() async {
    if (_isolate != null && _isPaused) {
      _isolate!.resume(_resumeCapability!);

      _isPaused = false;
    }
  }

  Future<void> kill() async {
    if (_isInitialized) {
      _isolate?.kill(priority: Isolate.immediate);

      _isolate = null;

      _isInitialized = false;
      _isPaused = false;
    }
  }

  /// Dispoces all resource, streams for [IsolateSupervisor]. After dispoce you can't use listening for [IsolateSupervisor] messages.
  Future<void> dispose() async {
    _receivePort.close();
    _errorReceivePort.close();

    await _messageController.close();
    await _errorController.close();
    await _eventController.close();

    _messageQueue.clear();

    _isDisposed = true;
  }

  /// Sends message to [Isolate] in [IsolateSupervisor].
  void send(message) {
    if (_isInitialized) {
      _isolateSendPort?.send(message);
    } else {
      _messageQueue.add(message);
    }
  }

  /// Sends all [IsolateMessage] messages in [_messageQueue] to isolate
  void _sendMessageQueue() {
    while (_messageQueue.isNotEmpty) {
      var message = _messageQueue.removeFirst();

      send(message);
    }
  }
}
