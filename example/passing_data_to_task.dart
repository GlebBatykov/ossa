import 'package:ossa/ossa.dart';

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
