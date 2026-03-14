class ExampleGallery {
  static const Map<String, String> examples = {
    'Hello World': '''void main() {
  print('Hello World!');
}''',
    'Input / Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  // For platforms where stdin is not interactive, we can use a mock approach or print a predefined message
  // String? name = stdin.readLineSync();
  String name = 'Developer';
  print('Hello, \$name!');
}''',
    'List': '''void main() {
  List<int> numbers = [1, 2, 3, 4, 5];

  for (var num in numbers) {
    if (num % 2 == 0) {
      print('\$num is Even');
    } else {
      print('\$num is Odd');
    }
  }
}''',
    'Class': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p1 = Person('Alice', 25);
  p1.introduce();
}''',
    'Async': '''Future<void> main() async {
  print('Fetching data...');

  await Future.delayed(Duration(seconds: 2));

  print('Data fetched successfully!');
}'''
  };
}
