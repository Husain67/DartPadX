import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';

// ignore_for_file: prefer_const_constructors, prefer_const_declarations

class TestConnectionDialog extends StatefulWidget {
  final CompilerPreset preset;
  const TestConnectionDialog({super.key, required this.preset});

  @override
  State<TestConnectionDialog> createState() => _TestConnectionDialogState();
}

class _TestConnectionDialogState extends State<TestConnectionDialog> {
  bool _isLoading = true;
  String _rawResponse = '';
  String _parsedStdout = '';
  String _parsedStderr = '';
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    final preset = widget.preset;
    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    String bodyString = preset.requestBodyTemplate;
    final code = "print('Hello from custom API');";

    final encodedCode = jsonEncode(code);
    final rawCode = encodedCode.substring(1, encodedCode.length - 1);

    final encodedStdin = jsonEncode("");
    final rawStdin = encodedStdin.substring(1, encodedStdin.length - 1);

    bodyString = bodyString.replaceAll('{code}', rawCode);
    bodyString = bodyString.replaceAll('{stdin}', rawStdin);

    try {
      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: preset.headers, body: bodyString);
      } else {
        response = await http.get(uri, headers: preset.headers);
      }

      _rawResponse = response.body;

      try {
        final decoded = jsonDecode(response.body);
        _parsedStdout = _extractByPath(decoded, preset.stdoutPath) ?? '';
        _parsedStderr = _extractByPath(decoded, preset.stderrPath) ?? '';

        if (_parsedStderr.isEmpty) {
          _parsedStderr = _extractByPath(decoded, preset.errorPath) ?? '';
        }
      } catch (e) {
        _errorMsg = 'Failed to parse JSON response: $e';
      }

    } catch (e) {
      _errorMsg = 'HTTP Request failed: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  dynamic _extractByPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Divider(color: Colors.white24),
            if (_isLoading)
              Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow)))
            else
              Expanded(
                child: ListView(
                  children: [
                    if (_errorMsg.isNotEmpty)
                      Text('Error: $_errorMsg', style: TextStyle(color: Colors.redAccent)),
                    SizedBox(height: 8),
                    Text('Parsed Stdout:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    Text(_parsedStdout.isEmpty ? '<Empty>' : _parsedStdout, style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('Parsed Stderr:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    Text(_parsedStderr.isEmpty ? '<Empty>' : _parsedStderr, style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 16),
                    Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.black26,
                      child: Text(_rawResponse, style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white54)),
                    )
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: AppTheme.primaryYellow)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
