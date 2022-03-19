part of theater_task.core;

class ErrorSubscription {
  bool _isCancel = false;

  bool get isCancel => _isCancel;

  final StreamSubscription _subscription;

  ErrorSubscription(StreamSubscription subscription)
      : _subscription = subscription;

  void cancel() {
    _subscription.cancel();

    _isCancel = true;
  }
}
