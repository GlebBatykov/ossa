import 'package:ossa/ossa.dart';

void main() async {
  // Create and run Task with double return type using run method
  var task = await Task.run<double>((context) => 3 * 7);

  // Wait result from Task
  var result = await task.result();

  print(result);
}
