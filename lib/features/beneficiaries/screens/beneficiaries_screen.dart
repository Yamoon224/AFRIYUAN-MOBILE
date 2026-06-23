import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/beneficiary_provider.dart';

class BeneficiariesScreen extends ConsumerWidget {
  const BeneficiariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(beneficiaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Bénéficiaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => context.go('/beneficiaries/nouveau')),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.beneficiaries.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_outline, size: 56, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 16),
                  const Text('Aucun bénéficiaire', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/beneficiaries/nouveau'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Ajouter'),
                  ),
                ]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(beneficiaryProvider.notifier).load(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.beneficiaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = state.beneficiaries[i];
                      return Dismissible(
                        key: Key(b.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                            title: const Text('Supprimer ?'),
                            content: Text('Supprimer ${b.displayName} ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                            ],
                          ));
                        },
                        onDismissed: (_) => ref.read(beneficiaryProvider.notifier).delete(b.id),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: b.isChina ? AppColors.primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                              child: Center(child: Text(b.isChina ? '🇨🇳' : '🌍', style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text(b.receiveMethod.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            ])),
                            GestureDetector(
                              onTap: () => context.go('/transfers/nouveau'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                child: Text('Envoyer', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
