
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dartmini_ide/src/features/settings/domain/compiler_preset.dart';

class TestConnectionDialog extends StatefulWidget {
  final CompilerPreset preset;

  const TestConnectionDialog({super.key, required this.preset});

  @override
  State<TestConnectionDialog> createState() => _TestConnectionDialogState();
}

class _TestConnectionDialogState extends State<TestConnectionDialog> {
  String _response = 'Testing...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    final preset = widget.preset;
    final code = "void main() { print('Hello from custom API'); }";
    final stdinStr = "";

    try {
      String body = preset.requestBodyTemplate
          .replaceAll('{code}', code.replaceAll('\n', '\\n').replaceAll('"', '\\"'))
          .replaceAll('{stdin}', stdinStr.replaceAll('\n', '\\n').replaceAll('"', '\\"'));

      Map<String, String> resolvedHeaders = Map.from(preset.headers);

      Uri uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: resolvedHeaders, body: body.isEmpty ? null : body);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: resolvedHeaders, body: body.isEmpty ? null : body);
      } else {
        response = await http.get(uri, headers: resolvedHeaders);
      }

      setState(() {
        _isLoading = false;
        _response = 'Status Code: ${response.statusCode}\n\nResponse Body:\n${response.body}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Test Connection'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: SelectableText(
                  _response,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
