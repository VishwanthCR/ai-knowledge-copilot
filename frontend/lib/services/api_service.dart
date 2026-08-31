import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class ApiService {

  static const String baseUrl =
      'http://127.0.0.1:8000';


  // ==========================================================
  // UPLOAD PDF
  // ==========================================================

  Future<Map<String, dynamic>> uploadPdf(
    String fileName,
    Uint8List fileBytes,
  ) async {

    try {

      final uri = Uri.parse(
        '$baseUrl/upload',
      );

      debugPrint('Uploading: $fileName');
      debugPrint('URL: $uri');
      debugPrint('File size: ${fileBytes.length} bytes');

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      debugPrint('Sending request...');

      final streamedResponse =
          await request.send();

      debugPrint(
        'Status code: ${streamedResponse.statusCode}',
      );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Response body: ${response.body}',
      );

      // --------------------------------------------------------
      // Check HTTP status
      // --------------------------------------------------------

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {

        throw Exception(
          'Server returned ${response.statusCode}: '
          '${response.body}',
        );
      }

      // --------------------------------------------------------
      // Decode JSON
      // --------------------------------------------------------

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {

        throw Exception(
          'Unexpected server response: '
          '${response.body}',
        );
      }

      debugPrint('Upload successful.');

      return decoded;

    } catch (e) {

      debugPrint(
        'UPLOAD ERROR: $e',
      );

      rethrow;
    }
  }


  // ==========================================================
  // ASK QUESTION
  // ==========================================================

  Future<Map<String, dynamic>> askQuestion(
    String question,
  ) async {

    try {

      final uri = Uri.parse(
        '$baseUrl/ask',
      );

      debugPrint(
        'Asking question: $question',
      );

      final response = await http.post(

        uri,

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
          'question': question,
        }),
      );

      debugPrint(
        'Ask status code: ${response.statusCode}',
      );

      debugPrint(
        'Ask response: ${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {

        throw Exception(
          'Server returned ${response.statusCode}: '
          '${response.body}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {

        throw Exception(
          'Unexpected server response.',
        );
      }

      return decoded;

    } catch (e) {

      debugPrint(
        'ASK ERROR: $e',
      );

      rethrow;
    }
  }
}