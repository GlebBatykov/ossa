import 'package:ossa/ossa.dart';

void main() async {
  // Create and run reusable task using run method
  var task = await Task.run<void>((context) {
    print('Hello, from task!');
  }, type: TaskType.reusable);

  // Wait when task is completed
  await task.result();

  // Start task
  await task.start();

  // Wait when task is completed
  await task.result();

  // Dispose reusable task
  await task.dispose();
}
