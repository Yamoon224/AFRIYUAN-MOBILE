import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFF9B0E1F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bonjour 👋', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          Text(auth.user?.firstName ?? 'Utilisateur', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ]),
                        Row(children: [
                          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24), onPressed: () => context.go('/notifications')),
                          GestureDetector(
                            onTap: () => context.go('/profil'),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(auth.user?.firstName.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // KYC banner
                    if (auth.user != null && !auth.user!.isKycApproved)
                    GestureDetector(
                      onTap: () => context.go('/kyc'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Complétez votre vérification KYC pour augmenter vos limites', style: TextStyle(color: Colors.white, fontSize: 12))),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // Send button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/transfers/nouveau'),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Nouveau transfert', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                dashboard.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Erreur: $e'),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _statCard('Total envoyé', '${NumberFormat('#,###', 'fr').format(data.totalSent)} XOF', Icons.trending_up, Colors.orange),
                        const SizedBox(width: 12),
                        _statCard('Bénéficiaires', '${data.beneficiariesCount}', Icons.people_outline, Colors.blue),
                      ]),
                      const SizedBox(height: 20),

                      // Exchange rates
                      const Text('Taux du jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 12),
                      if (data.rates.isEmpty) Text('Aucun taux disponible', style: TextStyle(color: Colors.grey[400]))
                      else SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.rates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final r = data.rates[i];
                            return Container(
                              width: 140, padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${r['from_currency']} → ${r['to_currency']}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(double.tryParse(r['margin_rate'].toString())?.toStringAsFixed(4) ?? '—', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                              ]),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recent transactions
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Transactions récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        TextButton(onPressed: () => context.go('/transfers'), child: const Text('Tout voir', style: TextStyle(color: Color(0xFFD4132B), fontSize: 13))),
                      ]),
                      const SizedBox(height: 8),
                      if (data.recentTransactions.isEmpty)
                        _emptyTransactions(context)
                      else
                        ...data.recentTransactions.map((tx) => _txTile(tx, context)),
                    ],
                  ),
                ),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ]),
    ),
  );

  Widget _emptyTransactions(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(children: [
      Icon(Icons.swap_horiz, size: 40, color: Colors.grey[300]),
      const SizedBox(height: 10),
      Text('Aucune transaction', style: TextStyle(color: Colors.grey[400])),
      const SizedBox(height: 8),
      TextButton(onPressed: () => context.go('/transfers/nouveau'), child: const Text('Faire un transfert', style: TextStyle(color: Color(0xFFD4132B)))),
    ]),
  );

  Widget _txTile(TransactionModel tx, BuildContext context) => GestureDetector(
    onTap: () => context.go('/transfers/${tx.uuid}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: tx.isAfricaToChina ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(tx.isAfricaToChina ? '🌍' : '🇨🇳', style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.beneficiaryName ?? 'Bénéficiaire', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
          Text(tx.referenceNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${NumberFormat('#,###', 'fr').format(tx.sendAmount)} ${tx.sendCurrency}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: tx.isCompleted ? Colors.green[50] : Colors.blue[50], borderRadius: BorderRadius.circular(6)),
            child: Text(tx.isCompleted ? 'Complété' : 'En cours', style: TextStyle(fontSize: 10, color: tx.isCompleted ? Colors.green[700] : Colors.blue[700], fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    ),
  );
}
