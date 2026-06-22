import re

with open("lib/ui/screens/home_screen.dart", "r") as f:
    content = f.read()

# 1. Add Stdin Field below the editor
old_editor = """            // Editor
            Expanded(
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator())
                  : CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.grey, height: 1.3),
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
            ),"""

new_editor = """            // Editor
            Expanded(
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator())
                  : CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.grey, height: 1.3),
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
            ),

            // Stdin input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.pureBlack,
              child: TextField(
                controller: _stdinController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Standard Input (stdin)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.keyboard, color: Colors.grey, size: 16),
                ),
              ),
            ),"""

content = content.replace(old_editor, new_editor)


# 2. Add "Format Code" and "Examples" to Toolbar
old_toolbar = """                  ToolbarButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],"""

new_toolbar = """                  ToolbarButton(
                    icon: Icons.format_align_left,
                    label: 'Format Code',
                    onTap: () {
                      // Basic formatting simulation (or use dart_style if added, but for now we just show a toast)
                      Fluttertoast.showToast(msg: "Formatting not supported in beta");
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.library_books,
                    label: 'Examples',
                    onTap: () {
                      _showExamplesGallery();
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],"""

content = content.replace(old_toolbar, new_toolbar)

# 3. Add _showExamplesGallery method inside _HomeScreenState
examples_method = """  void _showExamplesGallery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hello World'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('hello.dart', "void main() {\\n  print('Hello World');\\n}");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('List & Map'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('list.dart', "void main() {\\n  var list = [1, 2, 3];\\n  print(list);\\n}");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Class Example'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('class.dart', "class Person {\\n  String name;\\n  Person(this.name);\\n}\\n\\nvoid main() {\\n  var p = Person('Dart');\\n  print(p.name);\\n}");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override"""

content = content.replace("  @override\n  Widget build(BuildContext context) {", examples_method + "\n  Widget build(BuildContext context) {")

with open("lib/ui/screens/home_screen.dart", "w") as f:
    f.write(content)
