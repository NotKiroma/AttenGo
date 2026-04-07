// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, email, firstName, lastName, avatarUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<LocalProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? createdAt;
  const LocalProfile(
      {required this.id,
      required this.email,
      required this.firstName,
      required this.lastName,
      this.avatarUrl,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      id: Value(id),
      email: Value(email),
      firstName: Value(firstName),
      lastName: Value(lastName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  LocalProfile copyWith(
          {String? id,
          String? email,
          String? firstName,
          String? lastName,
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> createdAt = const Value.absent()}) =>
      LocalProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, email, firstName, lastName, avatarUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.id == this.id &&
          other.email == this.email &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.avatarUrl == this.avatarUrl &&
          other.createdAt == this.createdAt);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String?> avatarUrl;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String id,
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalProfile> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? avatarUrl,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String?>? avatarUrl,
      Value<String?>? createdAt,
      Value<int>? rowid}) {
    return LocalProfilesCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalGroupsTable extends LocalGroups
    with TableInfo<$LocalGroupsTable, LocalGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, ownerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_groups';
  @override
  VerificationContext validateIntegrity(Insertable<LocalGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
    );
  }

  @override
  $LocalGroupsTable createAlias(String alias) {
    return $LocalGroupsTable(attachedDatabase, alias);
  }
}

class LocalGroup extends DataClass implements Insertable<LocalGroup> {
  final String id;
  final String name;
  final String ownerId;
  const LocalGroup(
      {required this.id, required this.name, required this.ownerId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_id'] = Variable<String>(ownerId);
    return map;
  }

  LocalGroupsCompanion toCompanion(bool nullToAbsent) {
    return LocalGroupsCompanion(
      id: Value(id),
      name: Value(name),
      ownerId: Value(ownerId),
    );
  }

  factory LocalGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerId': serializer.toJson<String>(ownerId),
    };
  }

  LocalGroup copyWith({String? id, String? name, String? ownerId}) =>
      LocalGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
      );
  @override
  String toString() {
    return (StringBuffer('LocalGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, ownerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId);
}

class LocalGroupsCompanion extends UpdateCompanion<LocalGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerId;
  final Value<int> rowid;
  const LocalGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGroupsCompanion.insert({
    required String id,
    required String name,
    required String ownerId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        ownerId = Value(ownerId);
  static Insertable<LocalGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? ownerId,
      Value<int>? rowid}) {
    return LocalGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalGroupMembersTable extends LocalGroupMembers
    with TableInfo<$LocalGroupMembersTable, LocalGroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isStudentMeta =
      const VerificationMeta('isStudent');
  @override
  late final GeneratedColumn<bool> isStudent = GeneratedColumn<bool>(
      'is_student', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_student" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, groupId, userId, role, isStudent];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_group_members';
  @override
  VerificationContext validateIntegrity(Insertable<LocalGroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_student')) {
      context.handle(_isStudentMeta,
          isStudent.isAcceptableOrUnknown(data['is_student']!, _isStudentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGroupMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      isStudent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_student'])!,
    );
  }

  @override
  $LocalGroupMembersTable createAlias(String alias) {
    return $LocalGroupMembersTable(attachedDatabase, alias);
  }
}

class LocalGroupMember extends DataClass
    implements Insertable<LocalGroupMember> {
  final int id;
  final String groupId;
  final String userId;
  final String role;
  final bool isStudent;
  const LocalGroupMember(
      {required this.id,
      required this.groupId,
      required this.userId,
      required this.role,
      required this.isStudent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['is_student'] = Variable<bool>(isStudent);
    return map;
  }

  LocalGroupMembersCompanion toCompanion(bool nullToAbsent) {
    return LocalGroupMembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      role: Value(role),
      isStudent: Value(isStudent),
    );
  }

  factory LocalGroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGroupMember(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      isStudent: serializer.fromJson<bool>(json['isStudent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'isStudent': serializer.toJson<bool>(isStudent),
    };
  }

  LocalGroupMember copyWith(
          {int? id,
          String? groupId,
          String? userId,
          String? role,
          bool? isStudent}) =>
      LocalGroupMember(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        isStudent: isStudent ?? this.isStudent,
      );
  @override
  String toString() {
    return (StringBuffer('LocalGroupMember(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('isStudent: $isStudent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, userId, role, isStudent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGroupMember &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.isStudent == this.isStudent);
}

class LocalGroupMembersCompanion extends UpdateCompanion<LocalGroupMember> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> role;
  final Value<bool> isStudent;
  const LocalGroupMembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.isStudent = const Value.absent(),
  });
  LocalGroupMembersCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required String userId,
    required String role,
    this.isStudent = const Value.absent(),
  })  : groupId = Value(groupId),
        userId = Value(userId),
        role = Value(role);
  static Insertable<LocalGroupMember> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<bool>? isStudent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (isStudent != null) 'is_student': isStudent,
    });
  }

  LocalGroupMembersCompanion copyWith(
      {Value<int>? id,
      Value<String>? groupId,
      Value<String>? userId,
      Value<String>? role,
      Value<bool>? isStudent}) {
    return LocalGroupMembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isStudent: isStudent ?? this.isStudent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isStudent.present) {
      map['is_student'] = Variable<bool>(isStudent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroupMembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('isStudent: $isStudent')
          ..write(')'))
        .toString();
  }
}

