import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Row(children: [
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  if (provider.nonLues > 0)
                    Text('${provider.nonLues} non lue(s)',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12)),
                ]),
            const Spacer(),
            if (provider.nonLues > 0)
              GestureDetector(
                onTap: () => context.read<NotificationProvider>()
                    .marquerToutesLues(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Tout lire',
                      style: TextStyle(color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),

        // ── Liste
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
              : provider.notifications.isEmpty
              ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary, size: 48)),
              const SizedBox(height: 16),
              const Text('Aucune notification',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text('Vous serez notifié ici',
                  style: TextStyle(fontSize: 13,
                      color: AppColors.textLight)),
            ],
          ))
              : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context
                .read<NotificationProvider>().charger(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (_, i) => _NotifCard(
                notif: provider.notifications[i],
                onTap: () => context
                    .read<NotificationProvider>()
                    .marquerLue(
                    provider.notifications[i]['id']),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  bool get _isLue => notif['lue'] == true;

  Color get _typeColor {
    switch (notif['type']) {
      case 'confirmation': return AppColors.success;
      case 'arrivee':      return AppColors.accent;
      case 'perte':        return AppColors.error;
      case 'alerte':       return AppColors.warning;
      default:             return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (notif['type']) {
      case 'confirmation': return Icons.confirmation_num_rounded;
      case 'arrivee':      return Icons.luggage_rounded;
      case 'perte':        return Icons.report_problem_rounded;
      case 'alerte':       return Icons.notifications_rounded;
      default:             return Icons.info_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7)     return 'Il y a ${diff.inDays}j';
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${date.day} ${months[date.month-1]}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _isLue ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isLue ? Colors.white : AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLue
              ? const Color(0xFFE2E8F0)
              : _typeColor.withOpacity(0.3),
          width: _isLue ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(_isLue ? 0.03 : 0.06),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(notif['message'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _isLue
                            ? FontWeight.w500 : FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.4,
                      ))),
                  if (!_isLue)
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _typeColor,
                          shape: BoxShape.circle,
                        )),
                ]),
                const SizedBox(height: 6),
                Text(_formatDate(notif['created_at']),
                    style: TextStyle(fontSize: 11,
                        color: AppColors.textLight)),
              ],
            )),
          ]),
    ),
  );
}