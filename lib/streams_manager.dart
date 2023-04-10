import 'dart:async';

class StreamManager {
  final List<StreamSubscription> _subscriptions = [];

  StreamSubscription<T> listen<T>(Stream<T> stream, void Function(T) onData,
      {Function onError, void Function() onDone, bool cancelOnError = false}) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    _subscriptions.add(subscription);
    return subscription;
  }

  void cancel(StreamSubscription subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }

  void cancelAll() {
    _subscriptions.forEach((subscription) => subscription.cancel());
    _subscriptions.clear();
  }
}
