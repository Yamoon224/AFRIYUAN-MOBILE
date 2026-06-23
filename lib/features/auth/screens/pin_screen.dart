import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _storage = FlutterSecureStorage();
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;
  String? _error;

  void _onCompleted(String value) {
    if (!_isConfirming) {
      setState(() { _firstPin = value; _isConfirming = true; _pin = ''; });
    } else {
      if (value == _firstPin) {
        _storage.write(key: 'pin', value: value).then((_) { if (mounted) context.go('/'); });
      } else {
        setState(() { _error = 'Les codes PIN ne correspondent pas.'; _firstPin = null; _isConfirming = false; _pin = ''; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PinTheme(
      width: 56, height: 64,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(22)),
                child: Icon(Icons.lock_outline, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              Text(
                _isConfirming ? 'Confirmer le PIN' : 'Créer votre PIN',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming ? 'Ressaisissez votre code à 6 chiffres' : 'Ce code sécurisera vos transferts',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                ),
                const SizedBox(height: 20),
              ],

              Pinput(
                key: ValueKey(_isConfirming),
                length: 6,
                obscureText: true,
                defaultPinTheme: theme,
                focusedPinTheme: theme.copyWith(decoration: theme.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 2))),
                onChanged: (v) => _pin = v,
                onCompleted: _onCompleted,
              ),

              if (_isConfirming) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() { _isConfirming = false; _firstPin = null; _pin = ''; _error = null; }),
                  child: Text('Recommencer', style: TextStyle(color: Colors.grey[500])),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
