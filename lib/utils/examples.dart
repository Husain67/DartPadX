class Examples {
  static const Map<String, String> collection = {
    'Hello World': '''
void main() {
  print('Hello, DartMini IDE!');
}
''',
    'List & Loops': '''
void main() {
  List<String> fruits = ['Apple', 'Banana', 'Orange'];
  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}
''',
    'Classes': '''
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var person = Person('Alice', 25);
  person.introduce();
}
''',
    'Async Await': '''
Future<void> fetchUserData() async {
  print('Fetching user data...');
  await Future.delayed(Duration(seconds: 2));
  print('User data loaded.');
}

void main() async {
  print('Start');
  await fetchUserData();
  print('End');
}
'''
  };
}
