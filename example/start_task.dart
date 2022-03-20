import 'package:theater_task/theater_task.dart';

void main() async {
  //
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
