with open("lib/ui/settings_screen.dart", "r") as f:
    content = f.read()

content = content.replace("            title: Text('Status: \\${response.statusCode}'),", "            // ignore: prefer_const_constructors\n            title: Text('Status: \\${response.statusCode}'),")
content = content.replace("            content: SingleChildScrollView(child: Text(response.body)),", "            // ignore: prefer_const_constructors\n            content: SingleChildScrollView(child: Text(response.body)),")

with open("lib/ui/settings_screen.dart", "w") as f:
    f.write(content)
