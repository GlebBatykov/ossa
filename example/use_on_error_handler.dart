import 'package:ossa/ossa.dart';

void main() async {
  late Task task;

  //
  task = await Task.run<void>((context) {
    throw FormatException();
  }, onError: (error) async {
    print(error.object.toString());

    task.dispose();
  });

  //
  await task.result();
}
