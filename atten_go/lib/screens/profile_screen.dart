import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/attendance_service.dart';
import '../services/db_service.dart';
import '../services/realtime_service.dart';
import '../utils/dark_page_route.dart';

// Сжатие изображения — работает в main isolate (dart:ui требует Flutter engine)
Future<Uint8List> _compressImageBytes(Uint8List input) async {
  try {
    const maxSize = 400; // максимум 400px по большей стороне

    // Первый проход — декодируем и масштабируем
    final codec = await ui.instantiateImageCodec(input, targetWidth: maxSize, targetHeight: maxSize);
    final frame = await codec.getNextFrame();
    final pngData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();

    if (pngData == null) {
      return input;
    }
    final result = Uint8List.view(pngData.buffer);

    // Если всё ещё больше 1.5MB — повторяем с меньшим размером
    if (result.lengthInBytes > 1024 * 1024) {
      final codec2 = await ui.instantiateImageCodec(result, targetWidth: 256, targetHeight: 256);
      final frame2 = await codec2.getNextFrame();
      final pngData2 = await frame2.image.toByteData(format: ui.ImageByteFormat.png);
      frame2.image.dispose();
      if (pngData2 != null) {
        return Uint8List.view(pngData2.buffer);
      }
    }

    return result;
  } catch (_) {
    return input;
  }
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onRoleChanged;
  const ProfileScreen({super.key, this.onRoleChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  GroupMember? _membership;
  Group? _currentGroup;
  bool _isLoading = true;

  // Статистика посещаемости
  int _totalLessons = 0;
  int _attended = 0;
  int _missed = 0;
  int _excused = 0;
  final Map<String, Map<String, dynamic>> _subjectStats = {};
  final Set<String> _expandedSubjects = {};

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();

    // Авто-обновление при изменениях профиля, группы, посещаемости
    _subs.add(
      RealtimeService.onProfilesChanged.listen((_) {
        if (mounted) _load();
      }),
    );
    _subs.add(
      RealtimeService.onGroupMembersChanged.listen((_) {
        if (mounted) _load();
      }),
    );
    _subs.add(
      RealtimeService.onAttendanceRecordsChanged.listen((_) {
        if (mounted) _load();
      }),
    );
  }

  Future<void> _load() async {
    final profile = await AuthService.getProfile();
    final membership = await GroupService.getMyMembership();
    final currentGroup = await GroupService.getCurrentGroup();

    _totalLessons = 0;
    _attended = 0;
    _missed = 0;
    _excused = 0;
    _subjectStats.clear();
    _expandedSubjects.clear();
    if (membership != null && membership.isStudent) {
      await _loadMyStats();
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _membership = membership;
        _currentGroup = currentGroup;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyStats() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      return;
    }
    try {
      final gid = await GroupService.getCurrentGroupId();
      if (gid == null) {
        return;
      }
      final db = DatabaseService.client;
      final studentRows = await db.from('students').select('id').eq('group_id', gid).eq('linked_user_id', uid).limit(1);
      if ((studentRows as List).isEmpty) return;
      final myStudentId = studentRows.first['id'] as String;

      final all = await AttendanceService.loadAll();
      for (final lesson in all) {
        if (lesson.lessonKey == 'weekend') {
          continue;
        }
        StudentAttendance? sa;
        try {
          sa = lesson.students.firstWhere((s) => s.studentId == myStudentId);
        } catch (_) {
          continue;
        }
        if (sa.status == null) {
          continue;
        }
        _totalLessons++;
        if (sa.status == 'present') {
          _attended++;
        }
        if (sa.status == 'absent') {
          _missed++;
        }
        if (sa.status == 'late') {
          _excused++;
        }

        _subjectStats.putIfAbsent(lesson.subject, () => {'present': 0, 'absent': 0, 'late': 0, 'total': 0});
        _subjectStats[lesson.subject]!['total']++;
        _subjectStats[lesson.subject]![sa.status!] = (_subjectStats[lesson.subject]![sa.status!] as int) + 1;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void _toggleGroupMember(bool value) {
    // Optimistic update — сразу меняем UI без ожидания сервера
    if (_membership == null) {
      return;
    }
    setState(() {
      _membership = GroupMember(id: _membership!.id, groupId: _membership!.groupId, userId: _membership!.userId, role: _membership!.role, isStudent: value, email: _membership!.email, firstName: _membership!.firstName, lastName: _membership!.lastName, avatarUrl: _membership!.avatarUrl);
    });
    // Запрос в фоне — не блокируем UI
    GroupService.toggleIsStudent(value).then((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _pickAvatar() async {
    // Показываем выбор источника: галерея или камера
    final source = await showModalBottomSheet<ImageSource>(
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
            children: [
              Text(
                'Выберите источник',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.045, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: fs * 0.04),
              _sourceOption(ctx, fs, Icons.photo_library_outlined, 'Галерея', ImageSource.gallery),
              SizedBox(height: fs * 0.025),
              _sourceOption(ctx, fs, Icons.camera_alt_outlined, 'Камера', ImageSource.camera),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image == null) {
        return;
      }

      setState(() => _isLoading = true);
      final rawBytes = await image.readAsBytes();
      // Сжимаем до 400px (dart:ui требует main isolate)
      final bytes = await _compressImageBytes(rawBytes);
      final result = await AuthService.uploadAvatar(bytes);
      if (result.success) {
        await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Ошибка')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _sourceOption(BuildContext ctx, double fs, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, source),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF455664)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0D59F2), size: fs * 0.06),
            SizedBox(width: fs * 0.035),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() async {
    final groupName = await showDialog<String>(
      context: context,
      builder: (ctx) => const _TextInputDialog(title: 'Создать группу', hint: 'Название группы', confirmLabel: 'Создать', icon: Icons.group_work_outlined),
    );
    if (groupName == null || groupName.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final res = await GroupService.createGroup(groupName.trim());
    if (mounted) {
      if (res.success) {
        AttendanceService.invalidateCache();
        await _load();
        widget.onRoleChanged?.call();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Группа «${res.group!.name}» создана')));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Ошибка')));
      }
    }
  }

  void _openMyGroup() {
    if (_currentGroup == null) {
      return;
    }
    Navigator.push(context, DarkPageRoute(builder: (_) => _MyGroupScreen(group: _currentGroup!))).then((result) {
      _load();
      // Если группа удалена — уведомляем главный экран об изменении роли
      if (result == 'deleted') {
        widget.onRoleChanged?.call();
      }
    });
  }

  void _editProfile() async {
    if (_profile == null) {
      return;
    }
    final updated = await Navigator.push<bool>(context, DarkPageRoute(builder: (_) => _EditProfileScreen(profile: _profile!)));
    if (updated == true) {
      _load();
    }
  }

  void _changePassword() => Navigator.push(context, DarkPageRoute(builder: (_) => const _ChangePasswordScreen()));

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

                    // Галочка «Я — участник группы» — только для owner/admin своей группы
                    if (_currentGroup != null && (_membership?.canManage == true)) ...[_buildGroupMemberToggle(fs), SizedBox(height: h * 0.012)],

                    // Моя статистика (если член группы)
                    if (_membership?.isStudent == true) ...[_buildStatsGrid(fs, h), SizedBox(height: h * 0.012), if (_subjectStats.isNotEmpty) _buildSubjectStats(fs, h), SizedBox(height: h * 0.008)],

                    // Группа
                    if (_currentGroup != null) ...[
                      _buildActionTile(fs: fs, icon: Icons.group_work_outlined, label: _currentGroup!.name, subtitle: 'Моя группа • Нажми чтобы открыть', onTap: _openMyGroup),
                      SizedBox(height: h * 0.012),
                    ] else ...[
                      _buildActionTile(fs: fs, icon: Icons.group_add_outlined, label: 'Создать группу', subtitle: 'Группа пока не создана', onTap: _createGroup, color: const Color(0xFF0D59F2)),
                      SizedBox(height: h * 0.012),
                    ],

                    // Действия
                    _buildActionTile(fs: fs, icon: Icons.edit_outlined, label: 'Редактировать профиль', onTap: _editProfile),
                    SizedBox(height: h * 0.012),
                    _buildActionTile(fs: fs, icon: Icons.lock_outline, label: 'Сменить пароль', onTap: _changePassword),
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
                            errorBuilder: (_, _, _) => Center(
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
      child: Column(
        children: [
          _infoRow(fs, Icons.person_outline, 'Имя', _profile?.firstName ?? '—'),
          _divider(fs),
          _infoRow(fs, Icons.person_outline, 'Фамилия', _profile?.lastName ?? '—'),
          _divider(fs),
          _infoRow(fs, Icons.email_outlined, 'Почта', _profile?.email ?? '—'),
          _divider(fs),
          _infoRow(fs, Icons.fingerprint_outlined, 'ID пользователя', AuthService.currentUserId?.substring(0, 8).toUpperCase() ?? '—'),
        ],
      ),
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
          Switch.adaptive(value: isMember, onChanged: _toggleGroupMember, activeThumbColor: const Color(0xFF0D59F2), inactiveTrackColor: const Color(0xFF455664)),
        ],
      ),
    );
  }

  // ── Статистика: 4 карточки как в StudentProfileScreen ──

  Color _gradeColor(double p) {
    if (p >= 0.9) {
      return const Color(0xFF34D399);
    }
    if (p >= 0.7) {
      return const Color(0xFFFACC15);
    }
    return const Color(0xFFF87171);
  }

  String _grade(double p) {
    if (p >= 0.9) {
      return 'ХОРОШО';
    }
    if (p >= 0.7) {
      return 'СРЕДНЕ';
    }
    return 'ПЛОХО';
  }

  Widget _buildStatsGrid(double fs, double h) {
    final attendPct = _totalLessons > 0 ? ((_attended / _totalLessons) * 100).toStringAsFixed(1) : '0';
    final missedPct = _totalLessons > 0 ? ((_missed / _totalLessons) * 100).toStringAsFixed(1) : '0';
    final excusedPct = _totalLessons > 0 ? ((_excused / _totalLessons) * 100).toStringAsFixed(1) : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(fs, h, label: 'Всего занятий', value: '$_totalLessons', badge: '100%', badgeColor: const Color(0xFF34D399)),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: _statCard(fs, h, label: 'Посещено', value: '$_attended', badge: '$attendPct%', badgeColor: const Color(0xFF34D399)),
            ),
          ],
        ),
        SizedBox(height: fs * 0.03),
        Row(
          children: [
            Expanded(
              child: _statCard(fs, h, label: 'Пропущено', value: '$_missed', badge: '$missedPct%', badgeColor: const Color(0xFFF87171)),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: _statCard(fs, h, label: 'Уваж. причина', value: '$_excused', badge: '$excusedPct%', badgeColor: const Color(0xFFFACC15)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(double fs, double h, {required String label, required String value, required String badge, required Color badgeColor}) {
    return Container(
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
            label,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033),
          ),
          SizedBox(height: h * 0.006),
          Text(
            value,
            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.09, fontWeight: FontWeight.bold, height: 1.0),
          ),
          SizedBox(height: h * 0.008),
          Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 3),
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.04)),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: fs * 0.028, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectStats(double fs, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'По предметам',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.044, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => setState(() {
                if (_expandedSubjects.length == _subjectStats.length) {
                  _expandedSubjects.clear();
                } else {
                  _expandedSubjects.addAll(_subjectStats.keys);
                }
              }),
              child: Text(
                _expandedSubjects.length == _subjectStats.length ? 'Свернуть все' : 'Развернуть все',
                style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.033),
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.015),
        ..._subjectStats.entries.map((e) => _subjectCard(fs, h, e.key, e.value)),
      ],
    );
  }

  Widget _subjectCard(double fs, double h, String subject, Map<String, dynamic> stats) {
    final total = stats['total'] as int;
    final p = total == 0 ? 0.0 : (stats['present'] as int) / total;
    final pInt = (p * 100).round();
    final color = _gradeColor(p);
    final grade = _grade(p);
    final isExpanded = _expandedSubjects.contains(subject);

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedSubjects.remove(subject);
        } else {
          _expandedSubjects.add(subject);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: h * 0.012),
        padding: EdgeInsets.all(fs * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF455664), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                ),
                SizedBox(width: fs * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(fs * 0.04),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(color: color, fontSize: fs * 0.027, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: fs * 0.02),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF7D92B1), size: fs * 0.06),
                ),
              ],
            ),
            SizedBox(height: h * 0.006),
            Text(
              '$pInt% посещаемости',
              style: TextStyle(color: color, fontSize: fs * 0.032, fontWeight: FontWeight.w600),
            ),
            if (isExpanded) ...[
              SizedBox(height: h * 0.012),
              Container(height: 1, color: const Color(0xFF455664).withValues(alpha: 0.5)),
              SizedBox(height: h * 0.012),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Посещаемость',
                    style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033),
                  ),
                  Text(
                    '$pInt%',
                    style: TextStyle(color: color, fontSize: fs * 0.036, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: h * 0.008),
              LayoutBuilder(
                builder: (_, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: fs * 0.015,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(fs * 0.04)),
                      ),
                      Container(
                        height: fs * 0.015,
                        width: constraints.maxWidth * p.clamp(0.0, 1.0),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(fs * 0.04)),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: h * 0.012),
              Row(
                children: [
                  _detailChip(fs, 'Присутствие', '${stats['present']}', const Color(0xFF34D399)),
                  SizedBox(width: fs * 0.02),
                  _detailChip(fs, 'Пропуски', '${stats['absent']}', const Color(0xFFF87171)),
                  SizedBox(width: fs * 0.02),
                  _detailChip(fs, 'Уваж. причина', '${stats['late']}', const Color(0xFFFACC15)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailChip(double fs, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: fs * 0.02),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(fs * 0.04)),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: fs * 0.038, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: fs * 0.025),
            ),
          ],
        ),
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
    child: Container(height: 1, color: const Color(0xFF455664).withValues(alpha: 0.5)),
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
// ЭКРАН «МОЯ ГРУППА»
// ═══════════════════════════════════════════════════════════════════════════════

