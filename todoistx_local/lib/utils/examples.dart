class IDEExamples {
  static const Map<String, String> gallery = {
    'Hello World': '''void main() {
  print('Hello, DartMini IDE!');
}''',
    'Input/Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
    'List & Loops': '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Mango'];

  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''',
    'Class Example': '''class Animal {
  String name;
  Animal(this.name);

  void speak() {
    print('\$name makes a noise.');
  }
}

class Dog extends Animal {
  Dog(String name) : super(name);

  @override
  void speak() {
    print('\$name barks!');
  }
}

void main() {
  var dog = Dog('Rex');
  dog.speak();
}''',
    'Async Await': '''Future<String> fetchUserOrder() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(const Duration(seconds: 2), () => 'Large Latte');
}

void main() async {
  print('Fetching user order...');
  var order = await fetchUserOrder();
  print('Your order is: \$order');
}''',
  };
}
