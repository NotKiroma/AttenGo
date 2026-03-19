import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';

// owner  — создатель группы
// admin  — назначенный администратор (все права кроме удаления группы)
// member — обычный участник (нет посещаемости и отчётов)

class Group {
  final String id;
  final String name;
  final String ownerId;
  Group({required this.id, required this.name, required this.ownerId});
  factory Group.fromRow(Map<String, dynamic> row) => Group(id: row['id'] as String, name: row['name'] as String? ?? 'Группа', ownerId: row['owner_id'] as String);
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

  GroupMember({required this.id, required this.groupId, required this.userId, required this.role, required this.isStudent, this.email, this.firstName, this.lastName, this.avatarUrl});

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

  GroupInvitation({required this.id, required this.groupId, required this.senderId, required this.recipientEmail, required this.role, required this.status, this.createdAt, this.senderName, this.groupName});
}

class GroupService {
  static final _db = DatabaseService.client;
  static String? get _uid => AuthService.currentUserId;
  static Group? _cachedGroup;
  static GroupMember? _cachedMembership;

  static void invalidateCache() {
    _cachedGroup = null;
    _cachedMembership = null;
  }

  // ── Создать группу ──
  static Future<({bool success, String? error, Group? group})> createGroup(String name) async {
    if (_uid == null) return (success: false, error: 'Не авторизован', group: null);
    final trimmed = name.trim();
    if (trimmed.isEmpty) return (success: false, error: 'Введите название', group: null);
    try {
      final gRows = await _db.from('groups').insert({'name': trimmed, 'owner_id': _uid!}).select();
      if ((gRows as List).isEmpty) return (success: false, error: 'Ошибка', group: null);
      final group = Group.fromRow(gRows.first);
      await _db.from('group_members').insert({'group_id': group.id, 'user_id': _uid!, 'role': 'owner', 'is_student': false});
      invalidateCache();
      return (success: true, error: null, group: group);
    } catch (e) {
      developer.log('[GroupService] createGroup error: $e');
      return (success: false, error: 'Ошибка: $e', group: null);
    }
  }

  // ── Текущая группа ──
  static Future<Group?> getCurrentGroup() async {
    if (_cachedGroup != null) return _cachedGroup;
    if (_uid == null) return null;
    try {
      final ms = await _db.from('group_members').select().eq('user_id', _uid!);
      if ((ms as List).isEmpty) return null;
      final gid = ms.first['group_id'] as String;
      final gRows = await _db.from('groups').select().eq('id', gid).limit(1);
      if ((gRows as List).isNotEmpty) {
        _cachedGroup = Group.fromRow(gRows.first);
        return _cachedGroup;
      }
      return null;
    } catch (e) {
      developer.log('[GroupService] getCurrentGroup error: $e');
      return null;
    }
  }

  static Future<String?> getCurrentGroupId() async => (await getCurrentGroup())?.id;

  // ── Моя роль ──
  static Future<GroupMember?> getMyMembership() async {
    if (_cachedMembership != null) return _cachedMembership;
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return null;
    try {
      final rows = await _db.from('group_members').select().eq('group_id', gid).eq('user_id', _uid!).limit(1);
      if ((rows as List).isEmpty) return null;
      final r = rows.first;
      _cachedMembership = GroupMember(id: r['id'] as int, groupId: r['group_id'] as String, userId: r['user_id'] as String, role: r['role'] as String, isStudent: r['is_student'] as bool? ?? false);
      return _cachedMembership;
    } catch (e) {
      developer.log('[GroupService] getMyMembership error: $e');
      return null;
    }
  }

  static Future<bool> canManage() async => (await getMyMembership())?.canManage ?? false;
  static Future<bool> isOwner() async => (await getCurrentGroup())?.ownerId == _uid;

  // ── Участники ──
  static Future<List<GroupMember>> getMembers() async {
    final gid = await getCurrentGroupId();
    if (gid == null) return [];
    try {
      final rows = await _db.from('group_members').select().eq('group_id', gid).order('role', ascending: true);
      final members = <GroupMember>[];
      for (final r in rows as List) {
        final uid = r['user_id'] as String;
        Map<String, dynamic>? p;
        try {
          final pRows = await _db.from('profiles').select().eq('id', uid).limit(1);
          if ((pRows as List).isNotEmpty) p = pRows.first;
        } catch (_) {}
        members.add(
          GroupMember(
            id: r['id'] as int,
            groupId: r['group_id'] as String,
            userId: uid,
            role: r['role'] as String,
            isStudent: r['is_student'] as bool? ?? false,
            email: p?['email'] as String?,
            firstName: p?['first_name'] as String?,
            lastName: p?['last_name'] as String?,
            avatarUrl: p?['avatar_url'] as String?,
          ),
        );
      }
      return members;
    } catch (e) {
      developer.log('[GroupService] getMembers error: $e');
      return [];
    }
  }

