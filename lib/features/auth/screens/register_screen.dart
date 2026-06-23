import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure      = true;
  String _phoneCode  = '+225';

  static const _phoneCodes = [
    ('+225', 'CI 🇨🇮'), ('+224', 'GN 🇬🇳'), ('+221', 'SN 🇸🇳'),
    ('+233', 'GH 🇬🇭'), ('+241', 'GA 🇬🇦'), ('+231', 'LR 🇱🇷'),
    ('+232', 'SL 🇸🇱'), ('+245', 'GW 🇬🇼'), ('+86',  'CN 🇨🇳'),
  ];

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref.read(authProvider.notifier).register({
      'first_name':         _firstCtrl.text.trim(),
      'last_name':          _lastCtrl.text.trim(),
      'email':              _emailCtrl.text.trim(),
      'phone_country_code': _phoneCode,
      'phone_number':       _phoneCtrl.text.trim(),
      'password':           _passCtrl.text,
      'password_confirmation': _confirmCtrl.text,
      'country_id':         1,
    });
    if (result != null && mounted) {
      context.go('/otp', extra: '$_phoneCode${_phoneCtrl.text.trim()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)), onPressed: () => context.go('/login')),
        title: const Text('Créer un compte', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auth.error != null) ...[
                  _errorBox(auth.error!),
                  const SizedBox(height: 16),
                ],

                Row(children: [
                  Expanded(child: _section('Prénom', _firstCtrl, 'Jean')),
                  const SizedBox(width: 12),
                  Expanded(child: _section('Nom', _lastCtrl, 'Kouassi')),
                ]),
                const SizedBox(height: 16),
                _section('Adresse email', _emailCtrl, 'vous@exemple.com', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),

                _label('Téléphone'),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _phoneCode,
                        items: _phoneCodes.map((e) => DropdownMenuItem(value: e.$1, child: Text('${e.$1} ${e.$2}', style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _phoneCode = v!),
                        style: const TextStyle(color: Color(0xFF111827), fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _inputDec('07 00 00 00 00'), validator: (v) => v!.isEmpty ? 'Requis' : null)),
                ]),
                const SizedBox(height: 16),

                _label('Mot de passe'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: _inputDec('Au moins 8 caractères').copyWith(
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400], size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                  validator: (v) => v!.length < 8 ? 'Minimum 8 caractères' : null,
                ),
                const SizedBox(height: 16),

                _section('Confirmer le mot de passe', _confirmCtrl, '••••••••', obscure: true,
                  validator: (v) => v != _passCtrl.text ? 'Les mots de passe ne correspondent pas' : null),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Créer mon compte', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(text: const TextSpan(text: 'Déjà inscrit ? ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14), children: [TextSpan(text: 'Se connecter', style: TextStyle(color: Color(0xFFD4132B), fontWeight: FontWeight.w600))])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
    child: Text(msg, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
  );

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))));

  Widget _section(String label, TextEditingController ctrl, String hint, {TextInputType? keyboard, bool obscure = false, String? Function(String?)? validator}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      TextFormField(controller: ctrl, keyboardType: keyboard, obscureText: obscure, decoration: _inputDec(hint), validator: validator ?? (v) => v!.isEmpty ? 'Requis' : null),
    ],
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true, fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4132B), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
