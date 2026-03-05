import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';

// ─── Модели ───────────────────────────────────────────────────────────────────

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
}

class Invitation {
  final int id;
  final String groupId;
  final String senderId;
  final String recipientEmail;
  final bool isStudent;
  final String status;
  final DateTime? createdAt;
  final String? senderName;
  final String? groupName;

  Invitation({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.recipientEmail,
    required this.isStudent,
    required this.status,
    this.createdAt,
    this.senderName,
    this.groupName,
  });
}

// ─── Сервис ───────────────────────────────────────────────────────────────────

class GroupService {
  static final _db = DatabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // Кеш текущей группы
  static Group? _cachedGroup;
  // Явно выбранная группа (если пользователь переключил)
  static String? _activeGroupId;

  static void invalidateCache() {
    _cachedGroup = null;
    _activeGroupId = null;
  }

  /// Установить активную группу (при переключении)
  static void setActiveGroup(String groupId) {
    _activeGroupId = groupId;
    _cachedGroup = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Получить все группы пользователя
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<({Group group, String role})>> getAllGroups() async {
    if (_uid == null) return [];
    try {
      final rows = await _db
          .from('group_members')
          .select()
          .eq('user_id', _uid!);

      final result = <({Group group, String role})>[];
      for (final r in rows as List) {
        final gid = r['group_id'] as String;
        final role = r['role'] as String;
        try {
          final gRows = await _db.from('groups').select().eq('id', gid).limit(1);
          if ((gRows as List).isNotEmpty) {
            result.add((group: Group.fromRow(gRows.first), role: role));
          }
        } catch (_) {}
      }
      return result;
    } catch (e) {
      developer.log('[GroupService] getAllGroups error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Получить текущую (активную) группу
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Group?> getCurrentGroup() async {
    if (_cachedGroup != null) return _cachedGroup;
    if (_uid == null) return null;
    try {
      // Если есть явно выбранная группа — используем её
      if (_activeGroupId != null) {
        final rows = await _db.from('groups').select().eq('id', _activeGroupId!).limit(1);
        if ((rows as List).isNotEmpty) {
          _cachedGroup = Group.fromRow(rows.first);
          return _cachedGroup;
        }
      }

      // Загружаем все membership
      final memberships = await _db
          .from('group_members')
          .select()
          .eq('user_id', _uid!);

      if ((memberships as List).isEmpty) return null;

      // Приоритет: группа где есть данные (не owner пустой),
      // потом owner, потом первая попавшаяся
      // Но для простоты: если >1 группы — берём НЕ свою (т.е. где role != owner), 
      // потому что скорее всего пользователя пригласили в рабочую группу
      String? targetGroupId;

      if (memberships.length == 1) {
        targetGroupId = memberships.first['group_id'] as String;
      } else {
        // Сначала ищем группу где role=manager (куда пригласили)
        for (final m in memberships) {
          if (m['role'] == 'manager') {
            targetGroupId = m['group_id'] as String;
            break;
          }
        }
        // Если не нашли — берём owner
        targetGroupId ??= memberships.first['group_id'] as String;
      }

      final gRows = await _db.from('groups').select().eq('id', targetGroupId!).limit(1);
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

  /// ID текущей группы
  static Future<String?> getCurrentGroupId() async {
    final g = await getCurrentGroup();
    return g?.id;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Является ли текущий пользователь владельцем
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool> isOwner() async {
    final g = await getCurrentGroup();
    return g?.ownerId == _uid;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Моё членство
  // ══════════════════════════════════════════════════════════════════════════

  static Future<GroupMember?> getMyMembership() async {
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return null;
    try {
      final rows = await _db
          .from('group_members')
          .select()
          .eq('group_id', gid)
          .eq('user_id', _uid!)
          .limit(1);
      if ((rows as List).isEmpty) return null;
      final r = rows.first;
      return GroupMember(
        id: r['id'] as int,
        groupId: r['group_id'] as String,
        userId: r['user_id'] as String,
        role: r['role'] as String,
        isStudent: r['is_student'] as bool? ?? false,
      );
    } catch (e) {
      developer.log('[GroupService] getMyMembership error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Переключить «Я — член группы»
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> toggleIsStudent(bool value) async {
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) return;
    try {
      await _db
          .from('group_members')
          .update({'is_student': value})
          .eq('group_id', gid)
          .eq('user_id', _uid!);

      if (value) {
        // Создаём запись в students если нет
        final profile = await AuthService.getProfile();
        if (profile == null) return;
        final existing = await _db
            .from('students')
            .select('id')
            .eq('group_id', gid)
            .eq('linked_user_id', _uid!)
            .limit(1);
        if ((existing as List).isEmpty) {
          await _db.from('students').insert({
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
          // Реактивируем если была деактивирована
          await _db
              .from('students')
              .update({'status': 'active'})
              .eq('group_id', gid)
              .eq('linked_user_id', _uid!);
        }
      } else {
        // Деактивируем запись (не удаляем — сохраняем историю)
        await _db
            .from('students')
            .update({'status': 'inactive'})
            .eq('group_id', gid)
            .eq('linked_user_id', _uid!);
      }
    } catch (e) {
      developer.log('[GroupService] toggleIsStudent error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Список участников группы
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<GroupMember>> getMembers() async {
    final gid = await getCurrentGroupId();
    if (gid == null) return [];
    try {
      // Загружаем членов
      final rows = await _db
          .from('group_members')
          .select()
          .eq('group_id', gid)
          .order('role', ascending: true);

      final members = <GroupMember>[];
      for (final r in rows as List) {
        final userId = r['user_id'] as String;
        // Загружаем профиль отдельно
        Map<String, dynamic>? p;
        try {
          final pRows = await _db.from('profiles').select().eq('id', userId).limit(1);
          if ((pRows as List).isNotEmpty) p = pRows.first;
        } catch (_) {}

        members.add(GroupMember(
          id: r['id'] as int,
          groupId: r['group_id'] as String,
          userId: userId,
          role: r['role'] as String,
          isStudent: r['is_student'] as bool? ?? false,
          email: p?['email'] as String?,
          firstName: p?['first_name'] as String?,
          lastName: p?['last_name'] as String?,
          avatarUrl: p?['avatar_url'] as String?,
        ));
      }
      return members;
    } catch (e) {
      developer.log('[GroupService] getMembers error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Приглашение
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> invite({
    required String email,
    required bool isStudent,
  }) async {
    final gid = await getCurrentGroupId();
    if (gid == null || _uid == null) {
      return (success: false, error: 'Группа не найдена');
    }
    try {
      // Проверяем не приглашён ли уже
      final existing = await _db
          .from('invitations')
          .select()
          .eq('group_id', gid)
          .eq('recipient_email', email.trim())
          .eq('status', 'pending')
          .limit(1);
      if ((existing as List).isNotEmpty) {
        return (success: false, error: 'Приглашение уже отправлено');
      }

      // Создаём приглашение
      await _db.from('invitations').insert({
        'group_id': gid,
        'sender_id': _uid!,
        'recipient_email': email.trim(),
        'is_student': isStudent,
      });

      // Уведомление создаётся автоматически триггером в БД

      return (success: true, error: null);
    } catch (e) {
      developer.log('[GroupService] invite error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Мои входящие приглашения
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<Invitation>> getMyInvitations() async {
    if (_uid == null) return [];
    try {
      final email = _db.auth.currentUser?.email;
      if (email == null) return [];

      final rows = await _db
          .from('invitations')
          .select()
          .eq('recipient_email', email)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final result = <Invitation>[];
      for (final r in rows as List) {
        // Загружаем имя отправителя
        String? senderName;
        try {
          final sRows = await _db.from('profiles').select('first_name, last_name').eq('id', r['sender_id']).limit(1);
          if ((sRows as List).isNotEmpty) {
            senderName = '${sRows.first['first_name'] ?? ''} ${sRows.first['last_name'] ?? ''}'.trim();
          }
        } catch (_) {}

        // Загружаем имя группы
        String? groupName;
        try {
          final gRows = await _db.from('groups').select('name').eq('id', r['group_id']).limit(1);
          if ((gRows as List).isNotEmpty) {
            groupName = gRows.first['name'] as String?;
          }
        } catch (_) {}

        result.add(Invitation(
          id: r['id'] as int,
          groupId: r['group_id'] as String,
          senderId: r['sender_id'] as String,
          recipientEmail: r['recipient_email'] as String,
          isStudent: r['is_student'] as bool? ?? false,
          status: r['status'] as String,
          createdAt: r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String) : null,
          senderName: senderName,
          groupName: groupName,
        ));
      }
      return result;
    } catch (e) {
      developer.log('[GroupService] getMyInvitations error: $e');
      return [];
    }
  }

  /// Принять приглашение
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

  /// Отклонить приглашение
  static Future<void> declineInvitation(int invitationId) async {
    try {
      await _db
          .from('invitations')
          .update({'status': 'declined'})
          .eq('id', invitationId);
    } catch (e) {
      developer.log('[GroupService] declineInvitation error: $e');
    }
  }

  /// Удалить участника из группы (только owner)
  static Future<void> removeMember(int memberId) async {
    try {
      await _db.from('group_members').delete().eq('id', memberId);
    } catch (e) {
      developer.log('[GroupService] removeMember error: $e');
    }
  }
}