import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/injection_container.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../bloc/colis_state.dart';
import 'home_page.dart';
import 'reception_envoi_page.dart';
import 'suivi_page.dart';
import 'notifications_page.dart';

class MainClientPage extends StatefulWidget {
  final User? user;
  const MainClientPage({super.key, this.user});

  @override
  State<MainClientPage> createState() => _MainClientPageState();
}

class _MainClientPageState extends State<MainClientPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<AnimationController> _controllers;

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.all_inbox_rounded, label: 'Mes colis'),
    _NavItem(icon: Icons.timeline_rounded, label: 'Suivi'),
    _NavItem(icon: Icons.notifications_rounded, label: 'Notifs'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      ),
    );
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    _controllers[_selectedIndex].reverse();
    setState(() => _selectedIndex = index);
    _controllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ColisBloc>()
        ..add(LoadStatistiques())
        ..add(LoadColisEnvoyes())
        ..add(LoadColisRecus())
        ..add(LoadNotifications()),
      child: Builder(builder: (context) {
        final pages = [
          HomePage(user: widget.user),
          ReceptionEnvoiPage(user: widget.user),
          SuiviPage(user: widget.user),
          NotificationsPage(
            user: widget.user,
            onVoirColis: () => _onTap(1), // → onglet "Mes colis"
          ),
        ];
        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedIndex,
            items: _items,
            controllers: _controllers,
            onTap: _onTap,
          ),
        );
      }),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final List<AnimationController> controllers;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.items,
    required this.controllers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<ColisBloc, ColisState>(
      buildWhen: (prev, curr) {
        final prevUnread = prev.notifications.where((n) => !n.lue).length;
        final currUnread = curr.notifications.where((n) => !n.lue).length;
        return prevUnread != currUnread;
      },
      builder: (context, state) {
        final unreadCount =
            state.notifications.where((n) => !n.lue).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding > 0 ? 4 : 10),
              child: Row(
                children: List.generate(items.length, (i) {
                  final isSelected = i == selectedIndex;
                  final item = items[i];
                  final showBadge = i == 3 && unreadCount > 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: controllers[i],
                        builder: (_, __) {
                          final t = controllers[i].value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pill indicateur
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColor.kPrimary
                                          .withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Icône avec scale
                                      Transform.scale(
                                        scale: 1.0 + (t * 0.18),
                                        child: Icon(
                                          item.icon,
                                          size: 22,
                                          color: isSelected
                                              ? AppColor.kPrimary
                                              : AppColor.kGrayscale40,
                                        ),
                                      ),
                                      // Badge notifications
                                      if (showBadge)
                                        Positioned(
                                          right: -8,
                                          top: -6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5),
                                            ),
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : '$unreadCount',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Label
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isSelected ? 11 : 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColor.kPrimary
                                      : AppColor.kGrayscale40,
                                ),
                                child: Text(item.label,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
