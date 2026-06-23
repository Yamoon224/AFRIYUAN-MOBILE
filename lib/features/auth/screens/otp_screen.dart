import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otp = '';
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) { t.cancel(); return; }
      setState(() => _countdown--);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    final ok = await ref.read(authProvider.notifier).verifyOtp(_otp);
    if (ok && mounted) context.go('/pin');
  }

  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final theme = PinTheme(
      width: 52, height: 58,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );
    final focused = theme.copyWith(decoration: theme.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 2)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)), onPressed: () => context.go('/register'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.smartphone_outlined, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Vérification SMS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Code envoyé au', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text(widget.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 36),

              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Text(auth.error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                ),
                const SizedBox(height: 20),
              ],

              Pinput(
                length: 6,
                defaultPinTheme: theme,
                focusedPinTheme: focused,
                onChanged: (v) => _otp = v,
                onCompleted: (v) { _otp = v; _verify(); },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading || _otp.length < 6 ? null : _verify,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Vérifier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),

              _countdown > 0
                  ? Text('Renvoyer dans ${_countdown}s', style: TextStyle(color: Colors.grey[400], fontSize: 13))
                  : TextButton(
                      onPressed: () { setState(() => _countdown = 60); _startTimer(); },
                      child: const Text('Renvoyer le code', style: TextStyle(color: Color(0xFFD4132B), fontWeight: FontWeight.w600)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