class _MyGroupScreen extends StatefulWidget {
  final Group group;
  const _MyGroupScreen({required this.group});

  @override
  State<_MyGroupScreen> createState() => _MyGroupScreenState();
}

class _MyGroupScreenState extends State<_MyGroupScreen> {
  List<GroupMember> _members = [];
  bool _isLoading = true;
  bool _isOwner = false;
  bool _canManage = false; // owner или admin

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await GroupService.getMembers();
    final isOwner = await GroupService.isOwner();
    final canManage = await GroupService.canManage();
    if (mounted) {
      setState(() {
        _members = members;
        _isOwner = isOwner;
        _canManage = canManage;
        _isLoading = false;
      });
    }
  }

  void _addMember() async {
    await _showInviteDialog('member');
  }

  Future<void> _deleteGroup() async {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10232C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
        title: Text(
          'Удалить группу?',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
        ),
        content: Text(
          'Это действие нельзя отменить. Все участники, студенты и данные посещаемости будут удалены.',
          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Удалить',
              style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.036, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isLoading = true);
    final res = await GroupService.deleteGroup();
    if (mounted) {
      if (res.success) {
        GroupService.invalidateCache();
        Navigator.pop(context, 'deleted');
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Ошибка')));
      }
    }
  }

  Future<bool?> _confirmRemove(GroupMember m) async {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10232C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
        title: Text(
          'Удалить участника?',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
        ),
        content: Text(
          '${m.fullName.isNotEmpty ? m.fullName : m.email ?? 'Пользователь'} будет удалён из группы.',
          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Удалить',
              style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.036, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(GroupMember m) async {
    setState(() => _isLoading = true);
    await GroupService.removeMember(m.id);
    await _load();
  }

  void _showMemberSheet(GroupMember m) {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final name = m.fullName.isNotEmpty ? m.fullName : m.email ?? 'Пользователь';
    final isAdmin = m.role == 'admin';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF152028),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(fs * 0.05, fs * 0.04, fs * 0.05, fs * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: fs * 0.1,
              height: 4,
              margin: EdgeInsets.only(bottom: fs * 0.04),
              decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
            ),
            // Имя участника
            Row(
              children: [
                Container(
                  width: fs * 0.11,
                  height: fs * 0.11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D59F2),
                    image: m.avatarUrl != null ? DecorationImage(image: NetworkImage(m.avatarUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: m.avatarUrl == null
                      ? Center(
                          child: Text(
                            _initials(name),
                            style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.bold),
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
                        name,
                        style: TextStyle(color: Colors.white, fontSize: fs * 0.042, fontWeight: FontWeight.bold),
                      ),
                      if (m.email != null && m.fullName.isNotEmpty)
                        Text(
                          m.email!,
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03),
                        ),
                      SizedBox(height: 4),
                      _badge(fs, isAdmin ? 'Администратор' : 'Участник', isAdmin ? const Color(0xFFFACC15) : const Color(0xFF455664)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: fs * 0.045),
            // Кнопка смены роли
            _sheetAction(
              ctx: ctx,
              fs: fs,
              icon: isAdmin ? Icons.person_outline : Icons.admin_panel_settings_outlined,
              label: isAdmin ? 'Сделать участником' : 'Назначить администратором',
              color: isAdmin ? const Color(0xFF0D59F2) : const Color(0xFFFACC15),
              onTap: () {
                Navigator.pop(ctx);
                _changeRole(m);
              },
            ),
            SizedBox(height: fs * 0.025),
            // Кнопка удаления
            _sheetAction(
              ctx: ctx,
              fs: fs,
              icon: Icons.person_remove_outlined,
              label: 'Удалить из группы',
              color: const Color(0xFFF87171),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await _confirmRemove(m);
                if (ok == true) {
                  await _removeMember(m);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction({required BuildContext ctx, required double fs, required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.038),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: fs * 0.055),
            SizedBox(width: fs * 0.035),
            Text(
              label,
              style: TextStyle(color: color, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(GroupMember m) async {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final newRole = m.role == 'admin' ? 'member' : 'admin';
    final newRoleLabel = newRole == 'admin' ? 'Администратора' : 'Участника';
    final name = m.fullName.isNotEmpty ? m.fullName : m.email ?? 'Пользователь';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10232C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
        title: Text(
          'Изменить роль?',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
        ),
        content: Text(
          '$name будет назначен(а) $newRoleLabel.',
          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              newRole == 'admin' ? 'Назначить админом' : 'Сделать участником',
              style: TextStyle(color: newRole == 'admin' ? const Color(0xFFFACC15) : const Color(0xFF0D59F2), fontSize: fs * 0.036, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isLoading = true);
    final res = await GroupService.changeRole(m.userId, newRole);
    if (mounted) {
      if (res.success) {
        await _load();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Ошибка')));
      }
    }
  }

  Future<void> _showInviteDialog(String initialRole) async {
    final result = await showDialog<({String email, String role})>(
      context: context,
      builder: (ctx) => _InviteDialog(initialRole: initialRole),
    );
    if (result == null || result.email.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = true);
    final res = await GroupService.sendInvitation(email: result.email, role: result.role);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.success ? 'Приглашение отправлено' : (res.error ?? 'Ошибка'))));
    }
  }

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
          widget.group.name,
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_canManage)
            IconButton(
              icon: Icon(Icons.person_add_outlined, color: const Color(0xFF0D59F2), size: fs * 0.055),
              onPressed: _addMember,
              tooltip: 'Пригласить',
            ),
          if (_isOwner)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: const Color(0xFFF87171), size: fs * 0.055),
              onPressed: _deleteGroup,
              tooltip: 'Удалить группу',
            ),
        ],
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
              child: _members.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, color: const Color(0xFF455664), size: fs * 0.15),
                              SizedBox(height: fs * 0.03),
                              Text(
                                'Нет участников',
                                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.04),
                              ),
                              SizedBox(height: fs * 0.015),
                              GestureDetector(
                                onTap: _addMember,
                                child: Text(
                                  'Добавить пользователя',
                                  style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.038, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.04),
                      itemCount: _members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        final initials = _initials(m.fullName.isNotEmpty ? m.fullName : (m.email ?? '?'));
                        final canManageThis = _isOwner && !m.isOwner;
                        return GestureDetector(
                          onTap: canManageThis ? () => _showMemberSheet(m) : null,
                          child: Container(
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
                                            initials,
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
                                      if (m.email != null && m.fullName.isNotEmpty)
                                        Text(
                                          m.email!,
                                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03),
                                        ),
                                      SizedBox(height: 4),
                                      Row(children: [_badge(fs, m.isOwner ? 'Владелец' : (m.role == 'admin' ? 'Администратор' : 'Участник'), m.isOwner ? const Color(0xFF0D59F2) : (m.role == 'admin' ? const Color(0xFFFACC15) : const Color(0xFF455664)))]),
                                    ],
                                  ),
                                ),
                                if (canManageThis) Icon(Icons.more_vert_rounded, color: const Color(0xFF455664), size: fs * 0.05),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: _canManage
          ? Padding(
              padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, MediaQuery.of(context).padding.bottom + 16),
              child: ElevatedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Добавить пользователя'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D59F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                  textStyle: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }

  Widget _badge(double fs, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.04)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: fs * 0.026, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
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
      if (result.success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = result.error);
      }
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль изменён')));
      } else {
        setState(() => _error = result.error);
      }
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

