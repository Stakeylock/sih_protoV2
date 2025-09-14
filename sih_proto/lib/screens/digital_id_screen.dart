import 'dart:typed_data'; // for web/mobile byte handling
import 'package:image_picker/image_picker.dart'; // camera/gallery picker
import 'package:supabase_flutter/supabase_flutter.dart'; // for later integration
import 'package:flutter/foundation.dart' show kIsWeb; // web detection

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/services/database_service.dart';
import 'package:sih_proto/services/digital_id_service.dart';
import 'package:sih_proto/utils/app_theme.dart';
import 'package:sih_proto/repositories/kyc_repository.dart';
import 'package:sih_proto/services/kyc_api.dart';

class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id;
    final dbService = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Digital ID')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: userId == null
            ? const Center(child: Text('User not found.'))
            : FutureBuilder<DigitalId?>(
                future: dbService.getDigitalId(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load Digital ID.'),
                    );
                  }
                  final id = snapshot.data;
                  if (id == null) {
                    return const Center(
                      child: Text('Digital ID not issued yet.'),
                    );
                  }

                  final userName = appState.userProfile?['full_name'] ?? 'N/A';
                  final issued = id.issuedAt.toLocal().toString().substring(
                    0,
                    16,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Digital ID card (unchanged)
                        Center(
                          child: AspectRatio(
                            aspectRatio: 85.60 / 53.98,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.accentColor, Colors.cyan],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOURIST DIGITAL ID',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.7),
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      userName.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildRow(
                                      'DOC TYPE',
                                      id.method.toUpperCase(),
                                    ),
                                    _buildRow('KEY TYPE', id.keyType),
                                    _buildRow('ISSUED AT', issued),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            id.did,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.copy,
                                            color: AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                          onPressed: () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: id.did),
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('DID copied'),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(
                                        Icons.qr_code_2,
                                        size: 40,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // KYC section under the ID card
                        FutureBuilder<Map<String, dynamic>?>(
                          future: dbService.getUserProfile(userId),
                          builder: (context, profSnap) {
                            if (profSnap.connectionState !=
                                ConnectionState.done) {
                              return const SizedBox.shrink();
                            }
                            final profile = profSnap.data ?? {};
                            final isVerified = profile['is_verified'] == true;

                            if (!isVerified) {
                              return KYCStatusCard(
                                onStart: () =>
                                    _openKycBottomSheet(context, userId),
                              );
                            }

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: dbService.getKycInfo(userId),
                              builder: (context, kycSnap) {
                                if (kycSnap.connectionState !=
                                    ConnectionState.done) {
                                  return const SizedBox.shrink();
                                }
                                final info = kycSnap.data ?? {};
                                return VerifiedKycCard(
                                  docType: info['doc_type_uploaded'] ?? 'N/A',
                                  name: info['full_name_ext'] ?? 'N/A',
                                  dob: (info['dob_ext'] ?? 'N/A').toString(),
                                  idNum: info['id_num_ext'] ?? 'N/A',
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // KYC Modal Bottom Sheet
  Future<void> _openKycBottomSheet(BuildContext context, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: KycWizard(
          userId: userId,
          onSubmitted: () {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'KYC in process. You will be notified upon completion.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Stateless helpers remain
Widget _buildRow(String title, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

// KYC CTA card for unverified users
class KYCStatusCard extends StatelessWidget {
  final VoidCallback onStart;
  const KYCStatusCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.verified_user, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Identity Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Steps to verify your identification:'),
            const SizedBox(height: 8),
            const Text('1. Upload a government-issued ID'),
            const Text('2. Scan face live (or upload a selfie)'),
            const Text('3. Wait for system verification'),
            const Text(
              '4. Earn a verified badge and profile points usable at trusted stalls',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.shield),
                label: const Text('Get Verified'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Verified KYC display
class VerifiedKycCard extends StatelessWidget {
  final String docType;
  final String name;
  final String dob;
  final String idNum;

  const VerifiedKycCard({
    super.key,
    required this.docType,
    required this.name,
    required this.dob,
    required this.idNum,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'KYC Verified',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('Document Type', docType),
            _kv('Name', name),
            _kv('Date of Birth', dob),
            _kv('ID Number', idNum),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// KYC modal wizard
class KycWizard extends StatefulWidget {
  final String userId;
  final VoidCallback onSubmitted;

  const KycWizard({super.key, required this.userId, required this.onSubmitted});

  @override
  State<KycWizard> createState() => _KycWizardState();
}

class _KycWizardState extends State<KycWizard> {
  int step = 0;
  Uint8List? idImageBytes;
  Uint8List? selfieBytes;
  bool submitting = false;

  final ImagePicker _picker = ImagePicker(); // camera/gallery
  final _formKey = GlobalKey<FormState>(); // for Step 1 validation [9]
  final _docTypeCtrl = TextEditingController();

  @override
  void dispose() {
    _docTypeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'KYC Verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StepperHeader(current: step, total: 2),
              const SizedBox(height: 8),
              if (step == 0) _idStep() else _selfieStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _idStep() {
    return Form(
      key: _formKey, // validate before continue [9]
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1: Upload government-issued ID'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _docTypeCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Document type (e.g., Aadhar, Driving License)',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter the document type'
                : null,
          ),
          const SizedBox(height: 12),
          _imageBox(idImageBytes, placeholder: 'No ID selected'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async =>
                    _pickImage(isSelfie: false, fromCamera: false),
                icon: const Icon(Icons.upload),
                label: const Text('Upload Image'),
              ),
              OutlinedButton.icon(
                onPressed: () async =>
                    _pickImage(isSelfie: false, fromCamera: true),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Use Camera'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (idImageBytes == null)
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate())
                        return; // require doc type [9]
                      setState(() => submitting = true);
                      // TODO: send docType + ID image to backend
                      // await DatabaseService().upsertKycDraft(userId: widget.userId, docTypeUploaded: _docTypeCtrl.text.trim());
                      await Future.delayed(const Duration(milliseconds: 600));
                      setState(() {
                        submitting = false;
                        step = 1;
                      });
                    },
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2: Capture or upload a selfie'),
        const SizedBox(height: 8),
        _imageBox(selfieBytes, placeholder: 'No selfie selected'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async =>
                  _pickImage(isSelfie: true, fromCamera: true),
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text('Live Selfie'),
            ),
            OutlinedButton.icon(
              onPressed: () async =>
                  _pickImage(isSelfie: true, fromCamera: false),
              icon: const Icon(Icons.image),
              label: const Text('Upload Selfie'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selfieBytes == null
                ? null
                : () async {
                    setState(() => submitting = true);
                    try {
                      // Pick the right base URL per runtime:
                      // - Web/desktop: http://localhost:5005
                      // - Android emulator: http://10.0.2.2:5005
                      // - Physical device: http://<PC-LAN-IP>:5005
                      const apiBase =
                          'http://localhost:5005'; // change if needed [18]

                      final repo = KycRepository(
                        api: KycApi(apiBase),
                        supabase: Supabase.instance.client,
                      );

                      final outcome = await repo.verifyAndPersist(
                        userId: widget.userId,
                        idBytes: idImageBytes!,
                        idFilename: 'id.jpg',
                        selfieBytes: selfieBytes!,
                        selfieFilename: 'selfie.jpg',
                        docType: _docTypeCtrl.text.trim(),
                      ); // handles multipart + Supabase updates [1][16][12]

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            outcome.verified
                                ? 'KYC verified'
                                : 'KYC submitted (not verified)',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('KYC failed: $e')));
                    } finally {
                      if (!mounted) return;
                      setState(() => submitting = false);
                      widget
                          .onSubmitted(); // closes sheet and returns to screen
                    }
                  },
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit for Verification'),
          ),
        ),
      ],
    );
  }

  Widget _imageBox(Uint8List? bytes, {required String placeholder}) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: bytes == null
          ? Text(placeholder, style: const TextStyle(color: Colors.black54))
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Future<void> _pickImage({
    required bool isSelfie,
    required bool fromCamera,
  }) async {
    try {
      final source = fromCamera
          ? ImageSource.camera
          : ImageSource.gallery; // both supported
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        if (isSelfie) {
          selfieBytes = bytes;
        } else {
          idImageBytes = bytes;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not access ${fromCamera ? 'camera' : 'gallery'}: $e',
          ),
        ),
      );
    }
  }
}

// Simple step indicator
class StepperHeader extends StatelessWidget {
  final int current;
  final int total;

  const StepperHeader({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppTheme.accentColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}
