// lib/services/digital_id_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin service that calls the external Digital ID issuance API.
/// Returns a plain Map<String, dynamic> with keys compatible with your DB:
/// { did, method, public_key_multibase, key_type, issued_at }
class DigitalIdService {
  const DigitalIdService();

  /// Issues a new Digital ID for the given user.
  ///
  /// Expects the backend to:
  /// - accept POST at `$apiBase/issue-did`
  /// - body: { user_id: string }
  /// - return 200 with JSON: { did, method, public_key_multibase, key_type, issued_at }
  ///
  /// Throws on non-200 or invalid JSON.
  Future<Map<String, dynamic>> issueNewDid({
    required String apiBase,
    required String userId,
  }) async {
    final uri = Uri.parse('$apiBase/issue-did');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = json.encode({'user_id': userId});

    final resp = await http.post(uri, headers: headers, body: body);
    if (resp.statusCode != 200) {
      throw Exception('Issue DID failed (${resp.statusCode}): ${resp.body}');
    }

    Map<String, dynamic> jsonMap;
    try {
      jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid JSON from issue-did API: $e');
    }

    // Basic shape validation to fail fast if backend changes
    for (final k in const [
      'did',
      'method',
      'public_key_multibase',
      'key_type',
      'issued_at',
    ]) {
      if (!jsonMap.containsKey(k)) {
        throw Exception('Missing key "$k" in issue-did response');
      }
    }

    return jsonMap;
  }
}
