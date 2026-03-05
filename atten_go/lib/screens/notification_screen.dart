import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/group_service.dart';
import '../services/attendance_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  List<Invitation> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await NotificationService.loadAll();
    final inv = await GroupService.getMyInvitations();
    if (mounted) setState(() { _notifications = n; _invitations = inv; _isLoading = false; });
  }

  Future<void> _acceptInvite(Invitation inv) async {
    final result = await GroupService.acceptInvitation(inv.id);
    if (result.success) {
      // Сбрасываем кеш чтобы приложение загрузило данные новой группы
      GroupService.invalidateCache();
      AttendanceService.invalidateCache();
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы присоединились к группе'), backgroundColor: Color(0xFF10232C)),
        );
        // Возвращаемся на главный экран чтобы данные обновились
        Navigator.pop(context);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Ошибка'), backgroundColor: const Color(0xFF10232C)),
      );
    }
  }

  Future<void> _declineInvite(Invitation inv) async {
    await GroupService.declineInvitation(inv.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Уведомления', style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: Icon(Icons.done_all_rounded, color: const Color(0xFF0D59F2), size: fs * 0.055),
              onPressed: () async {
                await NotificationService.markAllAsRead();
                _load();
              },
            ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF455664), height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0D59F2),
              backgroundColor: const Color(0xFF10232C),
              child: _invitations.isEmpty && _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: h * 0.3),
                        Center(
                          child: Column(children: [
                            Icon(Icons.notifications_none_rounded, color: const Color(0xFF455664), size: fs * 0.15),
                            SizedBox(height: fs * 0.03),
                            Text('Нет уведомлений', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.04)),
                          ]),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04).add(EdgeInsets.only(top: h * 0.02, bottom: h * 0.04)),
                      children: [
                        // Приглашения
                        if (_invitations.isNotEmpty) ...[
                          Text('Приглашения', style: TextStyle(color: Colors.white, fontSize: fs * 0.042, fontWeight: FontWeight.bold)),
                          SizedBox(height: h * 0.012),
                          ..._invitations.map((inv) => _invitationCard(fs, h, inv)),
                          SizedBox(height: h * 0.02),
                        ],
                        // Уведомления
                        if (_notifications.isNotEmpty) ...[
                          Text('История', style: TextStyle(color: Colors.white, fontSize: fs * 0.042, fontWeight: FontWeight.bold)),
                          SizedBox(height: h * 0.012),
                          ..._notifications.map((n) => _notificationCard(fs, h, n)),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _invitationCard(double fs, double h, Invitation inv) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.012),
      padding: EdgeInsets.all(fs * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF0D59F2).withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.group_add_rounded, color: const Color(0xFF0D59F2), size: fs * 0.05),
            SizedBox(width: fs * 0.025),
            Expanded(
              child: Text(
                inv.senderName ?? 'Пользователь',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          SizedBox(height: h * 0.008),
          Text(
            'Приглашает вас в группу «${inv.groupName ?? 'Группа'}»${inv.isStudent ? ' как участника' : ' как менеджера'}',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033),
          ),
          SizedBox(height: h * 0.015),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _declineInvite(inv),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: fs * 0.025),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(fs * 0.04),
                    border: Border.all(color: const Color(0xFF455664)),
                  ),
                  child: Center(child: Text('Отклонить', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.034, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: GestureDetector(
                onTap: () => _acceptInvite(inv),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: fs * 0.025),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D59F2),
                    borderRadius: BorderRadius.circular(fs * 0.04),
                  ),
                  child: Center(child: Text('Принять', style: TextStyle(color: Colors.white, fontSize: fs * 0.034, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _notificationCard(double fs, double h, AppNotification n) {
    return Dismissible(
      key: Key('n_${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => NotificationService.delete(n.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: fs * 0.05),
        decoration: BoxDecoration(color: const Color(0xFFF87171).withOpacity(0.2), borderRadius: BorderRadius.circular(fs * 0.04)),
        child: Icon(Icons.delete_outline, color: const Color(0xFFF87171), size: fs * 0.06),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.01),
        padding: EdgeInsets.all(fs * 0.035),
        decoration: BoxDecoration(
          color: n.isRead ? const Color(0xFF10232C) : const Color(0xFF10232C).withOpacity(0.9),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: n.isRead ? const Color(0xFF455664).withOpacity(0.5) : const Color(0xFF455664)),
        ),
        child: Row(children: [
          Container(
            width: fs * 0.1,
            height: fs * 0.1,
            decoration: BoxDecoration(
              color: const Color(0xFF0D59F2).withOpacity(0.15),
              borderRadius: BorderRadius.circular(fs * 0.03),
            ),
            child: Icon(
              n.type == 'invitation' ? Icons.group_add_rounded : Icons.notifications_rounded,
              color: const Color(0xFF0D59F2),
              size: fs * 0.05,
            ),
          ),
          SizedBox(width: fs * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: TextStyle(color: Colors.white, fontSize: fs * 0.035, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600)),
                if (n.body.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(n.body, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (!n.isRead)
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0D59F2), shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}