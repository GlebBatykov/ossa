part of ossa.task;

abstract class TaskAction {}

class TaskStart extends TaskAction {
  final Map<String, dynamic> data;

  TaskStart(this.data);
}
