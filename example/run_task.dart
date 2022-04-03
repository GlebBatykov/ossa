import 'package:ossa/ossa.dart';

void main() async {
  // Create and run Task using run method
  var task = await Task.run((context) {
    print('Hello, from task!');
  });

  // Wait when task is completed
  await task.result();
}
