import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transfer_provider.dart';

class TransferDetailScreen extends ConsumerWidget {
  final String uuid;
  const TransferDetailScreen({super.key, required this.uuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(uuid));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Détail du transfert', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur: $e')),
        data: (tx) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Amount card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tx.isAfricaToChina ? [AppColors.primary, const Color(0xFF9B0E1F)] : [const Color(0xFF1D4ED8), const Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Text(tx.isAfricaToChina ? '🌍 → 🇨🇳' : '🇨🇳 → 🌍', style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 12),
                Text('${NumberFormat('#,###', 'fr').format(tx.sendAmount)} ${tx.sendCurrency}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('→ ¥${NumberFormat('#,##0.00').format(tx.receiveAmount)} CNY',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                const SizedBox(height: 16),
                _StatusPill(status: tx.status),
              ]),
            ),
            const SizedBox(height: 16),

            // Details
            _Card(title: 'Détails du transfert', children: [
              _Row('Référence',        tx.referenceNumber, mono: true),
              _Row('Montant envoyé',   '${NumberFormat('#,###').format(tx.sendAmount)} ${tx.sendCurrency}'),
              _Row('Frais',            '${NumberFormat('#,###').format(tx.feeAmount)} ${tx.sendCurrency}'),
              _Row('Taux de change',   '1 ${tx.sendCurrency} = ¥${tx.exchangeRate.toStringAsFixed(4)}'),
              _Row('Montant reçu',     '¥${NumberFormat('#,##0.00').format(tx.receiveAmount)} CNY', bold: true),
              _Row('Méthode',          tx.paymentMethod.replaceAll('_', ' ')),
              _Row('Date',             DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt)),
            ]),
            const SizedBox(height: 12),

            if (tx.beneficiaryName != null)
            _Card(title: 'Bénéficiaire', children: [
              _Row('Nom', tx.beneficiaryName!),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
      const Divider(height: 20),
      ...children,
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool mono, bold;
  const _Row(this.label, this.value, {this.mono = false, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? const Color(0xFFD4132B) : const Color(0xFF111827), fontFamily: mono ? 'monospace' : null)),
    ]),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'completed'  => ('✓ Complété', Colors.green[100]!, Colors.green[800]!),
      'processing' || 'payment_confirmed' || 'sent_to_beneficiary' => ('⏳ En cours', Colors.blue[100]!, Colors.blue[800]!),
      'failed'     => ('✕ Échoué', Colors.red[100]!, Colors.red[800]!),
      'cancelled'  => ('Annulé', Colors.grey[200]!, Colors.grey[700]!),
      _            => (status, Colors.grey[200]!, Colors.grey[700]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
