import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Logo
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('A¥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    const Text('AfriYuan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  ],
                ),
                const SizedBox(height: 40),
                const Text('Bon retour !', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text('Connectez-vous pour continuer', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 32),

                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Text(auth.error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                _label('Adresse email'),
                _field(controller: _emailCtrl, hint: 'vous@exemple.com', keyboard: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Email requis' : null),
                const SizedBox(height: 16),

                _label('Mot de passe'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: _inputDec('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400], size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Mot de passe requis' : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Pas encore inscrit ? ',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        children: [TextSpan(text: 'Créer un compte', style: TextStyle(color: Color(0xFFD4132B), fontWeight: FontWeight.w600))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
  );

  Widget _field({required TextEditingController controller, required String hint, TextInputType? keyboard, String? Function(String?)? validator}) =>
      TextFormField(controller: controller, keyboardType: keyboard, decoration: _inputDec(hint), validator: validator);

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4132B), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
