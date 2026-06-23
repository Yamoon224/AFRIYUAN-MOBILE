import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827), elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Row(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: user?.profilePhotoUrl != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(user!.profilePhotoUrl!, fit: BoxFit.cover))
                    : Center(child: Text('${user?.firstName.substring(0, 1) ?? 'U'}${user?.lastName.substring(0, 1) ?? ''}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827))),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Row(children: [
                  _pill(user?.isKycApproved == true ? 'KYC ✓' : 'KYC requis', user?.isKycApproved == true ? Colors.green : Colors.amber),
                  const SizedBox(width: 6),
                  _pill('Niveau ${user?.kycLevel ?? 0}', Colors.blue),
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Menu items
          _Section(title: 'Compte', items: [
            _MenuItem(icon: Icons.person_outline, label: 'Informations personnelles', onTap: () => _showEditProfile(context, ref)),
            _MenuItem(icon: Icons.lock_outline, label: 'Changer le mot de passe', onTap: () => _showChangePassword(context, ref)),
            _MenuItem(icon: Icons.pin_outlined, label: 'Code PIN de transaction', onTap: () => context.go('/pin')),
          ]),
          const SizedBox(height: 12),

          _Section(title: 'Sécurité', items: [
            _MenuItem(icon: Icons.verified_user_outlined, label: 'Vérification d\'identité (KYC)', onTap: () => context.go('/kyc')),
            _MenuItem(icon: Icons.credit_card_outlined, label: 'Mes cartes', onTap: () => context.go('/cartes')),
          ]),
          const SizedBox(height: 12),

          _Section(title: 'Préférences', items: [
            _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.go('/notifications')),
            _MenuItem(icon: Icons.language_outlined, label: 'Langue', trailing: 'Français', onTap: () {}),
          ]),
          const SizedBox(height: 12),

          // Logout
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Se déconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('AfriYuan v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
        ],
      ),
    );
  }

  Widget _pill(String label, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color[700], fontWeight: FontWeight.w600)),
  );

  void _showEditProfile(BuildContext context, WidgetRef ref) {
    final user   = ref.read(authProvider).user;
    final firstC = TextEditingController(text: user?.firstName);
    final lastC  = TextEditingController(text: user?.lastName);
    final emailC = TextEditingController(text: user?.email);

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Modifier le profil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _inputField('Prénom', firstC),
          const SizedBox(height: 12),
          _inputField('Nom', lastC),
          const SizedBox(height: 12),
          _inputField('Email', emailC, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await ApiClient.instance.patch(Endpoints.profile, data: {'first_name': firstC.text, 'last_name': lastC.text, 'email': emailC.text});
                await ref.read(authProvider.notifier).loadUser();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currC = TextEditingController();
    final newC  = TextEditingController();
    final confC = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Changer le mot de passe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _inputField('Mot de passe actuel', currC, obscure: true),
          const SizedBox(height: 12),
          _inputField('Nouveau mot de passe', newC, obscure: true),
          const SizedBox(height: 12),
          _inputField('Confirmer', confC, obscure: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await ApiClient.instance.patch(Endpoints.changePassword, data: {'current_password': currC.text, 'password': newC.text, 'password_confirmation': confC.text});
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {TextInputType? keyboard, bool obscure = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, obscureText: obscure,
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4132B), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        )),
    ],
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]), child: Column(children: items)),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: const Color(0xFF6B7280), size: 22),
    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
      const SizedBox(width: 4),
      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD1D5DB)),
    ]),
    onTap: onTap,
  );
}
