with open("dart_mini_ide/lib/screens/examples_screen.dart", "r") as f:
    text = f.read()

text = text.replace("Fluttertoast.showToast(msg: 'Loaded \\${ex['title']}');", "Fluttertoast.showToast(msg: 'Loaded ${ex[\"title\"]}');")

with open("dart_mini_ide/lib/screens/examples_screen.dart", "w") as f:
    f.write(text)

with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "r") as f:
    text2 = f.read()

text2 = text2.replace("import 'package:path_provider/path_provider.dart';", "")

with open("dart_mini_ide/lib/widgets/toolbar_widget.dart", "w") as f:
    f.write(text2)
