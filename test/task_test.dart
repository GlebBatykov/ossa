import 'dart:async';

import 'package:ossa/ossa.dart';
import 'package:test/test.dart';

void main() {
  group('task', () {
    test(
        '.run(). Create instance of task using run() method and wait result from him.',
        () async {
      var task = await Task.run<int>((context) => 25);

      expect(task.status, TaskStatus.running);
      expect(await task.result(), 25);
      expect(task.status, TaskStatus.disposed);
    });

    test(
        '.initialize(). Create instance of task without run() method, initializes him.',
        () async {
      var task = Task((context) {});

      expect(task.status, TaskStatus.notInitialized);

      await task.initialize();

      expect(task.status, TaskStatus.waitingToRun);

      await task.dispose();

      expect(task.status, TaskStatus.disposed);
    });

    test(
        '.start(). Creates instance of task without run() method, initializes, starts him.',
        () async {
      var task = Task<String>((context) => 'Hello, from task!');

      expect(task.status, TaskStatus.notInitialized);

      await task.initialize();

      expect(task.status, TaskStatus.waitingToRun);

      await task.start();

      expect(task.status, TaskStatus.running);
      expect(await task.result(), 'Hello, from task!');
      expect(task.status, TaskStatus.disposed);
    });

    test('.pause(). Create instance of task using run() method and pauses him.',
        () async {
      var task = await Task.run((context) {});

      expect(task.status, TaskStatus.running);

      await task.pause();

      expect(task.status, TaskStatus.paused);

      await task.dispose();

      expect(task.status, TaskStatus.disposed);
    });

    test(
        '.resume(). Create instance of task using run() method, pause and resume him.',
        () async {
      var task = await Task.run<int>((context) => 100);

      expect(task.status, TaskStatus.running);

      await task.pause();

      expect(task.status, TaskStatus.paused);

      await task.resume();

      expect(task.status, TaskStatus.running);
      expect(await task.result(), 100);
      expect(task.status, TaskStatus.disposed);
    });

    test(
        '.dispose(). Create instanse of task without run() method, dispose him.',
        () async {
      var task = Task((context) {});

      expect(task.status, TaskStatus.notInitialized);

      await task.dispose();

      expect(task.status, TaskStatus.disposed);
    });

    test('passing data to task.', () async {
      var data = 100;

      var task = await Task.run<int>((context) => context.get<int>('data') * 5,
          data: {'data': data});

      expect(task.status, TaskStatus.running);
      expect(await task.result(), 500);
      expect(task.status, TaskStatus.disposed);
    });

    test('handle exception using onError handler.', () async {
      var controller = StreamController<Object>();

      await Task.run<int>((context) {
        throw FormatException();
      }, onError: (object) {
        controller.sink.add(object.object);
      });

      var event = await controller.stream.first;

      expect(event, isA<FormatException>());

      await controller.close();
    }, timeout: Timeout(Duration(seconds: 1)));

    test(
        'handle exception without onError handler, using result method and try/catch.',
        () async {
      late Object error;

      var task = await Task.run((context) {
        throw FormatException();
      });

      try {
        await task.result();
      } catch (object) {
        if (object is TaskCompleteException) {
          error = object.object;
        }
      }

      expect(error, isA<FormatException>());
    });

    test('handle result using onDone handler.', () async {
      var controller = StreamController<int>();

      await Task.run<int>((context) => 21, onDone: (value) {
        controller.sink.add(value);
      });

      var event = await controller.stream.first;

      expect(event, 21);

      await controller.close();
    });

    test('get result using result() method.', () async {
      var task = await Task.run<double>((context) => 2 * 5);

      expect(await task.result(), 10);

      expect(task.status, TaskStatus.disposed);
    });
  });
}
