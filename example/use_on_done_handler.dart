import 'package:ossa/ossa.dart';

void main() async {
  // Create and run task with int return type, set onDone handler
  var task = await Task.run<int>((context) {
    return 5 * 10;
  }, onDone: (value) async {
    print(value);
  });
}
