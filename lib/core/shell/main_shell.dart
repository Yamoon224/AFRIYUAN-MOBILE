import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,         activeIcon: Icons.home,          label: 'Accueil',      path: '/'),
    (icon: Icons.swap_horiz_outlined,   activeIcon: Icons.swap_horiz,    label: 'Transferts',   path: '/transfers'),
    (icon: Icons.people_outline,        activeIcon: Icons.people,        label: 'Bénéficiaires',path: '/beneficiaries'),
    (icon: Icons.person_outline,        activeIcon: Icons.person,        label: 'Profil',       path: '/profil'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transfers'))     return 1;
    if (location.startsWith('/beneficiaries')) return 2;
    if (location.startsWith('/profil'))        return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab   = _tabs[i];
              final active = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(tab.path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? tab.activeIcon : tab.icon,
                          color: active ? AppColors.primary : Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            color: active ? AppColors.primary : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
