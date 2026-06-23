import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/card_provider.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});
  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  bool _showAdd = false;
  bool _adding  = false;

  Future<void> _addCard(String clientSecret) async {
    setState(() => _adding = true);
    try {
      await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: 'AfriYuan',
        style: ThemeMode.light,
      ));
      await Stripe.instance.presentPaymentSheet();
      // After setup, attach the confirmed PM via API
      // The webhook will handle the rest; for now just reload
      await ref.read(cardProvider.notifier).load();
      if (mounted) setState(() => _showAdd = false);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red[600]));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mes cartes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showAdd = !_showAdd),
            icon: Icon(_showAdd ? Icons.close : Icons.add, color: AppColors.primary, size: 18),
            label: Text(_showAdd ? 'Annuler' : 'Ajouter', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardProvider.notifier).load(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add card
            if (_showAdd && state.setupIntentSecret != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ajouter une carte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  const Text('Visa, Mastercard, UnionPay acceptés', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _adding ? null : () => _addCard(state.setupIntentSecret!),
                      icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.credit_card, size: 18),
                      label: Text(_adding ? 'Traitement...' : 'Saisir les informations de la carte'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_outline, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    const Text('Sécurisé par Stripe — données chiffrées', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            if (state.isLoading) const Center(child: CircularProgressIndicator())
            else if (state.cards.isEmpty && !_showAdd)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(children: [
                    const Icon(Icons.credit_card_outlined, size: 56, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 16),
                    const Text('Aucune carte enregistrée', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => _showAdd = true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Ajouter une carte'),
                    ),
                  ]),
                ),
              )
            else
              ...state.cards.map((card) => _CardTile(card: card, onSetDefault: () => ref.read(cardProvider.notifier).setDefault(card.id), onDelete: () => ref.read(cardProvider.notifier).delete(card.id))),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback onSetDefault, onDelete;
  const _CardTile({required this.card, required this.onSetDefault, required this.onDelete});

  Color get _brandColor => switch (card.brand) {
    'visa'       => const Color(0xFF1A1F71),
    'mastercard' => const Color(0xFFEB001B),
    'unionpay'   => const Color(0xFFD4132B),
    _            => const Color(0xFF374151),
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(
      children: [
        Container(height: 4, decoration: BoxDecoration(color: _brandColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(card.brand.toUpperCase().substring(0, card.brand.length.clamp(0, 4)), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _brandColor))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•••• •••• •••• ${card.lastFour}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827))),
              Text('Exp. ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ])),
            if (card.isDefault)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text('Par défaut', style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600))),
          ]),
        ),
        const Divider(height: 1),
        Row(children: [
          if (!card.isDefault)
          Expanded(child: TextButton(onPressed: onSetDefault, child: const Text('Définir par défaut', style: TextStyle(fontSize: 13)))),
          Expanded(child: TextButton(onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Supprimer ?'), content: Text('Supprimer ${card.displayName} ?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red)))]));
            if (ok == true) onDelete();
          }, child: const Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.red)))),
        ]),
      ],
    ),
  );
}
