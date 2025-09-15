// lib/models/digital_id.dart
class DigitalId {
  final String userId;        // who owns this Digital ID
  final String did;           // DID string
  final String method;        // e.g., 'aadhar', 'passport', etc.
  final String keyType;       // e.g., 'ed25519'
  final DateTime issuedAt;    // issuance timestamp

  const DigitalId({
    required this.userId,
    required this.did,
    required this.method,
    required this.keyType,
    required this.issuedAt,
  });

  DigitalId copyWith({
    String? userId,
    String? did,
    String? method,
    String? keyType,
    DateTime? issuedAt,
  }) {
    return DigitalId(
      userId: userId ?? this.userId,
      did: did ?? this.did,
      method: method ?? this.method,
      keyType: keyType ?? this.keyType,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  factory DigitalId.fromMap(Map<String, dynamic> map) {
    return DigitalId(
      userId: map['user_id'] as String,
      did: map['did'] as String,
      method: (map['method'] ?? '').toString(),
      keyType: (map['key_type'] ?? '').toString(),
      issuedAt: _parseDate(map['issued_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'did': did,
      'method': method,
      'key_type': keyType,
      'issued_at': issuedAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
