import 'package:ossa/ossa.dart';

void main() async {
  //
  var task = await Task.run<void>((context) {
    throw FormatException();
  });

  try {
    //
    await task.result();
  } catch (object) {
    //

    if (object is TaskCompleteException) {
      print('Hello, task complete exception!');

      if (object.object is FormatException) {
        print('Hello, format exception!');
      }
    }

    //
    await task.dispose();
  }
}
