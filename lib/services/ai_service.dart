import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'http://10.0.0.132:8000';

  static Future<Map<String, dynamic>> predictImage(
      String imagePath,
      ) async {
    final url = Uri.parse('$baseUrl/predict');

    final request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath('file', imagePath),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(
      const Duration(seconds: 30),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Server Error: ${response.statusCode}',
      );
    }

    final dynamic decodedResult;

    try {
      decodedResult = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response from AI server.');
    }

    if (decodedResult is! Map<String, dynamic>) {
      throw Exception('Unexpected AI server response.');
    }

    if (decodedResult['success'] != true) {
      throw Exception(
        decodedResult['error'] ?? 'AI prediction failed',
      );
    }

    final prediction = decodedResult['prediction'];
    final confidence = decodedResult['confidence'];

    if (prediction is! String || confidence is! num) {
      throw Exception(
        'AI response is missing prediction or confidence.',
      );
    }

    return {
      ...decodedResult,
      'prediction': prediction,
      'confidence': confidence.toDouble(),
    };
  }
}