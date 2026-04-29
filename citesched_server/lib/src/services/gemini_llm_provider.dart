import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

class GroundedLlmRequest {
  const GroundedLlmRequest({
    required this.model,
    required this.systemPrompt,
    required this.userPrompt,
    required this.groundedJson,
    required this.history,
  });

  final String model;
  final String systemPrompt;
  final String userPrompt;
  final String groundedJson;
  final List<Map<String, String>> history;
}

class GroundedLlmResult {
  const GroundedLlmResult({
    required this.text,
    required this.model,
  });

  final String text;
  final String model;
}

abstract class LlmProvider {
  Future<GroundedLlmResult?> generate(
    Session session,
    GroundedLlmRequest request,
  );
}

class GeminiLlmProvider implements LlmProvider {
  GeminiLlmProvider({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<GroundedLlmResult?> generate(
    Session session,
    GroundedLlmRequest request,
  ) async {
    final apiKey = _configValue('GEMINI_API_KEY', 'geminiApiKey');
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${request.model}:generateContent?key=$apiKey',
    );

    final response = await _httpClient
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': request.systemPrompt},
              ],
            },
            'contents': [
              ...request.history.map(
                (entry) => {
                  'role': entry['role'] == 'assistant' ? 'model' : 'user',
                  'parts': [
                    {'text': entry['text'] ?? ''},
                  ],
                },
              ),
              {
                'role': 'user',
                'parts': [
                  {
                    'text': '''
Verified CITESched data:
${request.groundedJson}

User request:
${request.userPrompt}
''',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'topP': 0.8,
              'maxOutputTokens': 700,
            },
          }),
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      session.log(
        'Gemini request failed (${response.statusCode}): ${response.body}',
      );
      return null;
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) return null;

    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map<String, dynamic>) return null;
    final content = first['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text.trim());
        }
      }
    }

    final resolvedText = buffer.toString().trim();
    if (resolvedText.isEmpty) return null;

    return GroundedLlmResult(
      text: resolvedText,
      model: request.model,
    );
  }

  String? _configValue(String envKey, String passwordKey) {
    final envValue = Platform.environment[envKey];
    if (envValue != null && envValue.trim().isNotEmpty) return envValue.trim();

    try {
      final fromPasswords = Serverpod.instance.getPassword(passwordKey);
      if (fromPasswords != null && fromPasswords.trim().isNotEmpty) {
        return fromPasswords.trim();
      }
    } catch (_) {}

    return null;
  }
}