class $LocalStudentsTable extends LocalStudents
    with TableInfo<$LocalStudentsTable, LocalStudent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _middleNameMeta =
      const VerificationMeta('middleName');
  @override
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
      'middle_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _birthDayMeta =
      const VerificationMeta('birthDay');
  @override
  late final GeneratedColumn<String> birthDay = GeneratedColumn<String>(
      'birth_day', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _birthMonthMeta =
      const VerificationMeta('birthMonth');
  @override
  late final GeneratedColumn<String> birthMonth = GeneratedColumn<String>(
      'birth_month', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _birthYearMeta =
      const VerificationMeta('birthYear');
  @override
  late final GeneratedColumn<String> birthYear = GeneratedColumn<String>(
      'birth_year', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isMaleMeta = const VerificationMeta('isMale');
  @override
  late final GeneratedColumn<bool> isMale = GeneratedColumn<bool>(
      'is_male', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_male" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _linkedUserIdMeta =
      const VerificationMeta('linkedUserId');
  @override
  late final GeneratedColumn<String> linkedUserId = GeneratedColumn<String>(
      'linked_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        lastName,
        firstName,
        middleName,
        birthDay,
        birthMonth,
        birthYear,
        isMale,
        status,
        linkedUserId,
        avatarUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_students';
  @override
  VerificationContext validateIntegrity(Insertable<LocalStudent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    }
    if (data.containsKey('middle_name')) {
      context.handle(
          _middleNameMeta,
          middleName.isAcceptableOrUnknown(
              data['middle_name']!, _middleNameMeta));
    }
    if (data.containsKey('birth_day')) {
      context.handle(_birthDayMeta,
          birthDay.isAcceptableOrUnknown(data['birth_day']!, _birthDayMeta));
    }
    if (data.containsKey('birth_month')) {
      context.handle(
          _birthMonthMeta,
          birthMonth.isAcceptableOrUnknown(
              data['birth_month']!, _birthMonthMeta));
    }
    if (data.containsKey('birth_year')) {
      context.handle(_birthYearMeta,
          birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta));
    }
    if (data.containsKey('is_male')) {
      context.handle(_isMaleMeta,
          isMale.isAcceptableOrUnknown(data['is_male']!, _isMaleMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('linked_user_id')) {
      context.handle(
          _linkedUserIdMeta,
          linkedUserId.isAcceptableOrUnknown(
              data['linked_user_id']!, _linkedUserIdMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStudent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStudent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      middleName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}middle_name'])!,
      birthDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_day'])!,
      birthMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_month'])!,
      birthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_year'])!,
      isMale: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_male'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      linkedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}linked_user_id']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
    );
  }

  @override
  $LocalStudentsTable createAlias(String alias) {
    return $LocalStudentsTable(attachedDatabase, alias);
  }
}

class LocalStudent extends DataClass implements Insertable<LocalStudent> {
  final String id;
  final String groupId;
  final String lastName;
  final String firstName;
  final String middleName;
  final String birthDay;
  final String birthMonth;
  final String birthYear;
  final bool isMale;
  final String status;
  final String? linkedUserId;
  final String? avatarUrl;
  const LocalStudent(
      {required this.id,
      required this.groupId,
      required this.lastName,
      required this.firstName,
      required this.middleName,
      required this.birthDay,
      required this.birthMonth,
      required this.birthYear,
      required this.isMale,
      required this.status,
      this.linkedUserId,
      this.avatarUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['last_name'] = Variable<String>(lastName);
    map['first_name'] = Variable<String>(firstName);
    map['middle_name'] = Variable<String>(middleName);
    map['birth_day'] = Variable<String>(birthDay);
    map['birth_month'] = Variable<String>(birthMonth);
    map['birth_year'] = Variable<String>(birthYear);
    map['is_male'] = Variable<bool>(isMale);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || linkedUserId != null) {
      map['linked_user_id'] = Variable<String>(linkedUserId);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    return map;
  }

  LocalStudentsCompanion toCompanion(bool nullToAbsent) {
    return LocalStudentsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      lastName: Value(lastName),
      firstName: Value(firstName),
      middleName: Value(middleName),
      birthDay: Value(birthDay),
      birthMonth: Value(birthMonth),
      birthYear: Value(birthYear),
      isMale: Value(isMale),
      status: Value(status),
      linkedUserId: linkedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedUserId),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
    );
  }

  factory LocalStudent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStudent(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      lastName: serializer.fromJson<String>(json['lastName']),
      firstName: serializer.fromJson<String>(json['firstName']),
      middleName: serializer.fromJson<String>(json['middleName']),
      birthDay: serializer.fromJson<String>(json['birthDay']),
      birthMonth: serializer.fromJson<String>(json['birthMonth']),
      birthYear: serializer.fromJson<String>(json['birthYear']),
      isMale: serializer.fromJson<bool>(json['isMale']),
      status: serializer.fromJson<String>(json['status']),
      linkedUserId: serializer.fromJson<String?>(json['linkedUserId']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'lastName': serializer.toJson<String>(lastName),
      'firstName': serializer.toJson<String>(firstName),
      'middleName': serializer.toJson<String>(middleName),
      'birthDay': serializer.toJson<String>(birthDay),
      'birthMonth': serializer.toJson<String>(birthMonth),
      'birthYear': serializer.toJson<String>(birthYear),
      'isMale': serializer.toJson<bool>(isMale),
      'status': serializer.toJson<String>(status),
      'linkedUserId': serializer.toJson<String?>(linkedUserId),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
    };
  }

  LocalStudent copyWith(
          {String? id,
          String? groupId,
          String? lastName,
          String? firstName,
          String? middleName,
          String? birthDay,
          String? birthMonth,
          String? birthYear,
          bool? isMale,
          String? status,
          Value<String?> linkedUserId = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent()}) =>
      LocalStudent(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        lastName: lastName ?? this.lastName,
        firstName: firstName ?? this.firstName,
        middleName: middleName ?? this.middleName,
        birthDay: birthDay ?? this.birthDay,
        birthMonth: birthMonth ?? this.birthMonth,
        birthYear: birthYear ?? this.birthYear,
        isMale: isMale ?? this.isMale,
        status: status ?? this.status,
        linkedUserId:
            linkedUserId.present ? linkedUserId.value : this.linkedUserId,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
      );
  @override
  String toString() {
    return (StringBuffer('LocalStudent(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('birthDay: $birthDay, ')
          ..write('birthMonth: $birthMonth, ')
          ..write('birthYear: $birthYear, ')
          ..write('isMale: $isMale, ')
          ..write('status: $status, ')
          ..write('linkedUserId: $linkedUserId, ')
          ..write('avatarUrl: $avatarUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, lastName, firstName, middleName,
      birthDay, birthMonth, birthYear, isMale, status, linkedUserId, avatarUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStudent &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.lastName == this.lastName &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.birthDay == this.birthDay &&
          other.birthMonth == this.birthMonth &&
          other.birthYear == this.birthYear &&
          other.isMale == this.isMale &&
          other.status == this.status &&
          other.linkedUserId == this.linkedUserId &&
          other.avatarUrl == this.avatarUrl);
}

class LocalStudentsCompanion extends UpdateCompanion<LocalStudent> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> lastName;
  final Value<String> firstName;
  final Value<String> middleName;
  final Value<String> birthDay;
  final Value<String> birthMonth;
  final Value<String> birthYear;
  final Value<bool> isMale;
  final Value<String> status;
  final Value<String?> linkedUserId;
  final Value<String?> avatarUrl;
  final Value<int> rowid;
  const LocalStudentsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.lastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.birthDay = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.isMale = const Value.absent(),
    this.status = const Value.absent(),
    this.linkedUserId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStudentsCompanion.insert({
    required String id,
    required String groupId,
    this.lastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.birthDay = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.isMale = const Value.absent(),
    this.status = const Value.absent(),
    this.linkedUserId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId);
  static Insertable<LocalStudent> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? lastName,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? birthDay,
    Expression<String>? birthMonth,
    Expression<String>? birthYear,
    Expression<bool>? isMale,
    Expression<String>? status,
    Expression<String>? linkedUserId,
    Expression<String>? avatarUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (lastName != null) 'last_name': lastName,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (birthDay != null) 'birth_day': birthDay,
      if (birthMonth != null) 'birth_month': birthMonth,
      if (birthYear != null) 'birth_year': birthYear,
      if (isMale != null) 'is_male': isMale,
      if (status != null) 'status': status,
      if (linkedUserId != null) 'linked_user_id': linkedUserId,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStudentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? lastName,
      Value<String>? firstName,
      Value<String>? middleName,
      Value<String>? birthDay,
      Value<String>? birthMonth,
      Value<String>? birthYear,
      Value<bool>? isMale,
      Value<String>? status,
      Value<String?>? linkedUserId,
      Value<String?>? avatarUrl,
      Value<int>? rowid}) {
    return LocalStudentsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      birthDay: birthDay ?? this.birthDay,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      isMale: isMale ?? this.isMale,
      status: status ?? this.status,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (birthDay.present) {
      map['birth_day'] = Variable<String>(birthDay.value);
    }
    if (birthMonth.present) {
      map['birth_month'] = Variable<String>(birthMonth.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<String>(birthYear.value);
    }
    if (isMale.present) {
      map['is_male'] = Variable<bool>(isMale.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (linkedUserId.present) {
      map['linked_user_id'] = Variable<String>(linkedUserId.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudentsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('birthDay: $birthDay, ')
          ..write('birthMonth: $birthMonth, ')
          ..write('birthYear: $birthYear, ')
          ..write('isMale: $isMale, ')
          ..write('status: $status, ')
          ..write('linkedUserId: $linkedUserId, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalScheduleTable extends LocalSchedule
    with TableInfo<$LocalScheduleTable, LocalScheduleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalScheduleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayIndexMeta =
      const VerificationMeta('dayIndex');
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
      'day_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timeStartMeta =
      const VerificationMeta('timeStart');
  @override
  late final GeneratedColumn<String> timeStart = GeneratedColumn<String>(
      'time_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeEndMeta =
      const VerificationMeta('timeEnd');
  @override
  late final GeneratedColumn<String> timeEnd = GeneratedColumn<String>(
      'time_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
      'room', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teacherMeta =
      const VerificationMeta('teacher');
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
      'teacher', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, groupId, dayIndex, timeStart, timeEnd, subject, room, teacher];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_schedule';
  @override
  VerificationContext validateIntegrity(Insertable<LocalScheduleData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('day_index')) {
      context.handle(_dayIndexMeta,
          dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta));
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    if (data.containsKey('time_start')) {
      context.handle(_timeStartMeta,
          timeStart.isAcceptableOrUnknown(data['time_start']!, _timeStartMeta));
    } else if (isInserting) {
      context.missing(_timeStartMeta);
    }
    if (data.containsKey('time_end')) {
      context.handle(_timeEndMeta,
          timeEnd.isAcceptableOrUnknown(data['time_end']!, _timeEndMeta));
    } else if (isInserting) {
      context.missing(_timeEndMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('room')) {
      context.handle(
          _roomMeta, room.isAcceptableOrUnknown(data['room']!, _roomMeta));
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(_teacherMeta,
          teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta));
    } else if (isInserting) {
      context.missing(_teacherMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalScheduleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalScheduleData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      dayIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_index'])!,
      timeStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_start'])!,
      timeEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_end'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      room: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room'])!,
      teacher: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher'])!,
    );
  }

  @override
  $LocalScheduleTable createAlias(String alias) {
    return $LocalScheduleTable(attachedDatabase, alias);
  }
}

class LocalScheduleData extends DataClass
    implements Insertable<LocalScheduleData> {
  final int id;
  final String groupId;
  final int dayIndex;
  final String timeStart;
  final String timeEnd;
  final String subject;
  final String room;
  final String teacher;
  const LocalScheduleData(
      {required this.id,
      required this.groupId,
      required this.dayIndex,
      required this.timeStart,
      required this.timeEnd,
      required this.subject,
      required this.room,
      required this.teacher});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['day_index'] = Variable<int>(dayIndex);
    map['time_start'] = Variable<String>(timeStart);
    map['time_end'] = Variable<String>(timeEnd);
    map['subject'] = Variable<String>(subject);
    map['room'] = Variable<String>(room);
    map['teacher'] = Variable<String>(teacher);
    return map;
  }

  LocalScheduleCompanion toCompanion(bool nullToAbsent) {
    return LocalScheduleCompanion(
      id: Value(id),
      groupId: Value(groupId),
      dayIndex: Value(dayIndex),
      timeStart: Value(timeStart),
      timeEnd: Value(timeEnd),
      subject: Value(subject),
      room: Value(room),
      teacher: Value(teacher),
    );
  }

  factory LocalScheduleData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalScheduleData(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
      timeStart: serializer.fromJson<String>(json['timeStart']),
      timeEnd: serializer.fromJson<String>(json['timeEnd']),
      subject: serializer.fromJson<String>(json['subject']),
      room: serializer.fromJson<String>(json['room']),
      teacher: serializer.fromJson<String>(json['teacher']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'dayIndex': serializer.toJson<int>(dayIndex),
      'timeStart': serializer.toJson<String>(timeStart),
      'timeEnd': serializer.toJson<String>(timeEnd),
      'subject': serializer.toJson<String>(subject),
      'room': serializer.toJson<String>(room),
      'teacher': serializer.toJson<String>(teacher),
    };
  }

  LocalScheduleData copyWith(
          {int? id,
          String? groupId,
          int? dayIndex,
          String? timeStart,
          String? timeEnd,
          String? subject,
          String? room,
          String? teacher}) =>
      LocalScheduleData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        dayIndex: dayIndex ?? this.dayIndex,
        timeStart: timeStart ?? this.timeStart,
        timeEnd: timeEnd ?? this.timeEnd,
        subject: subject ?? this.subject,
        room: room ?? this.room,
        teacher: teacher ?? this.teacher,
      );
  @override
  String toString() {
    return (StringBuffer('LocalScheduleData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('timeStart: $timeStart, ')
          ..write('timeEnd: $timeEnd, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('teacher: $teacher')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, groupId, dayIndex, timeStart, timeEnd, subject, room, teacher);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalScheduleData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.dayIndex == this.dayIndex &&
          other.timeStart == this.timeStart &&
          other.timeEnd == this.timeEnd &&
          other.subject == this.subject &&
          other.room == this.room &&
          other.teacher == this.teacher);
}

class LocalScheduleCompanion extends UpdateCompanion<LocalScheduleData> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<int> dayIndex;
  final Value<String> timeStart;
  final Value<String> timeEnd;
  final Value<String> subject;
  final Value<String> room;
  final Value<String> teacher;
  const LocalScheduleCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.timeStart = const Value.absent(),
    this.timeEnd = const Value.absent(),
    this.subject = const Value.absent(),
    this.room = const Value.absent(),
    this.teacher = const Value.absent(),
  });
  LocalScheduleCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required int dayIndex,
    required String timeStart,
    required String timeEnd,
    required String subject,
    required String room,
    required String teacher,
  })  : groupId = Value(groupId),
        dayIndex = Value(dayIndex),
        timeStart = Value(timeStart),
        timeEnd = Value(timeEnd),
        subject = Value(subject),
        room = Value(room),
        teacher = Value(teacher);
  static Insertable<LocalScheduleData> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<int>? dayIndex,
    Expression<String>? timeStart,
    Expression<String>? timeEnd,
    Expression<String>? subject,
    Expression<String>? room,
    Expression<String>? teacher,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (dayIndex != null) 'day_index': dayIndex,
      if (timeStart != null) 'time_start': timeStart,
      if (timeEnd != null) 'time_end': timeEnd,
      if (subject != null) 'subject': subject,
      if (room != null) 'room': room,
      if (teacher != null) 'teacher': teacher,
    });
  }

  LocalScheduleCompanion copyWith(
      {Value<int>? id,
      Value<String>? groupId,
      Value<int>? dayIndex,
      Value<String>? timeStart,
      Value<String>? timeEnd,
      Value<String>? subject,
      Value<String>? room,
      Value<String>? teacher}) {
    return LocalScheduleCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      dayIndex: dayIndex ?? this.dayIndex,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (timeStart.present) {
      map['time_start'] = Variable<String>(timeStart.value);
    }
    if (timeEnd.present) {
      map['time_end'] = Variable<String>(timeEnd.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalScheduleCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('timeStart: $timeStart, ')
          ..write('timeEnd: $timeEnd, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('teacher: $teacher')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceLessonsTable extends LocalAttendanceLessons
    with TableInfo<$LocalAttendanceLessonsTable, LocalAttendanceLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceLessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonKeyMeta =
      const VerificationMeta('lessonKey');
  @override
  late final GeneratedColumn<String> lessonKey = GeneratedColumn<String>(
      'lesson_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, groupId, date, lessonKey, subject];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance_lessons';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAttendanceLesson> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('lesson_key')) {
      context.handle(_lessonKeyMeta,
          lessonKey.isAcceptableOrUnknown(data['lesson_key']!, _lessonKeyMeta));
    } else if (isInserting) {
      context.missing(_lessonKeyMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAttendanceLesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceLesson(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      lessonKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_key'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
    );
  }

  @override
  $LocalAttendanceLessonsTable createAlias(String alias) {
    return $LocalAttendanceLessonsTable(attachedDatabase, alias);
  }
}

class LocalAttendanceLesson extends DataClass
    implements Insertable<LocalAttendanceLesson> {
  final int id;
  final String groupId;
  final String date;
  final String lessonKey;
  final String subject;
  const LocalAttendanceLesson(
      {required this.id,
      required this.groupId,
      required this.date,
      required this.lessonKey,
      required this.subject});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['date'] = Variable<String>(date);
    map['lesson_key'] = Variable<String>(lessonKey);
    map['subject'] = Variable<String>(subject);
    return map;
  }

  LocalAttendanceLessonsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceLessonsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      date: Value(date),
      lessonKey: Value(lessonKey),
      subject: Value(subject),
    );
  }

  factory LocalAttendanceLesson.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceLesson(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      date: serializer.fromJson<String>(json['date']),
      lessonKey: serializer.fromJson<String>(json['lessonKey']),
      subject: serializer.fromJson<String>(json['subject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'date': serializer.toJson<String>(date),
      'lessonKey': serializer.toJson<String>(lessonKey),
      'subject': serializer.toJson<String>(subject),
    };
  }

  LocalAttendanceLesson copyWith(
          {int? id,
          String? groupId,
          String? date,
          String? lessonKey,
          String? subject}) =>
      LocalAttendanceLesson(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        date: date ?? this.date,
        lessonKey: lessonKey ?? this.lessonKey,
        subject: subject ?? this.subject,
      );
  @override
  String toString() {
    return (StringBuffer('LocalAttendanceLesson(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('date: $date, ')
          ..write('lessonKey: $lessonKey, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, date, lessonKey, subject);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceLesson &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.date == this.date &&
          other.lessonKey == this.lessonKey &&
          other.subject == this.subject);
}

class LocalAttendanceLessonsCompanion
    extends UpdateCompanion<LocalAttendanceLesson> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<String> date;
  final Value<String> lessonKey;
  final Value<String> subject;
  const LocalAttendanceLessonsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.date = const Value.absent(),
    this.lessonKey = const Value.absent(),
    this.subject = const Value.absent(),
  });
  LocalAttendanceLessonsCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required String date,
    required String lessonKey,
    required String subject,
  })  : groupId = Value(groupId),
        date = Value(date),
        lessonKey = Value(lessonKey),
        subject = Value(subject);
  static Insertable<LocalAttendanceLesson> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<String>? date,
    Expression<String>? lessonKey,
    Expression<String>? subject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (date != null) 'date': date,
      if (lessonKey != null) 'lesson_key': lessonKey,
      if (subject != null) 'subject': subject,
    });
  }

  LocalAttendanceLessonsCompanion copyWith(
      {Value<int>? id,
      Value<String>? groupId,
      Value<String>? date,
      Value<String>? lessonKey,
      Value<String>? subject}) {
    return LocalAttendanceLessonsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      lessonKey: lessonKey ?? this.lessonKey,
      subject: subject ?? this.subject,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (lessonKey.present) {
      map['lesson_key'] = Variable<String>(lessonKey.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceLessonsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('date: $date, ')
          ..write('lessonKey: $lessonKey, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceRecordsTable extends LocalAttendanceRecords
    with TableInfo<$LocalAttendanceRecordsTable, LocalAttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, lessonId, studentId, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAttendanceRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lesson_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
    );
  }

  @override
  $LocalAttendanceRecordsTable createAlias(String alias) {
    return $LocalAttendanceRecordsTable(attachedDatabase, alias);
  }
}

class LocalAttendanceRecord extends DataClass
    implements Insertable<LocalAttendanceRecord> {
  final int id;
  final int lessonId;
  final String studentId;
  final String? status;
  const LocalAttendanceRecord(
      {required this.id,
      required this.lessonId,
      required this.studentId,
      this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lesson_id'] = Variable<int>(lessonId);
    map['student_id'] = Variable<String>(studentId);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  LocalAttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceRecordsCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      studentId: Value(studentId),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
    );
  }

  factory LocalAttendanceRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceRecord(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int>(lessonId),
      'studentId': serializer.toJson<String>(studentId),
      'status': serializer.toJson<String?>(status),
    };
  }

  LocalAttendanceRecord copyWith(
          {int? id,
          int? lessonId,
          String? studentId,
          Value<String?> status = const Value.absent()}) =>
      LocalAttendanceRecord(
        id: id ?? this.id,
        lessonId: lessonId ?? this.lessonId,
        studentId: studentId ?? this.studentId,
        status: status.present ? status.value : this.status,
      );
  @override
  String toString() {
    return (StringBuffer('LocalAttendanceRecord(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lessonId, studentId, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceRecord &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.studentId == this.studentId &&
          other.status == this.status);
}

class LocalAttendanceRecordsCompanion
    extends UpdateCompanion<LocalAttendanceRecord> {
  final Value<int> id;
  final Value<int> lessonId;
  final Value<String> studentId;
  final Value<String?> status;
  const LocalAttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.status = const Value.absent(),
  });
  LocalAttendanceRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int lessonId,
    required String studentId,
    this.status = const Value.absent(),
  })  : lessonId = Value(lessonId),
        studentId = Value(studentId);
  static Insertable<LocalAttendanceRecord> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? studentId,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (studentId != null) 'student_id': studentId,
      if (status != null) 'status': status,
    });
  }

  LocalAttendanceRecordsCompanion copyWith(
      {Value<int>? id,
      Value<int>? lessonId,
      Value<String>? studentId,
      Value<String?>? status}) {
    return LocalAttendanceRecordsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $LocalAnnouncementsTable extends LocalAnnouncements
    with TableInfo<$LocalAnnouncementsTable, LocalAnnouncement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAnnouncementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorIdMeta =
      const VerificationMeta('authorId');
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
      'author_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCancelMeta =
      const VerificationMeta('isCancel');
  @override
  late final GeneratedColumn<bool> isCancel = GeneratedColumn<bool>(
      'is_cancel', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cancel" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cancelDateMeta =
      const VerificationMeta('cancelDate');
  @override
  late final GeneratedColumn<String> cancelDate = GeneratedColumn<String>(
      'cancel_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cancelKeyMeta =
      const VerificationMeta('cancelKey');
  @override
  late final GeneratedColumn<String> cancelKey = GeneratedColumn<String>(
      'cancel_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<String> expiresAt = GeneratedColumn<String>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _authorNameMeta =
      const VerificationMeta('authorName');
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
      'author_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        authorId,
        title,
        body,
        isCancel,
        cancelDate,
        cancelKey,
        expiresAt,
        createdAt,
        authorName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_announcements';
  @override
  VerificationContext validateIntegrity(Insertable<LocalAnnouncement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(_authorIdMeta,
          authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta));
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_cancel')) {
      context.handle(_isCancelMeta,
          isCancel.isAcceptableOrUnknown(data['is_cancel']!, _isCancelMeta));
    }
    if (data.containsKey('cancel_date')) {
      context.handle(
          _cancelDateMeta,
          cancelDate.isAcceptableOrUnknown(
              data['cancel_date']!, _cancelDateMeta));
    }
    if (data.containsKey('cancel_key')) {
      context.handle(_cancelKeyMeta,
          cancelKey.isAcceptableOrUnknown(data['cancel_key']!, _cancelKeyMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('author_name')) {
      context.handle(
          _authorNameMeta,
          authorName.isAcceptableOrUnknown(
              data['author_name']!, _authorNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAnnouncement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAnnouncement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      authorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      isCancel: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cancel'])!,
      cancelDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cancel_date']),
      cancelKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cancel_key']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expires_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      authorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_name']),
    );
  }

  @override
  $LocalAnnouncementsTable createAlias(String alias) {
    return $LocalAnnouncementsTable(attachedDatabase, alias);
  }
}

class LocalAnnouncement extends DataClass
    implements Insertable<LocalAnnouncement> {
  final int id;
  final String groupId;
  final String authorId;
  final String title;
  final String body;
  final bool isCancel;
  final String? cancelDate;
  final String? cancelKey;
  final String? expiresAt;
  final String? createdAt;
  final String? authorName;
  const LocalAnnouncement(
      {required this.id,
      required this.groupId,
      required this.authorId,
      required this.title,
      required this.body,
      required this.isCancel,
      this.cancelDate,
      this.cancelKey,
      this.expiresAt,
      this.createdAt,
      this.authorName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['author_id'] = Variable<String>(authorId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['is_cancel'] = Variable<bool>(isCancel);
    if (!nullToAbsent || cancelDate != null) {
      map['cancel_date'] = Variable<String>(cancelDate);
    }
    if (!nullToAbsent || cancelKey != null) {
      map['cancel_key'] = Variable<String>(cancelKey);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<String>(expiresAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    return map;
  }

  LocalAnnouncementsCompanion toCompanion(bool nullToAbsent) {
    return LocalAnnouncementsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      authorId: Value(authorId),
      title: Value(title),
      body: Value(body),
      isCancel: Value(isCancel),
      cancelDate: cancelDate == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelDate),
      cancelKey: cancelKey == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelKey),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
    );
  }

  factory LocalAnnouncement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAnnouncement(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      authorId: serializer.fromJson<String>(json['authorId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      isCancel: serializer.fromJson<bool>(json['isCancel']),
      cancelDate: serializer.fromJson<String?>(json['cancelDate']),
      cancelKey: serializer.fromJson<String?>(json['cancelKey']),
      expiresAt: serializer.fromJson<String?>(json['expiresAt']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      authorName: serializer.fromJson<String?>(json['authorName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'authorId': serializer.toJson<String>(authorId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'isCancel': serializer.toJson<bool>(isCancel),
      'cancelDate': serializer.toJson<String?>(cancelDate),
      'cancelKey': serializer.toJson<String?>(cancelKey),
      'expiresAt': serializer.toJson<String?>(expiresAt),
      'createdAt': serializer.toJson<String?>(createdAt),
      'authorName': serializer.toJson<String?>(authorName),
    };
  }

  LocalAnnouncement copyWith(
          {int? id,
          String? groupId,
          String? authorId,
          String? title,
          String? body,
          bool? isCancel,
          Value<String?> cancelDate = const Value.absent(),
          Value<String?> cancelKey = const Value.absent(),
          Value<String?> expiresAt = const Value.absent(),
          Value<String?> createdAt = const Value.absent(),
          Value<String?> authorName = const Value.absent()}) =>
      LocalAnnouncement(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        authorId: authorId ?? this.authorId,
        title: title ?? this.title,
        body: body ?? this.body,
        isCancel: isCancel ?? this.isCancel,
        cancelDate: cancelDate.present ? cancelDate.value : this.cancelDate,
        cancelKey: cancelKey.present ? cancelKey.value : this.cancelKey,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        authorName: authorName.present ? authorName.value : this.authorName,
      );
  @override
  String toString() {
    return (StringBuffer('LocalAnnouncement(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('authorId: $authorId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isCancel: $isCancel, ')
          ..write('cancelDate: $cancelDate, ')
          ..write('cancelKey: $cancelKey, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('authorName: $authorName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, authorId, title, body, isCancel,
      cancelDate, cancelKey, expiresAt, createdAt, authorName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAnnouncement &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.authorId == this.authorId &&
          other.title == this.title &&
          other.body == this.body &&
          other.isCancel == this.isCancel &&
          other.cancelDate == this.cancelDate &&
          other.cancelKey == this.cancelKey &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.authorName == this.authorName);
}

class LocalAnnouncementsCompanion extends UpdateCompanion<LocalAnnouncement> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<String> authorId;
  final Value<String> title;
  final Value<String> body;
  final Value<bool> isCancel;
  final Value<String?> cancelDate;
  final Value<String?> cancelKey;
  final Value<String?> expiresAt;
  final Value<String?> createdAt;
  final Value<String?> authorName;
  const LocalAnnouncementsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.authorId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.isCancel = const Value.absent(),
    this.cancelDate = const Value.absent(),
    this.cancelKey = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.authorName = const Value.absent(),
  });
  LocalAnnouncementsCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required String authorId,
    required String title,
    required String body,
    this.isCancel = const Value.absent(),
    this.cancelDate = const Value.absent(),
    this.cancelKey = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.authorName = const Value.absent(),
  })  : groupId = Value(groupId),
        authorId = Value(authorId),
        title = Value(title),
        body = Value(body);
  static Insertable<LocalAnnouncement> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<String>? authorId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<bool>? isCancel,
    Expression<String>? cancelDate,
    Expression<String>? cancelKey,
    Expression<String>? expiresAt,
    Expression<String>? createdAt,
    Expression<String>? authorName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (isCancel != null) 'is_cancel': isCancel,
      if (cancelDate != null) 'cancel_date': cancelDate,
      if (cancelKey != null) 'cancel_key': cancelKey,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (authorName != null) 'author_name': authorName,
    });
  }

  LocalAnnouncementsCompanion copyWith(
      {Value<int>? id,
      Value<String>? groupId,
      Value<String>? authorId,
      Value<String>? title,
      Value<String>? body,
      Value<bool>? isCancel,
      Value<String?>? cancelDate,
      Value<String?>? cancelKey,
      Value<String?>? expiresAt,
      Value<String?>? createdAt,
      Value<String?>? authorName}) {
    return LocalAnnouncementsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      body: body ?? this.body,
      isCancel: isCancel ?? this.isCancel,
      cancelDate: cancelDate ?? this.cancelDate,
      cancelKey: cancelKey ?? this.cancelKey,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isCancel.present) {
      map['is_cancel'] = Variable<bool>(isCancel.value);
    }
    if (cancelDate.present) {
      map['cancel_date'] = Variable<String>(cancelDate.value);
    }
    if (cancelKey.present) {
      map['cancel_key'] = Variable<String>(cancelKey.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<String>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAnnouncementsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('authorId: $authorId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isCancel: $isCancel, ')
          ..write('cancelDate: $cancelDate, ')
          ..write('cancelKey: $cancelKey, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('authorName: $authorName')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationsTable extends LocalNotifications
    with TableInfo<$LocalNotificationsTable, LocalNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, type, title, body, data, isRead, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<LocalNotification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LocalNotificationsTable createAlias(String alias) {
    return $LocalNotificationsTable(attachedDatabase, alias);
  }
}

class LocalNotification extends DataClass
    implements Insertable<LocalNotification> {
  final int id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String data;
  final bool isRead;
  final String? createdAt;
  const LocalNotification(
      {required this.id,
      required this.userId,
      required this.type,
      required this.title,
      required this.body,
      required this.data,
      required this.isRead,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['data'] = Variable<String>(data);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  LocalNotificationsCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      data: Value(data),
      isRead: Value(isRead),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalNotification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotification(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      data: serializer.fromJson<String>(json['data']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'data': serializer.toJson<String>(data),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  LocalNotification copyWith(
          {int? id,
          String? userId,
          String? type,
          String? title,
          String? body,
          String? data,
          bool? isRead,
          Value<String?> createdAt = const Value.absent()}) =>
      LocalNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        data: data ?? this.data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('LocalNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, type, title, body, data, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.data == this.data &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class LocalNotificationsCompanion extends UpdateCompanion<LocalNotification> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> body;
  final Value<String> data;
  final Value<bool> isRead;
  final Value<String?> createdAt;
  const LocalNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String type,
    required String title,
    required String body,
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : userId = Value(userId),
        type = Value(type),
        title = Value(title),
        body = Value(body);
  static Insertable<LocalNotification> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? data,
    Expression<bool>? isRead,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (data != null) 'data': data,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalNotificationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String>? type,
      Value<String>? title,
      Value<String>? body,
      Value<String>? data,
      Value<bool>? isRead,
      Value<String?>? createdAt}) {
    return LocalNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalInvitationsTable extends LocalInvitations
    with TableInfo<$LocalInvitationsTable, LocalInvitation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipientEmailMeta =
      const VerificationMeta('recipientEmail');
  @override
  late final GeneratedColumn<String> recipientEmail = GeneratedColumn<String>(
      'recipient_email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _senderNameMeta =
      const VerificationMeta('senderName');
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
      'sender_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        senderId,
        recipientEmail,
        role,
        status,
        createdAt,
        senderName,
        groupName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_invitations';
  @override
  VerificationContext validateIntegrity(Insertable<LocalInvitation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('recipient_email')) {
      context.handle(
          _recipientEmailMeta,
          recipientEmail.isAcceptableOrUnknown(
              data['recipient_email']!, _recipientEmailMeta));
    } else if (isInserting) {
      context.missing(_recipientEmailMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('sender_name')) {
      context.handle(
          _senderNameMeta,
          senderName.isAcceptableOrUnknown(
              data['sender_name']!, _senderNameMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInvitation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInvitation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      recipientEmail: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recipient_email'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      senderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_name']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name']),
    );
  }

  @override
  $LocalInvitationsTable createAlias(String alias) {
    return $LocalInvitationsTable(attachedDatabase, alias);
  }
}

class LocalInvitation extends DataClass implements Insertable<LocalInvitation> {
  final int id;
  final String groupId;
  final String senderId;
  final String recipientEmail;
  final String role;
  final String status;
  final String? createdAt;
  final String? senderName;
  final String? groupName;
  const LocalInvitation(
      {required this.id,
      required this.groupId,
      required this.senderId,
      required this.recipientEmail,
      required this.role,
      required this.status,
      this.createdAt,
      this.senderName,
      this.groupName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['sender_id'] = Variable<String>(senderId);
    map['recipient_email'] = Variable<String>(recipientEmail);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    return map;
  }

  LocalInvitationsCompanion toCompanion(bool nullToAbsent) {
    return LocalInvitationsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      senderId: Value(senderId),
      recipientEmail: Value(recipientEmail),
      role: Value(role),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
    );
  }

  factory LocalInvitation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInvitation(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      recipientEmail: serializer.fromJson<String>(json['recipientEmail']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      groupName: serializer.fromJson<String?>(json['groupName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'senderId': serializer.toJson<String>(senderId),
      'recipientEmail': serializer.toJson<String>(recipientEmail),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String?>(createdAt),
      'senderName': serializer.toJson<String?>(senderName),
      'groupName': serializer.toJson<String?>(groupName),
    };
  }

  LocalInvitation copyWith(
          {int? id,
          String? groupId,
          String? senderId,
          String? recipientEmail,
          String? role,
          String? status,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> senderName = const Value.absent(),
          Value<String?> groupName = const Value.absent()}) =>
      LocalInvitation(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        senderId: senderId ?? this.senderId,
        recipientEmail: recipientEmail ?? this.recipientEmail,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        senderName: senderName.present ? senderName.value : this.senderName,
        groupName: groupName.present ? groupName.value : this.groupName,
      );
  @override
  String toString() {
    return (StringBuffer('LocalInvitation(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('recipientEmail: $recipientEmail, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('senderName: $senderName, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, senderId, recipientEmail, role,
      status, createdAt, senderName, groupName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInvitation &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.senderId == this.senderId &&
          other.recipientEmail == this.recipientEmail &&
          other.role == this.role &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.senderName == this.senderName &&
          other.groupName == this.groupName);
}

class LocalInvitationsCompanion extends UpdateCompanion<LocalInvitation> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<String> senderId;
  final Value<String> recipientEmail;
  final Value<String> role;
  final Value<String> status;
  final Value<String?> createdAt;
  final Value<String?> senderName;
  final Value<String?> groupName;
  const LocalInvitationsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.recipientEmail = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.senderName = const Value.absent(),
    this.groupName = const Value.absent(),
  });
  LocalInvitationsCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required String senderId,
    required String recipientEmail,
    required String role,
    required String status,
    this.createdAt = const Value.absent(),
    this.senderName = const Value.absent(),
    this.groupName = const Value.absent(),
  })  : groupId = Value(groupId),
        senderId = Value(senderId),
        recipientEmail = Value(recipientEmail),
        role = Value(role),
        status = Value(status);
  static Insertable<LocalInvitation> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<String>? recipientEmail,
    Expression<String>? role,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? senderName,
    Expression<String>? groupName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (recipientEmail != null) 'recipient_email': recipientEmail,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (senderName != null) 'sender_name': senderName,
      if (groupName != null) 'group_name': groupName,
    });
  }

  LocalInvitationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? groupId,
      Value<String>? senderId,
      Value<String>? recipientEmail,
      Value<String>? role,
      Value<String>? status,
      Value<String?>? createdAt,
      Value<String?>? senderName,
      Value<String?>? groupName}) {
    return LocalInvitationsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      groupName: groupName ?? this.groupName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (recipientEmail.present) {
      map['recipient_email'] = Variable<String>(recipientEmail.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInvitationsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('recipientEmail: $recipientEmail, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('senderName: $senderName, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  _$LocalDatabaseManager get managers => _$LocalDatabaseManager(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalGroupsTable localGroups = $LocalGroupsTable(this);
  late final $LocalGroupMembersTable localGroupMembers =
      $LocalGroupMembersTable(this);
  late final $LocalStudentsTable localStudents = $LocalStudentsTable(this);
  late final $LocalScheduleTable localSchedule = $LocalScheduleTable(this);
  late final $LocalAttendanceLessonsTable localAttendanceLessons =
      $LocalAttendanceLessonsTable(this);
  late final $LocalAttendanceRecordsTable localAttendanceRecords =
      $LocalAttendanceRecordsTable(this);
  late final $LocalAnnouncementsTable localAnnouncements =
      $LocalAnnouncementsTable(this);
  late final $LocalNotificationsTable localNotifications =
      $LocalNotificationsTable(this);
  late final $LocalInvitationsTable localInvitations =
      $LocalInvitationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localProfiles,
        localGroups,
        localGroupMembers,
        localStudents,
        localSchedule,
        localAttendanceLessons,
        localAttendanceRecords,
        localAnnouncements,
        localNotifications,
        localInvitations
      ];
}

typedef $$LocalProfilesTableInsertCompanionBuilder = LocalProfilesCompanion
    Function({
  required String id,
  Value<String> email,
  Value<String> firstName,
  Value<String> lastName,
  Value<String?> avatarUrl,
  Value<String?> createdAt,
  Value<int> rowid,
});
typedef $$LocalProfilesTableUpdateCompanionBuilder = LocalProfilesCompanion
    Function({
  Value<String> id,
  Value<String> email,
  Value<String> firstName,
  Value<String> lastName,
  Value<String?> avatarUrl,
  Value<String?> createdAt,
  Value<int> rowid,
});

class $$LocalProfilesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalProfilesTable,
    LocalProfile,
    $$LocalProfilesTableFilterComposer,
    $$LocalProfilesTableOrderingComposer,
    $$LocalProfilesTableProcessedTableManager,
    $$LocalProfilesTableInsertCompanionBuilder,
    $$LocalProfilesTableUpdateCompanionBuilder> {
  $$LocalProfilesTableTableManager(
      _$LocalDatabase db, $LocalProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalProfilesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalProfilesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalProfilesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProfilesCompanion(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatarUrl: avatarUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String id,
            Value<String> email = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProfilesCompanion.insert(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatarUrl: avatarUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalProfilesTableProcessedTableManager extends ProcessedTableManager<
    _$LocalDatabase,
    $LocalProfilesTable,
    LocalProfile,
    $$LocalProfilesTableFilterComposer,
    $$LocalProfilesTableOrderingComposer,
    $$LocalProfilesTableProcessedTableManager,
    $$LocalProfilesTableInsertCompanionBuilder,
    $$LocalProfilesTableUpdateCompanionBuilder> {
  $$LocalProfilesTableProcessedTableManager(super.$state);
}

class $$LocalProfilesTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalProfilesTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalGroupsTableInsertCompanionBuilder = LocalGroupsCompanion
    Function({
  required String id,
  required String name,
  required String ownerId,
  Value<int> rowid,
});
typedef $$LocalGroupsTableUpdateCompanionBuilder = LocalGroupsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> ownerId,
  Value<int> rowid,
});

class $$LocalGroupsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalGroupsTable,
    LocalGroup,
    $$LocalGroupsTableFilterComposer,
    $$LocalGroupsTableOrderingComposer,
    $$LocalGroupsTableProcessedTableManager,
    $$LocalGroupsTableInsertCompanionBuilder,
    $$LocalGroupsTableUpdateCompanionBuilder> {
  $$LocalGroupsTableTableManager(_$LocalDatabase db, $LocalGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalGroupsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalGroupsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalGroupsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalGroupsCompanion(
            id: id,
            name: name,
            ownerId: ownerId,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String id,
            required String name,
            required String ownerId,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalGroupsCompanion.insert(
            id: id,
            name: name,
            ownerId: ownerId,
            rowid: rowid,
          ),
        ));
}

class $$LocalGroupsTableProcessedTableManager extends ProcessedTableManager<
    _$LocalDatabase,
    $LocalGroupsTable,
    LocalGroup,
    $$LocalGroupsTableFilterComposer,
    $$LocalGroupsTableOrderingComposer,
    $$LocalGroupsTableProcessedTableManager,
    $$LocalGroupsTableInsertCompanionBuilder,
    $$LocalGroupsTableUpdateCompanionBuilder> {
  $$LocalGroupsTableProcessedTableManager(super.$state);
}

class $$LocalGroupsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalGroupsTable> {
  $$LocalGroupsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ownerId => $state.composableBuilder(
      column: $state.table.ownerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalGroupsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalGroupsTable> {
  $$LocalGroupsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ownerId => $state.composableBuilder(
      column: $state.table.ownerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalGroupMembersTableInsertCompanionBuilder
    = LocalGroupMembersCompanion Function({
  Value<int> id,
  required String groupId,
  required String userId,
  required String role,
  Value<bool> isStudent,
});
typedef $$LocalGroupMembersTableUpdateCompanionBuilder
    = LocalGroupMembersCompanion Function({
  Value<int> id,
  Value<String> groupId,
  Value<String> userId,
  Value<String> role,
  Value<bool> isStudent,
});

class $$LocalGroupMembersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalGroupMembersTable,
    LocalGroupMember,
    $$LocalGroupMembersTableFilterComposer,
    $$LocalGroupMembersTableOrderingComposer,
    $$LocalGroupMembersTableProcessedTableManager,
    $$LocalGroupMembersTableInsertCompanionBuilder,
    $$LocalGroupMembersTableUpdateCompanionBuilder> {
  $$LocalGroupMembersTableTableManager(
      _$LocalDatabase db, $LocalGroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalGroupMembersTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalGroupMembersTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalGroupMembersTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isStudent = const Value.absent(),
          }) =>
              LocalGroupMembersCompanion(
            id: id,
            groupId: groupId,
            userId: userId,
            role: role,
            isStudent: isStudent,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String groupId,
            required String userId,
            required String role,
            Value<bool> isStudent = const Value.absent(),
          }) =>
              LocalGroupMembersCompanion.insert(
            id: id,
            groupId: groupId,
            userId: userId,
            role: role,
            isStudent: isStudent,
          ),
        ));
}

class $$LocalGroupMembersTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalGroupMembersTable,
        LocalGroupMember,
        $$LocalGroupMembersTableFilterComposer,
        $$LocalGroupMembersTableOrderingComposer,
        $$LocalGroupMembersTableProcessedTableManager,
        $$LocalGroupMembersTableInsertCompanionBuilder,
        $$LocalGroupMembersTableUpdateCompanionBuilder> {
  $$LocalGroupMembersTableProcessedTableManager(super.$state);
}

class $$LocalGroupMembersTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalGroupMembersTable> {
  $$LocalGroupMembersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isStudent => $state.composableBuilder(
      column: $state.table.isStudent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalGroupMembersTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalGroupMembersTable> {
  $$LocalGroupMembersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isStudent => $state.composableBuilder(
      column: $state.table.isStudent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalStudentsTableInsertCompanionBuilder = LocalStudentsCompanion
    Function({
  required String id,
  required String groupId,
  Value<String> lastName,
  Value<String> firstName,
  Value<String> middleName,
  Value<String> birthDay,
  Value<String> birthMonth,
  Value<String> birthYear,
  Value<bool> isMale,
  Value<String> status,
  Value<String?> linkedUserId,
  Value<String?> avatarUrl,
  Value<int> rowid,
});
typedef $$LocalStudentsTableUpdateCompanionBuilder = LocalStudentsCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> lastName,
  Value<String> firstName,
  Value<String> middleName,
  Value<String> birthDay,
  Value<String> birthMonth,
  Value<String> birthYear,
  Value<bool> isMale,
  Value<String> status,
  Value<String?> linkedUserId,
  Value<String?> avatarUrl,
  Value<int> rowid,
});

class $$LocalStudentsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalStudentsTable,
    LocalStudent,
    $$LocalStudentsTableFilterComposer,
    $$LocalStudentsTableOrderingComposer,
    $$LocalStudentsTableProcessedTableManager,
    $$LocalStudentsTableInsertCompanionBuilder,
    $$LocalStudentsTableUpdateCompanionBuilder> {
  $$LocalStudentsTableTableManager(
      _$LocalDatabase db, $LocalStudentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalStudentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalStudentsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalStudentsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> middleName = const Value.absent(),
            Value<String> birthDay = const Value.absent(),
            Value<String> birthMonth = const Value.absent(),
            Value<String> birthYear = const Value.absent(),
            Value<bool> isMale = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> linkedUserId = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudentsCompanion(
            id: id,
            groupId: groupId,
            lastName: lastName,
            firstName: firstName,
            middleName: middleName,
            birthDay: birthDay,
            birthMonth: birthMonth,
            birthYear: birthYear,
            isMale: isMale,
            status: status,
            linkedUserId: linkedUserId,
            avatarUrl: avatarUrl,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String id,
            required String groupId,
            Value<String> lastName = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> middleName = const Value.absent(),
            Value<String> birthDay = const Value.absent(),
            Value<String> birthMonth = const Value.absent(),
            Value<String> birthYear = const Value.absent(),
            Value<bool> isMale = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> linkedUserId = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudentsCompanion.insert(
            id: id,
            groupId: groupId,
            lastName: lastName,
            firstName: firstName,
            middleName: middleName,
            birthDay: birthDay,
            birthMonth: birthMonth,
            birthYear: birthYear,
            isMale: isMale,
            status: status,
            linkedUserId: linkedUserId,
            avatarUrl: avatarUrl,
            rowid: rowid,
          ),
        ));
}

class $$LocalStudentsTableProcessedTableManager extends ProcessedTableManager<
    _$LocalDatabase,
    $LocalStudentsTable,
    LocalStudent,
    $$LocalStudentsTableFilterComposer,
    $$LocalStudentsTableOrderingComposer,
    $$LocalStudentsTableProcessedTableManager,
    $$LocalStudentsTableInsertCompanionBuilder,
    $$LocalStudentsTableUpdateCompanionBuilder> {
  $$LocalStudentsTableProcessedTableManager(super.$state);
}

class $$LocalStudentsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalStudentsTable> {
  $$LocalStudentsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get middleName => $state.composableBuilder(
      column: $state.table.middleName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get birthDay => $state.composableBuilder(
      column: $state.table.birthDay,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get birthMonth => $state.composableBuilder(
      column: $state.table.birthMonth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get birthYear => $state.composableBuilder(
      column: $state.table.birthYear,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isMale => $state.composableBuilder(
      column: $state.table.isMale,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get linkedUserId => $state.composableBuilder(
      column: $state.table.linkedUserId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalStudentsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalStudentsTable> {
  $$LocalStudentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get middleName => $state.composableBuilder(
      column: $state.table.middleName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get birthDay => $state.composableBuilder(
      column: $state.table.birthDay,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get birthMonth => $state.composableBuilder(
      column: $state.table.birthMonth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get birthYear => $state.composableBuilder(
      column: $state.table.birthYear,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isMale => $state.composableBuilder(
      column: $state.table.isMale,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get linkedUserId => $state.composableBuilder(
      column: $state.table.linkedUserId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalScheduleTableInsertCompanionBuilder = LocalScheduleCompanion
    Function({
  Value<int> id,
  required String groupId,
  required int dayIndex,
  required String timeStart,
  required String timeEnd,
  required String subject,
  required String room,
  required String teacher,
});
typedef $$LocalScheduleTableUpdateCompanionBuilder = LocalScheduleCompanion
    Function({
  Value<int> id,
  Value<String> groupId,
  Value<int> dayIndex,
  Value<String> timeStart,
  Value<String> timeEnd,
  Value<String> subject,
  Value<String> room,
  Value<String> teacher,
});

class $$LocalScheduleTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalScheduleTable,
    LocalScheduleData,
    $$LocalScheduleTableFilterComposer,
    $$LocalScheduleTableOrderingComposer,
    $$LocalScheduleTableProcessedTableManager,
    $$LocalScheduleTableInsertCompanionBuilder,
    $$LocalScheduleTableUpdateCompanionBuilder> {
  $$LocalScheduleTableTableManager(
      _$LocalDatabase db, $LocalScheduleTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalScheduleTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalScheduleTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalScheduleTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<int> dayIndex = const Value.absent(),
            Value<String> timeStart = const Value.absent(),
            Value<String> timeEnd = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> room = const Value.absent(),
            Value<String> teacher = const Value.absent(),
          }) =>
              LocalScheduleCompanion(
            id: id,
            groupId: groupId,
            dayIndex: dayIndex,
            timeStart: timeStart,
            timeEnd: timeEnd,
            subject: subject,
            room: room,
            teacher: teacher,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String groupId,
            required int dayIndex,
            required String timeStart,
            required String timeEnd,
            required String subject,
            required String room,
            required String teacher,
          }) =>
              LocalScheduleCompanion.insert(
            id: id,
            groupId: groupId,
            dayIndex: dayIndex,
            timeStart: timeStart,
            timeEnd: timeEnd,
            subject: subject,
            room: room,
            teacher: teacher,
          ),
        ));
}

class $$LocalScheduleTableProcessedTableManager extends ProcessedTableManager<
    _$LocalDatabase,
    $LocalScheduleTable,
    LocalScheduleData,
    $$LocalScheduleTableFilterComposer,
    $$LocalScheduleTableOrderingComposer,
    $$LocalScheduleTableProcessedTableManager,
    $$LocalScheduleTableInsertCompanionBuilder,
    $$LocalScheduleTableUpdateCompanionBuilder> {
  $$LocalScheduleTableProcessedTableManager(super.$state);
}

class $$LocalScheduleTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalScheduleTable> {
  $$LocalScheduleTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get dayIndex => $state.composableBuilder(
      column: $state.table.dayIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timeStart => $state.composableBuilder(
      column: $state.table.timeStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timeEnd => $state.composableBuilder(
      column: $state.table.timeEnd,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subject => $state.composableBuilder(
      column: $state.table.subject,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get room => $state.composableBuilder(
      column: $state.table.room,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalScheduleTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalScheduleTable> {
  $$LocalScheduleTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get dayIndex => $state.composableBuilder(
      column: $state.table.dayIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timeStart => $state.composableBuilder(
      column: $state.table.timeStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timeEnd => $state.composableBuilder(
      column: $state.table.timeEnd,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subject => $state.composableBuilder(
      column: $state.table.subject,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get room => $state.composableBuilder(
      column: $state.table.room,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalAttendanceLessonsTableInsertCompanionBuilder
    = LocalAttendanceLessonsCompanion Function({
  Value<int> id,
  required String groupId,
  required String date,
  required String lessonKey,
  required String subject,
});
typedef $$LocalAttendanceLessonsTableUpdateCompanionBuilder
    = LocalAttendanceLessonsCompanion Function({
  Value<int> id,
  Value<String> groupId,
  Value<String> date,
  Value<String> lessonKey,
  Value<String> subject,
});

class $$LocalAttendanceLessonsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalAttendanceLessonsTable,
    LocalAttendanceLesson,
    $$LocalAttendanceLessonsTableFilterComposer,
    $$LocalAttendanceLessonsTableOrderingComposer,
    $$LocalAttendanceLessonsTableProcessedTableManager,
    $$LocalAttendanceLessonsTableInsertCompanionBuilder,
    $$LocalAttendanceLessonsTableUpdateCompanionBuilder> {
  $$LocalAttendanceLessonsTableTableManager(
      _$LocalDatabase db, $LocalAttendanceLessonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalAttendanceLessonsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalAttendanceLessonsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalAttendanceLessonsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> lessonKey = const Value.absent(),
            Value<String> subject = const Value.absent(),
          }) =>
              LocalAttendanceLessonsCompanion(
            id: id,
            groupId: groupId,
            date: date,
            lessonKey: lessonKey,
            subject: subject,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String groupId,
            required String date,
            required String lessonKey,
            required String subject,
          }) =>
              LocalAttendanceLessonsCompanion.insert(
            id: id,
            groupId: groupId,
            date: date,
            lessonKey: lessonKey,
            subject: subject,
          ),
        ));
}

class $$LocalAttendanceLessonsTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalAttendanceLessonsTable,
        LocalAttendanceLesson,
        $$LocalAttendanceLessonsTableFilterComposer,
        $$LocalAttendanceLessonsTableOrderingComposer,
        $$LocalAttendanceLessonsTableProcessedTableManager,
        $$LocalAttendanceLessonsTableInsertCompanionBuilder,
        $$LocalAttendanceLessonsTableUpdateCompanionBuilder> {
  $$LocalAttendanceLessonsTableProcessedTableManager(super.$state);
}

class $$LocalAttendanceLessonsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalAttendanceLessonsTable> {
  $$LocalAttendanceLessonsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lessonKey => $state.composableBuilder(
      column: $state.table.lessonKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subject => $state.composableBuilder(
      column: $state.table.subject,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalAttendanceLessonsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalAttendanceLessonsTable> {
  $$LocalAttendanceLessonsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lessonKey => $state.composableBuilder(
      column: $state.table.lessonKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subject => $state.composableBuilder(
      column: $state.table.subject,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalAttendanceRecordsTableInsertCompanionBuilder
    = LocalAttendanceRecordsCompanion Function({
  Value<int> id,
  required int lessonId,
  required String studentId,
  Value<String?> status,
});
typedef $$LocalAttendanceRecordsTableUpdateCompanionBuilder
    = LocalAttendanceRecordsCompanion Function({
  Value<int> id,
  Value<int> lessonId,
  Value<String> studentId,
  Value<String?> status,
});

class $$LocalAttendanceRecordsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalAttendanceRecordsTable,
    LocalAttendanceRecord,
    $$LocalAttendanceRecordsTableFilterComposer,
    $$LocalAttendanceRecordsTableOrderingComposer,
    $$LocalAttendanceRecordsTableProcessedTableManager,
    $$LocalAttendanceRecordsTableInsertCompanionBuilder,
    $$LocalAttendanceRecordsTableUpdateCompanionBuilder> {
  $$LocalAttendanceRecordsTableTableManager(
      _$LocalDatabase db, $LocalAttendanceRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalAttendanceRecordsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalAttendanceRecordsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalAttendanceRecordsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<int> lessonId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String?> status = const Value.absent(),
          }) =>
              LocalAttendanceRecordsCompanion(
            id: id,
            lessonId: lessonId,
            studentId: studentId,
            status: status,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required int lessonId,
            required String studentId,
            Value<String?> status = const Value.absent(),
          }) =>
              LocalAttendanceRecordsCompanion.insert(
            id: id,
            lessonId: lessonId,
            studentId: studentId,
            status: status,
          ),
        ));
}

class $$LocalAttendanceRecordsTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalAttendanceRecordsTable,
        LocalAttendanceRecord,
        $$LocalAttendanceRecordsTableFilterComposer,
        $$LocalAttendanceRecordsTableOrderingComposer,
        $$LocalAttendanceRecordsTableProcessedTableManager,
        $$LocalAttendanceRecordsTableInsertCompanionBuilder,
        $$LocalAttendanceRecordsTableUpdateCompanionBuilder> {
  $$LocalAttendanceRecordsTableProcessedTableManager(super.$state);
}

class $$LocalAttendanceRecordsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalAttendanceRecordsTable> {
  $$LocalAttendanceRecordsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lessonId => $state.composableBuilder(
      column: $state.table.lessonId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get studentId => $state.composableBuilder(
      column: $state.table.studentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalAttendanceRecordsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalAttendanceRecordsTable> {
  $$LocalAttendanceRecordsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lessonId => $state.composableBuilder(
      column: $state.table.lessonId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get studentId => $state.composableBuilder(
      column: $state.table.studentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalAnnouncementsTableInsertCompanionBuilder
    = LocalAnnouncementsCompanion Function({
  Value<int> id,
  required String groupId,
  required String authorId,
  required String title,
  required String body,
  Value<bool> isCancel,
  Value<String?> cancelDate,
  Value<String?> cancelKey,
  Value<String?> expiresAt,
  Value<String?> createdAt,
  Value<String?> authorName,
});
typedef $$LocalAnnouncementsTableUpdateCompanionBuilder
    = LocalAnnouncementsCompanion Function({
  Value<int> id,
  Value<String> groupId,
  Value<String> authorId,
  Value<String> title,
  Value<String> body,
  Value<bool> isCancel,
  Value<String?> cancelDate,
  Value<String?> cancelKey,
  Value<String?> expiresAt,
  Value<String?> createdAt,
  Value<String?> authorName,
});

class $$LocalAnnouncementsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalAnnouncementsTable,
    LocalAnnouncement,
    $$LocalAnnouncementsTableFilterComposer,
    $$LocalAnnouncementsTableOrderingComposer,
    $$LocalAnnouncementsTableProcessedTableManager,
    $$LocalAnnouncementsTableInsertCompanionBuilder,
    $$LocalAnnouncementsTableUpdateCompanionBuilder> {
  $$LocalAnnouncementsTableTableManager(
      _$LocalDatabase db, $LocalAnnouncementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalAnnouncementsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalAnnouncementsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalAnnouncementsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> authorId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<bool> isCancel = const Value.absent(),
            Value<String?> cancelDate = const Value.absent(),
            Value<String?> cancelKey = const Value.absent(),
            Value<String?> expiresAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> authorName = const Value.absent(),
          }) =>
              LocalAnnouncementsCompanion(
            id: id,
            groupId: groupId,
            authorId: authorId,
            title: title,
            body: body,
            isCancel: isCancel,
            cancelDate: cancelDate,
            cancelKey: cancelKey,
            expiresAt: expiresAt,
            createdAt: createdAt,
            authorName: authorName,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String groupId,
            required String authorId,
            required String title,
            required String body,
            Value<bool> isCancel = const Value.absent(),
            Value<String?> cancelDate = const Value.absent(),
            Value<String?> cancelKey = const Value.absent(),
            Value<String?> expiresAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> authorName = const Value.absent(),
          }) =>
              LocalAnnouncementsCompanion.insert(
            id: id,
            groupId: groupId,
            authorId: authorId,
            title: title,
            body: body,
            isCancel: isCancel,
            cancelDate: cancelDate,
            cancelKey: cancelKey,
            expiresAt: expiresAt,
            createdAt: createdAt,
            authorName: authorName,
          ),
        ));
}

class $$LocalAnnouncementsTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalAnnouncementsTable,
        LocalAnnouncement,
        $$LocalAnnouncementsTableFilterComposer,
        $$LocalAnnouncementsTableOrderingComposer,
        $$LocalAnnouncementsTableProcessedTableManager,
        $$LocalAnnouncementsTableInsertCompanionBuilder,
        $$LocalAnnouncementsTableUpdateCompanionBuilder> {
  $$LocalAnnouncementsTableProcessedTableManager(super.$state);
}

class $$LocalAnnouncementsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalAnnouncementsTable> {
  $$LocalAnnouncementsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get authorId => $state.composableBuilder(
      column: $state.table.authorId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get body => $state.composableBuilder(
      column: $state.table.body,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCancel => $state.composableBuilder(
      column: $state.table.isCancel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cancelDate => $state.composableBuilder(
      column: $state.table.cancelDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cancelKey => $state.composableBuilder(
      column: $state.table.cancelKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get authorName => $state.composableBuilder(
      column: $state.table.authorName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalAnnouncementsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalAnnouncementsTable> {
  $$LocalAnnouncementsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get authorId => $state.composableBuilder(
      column: $state.table.authorId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get body => $state.composableBuilder(
      column: $state.table.body,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCancel => $state.composableBuilder(
      column: $state.table.isCancel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cancelDate => $state.composableBuilder(
      column: $state.table.cancelDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cancelKey => $state.composableBuilder(
      column: $state.table.cancelKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get authorName => $state.composableBuilder(
      column: $state.table.authorName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalNotificationsTableInsertCompanionBuilder
    = LocalNotificationsCompanion Function({
  Value<int> id,
  required String userId,
  required String type,
  required String title,
  required String body,
  Value<String> data,
  Value<bool> isRead,
  Value<String?> createdAt,
});
typedef $$LocalNotificationsTableUpdateCompanionBuilder
    = LocalNotificationsCompanion Function({
  Value<int> id,
  Value<String> userId,
  Value<String> type,
  Value<String> title,
  Value<String> body,
  Value<String> data,
  Value<bool> isRead,
  Value<String?> createdAt,
});

class $$LocalNotificationsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalNotificationsTable,
    LocalNotification,
    $$LocalNotificationsTableFilterComposer,
    $$LocalNotificationsTableOrderingComposer,
    $$LocalNotificationsTableProcessedTableManager,
    $$LocalNotificationsTableInsertCompanionBuilder,
    $$LocalNotificationsTableUpdateCompanionBuilder> {
  $$LocalNotificationsTableTableManager(
      _$LocalDatabase db, $LocalNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalNotificationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalNotificationsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalNotificationsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalNotificationsCompanion(
            id: id,
            userId: userId,
            type: type,
            title: title,
            body: body,
            data: data,
            isRead: isRead,
            createdAt: createdAt,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String userId,
            required String type,
            required String title,
            required String body,
            Value<String> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalNotificationsCompanion.insert(
            id: id,
            userId: userId,
            type: type,
            title: title,
            body: body,
            data: data,
            isRead: isRead,
            createdAt: createdAt,
          ),
        ));
}

class $$LocalNotificationsTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalNotificationsTable,
        LocalNotification,
        $$LocalNotificationsTableFilterComposer,
        $$LocalNotificationsTableOrderingComposer,
        $$LocalNotificationsTableProcessedTableManager,
        $$LocalNotificationsTableInsertCompanionBuilder,
        $$LocalNotificationsTableUpdateCompanionBuilder> {
  $$LocalNotificationsTableProcessedTableManager(super.$state);
}

class $$LocalNotificationsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get body => $state.composableBuilder(
      column: $state.table.body,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalNotificationsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get body => $state.composableBuilder(
      column: $state.table.body,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalInvitationsTableInsertCompanionBuilder
    = LocalInvitationsCompanion Function({
  Value<int> id,
  required String groupId,
  required String senderId,
  required String recipientEmail,
  required String role,
  required String status,
  Value<String?> createdAt,
  Value<String?> senderName,
  Value<String?> groupName,
});
typedef $$LocalInvitationsTableUpdateCompanionBuilder
    = LocalInvitationsCompanion Function({
  Value<int> id,
  Value<String> groupId,
  Value<String> senderId,
  Value<String> recipientEmail,
  Value<String> role,
  Value<String> status,
  Value<String?> createdAt,
  Value<String?> senderName,
  Value<String?> groupName,
});

class $$LocalInvitationsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalInvitationsTable,
    LocalInvitation,
    $$LocalInvitationsTableFilterComposer,
    $$LocalInvitationsTableOrderingComposer,
    $$LocalInvitationsTableProcessedTableManager,
    $$LocalInvitationsTableInsertCompanionBuilder,
    $$LocalInvitationsTableUpdateCompanionBuilder> {
  $$LocalInvitationsTableTableManager(
      _$LocalDatabase db, $LocalInvitationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalInvitationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalInvitationsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$LocalInvitationsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String> recipientEmail = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> senderName = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
          }) =>
              LocalInvitationsCompanion(
            id: id,
            groupId: groupId,
            senderId: senderId,
            recipientEmail: recipientEmail,
            role: role,
            status: status,
            createdAt: createdAt,
            senderName: senderName,
            groupName: groupName,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String groupId,
            required String senderId,
            required String recipientEmail,
            required String role,
            required String status,
            Value<String?> createdAt = const Value.absent(),
            Value<String?> senderName = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
          }) =>
              LocalInvitationsCompanion.insert(
            id: id,
            groupId: groupId,
            senderId: senderId,
            recipientEmail: recipientEmail,
            role: role,
            status: status,
            createdAt: createdAt,
            senderName: senderName,
            groupName: groupName,
          ),
        ));
}

class $$LocalInvitationsTableProcessedTableManager
    extends ProcessedTableManager<
        _$LocalDatabase,
        $LocalInvitationsTable,
        LocalInvitation,
        $$LocalInvitationsTableFilterComposer,
        $$LocalInvitationsTableOrderingComposer,
        $$LocalInvitationsTableProcessedTableManager,
        $$LocalInvitationsTableInsertCompanionBuilder,
        $$LocalInvitationsTableUpdateCompanionBuilder> {
  $$LocalInvitationsTableProcessedTableManager(super.$state);
}

class $$LocalInvitationsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalInvitationsTable> {
  $$LocalInvitationsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recipientEmail => $state.composableBuilder(
      column: $state.table.recipientEmail,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get senderName => $state.composableBuilder(
      column: $state.table.senderName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupName => $state.composableBuilder(
      column: $state.table.groupName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalInvitationsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalInvitationsTable> {
  $$LocalInvitationsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recipientEmail => $state.composableBuilder(
      column: $state.table.recipientEmail,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get senderName => $state.composableBuilder(
      column: $state.table.senderName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupName => $state.composableBuilder(
      column: $state.table.groupName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class _$LocalDatabaseManager {
  final _$LocalDatabase _db;
  _$LocalDatabaseManager(this._db);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalGroupsTableTableManager get localGroups =>
      $$LocalGroupsTableTableManager(_db, _db.localGroups);
  $$LocalGroupMembersTableTableManager get localGroupMembers =>
      $$LocalGroupMembersTableTableManager(_db, _db.localGroupMembers);
  $$LocalStudentsTableTableManager get localStudents =>
      $$LocalStudentsTableTableManager(_db, _db.localStudents);
  $$LocalScheduleTableTableManager get localSchedule =>
      $$LocalScheduleTableTableManager(_db, _db.localSchedule);
  $$LocalAttendanceLessonsTableTableManager get localAttendanceLessons =>
      $$LocalAttendanceLessonsTableTableManager(
          _db, _db.localAttendanceLessons);
  $$LocalAttendanceRecordsTableTableManager get localAttendanceRecords =>
      $$LocalAttendanceRecordsTableTableManager(
          _db, _db.localAttendanceRecords);
  $$LocalAnnouncementsTableTableManager get localAnnouncements =>
      $$LocalAnnouncementsTableTableManager(_db, _db.localAnnouncements);
  $$LocalNotificationsTableTableManager get localNotifications =>
      $$LocalNotificationsTableTableManager(_db, _db.localNotifications);
  $$LocalInvitationsTableTableManager get localInvitations =>
      $$LocalInvitationsTableTableManager(_db, _db.localInvitations);
}
