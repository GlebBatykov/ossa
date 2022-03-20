import 'package:theater_task/theater_task.dart';

void main() async {
  //
  var task = await Task.run<void>((context) {
    print('Hello, from task!');
  }, type: TaskType.reusable);

  //
  await task.result();

  //
  await task.start();

  //
  await task.result();

  //
  await task.dispose();
}
