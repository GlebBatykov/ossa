import 'package:ossa/ossa.dart';

void main() async {
  // We have some initial data
  var data = List<double>.generate(5, (index) => index.toDouble());

  var tasks = <Task<double>>[];

  for (var i = 0; i < data.length; i++) {
    // Create and run task with run method, passing data to task
    tasks.add(await Task.run<double>((context) {
      var number = context.get<double>('number');

      return number * number;
    }, data: {'number': data[i]}));
  }

  // Wait when all task is completed
  var results = await Future.wait<double>(List<Future<double>>.generate(
      tasks.length, (index) => tasks[index].result()));

  for (var result in results) {
    print(result);
  }
}
