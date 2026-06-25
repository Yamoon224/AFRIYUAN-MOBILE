import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transfer_provider.dart';
import '../../beneficiaries/providers/beneficiary_provider.dart';

class TransferWizardScreen extends ConsumerStatefulWidget {
  const TransferWizardScreen({super.key});
  @override
  ConsumerState<TransferWizardScreen> createState() => _TransferWizardState();
}

class _TransferWizardState extends ConsumerState<TransferWizardScreen> {
  int _step = 0;
  String _direction = 'africa_to_china';
  String _fromCurrency = 'XOF';
  final _amountCtrl = TextEditingController();
  Map<String, dynamic>? _quote;
  int? _selectedBeneficiaryId;
  String _paymentMethod = 'card';
  bool _quoteLoading = false;
  bool _submitting   = false;
  String? _error;

  static const _africanCurrencies = ['XOF', 'XAF', 'GNF', 'GHS', 'LRD', 'SLE'];

  String get _toCurrency => _direction == 'africa_to_china' ? 'CNY' : _fromCurrency;
  String get _actualFrom => _direction == 'africa_to_china' ? _fromCurrency : 'CNY';

  Future<void> _fetchQuote() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() { _quoteLoading = true; _error = null; });
    try {
      _quote = await ref.read(transferProvider.notifier).getQuote({
        'from_currency': _actualFrom,
        'to_currency':   _direction == 'africa_to_china' ? 'CNY' : _fromCurrency,
        'send_amount':   amount,
      });
    } catch (e) {
      _error = 'Impossible de récupérer le taux : $e';
    } finally {
      setState(() => _quoteLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ref.read(transferProvider.notifier).create({
      'from_currency':    _actualFrom,
      'to_currency':      _direction == 'africa_to_china' ? 'CNY' : _fromCurrency,
      'send_amount':      double.tryParse(_amountCtrl.text),
      'beneficiary_id':   _selectedBeneficiaryId,
      'payment_method':   _paymentMethod,
      'direction':        _direction,
    });
    setState(() => _submitting = false);
    if (ok && mounted) { context.go('/transfers'); }
  }

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_stepTitle(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/transfers')),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 3, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i <= _step ? AppColors.primary : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ))),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: [_buildStep0(), _buildStep1(), _buildStep2()][_step],
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  String _stepTitle() => ['Montant & Direction', 'Bénéficiaire', 'Confirmation'][_step];

  // ── Step 0 : Direction + Amount ───────────────────────────────────────────
  Widget _buildStep0() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Direction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    const SizedBox(height: 10),
    Row(children: [
      _dirBtn('africa_to_china', '🌍 Afrique → 🇨🇳 Chine'),
      const SizedBox(width: 10),
      _dirBtn('china_to_africa', '🇨🇳 Chine → 🌍 Afrique'),
    ]),
    const SizedBox(height: 20),

    const Text('Devise source', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _direction == 'africa_to_china' ? _fromCurrency : 'CNY',
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
          items: (_direction == 'africa_to_china' ? _africanCurrencies : ['CNY']).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (_direction == 'africa_to_china') setState(() => _fromCurrency = v!); },
        ),
      ),
    ),
    const SizedBox(height: 16),

    TextField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Montant à envoyer',
        hintText: '100 000',
        filled: true, fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4132B), width: 1.5)),
        suffixText: _direction == 'africa_to_china' ? _fromCurrency : 'CNY',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      onChanged: (_) { _quote = null; setState(() {}); },
    ),
    const SizedBox(height: 16),

    SizedBox(
      width: double.infinity, height: 46,
      child: OutlinedButton(
        onPressed: _quoteLoading ? null : _fetchQuote,
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _quoteLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Voir le taux'),
      ),
    ),

    if (_error != null) ...[
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
    ],

    if (_quote != null) ...[
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFED7AA))),
        child: Column(children: [
          _quoteRow('Taux de change', '1 ${_actualFrom} = ¥${_quote!['exchange_rate']} CNY'),
          _quoteRow('Frais', '${_quote!['fee_amount']} ${_actualFrom}'),
          const Divider(height: 16),
          _quoteRow('Vous recevez', '¥${_quote!['receive_amount']} CNY', bold: true),
        ]),
      ),
    ],
  ]);

  Widget _dirBtn(String dir, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() { _direction = dir; _fromCurrency = 'XOF'; _quote = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _direction == dir ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _direction == dir ? AppColors.primary : const Color(0xFFE5E7EB), width: _direction == dir ? 1.5 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: _direction == dir ? FontWeight.w600 : FontWeight.normal, color: _direction == dir ? AppColors.primary : const Color(0xFF6B7280))),
      ),
    ),
  );

  Widget _quoteRow(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? AppColors.primary : const Color(0xFF111827))),
    ]),
  );

  // ── Step 1 : Beneficiary ─────────────────────────────────────────────────
  Widget _buildStep1() {
    final benState = ref.watch(beneficiaryProvider);
    final filtered  = benState.beneficiaries.where((b) => _direction == 'africa_to_china' ? b.isChina : !b.isChina).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        _direction == 'africa_to_china' ? 'Sélectionnez un bénéficiaire en Chine' : 'Sélectionnez un bénéficiaire en Afrique',
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
      const SizedBox(height: 16),
      if (benState.isLoading) const Center(child: CircularProgressIndicator())
      else if (filtered.isEmpty)
        Column(children: [
          const Icon(Icons.people_outline, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          const Text('Aucun bénéficiaire', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/beneficiaries/nouveau'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Ajouter un bénéficiaire'),
          ),
        ])
      else
        ...filtered.map((b) => GestureDetector(
          onTap: () => setState(() => _selectedBeneficiaryId = b.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _selectedBeneficiaryId == b.id ? AppColors.primary.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _selectedBeneficiaryId == b.id ? AppColors.primary : const Color(0xFFE5E7EB), width: _selectedBeneficiaryId == b.id ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(b.firstName.substring(0, 1).toUpperCase(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(b.receiveMethod.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ])),
              if (_selectedBeneficiaryId == b.id) Icon(Icons.check_circle, color: AppColors.primary),
            ]),
          ),
        )),
    ]);
  }

  // ── Step 2 : Confirm ─────────────────────────────────────────────────────
  Widget _buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        _quoteRow('Direction', _direction == 'africa_to_china' ? '🌍 Afrique → 🇨🇳 Chine' : '🇨🇳 Chine → 🌍 Afrique'),
        _quoteRow('Montant envoyé', '${_amountCtrl.text} ${_actualFrom}'),
        if (_quote != null) ...[
          _quoteRow('Frais', '${_quote!['fee_amount']} ${_actualFrom}'),
          _quoteRow('Taux', '1 ${_actualFrom} = ¥${_quote!['exchange_rate']}'),
          const Divider(height: 16),
          _quoteRow('Montant reçu', '¥${_quote!['receive_amount']} CNY', bold: true),
        ],
      ]),
    ),
    const SizedBox(height: 16),
    const Text('Méthode de paiement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    const SizedBox(height: 10),
    ...['card', 'mobile_money', 'bank_transfer'].map((m) => RadioListTile<String>(
      value: m, groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!),
      title: Text(_methodLabel(m), style: const TextStyle(fontSize: 14)),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    )),
    if (_error != null) ...[
      const SizedBox(height: 8),
      Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
    ],
  ]);

  String _methodLabel(String m) => switch (m) { 'card' => '💳 Carte bancaire', 'mobile_money' => '📱 Mobile Money', _ => '🏦 Virement bancaire' };

  // ── Navigation bar ────────────────────────────────────────────────────────
  Widget _buildNavBar() => Container(
    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
    decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
    child: Row(children: [
      if (_step > 0) ...[
        Expanded(child: OutlinedButton(
          onPressed: () => setState(() => _step--),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6B7280), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Retour'),
        )),
        const SizedBox(width: 12),
      ],
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: _canProceed() ? (_step == 2 ? (_submitting ? null : _submit) : () => setState(() => _step++)) : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_step == 2 ? 'Confirmer le transfert' : 'Continuer', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );

  bool _canProceed() {
    if (_step == 0) return _amountCtrl.text.isNotEmpty && double.tryParse(_amountCtrl.text) != null && (_quote != null || true);
    if (_step == 1) return _selectedBeneficiaryId != null;
    return true;
  }
}
