import 'package:ossa/ossa.dart';

void main() async {
  // Create Task
  var task = Task<String>((context) {
    return 'Hello, world!';
  });

  //
  await task.initialize();
  //
  await task.start();

  //
  var result = await task.result();

  print(result);
}
