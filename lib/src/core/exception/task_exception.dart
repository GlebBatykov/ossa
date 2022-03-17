part of theater_task.core;

class TaskException implements Exception {
  final String? message;

  TaskException([this.message]);

  @override
  String toString() {
    if (message != null) {
      return runtimeType.toString() + ': ' + message!;
    } else {
      return super.toString();
    }
  }
}
