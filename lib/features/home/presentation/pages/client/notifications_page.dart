import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/injection_container.dart';
import '../../../domain/entities/notification_model.dart';
import '../../widgets/empty_state.dart';

class NotificationsPage extends StatefulWidget {
  final User? user;
  const NotificationsPage({super.key, this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/client/mes-notification');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement notifications: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: AppColor.kBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? buildEmptyState(
        icon: Icons.notifications_none,
        message: 'Aucune notification pour le moment.',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.lue ? AppColor.kWhite : AppColor.kAccentSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: n.lue ? AppColor.kLine : AppColor.kPrimary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  n.lue ? Icons.notifications : Icons.notifications_active,
                  color: n.lue ? AppColor.kGrayscale40 : AppColor.kPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.titre,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColor.kGrayscale60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(n.date),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}