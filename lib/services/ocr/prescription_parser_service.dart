import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:uuid/uuid.dart';

class PrescriptionParseException implements Exception {
  final String message;

  const PrescriptionParseException(this.message);

  @override
  String toString() => message;
}

class PrescriptionParserService {
  PrescriptionParserService({http.Client? client})
    : _client = client ?? http.Client();

  static const String systemPrompt = '''
You are a medical prescription parser. Extract structured medication 
data from the following raw prescription text. Return ONLY a valid 
JSON array with no explanation, no markdown, no backticks. Each item 
must have exactly these fields:
{
  "medicineName": "string",
  "dosage": "string (e.g. 1 tablet, 500mg)",
  "frequency": "string (e.g. twice daily, every 8 hours, at bedtime)",
  "durationDays": number (integer, default 7 if not mentioned),
  "instructions": "string (e.g. after meals, with water — empty string 
                   if none)"
}
If a field cannot be determined from the text, use sensible medical 
defaults. Never return null values.
''';

  final http.Client _client;
  final Uuid _uuid = const Uuid();

  Future<List<Medication>> parseMedications(String rawText) async {
    if (rawText.trim().isEmpty) return [];

    final content = await _requestStructuredJson(rawText);
    final decoded = _decodeJsonArray(content);
    final now = DateTime.now();

    return decoded.map((item) {
      final durationDays = _durationDays(item['durationDays']);
      final frequency = _stringValue(item['frequency'], fallback: 'once daily');

      return Medication(
        id: _uuid.v4(),
        name: _stringValue(item['medicineName'], fallback: 'Unknown medicine'),
        genericName: _stringValue(
          item['medicineName'],
          fallback: 'Unknown medicine',
        ),
        dosage: _stringValue(item['dosage'], fallback: '1 tablet'),
        frequency: frequency,
        duration: '$durationDays days',
        instructions: _stringValue(item['instructions']),
        startDate: now,
        endDate: now.add(Duration(days: durationDays)),
        timings: _timingsForFrequency(frequency),
        withFood: _mentionsFood(_stringValue(item['instructions'])),
        sideEffects: const [],
        notes: '',
      );
    }).toList();
  }

  Future<String> _requestStructuredJson(String rawText) {
    final provider = (dotenv.env['PRESCRIPTION_LLM_PROVIDER'] ?? '')
        .trim()
        .toLowerCase();
    if (provider == 'gemini') {
      return _requestGemini(rawText);
    }
    if (provider == 'openai' || provider.isEmpty) {
      return _requestOpenAi(rawText);
    }

    throw const PrescriptionParseException(
      'Unsupported prescription LLM provider.',
    );
  }

  Future<String> _requestOpenAi(String rawText) async {
    final apiKey = dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const PrescriptionParseException('OPENAI_API_KEY is missing.');
    }

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': dotenv.env['OPENAI_MODEL']?.trim().isNotEmpty == true
            ? dotenv.env['OPENAI_MODEL']!.trim()
            : 'gpt-4o',
        'temperature': 0,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrescriptionParseException(
        'OpenAI parsing failed: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['choices']?[0]?['message']?['content']?.toString() ?? '';
  }

  Future<String> _requestGemini(String rawText) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const PrescriptionParseException('GEMINI_API_KEY is missing.');
    }

    final model = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_MODEL']!.trim()
        : 'gemini-1.5-flash';

    final response = await _client.post(
      Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
        {'key': apiKey},
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'generationConfig': {'temperature': 0},
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\n\nRaw prescription text:\n$rawText'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrescriptionParseException(
        'Gemini parsing failed: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString() ??
        '';
  }

  List<Map<String, dynamic>> _decodeJsonArray(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const PrescriptionParseException('Empty LLM response.');
    }

    final start = trimmed.indexOf('[');
    final end = trimmed.lastIndexOf(']');
    if (start < 0 || end < start) {
      throw const PrescriptionParseException(
        'LLM response did not contain a JSON array.',
      );
    }

    final decoded = jsonDecode(trimmed.substring(start, end + 1));
    if (decoded is! List) {
      throw const PrescriptionParseException(
        'LLM response was not a JSON array.',
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _durationDays(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 7;
  }

  bool _mentionsFood(String instructions) {
    final text = instructions.toLowerCase();
    return text.contains('food') ||
        text.contains('meal') ||
        text.contains('after eating');
  }

  List<String> _timingsForFrequency(String frequency) {
    final text = frequency.toLowerCase();

    if (text.contains('every 6') ||
        text.contains('four') ||
        text.contains('4 times')) {
      return const ['06:00', '12:00', '18:00', '00:00'];
    }
    if (text.contains('every 8') ||
        text.contains('three') ||
        text.contains('3 times')) {
      return const ['08:00', '16:00', '00:00'];
    }
    if (text.contains('twice') ||
        text.contains('two') ||
        text.contains('2 times')) {
      return const ['08:00', '20:00'];
    }
    if (text.contains('bedtime') || text.contains('night')) {
      return const ['21:00'];
    }
    if (text.contains('morning')) {
      return const ['08:00'];
    }

    return const ['09:00'];
  }
}
