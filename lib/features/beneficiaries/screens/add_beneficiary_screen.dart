import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/beneficiary_provider.dart';

class AddBeneficiaryScreen extends ConsumerStatefulWidget {
  const AddBeneficiaryScreen({super.key});
  @override
  ConsumerState<AddBeneficiaryScreen> createState() => _AddBeneficiaryState();
}

class _AddBeneficiaryState extends ConsumerState<AddBeneficiaryScreen> {
  final _formKey    = GlobalKey<FormState>();
  String _type      = 'china';
  String _method    = 'bank_transfer';
  final _first      = TextEditingController();
  final _last       = TextEditingController();
  final _nickname   = TextEditingController();
  final _phone      = TextEditingController();
  final _bank       = TextEditingController();
  final _account    = TextEditingController();
  final _wallet     = TextEditingController();
  bool  _submitting = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _nickname, _phone, _bank, _account, _wallet]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final ok = await ref.read(beneficiaryProvider.notifier).create({
      'beneficiary_type':    _type,
      'first_name':          _first.text.trim(),
      'last_name':           _last.text.trim(),
      'nickname':            _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
      'phone_number':        _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'receive_method':      _method,
      'bank_name':           _bank.text.trim().isEmpty ? null : _bank.text.trim(),
      'bank_account_number': _account.text.trim().isEmpty ? null : _account.text.trim(),
      'wallet_account_number': _wallet.text.trim().isEmpty ? null : _wallet.text.trim(),
    });

    setState(() => _submitting = false);
    if (ok && mounted) context.go('/beneficiaries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nouveau bénéficiaire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type selector
              const Text('Destination', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 10),
              Row(children: [
                _typeBtn('china', '🇨🇳 Chine'),
                const SizedBox(width: 10),
                _typeBtn('africa', '🌍 Afrique'),
              ]),
              const SizedBox(height: 20),

              // Name fields
              Row(children: [
                Expanded(child: _field('Prénom', _first, 'Wei', req: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Nom', _last, 'Zhang', req: true)),
              ]),
              const SizedBox(height: 14),
              _field('Surnom (optionnel)', _nickname, 'Mon contact'),
              const SizedBox(height: 14),
              _field('Téléphone (optionnel)', _phone, '+86 138 0000 0000', keyboard: TextInputType.phone),
              const SizedBox(height: 20),

              // Method
              const Text('Mode de réception', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _methods().map((m) => _methodChip(m.$1, m.$2)).toList()),
              const SizedBox(height: 20),

              // Conditional fields
              if (_method == 'bank_transfer') ...[
                _field('Nom de la banque', _bank, 'Bank of China', req: true),
                const SizedBox(height: 14),
                _field('Numéro de compte', _account, '6222 0000 0000', req: true, keyboard: TextInputType.number),
              ] else if (_method == 'alipay' || _method == 'wechat_pay') ...[
                _field('Identifiant ${_method == 'alipay' ? 'Alipay' : 'WeChat'}', _wallet, 'Téléphone ou email', req: true),
              ],
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Ajouter le bénéficiaire', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  List<(String, String)> _methods() => _type == 'china'
      ? [('bank_transfer', 'Virement'), ('alipay', 'Alipay'), ('wechat_pay', 'WeChat Pay'), ('cash_pickup', 'Espèces')]
      : [('bank_transfer', 'Virement'), ('cash_pickup', 'Espèces')];

  Widget _typeBtn(String t, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() { _type = t; _method = 'bank_transfer'; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _type == t ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _type == t ? AppColors.primary : const Color(0xFFE5E7EB), width: _type == t ? 1.5 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: _type == t ? FontWeight.w600 : FontWeight.normal, color: _type == t ? AppColors.primary : const Color(0xFF6B7280))),
      ),
    ),
  );

  Widget _methodChip(String val, String label) => GestureDetector(
    onTap: () => setState(() => _method = val),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _method == val ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _method == val ? AppColors.primary : const Color(0xFFE5E7EB)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: _method == val ? FontWeight.w600 : FontWeight.normal, color: _method == val ? AppColors.primary : const Color(0xFF374151))),
    ),
  );

  Widget _field(String label, TextEditingController ctrl, String hint, {bool req = false, TextInputType? keyboard}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          filled: true, fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4132B), width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: req ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
      ),
    ],
  );
}
