import 'package:ossa/ossa.dart';

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
