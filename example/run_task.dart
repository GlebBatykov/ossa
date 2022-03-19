import 'package:theater_task/theater_task.dart';

void main() async {
  var task = await Task.run<double>((context) => 3 * 7);

  var result = await task.result();

  print(result);
}
