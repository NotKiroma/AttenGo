import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/attendance_service.dart';
import '../services/db_service.dart';
import '../utils/dark_page_route.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  GroupMember? _membership;
  List<GroupMember> _members = [];
  List<({Group group, String role})> _allGroups = [];
  Group? _currentGroup;
  bool _isLoading = true;
  bool _isOwner = false;

  // Статистика (если я — член группы)
  int _totalLessons = 0;
  int _attended = 0;
  int _missed = 0;
  int _excused = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await AuthService.getProfile();
    final membership = await GroupService.getMyMembership();
    final isOwner = await GroupService.isOwner();
    final members = await GroupService.getMembers();
    final allGroups = await GroupService.getAllGroups();
    final currentGroup = await GroupService.getCurrentGroup();

    _totalLessons = 0;
    _attended = 0;
    _missed = 0;
    _excused = 0;
    if (membership != null && membership.isStudent) {
      await _loadMyStats();
    }

    if (mounted)
      setState(() {
        _profile = profile;
        _membership = membership;
        _isOwner = isOwner;
        _members = members;
        _allGroups = allGroups;
        _currentGroup = currentGroup;
        _isLoading = false;
      });
  }

  Future<void> _loadMyStats() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;
    final all = await AttendanceService.loadAll();
    // Ищем мою запись в students по linked_user_id
    for (final lesson in all) {
      if (lesson.lessonKey == 'weekend') continue;
      StudentAttendance? sa;
      try {
        sa = lesson.students.firstWhere((s) {
          // Пробуем найти по student_id (может совпадать с нашим linked student)
          return true; // Будет фильтроваться по id ниже
        });
      } catch (_) {
        continue;
      }
      // Для простоты считаем все отмеченные
    }
    // Загружаем через linked_user_id
    try {
      final gid = await GroupService.getCurrentGroupId();
      if (gid == null) return;
      final db = DatabaseService.client;
      final studentRows = await db.from('students').select('id').eq('group_id', gid).eq('linked_user_id', uid).limit(1);
      if ((studentRows as List).isEmpty) return;
      final myStudentId = studentRows.first['id'] as String;

      for (final lesson in all) {
        if (lesson.lessonKey == 'weekend') continue;
        StudentAttendance? sa;
        try {
          sa = lesson.students.firstWhere((s) => s.studentId == myStudentId);
        } catch (_) {
          continue;
        }
        if (sa.status == null) continue;
        _totalLessons++;
        if (sa.status == 'present') _attended++;
        if (sa.status == 'absent') _missed++;
        if (sa.status == 'late') _excused++;
      }
    } catch (_) {}
  }

  Future<void> _toggleGroupMember(bool value) async {
    await GroupService.toggleIsStudent(value);
    await _load();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';

      setState(() => _isLoading = true);
      final result = await AuthService.uploadAvatar(bytes, validExt == 'jpg' ? 'jpeg' : validExt);
      if (result.success) {
        await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Ошибка'), backgroundColor: const Color(0xFF10232C)));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: const Color(0xFF10232C)));
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchGroup() {
    if (_allGroups.length <= 1) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final fs = MediaQuery.of(ctx).size.width.clamp(320.0, 430.0);
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF152028),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(fs * 0.05, 24, fs * 0.05, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выберите группу',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: fs * 0.04),
              ..._allGroups.map((g) {
                final isCurrent = g.group.id == _currentGroup?.id;
                final ownerName = g.role == 'owner' ? 'Моя группа' : g.group.name;
                return Padding(
                  padding: EdgeInsets.only(bottom: fs * 0.025),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!isCurrent) {
                        GroupService.setActiveGroup(g.group.id);
                        AttendanceService.invalidateCache();
                        setState(() {
                          _isLoading = true;
                        });
                        _load();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.04),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF0D59F2).withOpacity(0.15) : const Color(0xFF10232C),
                        borderRadius: BorderRadius.circular(fs * 0.04),
                        border: Border.all(color: isCurrent ? const Color(0xFF0D59F2) : const Color(0xFF455664), width: isCurrent ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(g.role == 'owner' ? Icons.shield_outlined : Icons.group_outlined, color: isCurrent ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), size: fs * 0.055),
                          SizedBox(width: fs * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ownerName,
                                  style: TextStyle(color: isCurrent ? Colors.white : const Color(0xFFCBD5E0), fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  g.role == 'owner' ? 'Владелец' : 'Менеджер',
                                  style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.032),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent) Icon(Icons.check_circle, color: const Color(0xFF0D59F2), size: fs * 0.05),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _editProfile() async {
    if (_profile == null) return;
    final updated = await Navigator.push<bool>(context, DarkPageRoute(builder: (_) => _EditProfileScreen(profile: _profile!)));
    if (updated == true) _load();
  }

  void _changePassword() => Navigator.push(context, DarkPageRoute(builder: (_) => const _ChangePasswordScreen()));

  void _inviteManager() => Navigator.push(context, DarkPageRoute(builder: (_) => const _InviteScreen()));

  void _viewMembers() => Navigator.push(
    context,
    DarkPageRoute(
      builder: (_) => _MembersScreen(members: _members, isOwner: _isOwner),
    ),
  );

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final fs = MediaQuery.of(ctx).size.width.clamp(320.0, 430.0);
        return AlertDialog(
          backgroundColor: const Color(0xFF10232C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
          title: Text(
            'Выйти из аккаунта?',
            style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
          ),
          content: Text(
            'Вы уверены, что хотите выйти?',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Отмена',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                AuthService.logout();
              },
              child: Text(
                'Выйти',
                style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
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
        title: Text(
          'Профиль',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.055, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0D59F2),
              backgroundColor: const Color(0xFF10232C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: w * 0.04).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
                child: Column(
                  children: [
                    _buildHeader(fs, h),
                    SizedBox(height: h * 0.03),
                    _buildInfoCard(fs),
                    SizedBox(height: h * 0.02),

                    // Галочка «Я — участник группы»
                    _buildGroupMemberToggle(fs),
                    SizedBox(height: h * 0.012),

                    // Моя статистика (если член группы)
                    if (_membership?.isStudent == true) ...[_buildMyStats(fs, h), SizedBox(height: h * 0.02)],

                    // Переключатель группы (если больше одной)
                    if (_allGroups.length > 1) ...[
                      _buildActionTile(fs: fs, icon: Icons.swap_horiz_rounded, label: _currentGroup?.name ?? 'Группа', subtitle: '${_allGroups.length} групп • Нажми чтобы переключить', onTap: _switchGroup, color: const Color(0xFF0D59F2)),
                      SizedBox(height: h * 0.012),
                    ] else if (_currentGroup != null) ...[
                      _buildActionTile(fs: fs, icon: Icons.group_work_outlined, label: _currentGroup!.name, onTap: () {}),
                      SizedBox(height: h * 0.012),
                    ],

                    // Действия
                    _buildActionTile(fs: fs, icon: Icons.edit_outlined, label: 'Редактировать профиль', onTap: _editProfile),
                    SizedBox(height: h * 0.012),
                    _buildActionTile(fs: fs, icon: Icons.lock_outline, label: 'Сменить пароль', onTap: _changePassword),
                    SizedBox(height: h * 0.012),
                    _buildActionTile(fs: fs, icon: Icons.group_add_outlined, label: 'Пригласить в группу', onTap: _inviteManager),
                    SizedBox(height: h * 0.012),
                    _buildActionTile(fs: fs, icon: Icons.people_outline, label: 'Участники группы (${_members.length})', onTap: _viewMembers),
                    SizedBox(height: h * 0.012),
                    _buildActionTile(fs: fs, icon: Icons.logout_rounded, label: 'Выйти', onTap: _logout, color: const Color(0xFFF87171)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(double fs, double h) {
    final avatarSize = fs * 0.28;
    final name = _profile?.fullName ?? '';
    final email = _profile?.email ?? '';
    final url = _profile?.avatarUrl;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D59F2),
                    border: Border.all(color: const Color(0xFF0D59F2), width: 3),
                  ),
                  child: url != null && url.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _profile?.initials ?? '?',
                                style: TextStyle(color: Colors.white, fontSize: fs * 0.09, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _profile?.initials ?? '?',
                            style: TextStyle(color: Colors.white, fontSize: fs * 0.09, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: fs * 0.08,
                    height: fs * 0.08,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D59F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF101C22), width: 2),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: fs * 0.04),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.018),
          Text(
            name.isNotEmpty ? name : 'Пользователь',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: fs * 0.058, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: h * 0.005),
          Text(
            email,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double fs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs * 0.045),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Column(children: [_infoRow(fs, Icons.person_outline, 'Имя', _profile?.firstName ?? '—'), _divider(fs), _infoRow(fs, Icons.person_outline, 'Фамилия', _profile?.lastName ?? '—'), _divider(fs), _infoRow(fs, Icons.email_outlined, 'Почта', _profile?.email ?? '—')]),
    );
  }

  Widget _buildGroupMemberToggle(double fs) {
    final isMember = _membership?.isStudent ?? false;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.how_to_reg_outlined, color: const Color(0xFF0D59F2), size: fs * 0.055),
          SizedBox(width: fs * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Я — участник группы',
                  style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Моя посещаемость будет отмечаться',
                  style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: isMember, onChanged: _toggleGroupMember, activeColor: const Color(0xFF0D59F2), inactiveTrackColor: const Color(0xFF455664)),
        ],
      ),
    );
  }

  Widget _buildMyStats(double fs, double h) {
    final attendPct = _totalLessons > 0 ? ((_attended / _totalLessons) * 100).round() : 0;
    final missedPct = _totalLessons > 0 ? ((_missed / _totalLessons) * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Моя посещаемость',
            style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: h * 0.015),
          Row(
            children: [
              _miniStat(fs, 'Всего', '$_totalLessons', const Color(0xFF0D59F2)),
              SizedBox(width: fs * 0.03),
              _miniStat(fs, 'Был', '$_attended ($attendPct%)', const Color(0xFF34D399)),
              SizedBox(width: fs * 0.03),
              _miniStat(fs, 'Пропуск', '$_missed ($missedPct%)', const Color(0xFFF87171)),
            ],
          ),
          if (_totalLessons > 0) ...[
            SizedBox(height: h * 0.012),
            LayoutBuilder(
              builder: (_, c) {
                final p = _totalLessons > 0 ? _attended / _totalLessons : 0.0;
                return Stack(
                  children: [
                    Container(
                      height: fs * 0.018,
                      width: c.maxWidth,
                      decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(fs * 0.04)),
                    ),
                    Container(
                      height: fs * 0.018,
                      width: c.maxWidth * p.clamp(0.0, 1.0),
                      decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(fs * 0.04)),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(double fs, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: fs * 0.034, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(double fs, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D59F2), size: fs * 0.05),
        SizedBox(width: fs * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(double fs) => Padding(
    padding: EdgeInsets.symmetric(vertical: fs * 0.025),
    child: Container(height: 1, color: const Color(0xFF455664).withOpacity(0.5)),
  );

  Widget _buildActionTile({required double fs, required IconData icon, required String label, required VoidCallback onTap, Color? color, String? subtitle}) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF455664), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: fs * 0.055),
            SizedBox(width: fs * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: c, fontSize: fs * 0.04, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF455664), size: fs * 0.055),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН ПРИГЛАШЕНИЯ
// ═══════════════════════════════════════════════════════════════════════════════

class _InviteScreen extends StatefulWidget {
  const _InviteScreen();
  @override
  State<_InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<_InviteScreen> {
  final _emailCtrl = TextEditingController();
  bool _isStudent = false;
  bool _isSending = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = 'Введите email';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _message = null;
    });
    final result = await GroupService.invite(email: email, isStudent: _isStudent);
    if (mounted) {
      setState(() {
        _isSending = false;
        _isError = !result.success;
        _message = result.success ? 'Приглашение отправлено!' : result.error;
        if (result.success) _emailCtrl.clear();
      });
    }
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
        title: Text(
          'Пригласить',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email приглашаемого',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: h * 0.008),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(fs * 0.04),
                border: Border.all(color: const Color(0xFF455664), width: 1),
              ),
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
                decoration: InputDecoration(
                  hintText: 'example@mail.com',
                  hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
                  prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF7D92B1), size: fs * 0.05),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
                ),
              ),
            ),
            SizedBox(height: h * 0.02),
            Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(fs * 0.04),
                border: Border.all(color: const Color(0xFF455664), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.how_to_reg_outlined, color: const Color(0xFF0D59F2), size: fs * 0.05),
                  SizedBox(width: fs * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Является участником',
                          style: TextStyle(color: Colors.white, fontSize: fs * 0.036, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Будет в списке студентов',
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(value: _isStudent, onChanged: (v) => setState(() => _isStudent = v), activeColor: const Color(0xFF0D59F2), inactiveTrackColor: const Color(0xFF455664)),
                ],
              ),
            ),
            if (_message != null) ...[
              SizedBox(height: h * 0.015),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(fs * 0.03),
                decoration: BoxDecoration(
                  color: (_isError ? const Color(0xFFF87171) : const Color(0xFF34D399)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(fs * 0.04),
                  border: Border.all(color: (_isError ? const Color(0xFFF87171) : const Color(0xFF34D399)).withOpacity(0.3)),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(color: _isError ? const Color(0xFFF87171) : const Color(0xFF34D399), fontSize: fs * 0.033),
                ),
              ),
            ],
            SizedBox(height: h * 0.035),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D59F2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF455664),
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                ),
                child: _isSending
                    ? SizedBox(
                        width: fs * 0.055,
                        height: fs * 0.055,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Отправить приглашение',
                        style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН УЧАСТНИКОВ ГРУППЫ
// ═══════════════════════════════════════════════════════════════════════════════

class _MembersScreen extends StatelessWidget {
  final List<GroupMember> members;
  final bool isOwner;
  const _MembersScreen({required this.members, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Участники',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.04),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final m = members[i];
          return Container(
            padding: EdgeInsets.all(fs * 0.04),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(fs * 0.04),
              border: Border.all(color: const Color(0xFF455664), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: fs * 0.12,
                  height: fs * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D59F2),
                    image: m.avatarUrl != null ? DecorationImage(image: NetworkImage(m.avatarUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: m.avatarUrl == null
                      ? Center(
                          child: Text(
                            _initials(m.fullName),
                            style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: fs * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.fullName.isNotEmpty ? m.fullName : m.email ?? '—',
                        style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: 2),
                            decoration: BoxDecoration(color: m.isOwner ? const Color(0xFF0D59F2).withOpacity(0.15) : const Color(0xFF455664).withOpacity(0.3), borderRadius: BorderRadius.circular(fs * 0.04)),
                            child: Text(
                              m.isOwner ? 'Владелец' : 'Менеджер',
                              style: TextStyle(color: m.isOwner ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.025, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (m.isStudent) ...[
                            SizedBox(width: fs * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF34D399).withOpacity(0.15), borderRadius: BorderRadius.circular(fs * 0.04)),
                              child: Text(
                                'Участник',
                                style: TextStyle(color: const Color(0xFF34D399), fontSize: fs * 0.025, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН РЕДАКТИРОВАНИЯ ПРОФИЛЯ
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const _EditProfileScreen({required this.profile});
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.profile.firstName);
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Заполните имя и фамилию');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final result = await AuthService.updateProfile(firstName: _firstNameCtrl.text, lastName: _lastNameCtrl.text);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success)
        Navigator.pop(context, true);
      else
        setState(() => _error = result.error);
    }
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
        title: Text(
          'Редактировать',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Имя',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: h * 0.008),
            _field(fs, _firstNameCtrl, 'Введите имя', Icons.person_outline),
            SizedBox(height: h * 0.02),
            Text(
              'Фамилия',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: h * 0.008),
            _field(fs, _lastNameCtrl, 'Введите фамилию', Icons.person_outline),
            if (_error != null) ...[
              SizedBox(height: h * 0.015),
              Text(
                _error!,
                style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.033),
              ),
            ],
            SizedBox(height: h * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D59F2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF455664),
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: fs * 0.055,
                        height: fs * 0.055,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Сохранить',
                        style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(double fs, TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          prefixIcon: Icon(icon, color: const Color(0xFF7D92B1), size: fs * 0.05),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН СМЕНЫ ПАРОЛЯ
// ═══════════════════════════════════════════════════════════════════════════════

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();
  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Минимум 6 символов');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final result = await AuthService.changePassword(_passwordCtrl.text);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль изменён'), backgroundColor: Color(0xFF10232C)));
      } else
        setState(() => _error = result.error);
    }
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
        title: Text(
          'Сменить пароль',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Новый пароль',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: h * 0.008),
            _pwField(fs, _passwordCtrl, 'Минимум 6 символов', _obscure1, () => setState(() => _obscure1 = !_obscure1)),
            SizedBox(height: h * 0.02),
            Text(
              'Подтвердите пароль',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: h * 0.008),
            _pwField(fs, _confirmCtrl, 'Повторите пароль', _obscure2, () => setState(() => _obscure2 = !_obscure2)),
            if (_error != null) ...[
              SizedBox(height: h * 0.015),
              Text(
                _error!,
                style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.033),
              ),
            ],
            SizedBox(height: h * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D59F2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF455664),
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: fs * 0.055,
                        height: fs * 0.055,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Сохранить',
                        style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(double fs, TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF7D92B1), size: fs * 0.05),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF7D92B1), size: fs * 0.05),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
        ),
      ),
    );
  }
}
