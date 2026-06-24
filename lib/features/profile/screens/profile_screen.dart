import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n      = AppLocalizations.of(context)!;
    final auth      = ref.watch(authProvider);
    final user      = auth.user;
    final locale    = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar + name ─────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: user?.profilePhotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(user!.profilePhotoUrl!,
                              fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            '${user?.firstName.isNotEmpty == true ? user!.firstName[0] : 'U'}'
                            '${user?.lastName.isNotEmpty == true ? user!.lastName[0] : ''}',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17)),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _pill(
                          user?.isKycApproved == true
                              ? 'KYC ✓'
                              : l10n.kycRequired,
                          user?.isKycApproved == true
                              ? Colors.green
                              : Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        _pill('Niveau ${user?.kycLevel ?? 0}', Colors.blue),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Compte ────────────────────────────────────────────────────
          _Section(title: l10n.settings, items: [
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Informations personnelles',
              onTap: () => _showEditProfile(context, ref),
            ),
            _MenuItem(
              icon: Icons.lock_outline,
              label: l10n.passwordChanged,
              onTap: () => _showChangePassword(context, ref),
            ),
            _MenuItem(
              icon: Icons.pin_outlined,
              label: l10n.createPin,
              onTap: () => context.go('/pin'),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Sécurité ──────────────────────────────────────────────────
          _Section(title: 'Sécurité', items: [
            _MenuItem(
              icon: Icons.verified_user_outlined,
              label: l10n.kyc,
              onTap: () => context.go('/kyc'),
            ),
            _MenuItem(
              icon: Icons.credit_card_outlined,
              label: l10n.myCards,
              onTap: () => context.go('/cartes'),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Apparence ─────────────────────────────────────────────────
          _Section(title: l10n.appearance, items: [
            // Langue
            _MenuItemCustom(
              icon: Icons.language_outlined,
              label: l10n.language,
              trailing: _LanguageToggle(
                current: locale.languageCode,
                onChanged: (code) =>
                    ref.read(localeProvider.notifier).setLocale(code),
              ),
            ),
            // Thème
            _MenuItemCustom(
              icon: Icons.brightness_6_outlined,
              label: l10n.theme,
              trailing: _ThemeToggle(
                current: themeMode,
                lightLabel: l10n.lightMode,
                darkLabel: l10n.darkMode,
                systemLabel: l10n.systemMode,
                onChanged: (mode) =>
                    ref.read(themeProvider.notifier).setTheme(mode),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Déconnexion ───────────────────────────────────────────────
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.logout, color: AppColors.primary),
              title: Text(l10n.logout,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('AfriYuan v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color[700],
                fontWeight: FontWeight.w600)),
      );

  void _showEditProfile(BuildContext context, WidgetRef ref) {
    final user   = ref.read(authProvider).user;
    final firstC = TextEditingController(text: user?.firstName);
    final lastC  = TextEditingController(text: user?.lastName);
    final emailC = TextEditingController(text: user?.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier le profil',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _inputField('Prénom', firstC),
            const SizedBox(height: 12),
            _inputField('Nom', lastC),
            const SizedBox(height: 12),
            _inputField('Email', emailC,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await ApiClient.instance.dio.patch(Endpoints.profile,
                      data: {
                        'first_name': firstC.text,
                        'last_name': lastC.text,
                        'email': emailC.text,
                      });
                  await ref.read(authProvider.notifier).loadUser();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currC = TextEditingController();
    final newC  = TextEditingController();
    final confC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Changer le mot de passe',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _inputField('Mot de passe actuel', currC, obscure: true),
            const SizedBox(height: 12),
            _inputField('Nouveau mot de passe', newC, obscure: true),
            const SizedBox(height: 12),
            _inputField('Confirmer', confC, obscure: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await ApiClient.instance.dio.patch(
                      Endpoints.changePassword,
                      data: {
                        'current_password': currC.text,
                        'password': newC.text,
                        'password_confirmation': confC.text,
                      });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Modifier'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    bool obscure = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            obscureText: obscure,
          ),
        ],
      );
}

// ── Language toggle ───────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle(
      {required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['fr', 'en'].map((code) {
          final active = current == code;
          return GestureDetector(
            onTap: () => onChanged(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Theme toggle ──────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({
    required this.current,
    required this.lightLabel,
    required this.darkLabel,
    required this.systemLabel,
    required this.onChanged,
  });
  final ThemeMode current;
  final String lightLabel;
  final String darkLabel;
  final String systemLabel;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (ThemeMode.light,  Icons.light_mode,    lightLabel),
      (ThemeMode.dark,   Icons.dark_mode,     darkLabel),
      (ThemeMode.system, Icons.brightness_auto, systemLabel),
    ];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (mode, icon, _) = item;
          final active = current == mode;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textSecondary),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
          ),
          Card(child: Column(children: items)),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading:
            Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.border),
        onTap: onTap,
      );
}

class _MenuItemCustom extends StatelessWidget {
  const _MenuItemCustom(
      {required this.icon, required this.label, required this.trailing});
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        leading:
            Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: trailing,
      );
}
