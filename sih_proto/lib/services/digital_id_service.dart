import 'dart:convert';
import 'package:http/http.dart' as http;

class DigitalId {
  final String did;
  final String method;
  final String publicKeyMultibase;
  final String keyType;
  final DateTime issuedAt;

  DigitalId({
    required this.did,
    required this.method,
    required this.publicKeyMultibase,
    required this.keyType,
    required this.issuedAt,
  });

  // Map rows from Supabase (snake_case) to model.
  factory DigitalId.fromMap(Map<String, dynamic> m) => DigitalId(
    did: m['did'] as String,
    method: m['method'] as String,
    publicKeyMultibase: m['public_key_multibase'] as String,
    keyType: m['key_type'] as String,
    issuedAt: DateTime.parse(m['issued_at'] as String),
  );
}

// Call external Node API to issue a DID (camelCase response).
Future<DigitalId> issueDidFromApi({
  required String apiBase, // e.g., http://localhost:8787
  required String userId,
}) async {
  final uri = Uri.parse('$apiBase/issue-did');
  final res = await http.post(
    uri,
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'userId': userId}),
  );
  if (res.statusCode != 200) {
    throw Exception('Issue DID failed: ${res.statusCode} ${res.body}');
  }
  final m = jsonDecode(res.body) as Map<String, dynamic>;
  return DigitalId(
    did: m['did'] as String,
    method: m['method'] as String,
    publicKeyMultibase: m['publicKeyMultibase'] as String, // API camelCase
    keyType: m['keyType'] as String, // API camelCase
    issuedAt: DateTime.parse(m['issuedAt'] as String), // API camelCase
  );
}
