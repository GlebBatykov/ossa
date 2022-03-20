import 'package:theater_task/theater_task.dart';

void main() async {
  late Task task;

  //
  task = await Task.run<int>((context) {
    return 5 * 10;
  }, onDone: (value) async {
    print(value);
  });
}