  static Future<({bool success, String? error})> changeRole(String userId, String newRole) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    if (!(await isOwner())) return (success: false, error: 'Только владелец может менять роли');
    final gid = await getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    try {
      await _db.from('group_members').update({'role': newRole}).eq('group_id', gid).eq('user_id', userId);
      invalidateCache();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> removeMember(int memberId) async {
    try {
      await _db.from('group_members').delete().eq('id', memberId);
      invalidateCache();
    } catch (e) {
      developer.log('[GroupService] removeMember error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Удалить группу (только owner)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> deleteGroup() async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final g = await getCurrentGroup();
    if (g == null) return (success: false, error: 'Группа не найдена');
    if (g.ownerId != _uid) return (success: false, error: 'Только владелец может удалить группу');
    try {
      // CASCADE в БД удалит group_members, invitations, attendance_lessons, students автоматически
      await _db.from('groups').delete().eq('id', g.id);
      invalidateCache();
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] deleteGroup error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> toggleIsStudent(bool value) async {
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return;
    try {
      await _db.from('group_members').update({'is_student': value}).eq('group_id', gid).eq('user_id', _uid!);
      if (value) {
        final profile = await AuthService.getProfile();
        if (profile == null) return;
        final existing = await _db.from('students').select('id').eq('group_id', gid).eq('linked_user_id', _uid!).limit(1);
        if ((existing as List).isEmpty) {
          await _db.from('students').insert({'user_id': _uid!, 'group_id': gid, 'linked_user_id': _uid!, 'last_name': profile.lastName, 'first_name': profile.firstName, 'middle_name': '', 'birth_day': '', 'birth_month': '', 'birth_year': '', 'is_male': true, 'status': 'active'});
        } else {
          await _db.from('students').update({'status': 'active'}).eq('group_id', gid).eq('linked_user_id', _uid!);
        }
      } else {
        await _db.from('students').update({'status': 'inactive'}).eq('group_id', gid).eq('linked_user_id', _uid!);
      }
      _cachedMembership = null;
    } catch (e) {
      developer.log('[GroupService] toggleIsStudent error: $e');
    }
  }

  static Future<({bool success, String? error})> addMemberByEmail(String email, String groupId) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final trimmed = email.trim().toLowerCase();
    try {
      final profileRows = await _db.from('profiles').select('id').eq('email', trimmed).limit(1);
      if ((profileRows as List).isEmpty) return (success: false, error: 'Пользователь не найден');
      final userId = profileRows.first['id'] as String;
      final existing = await _db.from('group_members').select('id').eq('group_id', groupId).eq('user_id', userId).limit(1);
      if ((existing as List).isNotEmpty) return (success: false, error: 'Уже в группе');
      await _db.from('group_members').insert({'group_id': groupId, 'user_id': userId, 'role': 'member', 'is_student': false});
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ПРИГЛАШЕНИЯ
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> sendInvitation({required String email, required String role}) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final gid = await getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    if (!(await canManage())) return (success: false, error: 'Нет прав');
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return (success: false, error: 'Введите email');
    try {
      final profileRows = await _db.from('profiles').select('id').eq('email', trimmed).limit(1);
      if ((profileRows as List).isEmpty) return (success: false, error: 'Пользователь с таким email не найден');
      final recipientId = profileRows.first['id'] as String;

      final inGroup = await _db.from('group_members').select('id').eq('group_id', gid).eq('user_id', recipientId).limit(1);
      if ((inGroup as List).isNotEmpty) return (success: false, error: 'Пользователь уже в группе');

      final existing = await _db.from('invitations').select('id').eq('group_id', gid).eq('recipient_email', trimmed).eq('status', 'pending').limit(1);
      if ((existing as List).isNotEmpty) return (success: false, error: 'Приглашение уже отправлено');

      await _db.from('invitations').insert({'group_id': gid, 'sender_id': _uid!, 'recipient_email': trimmed, 'role': role, 'status': 'pending'});

      final myProfile = await AuthService.getProfile();
      final groupData = await getCurrentGroup();
      await _db.from('notifications').insert({
        'user_id': recipientId,
        'type': 'invitation',
        'title': 'Приглашение в группу',
        'body': '${myProfile?.fullName ?? 'Пользователь'} приглашает вас в группу «${groupData?.name ?? 'Группа'}»',
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
    try {
      final email = _db.auth.currentUser?.email;
      if (email == null) return [];
      final rows = await _db.from('invitations').select().eq('recipient_email', email).eq('status', 'pending').order('created_at', ascending: false);
      final result = <GroupInvitation>[];
      for (final r in rows as List) {
        String? senderName, groupName;
        try {
          final sRows = await _db.from('profiles').select('first_name, last_name').eq('id', r['sender_id']).limit(1);
          if ((sRows as List).isNotEmpty) senderName = '${sRows.first['first_name'] ?? ''} ${sRows.first['last_name'] ?? ''}'.trim();
        } catch (_) {}
        try {
          final gRows = await _db.from('groups').select('name').eq('id', r['group_id']).limit(1);
          if ((gRows as List).isNotEmpty) groupName = gRows.first['name'] as String?;
        } catch (_) {}
        result.add(
          GroupInvitation(
            id: r['id'] as int,
            groupId: r['group_id'] as String,
            senderId: r['sender_id'] as String,
            recipientEmail: r['recipient_email'] as String,
            role: r['role'] as String? ?? 'member',
            status: r['status'] as String,
            createdAt: r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String) : null,
            senderName: senderName,
            groupName: groupName,
          ),
        );
      }
      return result;
    } catch (e) {
      developer.log('[GroupService] getMyInvitations error: $e');
      return [];
    }
  }

  static Future<({bool success, String? error})> acceptInvitation(int invitationId) async {
    try {
      await _db.rpc('accept_invitation', params: {'invitation_id': invitationId});
      invalidateCache();
      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] acceptInvitation error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> declineInvitation(int invitationId) async {
    try {
      await _db.from('invitations').update({'status': 'declined'}).eq('id', invitationId);
    } catch (e) {
      developer.log('[GroupService] declineInvitation error: $e');
    }
  }
}
