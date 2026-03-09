with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "r") as f:
    text = f.read()

text = text.replace("import 'package:path_provider/path_provider.dart';\n", "")
text = "import 'package:path_provider/path_provider.dart';\n" + text
text = text.replace("final directory = await getTemporaryDirectory();\n        final file = File('${directory.path}/${activeFile.name}');", "final directory = await getTemporaryDirectory();\n        final file = File('${directory.path}/${activeFile.name}');")

with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "w") as f:
    f.write(text)
