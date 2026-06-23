import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';

class _Notif {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const _Notif({required this.id, required this.type, required this.data, required this.isRead, required this.createdAt});

  factory _Notif.fromJson(Map<String, dynamic> j) => _Notif(
    id: j['id'], type: j['type'] ?? '',
    data: (j['data'] as Map<String, dynamic>?) ?? {},
    isRead: j['read_at'] != null,
    createdAt: DateTime.parse(j['created_at']),
  );
}

final _notifProvider = FutureProvider<List<_Notif>>((ref) async {
  final res = await ApiClient.instance.get(Endpoints.notifications);
  return (res.data['data'] as List).map((j) => _Notif.fromJson(j)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(_notifProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await ApiClient.instance.post(Endpoints.notificationsReadAll);
              ref.invalidate(_notifProvider);
            },
            child: Text('Tout lire', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_none, size: 56, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 16),
                const Text('Aucune notification', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
              ]))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_notifProvider),
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifTile(notif: list[i], onRead: () async {
                    await ApiClient.instance.post('${Endpoints.notifications}/${list[i].id}/read');
                    ref.invalidate(_notifProvider);
                  }, onTap: () {
                    final txId = list[i].data['transaction_id'];
                    if (txId != null) context.go('/transfers/$txId');
                  }),
                ),
              ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onRead, onTap;
  const _NotifTile({required this.notif, required this.onRead, required this.onTap});

  (IconData, Color) get _icon => switch (notif.type) {
    'transfer_completed' => (Icons.check_circle_outline, Colors.green),
    'transfer_failed'    => (Icons.error_outline, Colors.red),
    'kyc_approved'       => (Icons.verified_user_outlined, Colors.green),
    'kyc_rejected'       => (Icons.gpp_bad_outlined, Colors.red),
    _                    => (Icons.notifications_outlined, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _icon;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: notif.isRead ? const Color(0xFFF3F4F6) : AppColors.primary.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notif.data['title'] ?? notif.type.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
            if (notif.data['body'] != null) ...[const SizedBox(height: 2), Text(notif.data['body'], style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))],
            const SizedBox(height: 4),
            Text(DateFormat('dd/MM HH:mm').format(notif.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
          ])),
          if (!notif.isRead)
          Column(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(height: 4),
            GestureDetector(onTap: onRead, child: const Icon(Icons.done, size: 16, color: Color(0xFF9CA3AF))),
          ]),
        ]),
      ),
    );
  }
}
