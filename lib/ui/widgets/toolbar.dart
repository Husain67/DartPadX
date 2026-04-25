import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../services/file_service.dart';
import '../screens/settings_screen.dart';

class MainToolbar extends ConsumerWidget {
  const MainToolbar({super.key});

  Widget _buildButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton(Icons.add_box, 'New File', () => ref.read(fileProvider.notifier).addFile()),
          _buildButton(Icons.file_download, 'Import .dart', () async {
            final content = await FileService.importFile();
            if (content != null) {
              ref.read(fileProvider.notifier).addFile(content, 'imported.dart');
            }
          }),
          _buildButton(Icons.copy, 'Copy Code', () {
            final file = ref.read(fileProvider.notifier).activeFile;
            if (file != null) {
              Clipboard.setData(ClipboardData(text: file.content));
            }
          }),
          _buildButton(Icons.paste, 'Paste', () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
               final file = ref.read(fileProvider.notifier).activeFile;
               if (file != null) {
                 ref.read(fileProvider.notifier).updateActiveFileContent(file.content + data.text!);
                 // Force UI refresh of code
                 ref.read(fileProvider.notifier).forceRefresh();
               }
            }
          }),
          _buildButton(Icons.format_align_left, 'Format', () => ref.read(fileProvider.notifier).formatActiveCode()),

          _buildButton(Icons.menu_book, 'Examples', () {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('Examples Gallery'),
                 content: SizedBox(
                   width: double.maxFinite,
                   child: ListView(
                     shrinkWrap: true,
                     children: [
                       ListTile(title: const Text('Hello World'), onTap: () {
                         ref.read(fileProvider.notifier).addFile("void main() {\n  print('Hello World!');\n}", "hello.dart");
                         Navigator.pop(ctx);
                       }),
                       ListTile(title: const Text('List & Loop'), onTap: () {
                         ref.read(fileProvider.notifier).addFile("void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var n in numbers) {\n    print('Number: \$n');\n  }\n}", "list.dart");
                         Navigator.pop(ctx);
                       }),
                       ListTile(title: const Text('Class Example'), onTap: () {
                         ref.read(fileProvider.notifier).addFile("class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, I am \$name');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}", "class.dart");
                         Navigator.pop(ctx);
                       }),
                       ListTile(title: const Text('Async Example'), onTap: () {
                         ref.read(fileProvider.notifier).addFile("Future<void> fetchData() async {\n  await Future.delayed(Duration(seconds: 1));\n  print('Data fetched!');\n}\n\nvoid main() async {\n  print('Fetching...');\n  await fetchData();\n}", "async.dart");
                         Navigator.pop(ctx);
                       }),
                     ],
                   ),
                 ),
                 actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
               )
             );
          }),
          _buildButton(Icons.download, 'Download .dart', () {

            final file = ref.read(fileProvider.notifier).activeFile;
            if (file != null) FileService.downloadFile(file);
          }),
          _buildButton(Icons.share, 'Share', () {
            final file = ref.read(fileProvider.notifier).activeFile;
            if (file != null) FileService.shareCode(file);
          }),
          _buildButton(Icons.delete, 'Delete File', () {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('Delete File?'),
                 content: const Text('This cannot be undone.'),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                   TextButton(
                     onPressed: () {
                       Navigator.pop(ctx);
                       ref.read(fileProvider.notifier).deleteActiveFile();
                       Fluttertoast.showToast(msg: 'File deleted successfully');
                     },
                     child: const Text('Delete', style: TextStyle(color: Colors.red)),
                   ),
                 ],
               )
             );
          }),
          _buildButton(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }
}
