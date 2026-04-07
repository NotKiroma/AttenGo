// lib/services/group_service.dart
//
// Изменения vs оригинал:
//  • Добавлен cachedGroupId + setCachedGroupId для SyncService
//  • getCurrentGroup() сначала читает из LocalDatabase
//  • Все write-операции синкают нужную таблицу после Supabase
//  • removeMember(int memberId) — оригинальная сигнатура с int
//  • deleteGroup() — полностью из оригинала + SyncService.clearAll()

import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'attendance_service.dart';
import '../local/sync_service.dart';

// owner  — создатель группы
// admin  — назначенный администратор (все права кроме удаления группы)
// member — обычный участник (нет посещаемости и отчётов)

class Group {
  final String id;
  final String name;
  final String ownerId;
  Group({required this.id, required this.name, required this.ownerId});
  factory Group.fromRow(Map<String, dynamic> row) => Group(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Группа',
        ownerId: row['owner_id'] as String,
      );
}

class GroupMember {
  final int id;
  final String groupId;
  final String userId;
  final String role;
  final bool isStudent;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.isStudent,
    this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isMember => role == 'member';
  bool get canManage => role == 'owner' || role == 'admin';
}

class GroupInvitation {
  final int id;
  final String groupId;
  final String senderId;
  final String recipientEmail;
  final String role;
  final String status;
  final DateTime? createdAt;
  final String? senderName;
  final String? groupName;

  GroupInvitation({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.recipientEmail,
    required this.role,
    required this.status,
    this.createdAt,
    this.senderName,
    this.groupName,
  });
}

