with open('dart_mini_ide/lib/ui/examples_screen.dart', 'r') as f:
    lines = f.readlines()

lines[85] = "                  SnackBar(content: Text('Loaded \"${example[\"title\"]}\" example')),\n"

with open('dart_mini_ide/lib/ui/examples_screen.dart', 'w') as f:
    f.writelines(lines)
