part of theater_task.core;

class Subscription {
  bool _isCancel = false;

  bool get isCancel => _isCancel;

  final StreamSubscription _subscription;

  Subscription(StreamSubscription subscription) : _subscription = subscription;

  void cancel() {
    _subscription.cancel();

    _isCancel = true;
  }
}
