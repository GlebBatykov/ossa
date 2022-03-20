part of theater_task.task;

typedef TaskActionCallback<T> = T Function(TaskContext);

typedef TaskOnErrorCallback = void Function(TaskError);

typedef TaskOnDoneCallback<T> = void Function(T);

///
class Task<T> {
  final StreamController<TaskError> _errorController =
      StreamController.broadcast();

  StreamController<T?>? _resultController;

  final IsolateSupervisor _isolateSupervisor;

  final TaskType _type;

  final TaskOnDoneCallback<T>? _onDone;

  TaskStatus _status = TaskStatus.notInitialized;

  bool _isStarted = false;

  T? _result;

  ///
  TaskStatus get status => _status;

  Task(TaskActionCallback<T> action,
      {TaskOnErrorCallback? onError,
      TaskOnDoneCallback<T>? onDone,
      TaskType type = TaskType.oneShot})
      : _isolateSupervisor = IsolateSupervisor(action),
        _type = type,
        _onDone = onDone {
    _isolateSupervisor.errors.listen((error) {
      _errorController.add(TaskError(error.object, error.stackTrace));
    });

    if (onError != null) {
      _errorController.stream.listen(onError);
    }

    _isolateSupervisor.messages.listen((event) {
      if (event is TaskCompleted) {
        _handleEvent(event);
      }
    });
  }

  void _handleEvent(TaskEvent event) async {
    if (event is TaskCompleted) {
      _handleTaskCompletedEvent(event);
    }
  }

  void _handleTaskCompletedEvent(TaskCompleted event) async {
    _result = event.result as T;

    _onDone?.call(_result!);
    _resultController?.sink.add(_result);

    if (_type == TaskType.oneShot) {
      await dispose();
    } else {
      _isStarted = false;
      _status = TaskStatus.waitingToRun;
    }
  }

  ///
  static Future<Task<T>> run<T>(TaskActionCallback<T> action,
      {TaskOnErrorCallback? onError,
      TaskOnDoneCallback<T>? onDone,
      Map<String, dynamic>? data,
      TaskType type = TaskType.oneShot}) async {
    var task = Task<T>(action, onError: onError, onDone: onDone, type: type);

    await task.initialize();
    await task.start(data: data);

    return task;
  }

  ///
  Future<void> initialize() async {
    if (_status == TaskStatus.notInitialized) {
      await _isolateSupervisor.initialize();

      _status = TaskStatus.waitingToRun;
    } else {
      throw TaskException(message: '');
    }
  }

  ///
  Future<void> start(
      {Map<String, dynamic>? data, void Function(TaskError)? onError}) async {
    if (_status == TaskStatus.waitingToRun) {
      Subscription? onErrorSubscription;

      if (onError != null) {
        onErrorSubscription =
            Subscription(_errorController.stream.listen((error) {
          onError(error);

          onErrorSubscription!.cancel();
        }));
      }

      await _isolateSupervisor.start(data ?? {});

      if (onErrorSubscription != null && !onErrorSubscription.isCancel) {
        Future(() async {
          if (!onErrorSubscription!.isCancel) {
            await _isolateSupervisor.messages
                .firstWhere((element) => element is TaskCompleted);

            onErrorSubscription.cancel();
          }
        });
      }

      _status = TaskStatus.running;
      _isStarted = true;
    } else {
      throw TaskException(
          message:
              'Task is not waiting to run. Current status is ' + _status.name);
    }
  }

  ///
  Future<void> pause() async {
    if (_status == TaskStatus.running) {
      await _isolateSupervisor.pause();

      _status = TaskStatus.paused;
    } else {
      throw TaskException(message: 'Task is not initialized.');
    }
  }

  ///
  Future<void> resume() async {
    if (_status == TaskStatus.paused) {
      await _isolateSupervisor.resume();

      if (_isStarted) {
        _status = TaskStatus.running;
      } else {
        _status = TaskStatus.waitingToRun;
      }
    } else {
      throw TaskException(message: 'Task is not paused.');
    }
  }

  ///
  Future<void> kill() async {
    if ([TaskStatus.running, TaskStatus.waitingToRun, TaskStatus.paused]
        .contains(_status)) {
      await _isolateSupervisor.kill();

      _isStarted = false;
    } else {
      throw TaskException(message: 'Task is not initialized.');
    }
  }

  ///
  Future<T> result() async {
    if (_isStarted) {
      _resultController = StreamController();

      StreamController streamController = StreamController();

      late Subscription onErrorSubscription;

      onErrorSubscription =
          Subscription(_errorController.stream.listen((error) {
        streamController.sink.add(error);

        onErrorSubscription.cancel();
      }));

      var onResultSubscription =
          Subscription(_resultController!.stream.listen((result) {
        streamController.sink.add(result);
      }));

      var result = await streamController.stream.first;

      await streamController.close();
      await _resultController!.close();
      onResultSubscription.cancel();

      if (result is TaskError) {
        throw TaskCompleteException(result.object, result.stackTrace);
      } else {
        onErrorSubscription.cancel();

        return result;
      }
    } else if (!_isStarted && _result != null) {
      return _result!;
    } else {
      throw TaskException(message: 'Task is not started.');
    }
  }

  ///
  Future<void> dispose() async {
    if (_status != TaskStatus.disposed) {
      await _errorController.close();
      await _isolateSupervisor.dispose();

      _status = TaskStatus.disposed;
      _isStarted = false;
    } else {
      throw TaskException(message: 'Task ');
    }
  }
}
