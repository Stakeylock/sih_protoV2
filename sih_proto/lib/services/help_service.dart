import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HelpService {
  final String model = "gemini-1.5-flash";

  Future<String> getHelpResponse(String userMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']; // fetch from .env
    if (apiKey == null) {
      return "API key missing in .env file";
    }

    final url =
        "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] ?? "";
      } else {
        return "Error: ${response.statusCode} → ${response.body}";
      }
    } catch (e) {
      return "Failed to connect: $e";
    }
  }
}
