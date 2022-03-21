part of ossa.task;

///
class TaskContext {
  final Map<String, dynamic> _data;

  TaskContext(Map<String, dynamic> data) : _data = data;

  ///
  bool isExist(String instanceName) {
    return _data.keys.contains(instanceName);
  }

  /// Get instanse of type [T] by name [instanceName].
  ///
  /// If instanse is not exist in store an exception will be thrown.
  T get<T>(String instanceName) {
    dynamic object;

    try {
      object = _data[instanceName];

      return object as T;
    } on TypeError {
      throw TaskContextException(
          message: 'failed to convert type [' +
              object.runtimeType.toString() +
              '] to [' +
              T.toString() +
              '].');
    }
  }

  /// Get instanse of type [T] by name [instanceName].
  ///
  /// If instanse is not exist return null.
  T? tryGet<T>(String instanceName) {
    var object = _data[instanceName];

    return object != null ? object as T : object;
  }
}