// ═══════════════════════════════════════════════════════════════════════════════
// ДИАЛОГ ПРИГЛАШЕНИЯ (контроллер в State — не пересоздаётся при rebuild)
// ═══════════════════════════════════════════════════════════════════════════════

class _InviteDialog extends StatefulWidget {
  final String initialRole;
  const _InviteDialog({required this.initialRole});
  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  late final TextEditingController _ctrl;
  late String _role;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    return AlertDialog(
      backgroundColor: const Color(0xFF10232C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
      title: Text(
        'Пригласить в группу',
        style: TextStyle(color: Colors.white, fontSize: fs * 0.042),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF152028),
              borderRadius: BorderRadius.circular(fs * 0.03),
              border: Border.all(color: const Color(0xFF455664)),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
              onSubmitted: (v) => Navigator.pop(context, (email: v.trim(), role: _role)),
              decoration: InputDecoration(
                hintText: 'Email пользователя',
                hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
                prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF7D92B1), size: fs * 0.05),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
              ),
            ),
          ),
          SizedBox(height: fs * 0.03),
          // Выбор роли
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _role = 'member'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: fs * 0.025),
                    decoration: BoxDecoration(
                      color: _role == 'member' ? const Color(0xFF0D59F2).withValues(alpha: 0.15) : const Color(0xFF152028),
                      borderRadius: BorderRadius.circular(fs * 0.03),
                      border: Border.all(color: _role == 'member' ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person_outline, color: _role == 'member' ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), size: fs * 0.05),
                        const SizedBox(height: 4),
                        Text(
                          'Участник',
                          style: TextStyle(color: _role == 'member' ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: fs * 0.025),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _role = 'admin'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: fs * 0.025),
                    decoration: BoxDecoration(
                      color: _role == 'admin' ? const Color(0xFFFACC15).withValues(alpha: 0.15) : const Color(0xFF152028),
                      borderRadius: BorderRadius.circular(fs * 0.03),
                      border: Border.all(color: _role == 'admin' ? const Color(0xFFFACC15) : const Color(0xFF455664)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: _role == 'admin' ? const Color(0xFFFACC15) : const Color(0xFF7D92B1), size: fs * 0.05),
                        const SizedBox(height: 4),
                        Text(
                          'Админ',
                          style: TextStyle(color: _role == 'admin' ? const Color(0xFFFACC15) : const Color(0xFF7D92B1), fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Отмена',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (email: _ctrl.text.trim(), role: _role)),
          child: Text(
            'Пригласить',
            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ПЕРЕИСПОЛЬЗУЕМЫЙ ДИАЛОГ ВВОДА ТЕКСТА
// Контроллер живёт в State — не пересоздаётся при rebuild
// ═══════════════════════════════════════════════════════════════════════════════

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String confirmLabel;
  final IconData icon;
  const _TextInputDialog({required this.title, required this.hint, required this.confirmLabel, required this.icon});

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    return AlertDialog(
      backgroundColor: const Color(0xFF10232C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
      title: Text(
        widget.title,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF152028),
          borderRadius: BorderRadius.circular(fs * 0.03),
          border: Border.all(color: const Color(0xFF455664)),
        ),
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
            prefixIcon: Icon(widget.icon, color: const Color(0xFF7D92B1), size: fs * 0.05),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Отмена',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(
            widget.confirmLabel,
            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
