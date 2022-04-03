import 'package:ossa/ossa.dart';

void main() async {
  // Create and run Task using run method
  var task = await Task.run((context) {
    throw FormatException();
  });

  try {
    // Wait when task is completed
    await task.result();
  } catch (object) {
    // Handle error

    if (object is TaskCompleteException) {
      print(object);

      await task.dispose();
    }
  }
}
