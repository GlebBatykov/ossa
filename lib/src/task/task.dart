part of ossa.task;

typedef TaskActionCallback<T> = FutureOr<T> Function(TaskContext);

typedef TaskOnErrorCallback = void Function(TaskError);

typedef TaskOnDoneCallback<T> = void Function(T);

/// Used to create a task to run in another isolate.
class Task<T> {
  final StreamController<TaskError> _errorController =
      StreamController.broadcast();

  final IsolateSupervisor _isolateSupervisor;

  final TaskType _type;

  final TaskOnDoneCallback<T>? _onDone;

  StreamController<T?>? _resultController;

  TaskStatus _status = TaskStatus.notInitialized;

  bool _isStarted = false;

  T? _result;

  /// Current status of task.
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

    _errorController.stream.listen(onError != null
        ? (error) {
            if (_resultController == null) {
              _isStarted = false;
              _status = TaskStatus.waitingToRun;
            }

            onError(error);
          }
        : (event) async {
            await dispose();
          });

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

    if (_type == TaskType.oneShot) {
      await dispose();
    } else {
      _isStarted = false;
      _status = TaskStatus.waitingToRun;
    }

    _resultController?.sink.add(_result);
  }

  /// Creates task.
  ///
  /// Once created, it initializes the task, runs it, and returns an instance of it.
  ///
  /// Changes the status of the task to [TaskStatus.running].
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

  /// Initializes task.
  ///
  /// Creates a task isolate during initialization.
  ///
  /// Changes the status of the task to [TaskStatus.waitingToRun].
  Future<void> initialize() async {
    if (_status == TaskStatus.notInitialized) {
      await _isolateSupervisor.initialize();

      _status = TaskStatus.waitingToRun;
    } else {
      throw TaskException(message: 'Task was initialized.');
    }
  }

  /// Starts the execution of a task.
  ///
  /// [data] - passes this data to the task, it can be accessed using the task context.
  /// [onError] - error handler that is used in this task execution.
  ///
  /// Changes the status of the task to [TaskStatus.running].
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

  /// Pauses task.
  ///
  /// Pauses task isolate and changes the status of the task to [TaskStatus.paused].
  Future<void> pause() async {
    if (_status == TaskStatus.running) {
      await _isolateSupervisor.pause();

      _status = TaskStatus.paused;
    } else {
      throw TaskException(message: 'Task is not initialized.');
    }
  }

  /// Resumes task.
  ///
  /// Resumes task isolate and changes the status of the task to [TaskStatus.running]
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

  /// Kills task.
  ///
  /// Kills task isolate and changes the status of the task to [TaskStatus.notInitialized].
  Future<void> kill() async {
    if ([TaskStatus.running, TaskStatus.waitingToRun, TaskStatus.paused]
        .contains(_status)) {
      await _isolateSupervisor.kill();

      _isStarted = false;

      _status = TaskStatus.notInitialized;
    } else {
      throw TaskException(message: 'Task is not initialized.');
    }
  }

  /// Return result of task.
  ///
  /// If task is running, will wait for the result from the isolate, and then return it.
  ///
  /// If task has already been completed at the time of calling the result method and has not been started again, it will return the result from the previous task run.
  Future<T> result() async {
    if (_isStarted) {
      _resultController = StreamController<T>();

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

  /// Disposes task.
  ///
  /// Disposes task. Kills task isolate, closes all StreamControllers-s.
  ///
  /// Further use of this task instance is not possible.
  Future<void> dispose() async {
    if (_status != TaskStatus.disposed) {
      await _errorController.close();
      await _isolateSupervisor.dispose();

      _status = TaskStatus.disposed;
      _isStarted = false;
    } else {
      throw TaskException(message: 'Task was disposed.');
    }
  }
}
