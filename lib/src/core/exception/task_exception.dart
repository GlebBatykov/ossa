part of theater_task.core;

class TheaterTaskException implements Exception {
  final String? message;

  TheaterTaskException([this.message]);

  @override
  String toString() {
    if (message != null) {
      return runtimeType.toString() + ': ' + message!;
    } else {
      return super.toString();
    }
  }
}
