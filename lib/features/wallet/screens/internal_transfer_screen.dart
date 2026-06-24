import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/wallet_provider.dart';

class InternalTransferScreen extends ConsumerStatefulWidget {
  const InternalTransferScreen({super.key});

  @override
  ConsumerState<InternalTransferScreen> createState() =>
      _InternalTransferScreenState();
}

class _InternalTransferScreenState
    extends ConsumerState<InternalTransferScreen> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final state = ref.watch(internalTransferProvider);
    final notifier = ref.read(internalTransferProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.internalTransfer)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Recipient search ─────────────────────────────────────────
            Text(l10n.recipient,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (state.selectedRecipient == null) ...[
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: l10n.searchRecipient,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                onChanged: (v) => notifier.searchRecipient(v),
              ),
              if (state.searchResults.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: state.searchResults.map((user) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(user.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                        title: Text(user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.email),
                        onTap: () {
                          notifier.selectRecipient(user);
                          _searchCtrl.clear();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ] else ...[
              // ── Selected recipient chip ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(state.selectedRecipient!.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.selectedRecipient!.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Text(state.selectedRecipient!.email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: notifier.clearRecipient,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Amount ──────────────────────────────────────────────────
            Text(l10n.transferAmount,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: '0.00'),
            ),

            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────────
            Text(l10n.description,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(hintText: l10n.description),
            ),

            const Spacer(),

            // ── Error ────────────────────────────────────────────────────
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.submitting ||
                        state.selectedRecipient == null
                    ? null
                    : _submit,
                child: state.submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n.confirmTransfer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n   = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.transferAmount)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final err = await ref
        .read(internalTransferProvider.notifier)
        .transfer(amount, _descCtrl.text);

    if (!mounted) return;

    if (err == null) {
      ref.read(walletProvider.notifier).load();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.transferSuccess),
        backgroundColor: Colors.green,
      ));
      context.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: Colors.red,
      ));
    }
  }
}
