class Examples {
  static const Map<String, String> gallery = {
    'Hello World': '''void main() {
  print('Hello, DartMini IDE!');
}''',
    'List Operations': '''void main() {
  final numbers = [1, 2, 3, 4, 5];
  final doubled = numbers.map((n) => n * 2).toList();
  print('Original: \$numbers');
  print('Doubled: \$doubled');
}''',
    'Class Example': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 25);
  p.introduce();
}''',
    'Async Await': '''Future<void> fetchData() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 1));
  print('Data fetched!');
}

void main() async {
  await fetchData();
  print('Done.');
}''',
  };
}
