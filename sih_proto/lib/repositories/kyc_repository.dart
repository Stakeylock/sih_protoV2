// lib/repositories/kyc_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kyc_api.dart';

class KycRepository {
  final KycApi api;
  final SupabaseClient supabase;

  KycRepository({
    required this.api,
    required this.supabase,
  });

  /// Sends images to Python API, then updates Supabase based on result. [5]
  Future<VerifyOutcome> verifyAndPersist({
    required String userId,
    required List<int> idBytes,
    required String idFilename,
    required List<int> selfieBytes,
    required String selfieFilename,
    required String docType,
  }) async {
    // 1) Call Python API
    final res = await api.verify(
      idBytes: idBytes,
      idFilename: idFilename,
      selfieBytes: selfieBytes,
      selfieFilename: selfieFilename,
      docType: docType,
    );  // {verified_any, results, doc_type} [5]

    final bool verified = (res['verified_any'] == true);

    // 2) Persist into Supabase
    // Upsert kyc_info with doc_type and verification flag (OCR fields can be added later)
    await supabase
        .from('kyc_info')
        .upsert({
          'id': userId, // if your table uses user_id, switch key accordingly
          'doc_type_uploaded': docType,
          'is_verified': verified,
          // TODO: add OCR fields: full_name_ext, dob_ext, id_num_ext once backend extracts them
        })
        .select()
        .maybeSingle();  // zero-or-one row convenience [10][9]

    // Update profiles.is_verified
    await supabase.from('profiles').update({'is_verified': verified}).eq('id', userId);  // [9]

    return VerifyOutcome(
      verified: verified,
      raw: res,
    );
  }
}

class VerifyOutcome {
  final bool verified;
  final Map<String, dynamic> raw; // includes per-model distances
  VerifyOutcome({required this.verified, required this.raw});
}
