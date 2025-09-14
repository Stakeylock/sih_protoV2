// lib/services/kyc_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple client for the Python KYC API. [5]
class KycApi {
  final String baseUrl; // e.g., http://<LAN-IP>:5005
  KycApi(this.baseUrl);

  /// Calls POST /verify with ID and selfie bytes and returns decoded JSON. [6]
  Future<Map<String, dynamic>> verify({
    required List<int> idBytes,
    required String idFilename,
    required List<int> selfieBytes,
    required String selfieFilename,
    required String docType,
    List<String> models = const ["VGG-Face", "Facenet", "OpenFace", "ArcFace"],
    Map<String, double>? thresholds,
  }) async {
    final uri = Uri.parse('$baseUrl/verify');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('id_image', idBytes, filename: idFilename))
      ..files.add(http.MultipartFile.fromBytes('selfie_image', selfieBytes, filename: selfieFilename))
      ..fields['doc_type'] = docType
      ..fields['models'] = jsonEncode(models); // sent as JSON string [6];

    if (thresholds != null) {
      req.fields['thresholds'] = jsonEncode(thresholds);
    }  // [6]

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('Verify failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;  // {ok, results, verified_any, doc_type} [5]
  }
}
