import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mindheal/features/prescription/models/prescription_model.dart';

import 'prescription_parser_service.dart';

class EmptyOcrTextException implements Exception {}

class VisionOcrException implements Exception {
  final int statusCode;
  final String message;

  const VisionOcrException(this.statusCode, this.message);

  @override
  String toString() => 'Vision OCR failed: $statusCode - $message';
}

class PrescriptionOcrResult {
  final String imageUrl;
  final String rawText;
  final List<Medication> medications;
  final bool medicineExtractionFailed;

  const PrescriptionOcrResult({
    required this.imageUrl,
    required this.rawText,
    required this.medications,
    this.medicineExtractionFailed = false,
  });
}

class OcrService {
  OcrService({
    http.Client? client,
    FirebaseStorage? storage,
    PrescriptionParserService? parser,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? FirebaseStorage.instance,
       _parser = parser ?? PrescriptionParserService(client: client);

  final http.Client _client;
  final FirebaseStorage _storage;
  final PrescriptionParserService _parser;

  Future<String> uploadPrescriptionImage({
    required File imageFile,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeUserId = userId.trim().isEmpty ? 'unknown-user' : userId.trim();
    final ref = _storage.ref('prescriptions/$safeUserId/$timestamp.jpg');

    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<PrescriptionOcrResult> scanPrescription({
    required File imageFile,
    required String userId,
  }) async {
    final imageUrl = await uploadPrescriptionImage(
      imageFile: imageFile,
      userId: userId,
    );
    final rawText = await extractTextFromImageUrl(imageUrl);
    var medicineExtractionFailed = false;
    var medications = <Medication>[];

    try {
      medications = await _parser.parseMedications(rawText);
    } catch (_) {
      medicineExtractionFailed = true;
    }

    return PrescriptionOcrResult(
      imageUrl: imageUrl,
      rawText: rawText,
      medications: medications,
      medicineExtractionFailed: medicineExtractionFailed,
    );
  }

  Future<String> extractTextFromImageUrl(String imageUrl) async {
    final apiKey =
        dotenv.env['GOOGLE_CLOUD_VISION_API_KEY']?.trim().isNotEmpty == true
        ? dotenv.env['GOOGLE_CLOUD_VISION_API_KEY']!.trim()
        : dotenv.env['VISION_API_KEY']?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_CLOUD_VISION_API_KEY is missing.');
    }

    final response = await _client.post(
      Uri.https('vision.googleapis.com', '/v1/images:annotate', {
        'key': apiKey,
      }),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {
              'source': {'imageUri': imageUrl},
            },
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VisionOcrException(
        response.statusCode,
        _extractVisionErrorMessage(response.body),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final responseError = body['responses']?[0]?['error']?['message']
        ?.toString()
        .trim();
    if (responseError != null && responseError.isNotEmpty) {
      throw VisionOcrException(200, responseError);
    }

    final rawText =
        body['responses']?[0]?['fullTextAnnotation']?['text']
            ?.toString()
            .trim() ??
        '';

    if (rawText.isEmpty) throw EmptyOcrTextException();
    return rawText;
  }

  String _extractVisionErrorMessage(String responseBody) {
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final message = body['error']?['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {}

    return responseBody.trim().isEmpty
        ? 'Google Vision rejected the request.'
        : responseBody.trim();
  }
}
