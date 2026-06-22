with open("lib/providers/file_provider.dart", "r") as f:
    content = f.read()

old_code = """      content: '''void main() {
  print('Hello, DartMini IDE!');
}''',"""
new_code = """      content: '''import \\'dart:io\\';

void main() {
  print(\\'Hello, DartMini IDE!\\');
  print(\\'Enter something:\\');
  String? input = stdin.readLineSync();
  print(\\'You entered: \\$input\\');
}''',"""

with open("lib/providers/file_provider.dart", "w") as f:
    f.write(content.replace(old_code, new_code))
