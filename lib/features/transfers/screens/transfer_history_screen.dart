import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transfer_provider.dart';

class TransferHistoryScreen extends ConsumerStatefulWidget {
  const TransferHistoryScreen({super.key});
  @override
  ConsumerState<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends ConsumerState<TransferHistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        final state = ref.read(transferProvider);
        if (!state.isLoading && state.hasMore) ref.read(transferProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mes transferts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
            onPressed: () => context.go('/transfers/nouveau'),
          ),
        ],
      ),
      body: state.transactions.isEmpty && !state.isLoading
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.swap_horiz, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Aucune transaction', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/transfers/nouveau'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Faire un transfert'),
                ),
              ]),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(transferProvider.notifier).load(refresh: true),
              color: AppColors.primary,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: state.transactions.length + (state.isLoading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (i == state.transactions.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  final tx = state.transactions[i];
                  return _TransactionCard(tx: tx);
                },
              ),
            ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final dynamic tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isA2C = tx.isAfricaToChina;
    return GestureDetector(
      onTap: () => context.go('/transfers/${tx.uuid}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: isA2C ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(isA2C ? '🌍' : '🇨🇳', style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.beneficiaryName ?? 'Bénéficiaire', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(tx.referenceNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${NumberFormat('#,###', 'fr').format(tx.sendAmount)} ${tx.sendCurrency}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
              const SizedBox(height: 4),
              _StatusChip(status: tx.status),
            ]),
          ],
        ),
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
      'completed'  => ('Complété', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'processing' || 'payment_confirmed' || 'sent_to_beneficiary' => ('En cours', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'failed'     => ('Échoué', const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      'cancelled'  => ('Annulé', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      'refunded'   => ('Remboursé', const Color(0xFFFEF9C3), const Color(0xFFCA8A04)),
      _            => (status, const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
