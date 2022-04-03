import 'package:ossa/ossa.dart';

void main() async {
  late Task task;

  // Create and run Task using run method, set onError handler
  task = await Task.run<void>((context) {
    throw FormatException();
  }, onError: (error) async {
    print(error.object.toString());

    task.dispose();
  });
}
