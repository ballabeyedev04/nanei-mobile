import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/injection_container.dart';
import 'package:dio/dio.dart';
import '../../../domain/entities/notification_model.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../bloc/colis_state.dart';
import '../../widgets/empty_state.dart';

class NotificationsPage extends StatelessWidget {
  final User? user;
  final VoidCallback? onVoirColis;

  const NotificationsPage({super.key, this.user, this.onVoirColis});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColisBloc, ColisState>(
      builder: (context, state) {
        final notifications = state.notifications;
        final unreadCount = notifications.where((n) => !n.lue).length;
        final readCount = notifications.length - unreadCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: RefreshIndicator(
            onRefresh: () async =>
                context.read<ColisBloc>().add(LoadNotifications()),
            color: AppColor.kPrimary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(
                  context,
                  total: notifications.length,
                  unread: unreadCount,
                  read: readCount,
                ),
                if (notifications.isEmpty)
                  SliverFillRemaining(
                    child: buildEmptyState(
                      icon: Icons.notifications_none_rounded,
                      message: 'Aucune notification pour le moment.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _NotifCard(
                          notif: notifications[index],
                          index: index,
                          onVoirColis: onVoirColis,
                          onTap: () {
                            if (!notifications[index].lue) {
                              context.read<ColisBloc>().add(
                                    MarquerNotificationLueRequested(
                                        notifications[index].id),
                                  );
                            }
                          },
                        ),
                        childCount: notifications.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context, {
    required int total,
    required int unread,
    required int read,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kGrayscaleDark100,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unread > 0
                                ? '$unread message${unread > 1 ? 's' : ''} non lu${unread > 1 ? 's' : ''}'
                                : 'Tout est à jour',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: unread > 0
                                  ? AppColor.kPrimary
                                  : AppColor.kGrayscale40,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        if (unread > 0) ...[
                          _iconAction(
                            icon: Icons.done_all_rounded,
                            color: AppColor.kPrimary,
                            bg: AppColor.kAccentSoft,
                            onTap: () => _markAllAsRead(context),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _iconAction(
                          icon: Icons.refresh_rounded,
                          color: AppColor.kGrayscale60,
                          bg: const Color(0xFFF2F4F8),
                          onTap: () =>
                              context.read<ColisBloc>().add(LoadNotifications()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stat cards
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        label: 'Total',
                        count: total,
                        icon: Icons.notifications_rounded,
                        color: const Color(0xFF7C3AED),
                        bg: const Color(0xFFF5F3FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: 'Non lues',
                        count: unread,
                        icon: Icons.mark_email_unread_rounded,
                        color: AppColor.kPrimary,
                        bg: AppColor.kAccentSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: 'Lues',
                        count: read,
                        icon: Icons.mark_email_read_rounded,
                        color: const Color(0xFF059669),
                        bg: const Color(0xFFD1FAE5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColor.kGrayscaleDark100,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      await sl<Dio>().post('/client/notifications/mark-all-read');
    } catch (_) {}
    if (context.mounted) {
      context.read<ColisBloc>().add(LoadNotifications());
    }
  }
}

// ── Carte notification ─────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onVoirColis;

  const _NotifCard({
    required this.notif,
    required this.index,
    required this.onTap,
    this.onVoirColis,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final n = notif;
    final isUnread = !n.lue;
    final initials =
        '${n.expediteurPrenom.isNotEmpty ? n.expediteurPrenom[0] : ''}${n.expediteurNom.isNotEmpty ? n.expediteurNom[0] : ''}'
            .toUpperCase();
    final expediteur = '${n.expediteurPrenom} ${n.expediteurNom}'.trim();
    final accentColor =
        isUnread ? AppColor.kPrimary : const Color(0xFF059669);

    return TweenAnimationBuilder<double>(
      key: ValueKey(n.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index * 45),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child:
            Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? AppColor.kPrimary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent gauche coloré
                Container(width: 5, color: accentColor),

                // Contenu principal
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      splashColor: accentColor.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Ligne 1 : avatar + nom + date ─────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isUnread
                                          ? [
                                              AppColor.kPrimary,
                                              AppColor.kPrimaryLight,
                                            ]
                                          : [
                                              const Color(0xFF6B7280),
                                              const Color(0xFF9CA3AF),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials.isEmpty ? '?' : initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expediteur.isEmpty
                                            ? 'Expéditeur inconnu'
                                            : expediteur,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.kGrayscaleDark100,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatDate(n.date),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColor.kGrayscale40,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge lu / non-lu
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isUnread ? 'Nouveau' : 'Lu',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            Divider(height: 1, color: Colors.grey.shade100),
                            const SizedBox(height: 14),

                            // ── Ligne 2 : MESSAGE texte lisible ──────────
                            _buildMessage(
                              reference: n.referenceColis,
                              expediteur: expediteur,
                              type: n.typeColis,
                              isUnread: isUnread,
                            ),

                            // Description optionnelle
                            if (n.descriptionColis.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.notes_rounded,
                                        size: 12,
                                        color: AppColor.kGrayscale40),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        n.descriptionColis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColor.kGrayscale60,
                                          fontStyle: FontStyle.italic,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // ── Ligne 3 : bouton VOIR ─────────────────────
                            Row(
                              children: [
                                // Email expéditeur
                                if (n.expediteurEmail.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.mail_outline_rounded,
                                            size: 12,
                                            color: AppColor.kGrayscale20),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            n.expediteurEmail,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AppColor.kGrayscale40,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Spacer(),

                                // Bouton Voir
                                GestureDetector(
                                  onTap: () {
                                    // Marquer comme lu
                                    if (isUnread) onTap();
                                    // Naviguer vers Mes Colis
                                    onVoirColis?.call();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF7A00),
                                          Color(0xFFE06A00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColor.kPrimary
                                              .withValues(alpha: 0.30),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Voir le colis',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Message texte lisible ─────────────────────────────────────────────────

  Widget _buildMessage({
    required String reference,
    required String expediteur,
    required String type,
    required bool isUnread,
  }) {
    final styleNormal = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: const Color(0xFF4B5563),
      height: 1.6,
    );
    final styleBold = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColor.kGrayscaleDark100,
      height: 1.6,
    );
    final styleAccent = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColor.kPrimary,
      height: 1.6,
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Vous devez recevoir un colis', style: styleNormal),
          if (type.isNotEmpty) ...[
            TextSpan(text: ' de type ', style: styleNormal),
            TextSpan(text: type, style: styleBold),
          ],
          if (reference.isNotEmpty) ...[
            TextSpan(text: ' avec la référence ', style: styleNormal),
            TextSpan(text: '#$reference', style: styleAccent),
          ],
          if (expediteur.isNotEmpty) ...[
            TextSpan(text: ' de la part de ', style: styleNormal),
            TextSpan(text: expediteur, style: styleBold),
          ],
          TextSpan(text: '.', style: styleNormal),
        ],
      ),
    );
  }
}