class GroupService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;
  static String? get _uid => AuthService.currentUserId;

  static Group? _cachedGroup;
  static GroupMember? _cachedMembership;
  static String? _cachedGroupId;

  /// Используется SyncService для получения groupId без async
  static String? get cachedGroupId => _cachedGroupId;

  /// Вызывается из SyncService после синкронизации группы
  static void setCachedGroupId(String gid) => _cachedGroupId = gid;

  static void invalidateCache() {
    _cachedGroup = null;
    _cachedMembership = null;
    // _cachedGroupId не сбрасываем — нужен SyncService
  }

  /// Полная инвалидация включая groupId (при выходе из группы)
  static void fullInvalidate() {
    _cachedGroup = null;
    _cachedMembership = null;
    _cachedGroupId = null;
  }

  // ── Создать группу ──────────────────────────────────────────────────────────

  static Future<({bool success, String? error, Group? group})> createGroup(
      String name) async {
    if (_uid == null) {
      return (success: false, error: 'Не авторизован', group: null);
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return (success: false, error: 'Введите название', group: null);
    }
    try {
      final gRows = await _supa
          .from('groups')
          .insert({'name': trimmed, 'owner_id': _uid!})
          .select();
      if ((gRows as List).isEmpty) {
        return (success: false, error: 'Ошибка', group: null);
      }
      final group = Group.fromRow(gRows.first);
      await _supa.from('group_members').insert(
          {'group_id': group.id, 'user_id': _uid!, 'role': 'owner', 'is_student': false});
      invalidateCache();
      await SyncService.syncGroup(_uid!);
      return (success: true, error: null, group: group);
    } catch (e) {
      developer.log('[GroupService] createGroup error: $e');
      return (success: false, error: 'Ошибка: $e', group: null);
    }
  }

  // ── Текущая группа ──────────────────────────────────────────────────────────

  static Future<Group?> getCurrentGroup() async {
    if (_cachedGroup != null) return _cachedGroup;
    if (_uid == null) return null;

    // 1. Пробуем из локальной БД
    if (_cachedGroupId != null) {
      final localGroup = await _local.getGroup(_cachedGroupId!);
      if (localGroup != null) {
        _cachedGroup = Group(
          id: localGroup.id,
          name: localGroup.name,
          ownerId: localGroup.ownerId,
        );
        return _cachedGroup;
      }
    }

    // 2. Фоллбэк — Supabase
    try {
      final ms = await _supa.from('group_members').select().eq('user_id', _uid!);
      if ((ms as List).isEmpty) {
        _cachedGroup = null;
        _cachedMembership = null;
        return null;
      }
      final gid = ms.first['group_id'] as String;
      final gRows =
          await _supa.from('groups').select().eq('id', gid).limit(1);
      if ((gRows as List).isNotEmpty) {
        _cachedGroup = Group.fromRow(gRows.first);
        _cachedGroupId = gid;
        return _cachedGroup;
      }
      _cachedGroup = null;
      _cachedMembership = null;
      return null;
    } catch (e) {
      developer.log('[GroupService] getCurrentGroup error: $e');
      return null;
    }
  }

  static Future<String?> getCurrentGroupId() async =>
      (await getCurrentGroup())?.id;

  // ── Моя роль ────────────────────────────────────────────────────────────────

  static Future<GroupMember?> getMyMembership() async {
    if (_cachedMembership != null) return _cachedMembership;
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return null;

    // Пробуем из локальной БД
    try {
      final local = await _local.getMembership(gid, _uid!);
      if (local != null) {
        _cachedMembership = GroupMember(
          id: local.id,
          groupId: local.groupId,
          userId: local.userId,
          role: local.role,
          isStudent: local.isStudent,
        );
        return _cachedMembership;
      }
    } catch (_) {}

    // Фоллбэк — Supabase
    try {
      final rows = await _supa
          .from('group_members')
          .select()
          .eq('group_id', gid)
          .eq('user_id', _uid!)
          .limit(1);
      if ((rows as List).isEmpty) return null;
      final r = rows.first;
      _cachedMembership = GroupMember(
        id: r['id'] as int,
        groupId: r['group_id'] as String,
        userId: r['user_id'] as String,
        role: r['role'] as String,
        isStudent: r['is_student'] as bool? ?? false,
      );
      return _cachedMembership;
    } catch (e) {
      developer.log('[GroupService] getMyMembership error: $e');
      return null;
    }
  }

  static Future<bool> canManage() async =>
      (await getMyMembership())?.canManage ?? false;
  static Future<bool> isOwner() async =>
      (await getCurrentGroup())?.ownerId == _uid;

  // ── Участники ───────────────────────────────────────────────────────────────

  static Future<List<GroupMember>> getMembers() async {
    final gid = await getCurrentGroupId();
    if (gid == null) return [];
    try {
      // Пробуем из локальной БД
      final localMembers = await _local.getMembersForGroup(gid);
      if (localMembers.isNotEmpty) {
        return await Future.wait(localMembers.map((m) async {
          final profile = await _local.getProfile(m.userId);
          return GroupMember(
            id: m.id,
            groupId: m.groupId,
            userId: m.userId,
            role: m.role,
            isStudent: m.isStudent,
            email: profile?.email,
            firstName: profile?.firstName,
            lastName: profile?.lastName,
            avatarUrl: profile?.avatarUrl,
          );
        }));
      }

      // Фоллбэк — Supabase
      final rows = await _supa
          .from('group_members')
          .select()
          .eq('group_id', gid)
          .order('role', ascending: true);
      final list = rows as List;
      if (list.isEmpty) return [];

      final userIds = list.map((r) => r['user_id'] as String).toList();
      final profileRows = await _supa
          .from('profiles')
          .select('id, email, first_name, last_name, avatar_url')
          .inFilter('id', userIds);
      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profileRows as List) {
        profileMap[p['id'] as String] = p as Map<String, dynamic>;
      }
      return list.map((r) {
        final uid = r['user_id'] as String;
        final p = profileMap[uid];
        return GroupMember(
          id: r['id'] as int,
          groupId: r['group_id'] as String,
          userId: uid,
          role: r['role'] as String,
          isStudent: r['is_student'] as bool? ?? false,
          email: p?['email'] as String?,
          firstName: p?['first_name'] as String?,
          lastName: p?['last_name'] as String?,
          avatarUrl: p?['avatar_url'] as String?,
        );
      }).toList();
    } catch (e) {
      developer.log('[GroupService] getMembers error: $e');
      return [];
    }
  }

  // ── Изменить роль ───────────────────────────────────────────────────────────

  static Future<({bool success, String? error})> changeRole(
      String userId, String newRole) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    if (!(await isOwner())) {
      return (success: false, error: 'Только владелец может менять роли');
    }
    final gid = await getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    try {
      await _supa
          .from('group_members')
          .update({'role': newRole, 'is_student': newRole == 'member'})
          .eq('group_id', gid)
          .eq('user_id', userId);

      if (newRole == 'member') {
        final profileRows = await _supa
            .from('profiles')
            .select('first_name, last_name')
            .eq('id', userId)
            .limit(1);
        final firstName = (profileRows as List).isNotEmpty
            ? profileRows.first['first_name'] as String? ?? ''
            : '';
        final lastName = (profileRows as List).isNotEmpty
            ? profileRows.first['last_name'] as String? ?? ''
            : '';
        final existing = await _supa
            .from('students')
            .select('id')
            .eq('group_id', gid)
            .eq('linked_user_id', userId)
            .limit(1);
        if ((existing as List).isEmpty) {
          await _supa.from('students').insert({
            'user_id': userId,
            'group_id': gid,
            'linked_user_id': userId,
            'last_name': lastName,
            'first_name': firstName,
            'middle_name': '',
            'birth_day': '',
            'birth_month': '',
            'birth_year': '',
            'is_male': true,
            'status': 'active',
          });
        } else {
          await _supa
              .from('students')
              .update({'status': 'active'})
              .eq('group_id', gid)
              .eq('linked_user_id', userId);
        }
      } else {
        // Стал admin — деактивируем в students
        await _supa
            .from('students')
            .update({'status': 'inactive'})
            .eq('group_id', gid)
            .eq('linked_user_id', userId);
      }

      invalidateCache();
      AttendanceService.invalidateCache();
      await Future.wait([
        SyncService.syncGroup(_uid!),
        SyncService.syncStudents(gid),
      ]);
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] changeRole error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ── Удалить участника (по memberId — int, как в оригинале) ─────────────────

  static Future<void> removeMember(int memberId) async {
    try {
      // Получаем userId и groupId чтобы деактивировать студента
      final rows = await _supa
          .from('group_members')
          .select('user_id, group_id')
          .eq('id', memberId)
          .limit(1);
      if ((rows as List).isNotEmpty) {
        final userId = rows.first['user_id'] as String;
        final groupId = rows.first['group_id'] as String;
        await _supa
            .from('students')
            .update({'status': 'inactive'})
            .eq('group_id', groupId)
            .eq('linked_user_id', userId);
        await _supa.from('group_members').delete().eq('id', memberId);
        invalidateCache();
        AttendanceService.invalidateCache();
        await Future.wait([
          SyncService.syncGroup(_uid ?? userId),
          SyncService.syncStudents(groupId),
        ]);
      }
    } catch (e) {
      developer.log('[GroupService] removeMember error: $e');
    }
  }

  // ── Удалить группу (только owner) ──────────────────────────────────────────

  static Future<({bool success, String? error})> deleteGroup() async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final g = await getCurrentGroup();
    if (g == null) return (success: false, error: 'Группа не найдена');
    if (g.ownerId != _uid) {
      return (success: false, error: 'Только владелец может удалить группу');
    }
    try {
      await _supa.from('groups').delete().eq('id', g.id);
      fullInvalidate();
      AttendanceService.invalidateCache();
      await SyncService.clearAll();
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] deleteGroup error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ── toggleIsStudent ─────────────────────────────────────────────────────────

  static Future<void> toggleIsStudent(bool value) async {
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return;
    try {
      await _supa
          .from('group_members')
          .update({'is_student': value})
          .eq('group_id', gid)
          .eq('user_id', _uid!);
      if (value) {
        final profile = await AuthService.getProfile();
        if (profile == null) return;
        final existing = await _supa
            .from('students')
            .select('id')
            .eq('group_id', gid)
            .eq('linked_user_id', _uid!)
            .limit(1);
        if ((existing as List).isEmpty) {
          await _supa.from('students').insert({
            'user_id': _uid!,
            'group_id': gid,
            'linked_user_id': _uid!,
            'last_name': profile.lastName,
            'first_name': profile.firstName,
            'middle_name': '',
            'birth_day': '',
            'birth_month': '',
            'birth_year': '',
            'is_male': true,
            'status': 'active',
          });
        } else {
          await _supa
              .from('students')
              .update({'status': 'active'})
              .eq('group_id', gid)
              .eq('linked_user_id', _uid!);
        }
      } else {
        await _supa
            .from('students')
            .update({'status': 'inactive'})
            .eq('group_id', gid)
            .eq('linked_user_id', _uid!);
      }
      _cachedMembership = null;
      AttendanceService.invalidateCache();
      await Future.wait([
        SyncService.syncGroup(_uid!),
        SyncService.syncStudents(gid),
      ]);
    } catch (e) {
      developer.log('[GroupService] toggleIsStudent error: $e');
    }
  }

  // ── Добавить по email ───────────────────────────────────────────────────────

  static Future<({bool success, String? error})> addMemberByEmail(
      String email, String groupId) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final trimmed = email.trim().toLowerCase();
    try {
      final profileRows = await _supa
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('email', trimmed)
          .limit(1);
      if ((profileRows as List).isEmpty) {
        return (success: false, error: 'Пользователь не найден');
      }
      final userId = profileRows.first['id'] as String;
      final firstName = profileRows.first['first_name'] as String? ?? '';
      final lastName = profileRows.first['last_name'] as String? ?? '';

      final existing = await _supa
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        return (success: false, error: 'Уже в группе');
      }

      await _supa.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'is_student': true,
      });

      final existingStudent = await _supa
          .from('students')
          .select('id')
          .eq('group_id', groupId)
          .eq('linked_user_id', userId)
          .limit(1);
      if ((existingStudent as List).isEmpty) {
        await _supa.from('students').insert({
          'user_id': userId,
          'group_id': groupId,
          'linked_user_id': userId,
          'first_name': firstName,
          'last_name': lastName,
          'middle_name': '',
          'birth_day': '',
          'birth_month': '',
          'birth_year': '',
          'is_male': true,
          'status': 'active',
        });
      } else {
        await _supa
            .from('students')
            .update({'status': 'active'})
            .eq('group_id', groupId)
            .eq('linked_user_id', userId);
      }

      AttendanceService.invalidateCache();
      await Future.wait([
        SyncService.syncGroup(_uid!),
        SyncService.syncStudents(groupId),
      ]);
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ── ПРИГЛАШЕНИЯ ─────────────────────────────────────────────────────────────

  static Future<({bool success, String? error})> sendInvitation({
    required String email,
    required String role,
  }) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final gid = await getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    if (!(await canManage())) return (success: false, error: 'Нет прав');
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return (success: false, error: 'Введите email');
    try {
      final profileRows = await _supa
          .from('profiles')
          .select('id')
          .eq('email', trimmed)
          .limit(1);
      if ((profileRows as List).isEmpty) {
        return (success: false, error: 'Пользователь с таким email не найден');
      }
      final recipientId = profileRows.first['id'] as String;

      final inGroup = await _supa
          .from('group_members')
          .select('id')
          .eq('group_id', gid)
          .eq('user_id', recipientId)
          .limit(1);
      if ((inGroup as List).isNotEmpty) {
        return (success: false, error: 'Пользователь уже в группе');
      }

      final existingInv = await _supa
          .from('invitations')
          .select('id')
          .eq('group_id', gid)
          .eq('recipient_email', trimmed)
          .eq('status', 'pending')
          .limit(1);
      if ((existingInv as List).isNotEmpty) {
        return (success: false, error: 'Приглашение уже отправлено');
      }

      await _supa.from('invitations').insert({
        'group_id': gid,
        'sender_id': _uid!,
        'recipient_email': trimmed,
        'role': role,
        'status': 'pending',
      });

      final myProfile = await AuthService.getProfile();
      final groupData = await getCurrentGroup();
      await _supa.from('notifications').insert({
        'user_id': recipientId,
        'type': 'invitation',
        'title': 'Приглашение в группу',
        'body':
            '${myProfile?.fullName ?? 'Пользователь'} приглашает вас в группу «${groupData?.name ?? 'Группа'}»',
        'data': {'group_id': gid, 'sender_id': _uid!, 'role': role},
        'is_read': false,
      });
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] sendInvitation error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<List<GroupInvitation>> getMyInvitations() async {
    if (_uid == null) return [];
    final email = _supa.auth.currentUser?.email;
    if (email == null) return [];
    // Читаем из локальной БД
    final rows = await _local.getPendingInvitations(email);
    return rows
        .map((r) => GroupInvitation(
              id: r.id,
              groupId: r.groupId,
              senderId: r.senderId,
              recipientEmail: r.recipientEmail,
              role: r.role,
              status: r.status,
              createdAt:
                  r.createdAt != null ? DateTime.tryParse(r.createdAt!) : null,
              senderName: r.senderName,
              groupName: r.groupName,
            ))
        .toList();
  }

  static Future<({bool success, String? error})> acceptInvitation(
      int invitationId) async {
    try {
      await _supa
          .rpc('accept_invitation', params: {'invitation_id': invitationId});

      final invRows = await _supa
          .from('invitations')
          .select('group_id, role')
          .eq('id', invitationId)
          .limit(1);
      if ((invRows as List).isNotEmpty) {
        final gid = invRows.first['group_id'] as String;
        final role = invRows.first['role'] as String? ?? 'member';
        final uid = _uid;
        if (uid != null && role == 'member') {
          final profile = await AuthService.getProfile();
          final existing = await _supa
              .from('students')
              .select('id')
              .eq('group_id', gid)
              .eq('linked_user_id', uid)
              .limit(1);
          if ((existing as List).isEmpty) {
            await _supa.from('students').insert({
              'user_id': uid,
              'group_id': gid,
              'linked_user_id': uid,
              'first_name': profile?.firstName ?? '',
              'last_name': profile?.lastName ?? '',
              'middle_name': '',
              'birth_day': '',
              'birth_month': '',
              'birth_year': '',
              'is_male': true,
              'status': 'active',
            });
          } else {
            await _supa
                .from('students')
                .update({'status': 'active'})
                .eq('group_id', gid)
                .eq('linked_user_id', uid);
          }
        }
        invalidateCache();
        AttendanceService.invalidateCache();
        await SyncService.syncAll();
      }
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] acceptInvitation error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> declineInvitation(int invitationId) async {
    try {
      final invRows = await _supa
          .from('invitations')
          .select('group_id, sender_id, recipient_email')
          .eq('id', invitationId)
          .limit(1);

      await _supa
          .from('invitations')
          .update({'status': 'declined'})
          .eq('id', invitationId);

      if ((invRows as List).isNotEmpty) {
        final senderId = invRows.first['sender_id'] as String;
        final recipientEmail = invRows.first['recipient_email'] as String;
        final gid = invRows.first['group_id'] as String;

        String declinerName = recipientEmail;
        final uid = _uid;
        if (uid != null) {
          try {
            final pRows = await _supa
                .from('profiles')
                .select('first_name, last_name')
                .eq('id', uid)
                .limit(1);
            if ((pRows as List).isNotEmpty) {
              final full =
                  '${pRows.first['first_name'] ?? ''} ${pRows.first['last_name'] ?? ''}'
                      .trim();
              if (full.isNotEmpty) declinerName = full;
            }
          } catch (_) {}
        }

        String groupName = 'группу';
        try {
          final gRows = await _supa
              .from('groups')
              .select('name')
              .eq('id', gid)
              .limit(1);
          if ((gRows as List).isNotEmpty) {
            groupName = '«${gRows.first['name']}»';
          }
        } catch (_) {}

        await _supa.from('notifications').insert({
          'user_id': senderId,
          'type': 'invite_declined',
          'title': 'Приглашение отклонено',
          'body': '$declinerName отклонил(а) приглашение в $groupName',
          'data': {'group_id': gid},
          'is_read': false,
        });

        if (uid != null) {
          final email = _supa.auth.currentUser?.email;
          if (email != null) await SyncService.syncInvitations(email);
        }
      }
    } catch (e) {
      developer.log('[GroupService] declineInvitation error: $e');
    }
  }
}
