</div>

<div align="center">

**Languages:**
  
[![English](https://img.shields.io/badge/Language-English-blue?style=?style=flat-square)](README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blue?style=?style=flat-square)](README.ru.md)

</div>

- [Introduction](#introduction)
- [About Ossa](#about-ossa)
- [Installing](#installing)
- [What is Task](#what-is-task)
  - [Task types](#task-types)
  - [Task run](#task-run)
  - [Get result](#get-result)
  - [Passing data to task](#passing-data-to-task)
  - [Task status](#task-status)
- [Error handling](#error-handling)

# Introduction

Earlier, in order to simplify interactions with isolates in Dart, I started developing actor framework - [Theater](https://github.com/GlebBatykov/theater).

However, not everyone can like both the actor model itself, which is implemented by isolates in Dart, and the actor framework.

In addition to Dart, I also write in C# and, as for me, it has a convenient wrapper for working with multithreading - Task.

I decided to do something in Dart as similar as possible to Task in C#, but with some nuances due to the fact that isolates are still used under the hood.

# About Ossa

Provides a convenient wrapper for working with isolates similar to Task in C#.

# Installing

Add Ossa to your pubspec.yaml file:

```dart
dependencies:
  ossa: ^1.0.2
```

Import ossa in file that it will be used:

```dart
import 'package:ossa/ossa.dart';
```

# What is Task

Each task is started and runs in a separate isolate, tasks can return some result.

As already mentioned in the introduction, I tried to make the tasks as similar as possible to the Task in C#. However, there are differences.

For example, instead of a pool of isolates (in C#, a pool of threads) to which tasks are redirected and then executed, in Ossa, each task you create has its own isolate.

Each task manages the lifecycle of its isolate.

## Task types

There are two types of tasks:

- one shot (default);
- reusable.

The difference between these two types is that one shot tasks, after completing the task (including if the execution failed), call their dispose method, destroy their isolate and close all StreamController-s used by them, that is, releases all resources used by it. Reusable tasks do not do this, it is calculated that after creating a task you will use it repeatedly.

Why use a reused task instead of creating a new task in the future, if necessary? - so as not to create a new isolate every time.

## Task run

There are two ways to start a task:

- using the run method;
- creating task, initializing it and running it yourself.

Example of create and start task using the run method:

```dart
void main() async {
  // Create and run Task using run method
  var task = await Task.run((context) {
    print('Hello, from task!');
  });

  // Wait when task is completed
  await task.result();
}
```

Example of create task, initializing it and starting:

```dart
void main() async {
  // Create task
  var task = Task((context) {
    print('Hello, from task!');
  });

  // Initialize task before work with him
  await task.initialize();

  // Start task
  await task.start();

  // Wait when task is completed
  await task.result();
}
```

## Get result

The task can return the result of execution. When creating a task yourself, or creating and running using the run method, you can specify a Generic type that should return a Task.

You can process the result both asynchronously using the onDone handler, and wait for the result to be received using the Future received when calling the result method.

The result method, when the task is running, will wait for the result from the isolate, and then return it. If the task has already been completed at the time of calling the result method and has not been started again, it will return the result from the previous task run.

Getting the result from the Future received when calling the result method:

```dart
void main() async {
  // Create and run Task with double return type using run method
  var task = await Task.run<double>((context) => 3 * 7);

  // Wait result from Task
  var result = await task.result();

  print(result);
}
```

Expacted output:

```dart
21
```

Asynchronous receipt of the result using the onDone handler:

```dart
void main() async {
  // Create and run task with int return type, set onDone handler
  var task = await Task.run<int>((context) {
    return 5 * 10;
  }, onDone: (value) async {
    print(value);
  });
}
```

Expected output:

```dart
50
```

## Passing data to task

Each task is executed in its own isolate. Isolates do not have shared memory with each other. Therefore, the data that the task should work with is passed to it using the data parameter in the run and start methods.

Example of transferring data to a task:

```dart
void main() async {
  // We have some data
  var number = 100;

  // Create and run task using run method, passing data to task
  var task = await Task.run<int>((context) {
    var number = context.get<int>('number');

    return number * 10;
  }, data: {'number': number});

  // Wait when task is completed
  var result = await task.result();

  print(result);
}
```

Expected output:

```dart
1000
```

## Task status

A task has different statuses during its life cycle:

- not initialized (notInitialized);
- waiting to start (waitingToRun);
- running (running);
- paused (paused);
- disposed (disposed).

The task is not initialized when created without using the run method, before executing the initialize method. At this point, the task isolate has not yet been created and requires initialization before the task can be executed.

After starting the initialize method, the task is waiting to be started. It is ready to be executed and is waiting for the start method to be executed.

The task is in the execution status after the start method is executed, it can be paused (the task isolate is paused).

If the task is paused, then its execution can be resumed.

After disposed the task, its isolate is destroyed, all Stream Controllers are closed. Further use of this task instance is not possible.

# Error handling

An exception may occur during the execution of the task.

There are options for processing it:

- processing using the onError handler;
- conclusion of a part of the code with the expectation of a result in try/catch.

Example of handling an exception using the onError handler, asynchronously processing the result of the task execution:

```dart
void main() async {
  late Task task;

  // Create and run Task using run method, set onError handler
  task = await Task.run<void>((context) {
    throw FormatException();
  }, onError: (error) async {
    print(error.object.toString());

    task.dispose();
  });
}
```

If the onError handler was not set at the start of the task, then there are 2 scenarios what will happen to it:

- if you are waiting for the result of the task asynchronously, that is, using the onDone handler, then nothing will happen, the exception will not be handled in any way. The task will change from the running status to the ready for execution status (waitingToRun);
- if you are waiting for the result of the task using the result method, the exception will be called again called already in the result method.

Example of handling an exception without onError handler, waiting for the result using the result method:

```dart
void main() async {
  // Create and run Task using run method
  var task = await Task.run((context) {
    throw FormatException();
  });

  try {
    // Wait when task is completed
    await task.result();
  } catch (object) {
    // Handle error

    if (object is TaskCompleteException) {
      print(object);

      await task.dispose();
    }
  }
}
```
