sed -i "s/Fluttertoast.showToast(msg: 'Loaded \${ex\[\"title\"\]}');/Fluttertoast.showToast(msg: 'Loaded \${ex[\"title\"]}');/" dart_mini_ide/lib/screens/examples_screen.dart
sed -i "s/final directory = await getTemporaryDirectory();/final directory = await getTemporaryDirectory();/" dart_mini_ide/lib/widgets/toolbar_widget.dart
