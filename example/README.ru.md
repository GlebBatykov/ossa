<div align="center">

**Языки:**
  
[![English](https://img.shields.io/badge/Language-English-blue?style=?style=flat-square)](https://github.com/GlebBatykov/ossa/tree/main/example/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blue?style=?style=flat-square)](https://github.com/GlebBatykov/ossa/tree/main/example/README.ru.md)
  
</div>  

- [Hello World](#hello-world)
- [Получить результат из задачи](#получить-результат-из-задачи)
- [Распараллеливание алгоритма](#распараллеливание-алгоритма)

# Hello World

```dart
void main() async {
  // Create and run Task using run method
  var task = await Task.run((context) {
    print('Hello, from task!');
  });

  // Wait when task is completed
  await task.result();
}
```

# Получить результат из задачи

```dart
void main() async {
  // Create and run Task with double return type using run method
  var task = await Task.run<double>((context) => 3 * 7);

  // Wait result from Task
  var result = await task.result();

  print(result);
}
```

# Распараллеливание алгоритма

```dart
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
```
