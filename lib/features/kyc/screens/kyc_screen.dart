import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

final _kycDocsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.get(Endpoints.kycStatus);
  return (res.data['documents'] as List? ?? []).cast<Map<String, dynamic>>();
});

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});
  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  String _docType = 'passport';
  File?  _file;
  bool   _uploading = false;
  String? _success;
  String? _error;

  static const _docTypes = [
    ('passport',        'Passeport'),
    ('national_id',     'Carte d\'identité'),
    ('driving_license', 'Permis de conduire'),
    ('utility_bill',    'Justificatif de domicile'),
    ('selfie',          'Selfie'),
  ];

  Future<void> _pick() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _file = File(xfile.path));
  }

  Future<void> _upload() async {
    if (_file == null) return;
    setState(() { _uploading = true; _error = null; _success = null; });
    try {
      final form = FormData.fromMap({
        'document_type': _docType,
        'document': await MultipartFile.fromFile(_file!.path, filename: _file!.path.split('/').last),
      });
      await ApiClient.instance.post(Endpoints.kycUpload, data: form);
      ref.invalidate(_kycDocsProvider);
      setState(() { _success = 'Document soumis avec succès !'; _file = null; });
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final docs = ref.watch(_kycDocsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Vérification d\'identité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: auth.user?.isKycApproved == true
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : auth.user?.kycStatus == 'under_review'
                        ? [Colors.amber[400]!, Colors.amber[600]!]
                        : [AppColors.primary, const Color(0xFF9B0E1F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  auth.user?.isKycApproved == true ? 'Identité vérifiée ✓' : auth.user?.kycStatus == 'under_review' ? 'Vérification en cours...' : 'Vérification requise',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  auth.user?.isKycApproved == true ? 'Votre compte est pleinement activé.' : auth.user?.kycStatus == 'under_review' ? 'Sous 1 à 3 jours ouvrés.' : 'Soumettez vos documents pour lever vos limites.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('Niv. ${auth.user?.kycLevel ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Documents submitted
          docs.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) => list.isEmpty ? const SizedBox.shrink() : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documents soumis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 10),
                ...list.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.description_outlined, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_docTypes.firstWhere((t) => t.$1 == d['document_type'], orElse: () => (d['document_type'], d['document_type'])).$2, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                    _StatusChip(status: d['status'] ?? ''),
                  ]),
                )),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Upload form
          if (auth.user?.isKycApproved != true) ...[
            const Text('Soumettre un document', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),

            if (_success != null)
            Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[200]!)), child: Text(_success!, style: TextStyle(color: Colors.green[700], fontSize: 13))),
            if (_error != null)
            Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)), child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Type de document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _docType, isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
                      items: _docTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                      onChanged: (v) => setState(() => _docType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pick,
                  child: Container(
                    width: double.infinity, height: 100,
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid)),
                    child: _file != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_file!, fit: BoxFit.cover))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey[400]),
                            const SizedBox(height: 6),
                            Text('Appuyer pour sélectionner', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ]),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: (_file == null || _uploading) ? null : _upload,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: _uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Envoyer le document', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'approved'     => ('Approuvé', Colors.green[50]!, Colors.green[700]!),
      'under_review' => ('En examen', Colors.amber[50]!, Colors.amber[700]!),
      'rejected'     => ('Rejeté', Colors.red[50]!, Colors.red[700]!),
      _              => ('En attente', Colors.grey[100]!, Colors.grey[600]!),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)));
  }
}
