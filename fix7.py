with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "r") as f:
    text = f.read()

text = text.replace("import 'package:path_provider/path_provider.dart';\n", "")
text = "import 'package:path_provider/path_provider.dart';\n" + text

with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "w") as f:
    f.write(text)
