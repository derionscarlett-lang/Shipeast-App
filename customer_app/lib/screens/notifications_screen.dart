import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  DateTime? _lastReadAt;
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;
  StreamSubscription<Map<String, dynamic>?>? _profileSub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _subscribe();
    _markRead();
  }

  void _subscribe() {
    _notifSub = FirestoreService.notificationsStream().listen((notifs) {
      if (mounted) setState(() { _notifications = notifs; _loading = false; });
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileSub = FirestoreService.watchUserProfile(uid).listen((data) {
        if (mounted) {
          final ts = data?['notificationsReadAt'] as Timestamp?;
          setState(() => _lastReadAt = ts?.toDate());
        }
      });
    }
  }

  Future<void> _markRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService.markNotificationsRead(uid);
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  bool _isUnread(Map<String, dynamic> notif) {
    if (_lastReadAt == null) return true;
    final ts = notif['createdAt'] as Timestamp?;
    if (ts == null) return false;
    return ts.toDate().isAfter(_lastReadAt!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        color: Colors.white,
        child: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You're all caught up!",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _buildCard(_notifications[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> notif) {
    final title = notif['title'] as String? ?? 'Notification';
    final message = notif['message'] as String? ?? '';
    final type = notif['type'] as String? ?? 'info';
    final ts = notif['createdAt'] as Timestamp?;
    final unread = _isUnread(notif);

    final iconData = type == 'order'
        ? Icons.receipt_long
        : type == 'promo'
            ? Icons.local_offer
            : Icons.notifications;
    final iconColor = type == 'order'
        ? AppTheme.primary
        : type == 'promo'
            ? const Color(0xFFD97706)
            : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFFF8F8) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: unread ? Border.all(color: const Color(0xFFFFD0D7), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: Icon(iconData, size: 20, color: iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dark,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
                if (ts != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _timeAgo(ts.toDate()),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
