// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChildrenTable extends Children with TableInfo<$ChildrenTable, Child> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolYearStartMeta = const VerificationMeta(
    'schoolYearStart',
  );
  @override
  late final GeneratedColumn<String> schoolYearStart = GeneratedColumn<String>(
    'school_year_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolYearEndMeta = const VerificationMeta(
    'schoolYearEnd',
  );
  @override
  late final GeneratedColumn<String> schoolYearEnd = GeneratedColumn<String>(
    'school_year_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ruleId,
    schoolYearStart,
    schoolYearEnd,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<Child> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('school_year_start')) {
      context.handle(
        _schoolYearStartMeta,
        schoolYearStart.isAcceptableOrUnknown(
          data['school_year_start']!,
          _schoolYearStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schoolYearStartMeta);
    }
    if (data.containsKey('school_year_end')) {
      context.handle(
        _schoolYearEndMeta,
        schoolYearEnd.isAcceptableOrUnknown(
          data['school_year_end']!,
          _schoolYearEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schoolYearEndMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Child map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Child(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      schoolYearStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_year_start'],
      )!,
      schoolYearEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_year_end'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class Child extends DataClass implements Insertable<Child> {
  final int id;
  final String name;
  final String ruleId;
  final String schoolYearStart;
  final String schoolYearEnd;
  final int createdAt;
  const Child({
    required this.id,
    required this.name,
    required this.ruleId,
    required this.schoolYearStart,
    required this.schoolYearEnd,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rule_id'] = Variable<String>(ruleId);
    map['school_year_start'] = Variable<String>(schoolYearStart);
    map['school_year_end'] = Variable<String>(schoolYearEnd);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      name: Value(name),
      ruleId: Value(ruleId),
      schoolYearStart: Value(schoolYearStart),
      schoolYearEnd: Value(schoolYearEnd),
      createdAt: Value(createdAt),
    );
  }

  factory Child.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Child(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      schoolYearStart: serializer.fromJson<String>(json['schoolYearStart']),
      schoolYearEnd: serializer.fromJson<String>(json['schoolYearEnd']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'ruleId': serializer.toJson<String>(ruleId),
      'schoolYearStart': serializer.toJson<String>(schoolYearStart),
      'schoolYearEnd': serializer.toJson<String>(schoolYearEnd),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Child copyWith({
    int? id,
    String? name,
    String? ruleId,
    String? schoolYearStart,
    String? schoolYearEnd,
    int? createdAt,
  }) => Child(
    id: id ?? this.id,
    name: name ?? this.name,
    ruleId: ruleId ?? this.ruleId,
    schoolYearStart: schoolYearStart ?? this.schoolYearStart,
    schoolYearEnd: schoolYearEnd ?? this.schoolYearEnd,
    createdAt: createdAt ?? this.createdAt,
  );
  Child copyWithCompanion(ChildrenCompanion data) {
    return Child(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      schoolYearStart: data.schoolYearStart.present
          ? data.schoolYearStart.value
          : this.schoolYearStart,
      schoolYearEnd: data.schoolYearEnd.present
          ? data.schoolYearEnd.value
          : this.schoolYearEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Child(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ruleId: $ruleId, ')
          ..write('schoolYearStart: $schoolYearStart, ')
          ..write('schoolYearEnd: $schoolYearEnd, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, ruleId, schoolYearStart, schoolYearEnd, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Child &&
          other.id == this.id &&
          other.name == this.name &&
          other.ruleId == this.ruleId &&
          other.schoolYearStart == this.schoolYearStart &&
          other.schoolYearEnd == this.schoolYearEnd &&
          other.createdAt == this.createdAt);
}

class ChildrenCompanion extends UpdateCompanion<Child> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> ruleId;
  final Value<String> schoolYearStart;
  final Value<String> schoolYearEnd;
  final Value<int> createdAt;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.schoolYearStart = const Value.absent(),
    this.schoolYearEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChildrenCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String ruleId,
    required String schoolYearStart,
    required String schoolYearEnd,
    required int createdAt,
  }) : name = Value(name),
       ruleId = Value(ruleId),
       schoolYearStart = Value(schoolYearStart),
       schoolYearEnd = Value(schoolYearEnd),
       createdAt = Value(createdAt);
  static Insertable<Child> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? ruleId,
    Expression<String>? schoolYearStart,
    Expression<String>? schoolYearEnd,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ruleId != null) 'rule_id': ruleId,
      if (schoolYearStart != null) 'school_year_start': schoolYearStart,
      if (schoolYearEnd != null) 'school_year_end': schoolYearEnd,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChildrenCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? ruleId,
    Value<String>? schoolYearStart,
    Value<String>? schoolYearEnd,
    Value<int>? createdAt,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleId: ruleId ?? this.ruleId,
      schoolYearStart: schoolYearStart ?? this.schoolYearStart,
      schoolYearEnd: schoolYearEnd ?? this.schoolYearEnd,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (schoolYearStart.present) {
      map['school_year_start'] = Variable<String>(schoolYearStart.value);
    }
    if (schoolYearEnd.present) {
      map['school_year_end'] = Variable<String>(schoolYearEnd.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ruleId: $ruleId, ')
          ..write('schoolYearStart: $schoolYearStart, ')
          ..write('schoolYearEnd: $schoolYearEnd, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE NOCASE UNIQUE',
  );
  static const VerificationMeta _isCoreMeta = const VerificationMeta('isCore');
  @override
  late final GeneratedColumn<bool> isCore = GeneratedColumn<bool>(
    'is_core',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_core" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isCore, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_core')) {
      context.handle(
        _isCoreMeta,
        isCore.isAcceptableOrUnknown(data['is_core']!, _isCoreMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isCore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_core'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final int id;
  final String name;
  final bool isCore;
  final int sortOrder;
  const Subject({
    required this.id,
    required this.name,
    required this.isCore,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_core'] = Variable<bool>(isCore);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      isCore: Value(isCore),
      sortOrder: Value(sortOrder),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isCore: serializer.fromJson<bool>(json['isCore']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isCore': serializer.toJson<bool>(isCore),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Subject copyWith({int? id, String? name, bool? isCore, int? sortOrder}) =>
      Subject(
        id: id ?? this.id,
        name: name ?? this.name,
        isCore: isCore ?? this.isCore,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isCore: data.isCore.present ? data.isCore.value : this.isCore,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isCore: $isCore, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isCore, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.name == this.name &&
          other.isCore == this.isCore &&
          other.sortOrder == this.sortOrder);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isCore;
  final Value<int> sortOrder;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isCore = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isCore = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isCore,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isCore != null) 'is_core': isCore,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  SubjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isCore,
    Value<int>? sortOrder,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isCore: isCore ?? this.isCore,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isCore.present) {
      map['is_core'] = Variable<bool>(isCore.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isCore: $isCore, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    subjectId,
    day,
    minutes,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final int id;
  final int childId;
  final int subjectId;
  final String day;
  final int minutes;
  final String? note;
  final int createdAt;
  const LogEntry({
    required this.id,
    required this.childId,
    required this.subjectId,
    required this.day,
    required this.minutes,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<int>(childId);
    map['subject_id'] = Variable<int>(subjectId);
    map['day'] = Variable<String>(day);
    map['minutes'] = Variable<int>(minutes);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      childId: Value(childId),
      subjectId: Value(subjectId),
      day: Value(day),
      minutes: Value(minutes),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<int>(json['childId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      day: serializer.fromJson<String>(json['day']),
      minutes: serializer.fromJson<int>(json['minutes']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<int>(childId),
      'subjectId': serializer.toJson<int>(subjectId),
      'day': serializer.toJson<String>(day),
      'minutes': serializer.toJson<int>(minutes),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LogEntry copyWith({
    int? id,
    int? childId,
    int? subjectId,
    String? day,
    int? minutes,
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => LogEntry(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    subjectId: subjectId ?? this.subjectId,
    day: day ?? this.day,
    minutes: minutes ?? this.minutes,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      day: data.day.present ? data.day.value : this.day,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('subjectId: $subjectId, ')
          ..write('day: $day, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, childId, subjectId, day, minutes, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.subjectId == this.subjectId &&
          other.day == this.day &&
          other.minutes == this.minutes &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<int> id;
  final Value<int> childId;
  final Value<int> subjectId;
  final Value<String> day;
  final Value<int> minutes;
  final Value<String?> note;
  final Value<int> createdAt;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.day = const Value.absent(),
    this.minutes = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int childId,
    required int subjectId,
    required String day,
    required int minutes,
    this.note = const Value.absent(),
    required int createdAt,
  }) : childId = Value(childId),
       subjectId = Value(subjectId),
       day = Value(day),
       minutes = Value(minutes),
       createdAt = Value(createdAt);
  static Insertable<LogEntry> custom({
    Expression<int>? id,
    Expression<int>? childId,
    Expression<int>? subjectId,
    Expression<String>? day,
    Expression<int>? minutes,
    Expression<String>? note,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (subjectId != null) 'subject_id': subjectId,
      if (day != null) 'day': day,
      if (minutes != null) 'minutes': minutes,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? childId,
    Value<int>? subjectId,
    Value<String>? day,
    Value<int>? minutes,
    Value<String?>? note,
    Value<int>? createdAt,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      subjectId: subjectId ?? this.subjectId,
      day: day ?? this.day,
      minutes: minutes ?? this.minutes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('subjectId: $subjectId, ')
          ..write('day: $day, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkSamplesTable extends WorkSamples
    with TableInfo<$WorkSamplesTable, WorkSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    subjectId,
    day,
    title,
    filePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkSample(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkSamplesTable createAlias(String alias) {
    return $WorkSamplesTable(attachedDatabase, alias);
  }
}

class WorkSample extends DataClass implements Insertable<WorkSample> {
  final int id;
  final int childId;
  final int? subjectId;
  final String day;
  final String? title;
  final String filePath;
  final int createdAt;
  const WorkSample({
    required this.id,
    required this.childId,
    this.subjectId,
    required this.day,
    this.title,
    required this.filePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<int>(childId);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<int>(subjectId);
    }
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WorkSamplesCompanion toCompanion(bool nullToAbsent) {
    return WorkSamplesCompanion(
      id: Value(id),
      childId: Value(childId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      day: Value(day),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
    );
  }

  factory WorkSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkSample(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<int>(json['childId']),
      subjectId: serializer.fromJson<int?>(json['subjectId']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String?>(json['title']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<int>(childId),
      'subjectId': serializer.toJson<int?>(subjectId),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String?>(title),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WorkSample copyWith({
    int? id,
    int? childId,
    Value<int?> subjectId = const Value.absent(),
    String? day,
    Value<String?> title = const Value.absent(),
    String? filePath,
    int? createdAt,
  }) => WorkSample(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    day: day ?? this.day,
    title: title.present ? title.value : this.title,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkSample copyWithCompanion(WorkSamplesCompanion data) {
    return WorkSample(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkSample(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('subjectId: $subjectId, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, childId, subjectId, day, title, filePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkSample &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.subjectId == this.subjectId &&
          other.day == this.day &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt);
}

class WorkSamplesCompanion extends UpdateCompanion<WorkSample> {
  final Value<int> id;
  final Value<int> childId;
  final Value<int?> subjectId;
  final Value<String> day;
  final Value<String?> title;
  final Value<String> filePath;
  final Value<int> createdAt;
  const WorkSamplesCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int childId,
    this.subjectId = const Value.absent(),
    required String day,
    this.title = const Value.absent(),
    required String filePath,
    required int createdAt,
  }) : childId = Value(childId),
       day = Value(day),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<WorkSample> custom({
    Expression<int>? id,
    Expression<int>? childId,
    Expression<int>? subjectId,
    Expression<String>? day,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (subjectId != null) 'subject_id': subjectId,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkSamplesCompanion copyWith({
    Value<int>? id,
    Value<int>? childId,
    Value<int?>? subjectId,
    Value<String>? day,
    Value<String?>? title,
    Value<String>? filePath,
    Value<int>? createdAt,
  }) {
    return WorkSamplesCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      subjectId: subjectId ?? this.subjectId,
      day: day ?? this.day,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkSamplesCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('subjectId: $subjectId, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomRulesTable extends CustomRules
    with TableInfo<$CustomRulesTable, CustomRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredHoursMeta = const VerificationMeta(
    'requiredHours',
  );
  @override
  late final GeneratedColumn<int> requiredHours = GeneratedColumn<int>(
    'required_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredDaysMeta = const VerificationMeta(
    'requiredDays',
  );
  @override
  late final GeneratedColumn<int> requiredDays = GeneratedColumn<int>(
    'required_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    requiredHours,
    requiredDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('required_hours')) {
      context.handle(
        _requiredHoursMeta,
        requiredHours.isAcceptableOrUnknown(
          data['required_hours']!,
          _requiredHoursMeta,
        ),
      );
    }
    if (data.containsKey('required_days')) {
      context.handle(
        _requiredDaysMeta,
        requiredDays.isAcceptableOrUnknown(
          data['required_days']!,
          _requiredDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      requiredHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_hours'],
      ),
      requiredDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_days'],
      ),
    );
  }

  @override
  $CustomRulesTable createAlias(String alias) {
    return $CustomRulesTable(attachedDatabase, alias);
  }
}

class CustomRule extends DataClass implements Insertable<CustomRule> {
  final int id;
  final String label;
  final int? requiredHours;
  final int? requiredDays;
  const CustomRule({
    required this.id,
    required this.label,
    this.requiredHours,
    this.requiredDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || requiredHours != null) {
      map['required_hours'] = Variable<int>(requiredHours);
    }
    if (!nullToAbsent || requiredDays != null) {
      map['required_days'] = Variable<int>(requiredDays);
    }
    return map;
  }

  CustomRulesCompanion toCompanion(bool nullToAbsent) {
    return CustomRulesCompanion(
      id: Value(id),
      label: Value(label),
      requiredHours: requiredHours == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredHours),
      requiredDays: requiredDays == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredDays),
    );
  }

  factory CustomRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomRule(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      requiredHours: serializer.fromJson<int?>(json['requiredHours']),
      requiredDays: serializer.fromJson<int?>(json['requiredDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'requiredHours': serializer.toJson<int?>(requiredHours),
      'requiredDays': serializer.toJson<int?>(requiredDays),
    };
  }

  CustomRule copyWith({
    int? id,
    String? label,
    Value<int?> requiredHours = const Value.absent(),
    Value<int?> requiredDays = const Value.absent(),
  }) => CustomRule(
    id: id ?? this.id,
    label: label ?? this.label,
    requiredHours: requiredHours.present
        ? requiredHours.value
        : this.requiredHours,
    requiredDays: requiredDays.present ? requiredDays.value : this.requiredDays,
  );
  CustomRule copyWithCompanion(CustomRulesCompanion data) {
    return CustomRule(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      requiredHours: data.requiredHours.present
          ? data.requiredHours.value
          : this.requiredHours,
      requiredDays: data.requiredDays.present
          ? data.requiredDays.value
          : this.requiredDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomRule(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('requiredHours: $requiredHours, ')
          ..write('requiredDays: $requiredDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, requiredHours, requiredDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomRule &&
          other.id == this.id &&
          other.label == this.label &&
          other.requiredHours == this.requiredHours &&
          other.requiredDays == this.requiredDays);
}

class CustomRulesCompanion extends UpdateCompanion<CustomRule> {
  final Value<int> id;
  final Value<String> label;
  final Value<int?> requiredHours;
  final Value<int?> requiredDays;
  const CustomRulesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.requiredHours = const Value.absent(),
    this.requiredDays = const Value.absent(),
  });
  CustomRulesCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    this.requiredHours = const Value.absent(),
    this.requiredDays = const Value.absent(),
  }) : label = Value(label);
  static Insertable<CustomRule> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<int>? requiredHours,
    Expression<int>? requiredDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (requiredHours != null) 'required_hours': requiredHours,
      if (requiredDays != null) 'required_days': requiredDays,
    });
  }

  CustomRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<int?>? requiredHours,
    Value<int?>? requiredDays,
  }) {
    return CustomRulesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      requiredHours: requiredHours ?? this.requiredHours,
      requiredDays: requiredDays ?? this.requiredDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (requiredHours.present) {
      map['required_hours'] = Variable<int>(requiredHours.value);
    }
    if (requiredDays.present) {
      map['required_days'] = Variable<int>(requiredDays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomRulesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('requiredHours: $requiredHours, ')
          ..write('requiredDays: $requiredDays')
          ..write(')'))
        .toString();
  }
}

class $EntitlementsTable extends Entitlements
    with TableInfo<$EntitlementsTable, EntitlementData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _paidUntilMeta = const VerificationMeta(
    'paidUntil',
  );
  @override
  late final GeneratedColumn<String> paidUntil = GeneratedColumn<String>(
    'paid_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastVerifiedAt = GeneratedColumn<String>(
    'last_verified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('free'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, paidUntil, lastVerifiedAt, plan];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlement';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntitlementData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('paid_until')) {
      context.handle(
        _paidUntilMeta,
        paidUntil.isAcceptableOrUnknown(data['paid_until']!, _paidUntilMeta),
      );
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntitlementData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      paidUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_until'],
      ),
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_verified_at'],
      ),
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
    );
  }

  @override
  $EntitlementsTable createAlias(String alias) {
    return $EntitlementsTable(attachedDatabase, alias);
  }
}

class EntitlementData extends DataClass implements Insertable<EntitlementData> {
  final int id;
  final String? paidUntil;
  final String? lastVerifiedAt;
  final String plan;
  const EntitlementData({
    required this.id,
    this.paidUntil,
    this.lastVerifiedAt,
    required this.plan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || paidUntil != null) {
      map['paid_until'] = Variable<String>(paidUntil);
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<String>(lastVerifiedAt);
    }
    map['plan'] = Variable<String>(plan);
    return map;
  }

  EntitlementsCompanion toCompanion(bool nullToAbsent) {
    return EntitlementsCompanion(
      id: Value(id),
      paidUntil: paidUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(paidUntil),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      plan: Value(plan),
    );
  }

  factory EntitlementData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementData(
      id: serializer.fromJson<int>(json['id']),
      paidUntil: serializer.fromJson<String?>(json['paidUntil']),
      lastVerifiedAt: serializer.fromJson<String?>(json['lastVerifiedAt']),
      plan: serializer.fromJson<String>(json['plan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paidUntil': serializer.toJson<String?>(paidUntil),
      'lastVerifiedAt': serializer.toJson<String?>(lastVerifiedAt),
      'plan': serializer.toJson<String>(plan),
    };
  }

  EntitlementData copyWith({
    int? id,
    Value<String?> paidUntil = const Value.absent(),
    Value<String?> lastVerifiedAt = const Value.absent(),
    String? plan,
  }) => EntitlementData(
    id: id ?? this.id,
    paidUntil: paidUntil.present ? paidUntil.value : this.paidUntil,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    plan: plan ?? this.plan,
  );
  EntitlementData copyWithCompanion(EntitlementsCompanion data) {
    return EntitlementData(
      id: data.id.present ? data.id.value : this.id,
      paidUntil: data.paidUntil.present ? data.paidUntil.value : this.paidUntil,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      plan: data.plan.present ? data.plan.value : this.plan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementData(')
          ..write('id: $id, ')
          ..write('paidUntil: $paidUntil, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('plan: $plan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paidUntil, lastVerifiedAt, plan);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementData &&
          other.id == this.id &&
          other.paidUntil == this.paidUntil &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.plan == this.plan);
}

class EntitlementsCompanion extends UpdateCompanion<EntitlementData> {
  final Value<int> id;
  final Value<String?> paidUntil;
  final Value<String?> lastVerifiedAt;
  final Value<String> plan;
  const EntitlementsCompanion({
    this.id = const Value.absent(),
    this.paidUntil = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.plan = const Value.absent(),
  });
  EntitlementsCompanion.insert({
    this.id = const Value.absent(),
    this.paidUntil = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.plan = const Value.absent(),
  });
  static Insertable<EntitlementData> custom({
    Expression<int>? id,
    Expression<String>? paidUntil,
    Expression<String>? lastVerifiedAt,
    Expression<String>? plan,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paidUntil != null) 'paid_until': paidUntil,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (plan != null) 'plan': plan,
    });
  }

  EntitlementsCompanion copyWith({
    Value<int>? id,
    Value<String?>? paidUntil,
    Value<String?>? lastVerifiedAt,
    Value<String>? plan,
  }) {
    return EntitlementsCompanion(
      id: id ?? this.id,
      paidUntil: paidUntil ?? this.paidUntil,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      plan: plan ?? this.plan,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (paidUntil.present) {
      map['paid_until'] = Variable<String>(paidUntil.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<String>(lastVerifiedAt.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementsCompanion(')
          ..write('id: $id, ')
          ..write('paidUntil: $paidUntil, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('plan: $plan')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $WorkSamplesTable workSamples = $WorkSamplesTable(this);
  late final $CustomRulesTable customRules = $CustomRulesTable(this);
  late final $EntitlementsTable entitlements = $EntitlementsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    children,
    subjects,
    logEntries,
    workSamples,
    customRules,
    entitlements,
    appSettings,
  ];
}

typedef $$ChildrenTableCreateCompanionBuilder = ChildrenCompanion Function({
  Value<int> id,
  required String name,
  required String ruleId,
  required String schoolYearStart,
  required String schoolYearEnd,
  required int createdAt,
});
typedef $$ChildrenTableUpdateCompanionBuilder = ChildrenCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> ruleId,
  Value<String> schoolYearStart,
  Value<String> schoolYearEnd,
  Value<int> createdAt,
});

final class $$ChildrenTableReferences
    extends BaseReferences<_$AppDatabase, $ChildrenTable, Child> {
  $$ChildrenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LogEntriesTable, List<LogEntry>>
  _logEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: 'children__id__log_entries__child_id',
  );

  $$LogEntriesTableProcessedTableManager get logEntriesRefs {
    final manager = $$LogEntriesTableTableManager(
      $_db,
      $_db.logEntries,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkSamplesTable, List<WorkSample>>
  _workSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workSamples,
    aliasName: 'children__id__work_samples__child_id',
  );

  $$WorkSamplesTableProcessedTableManager get workSamplesRefs {
    final manager = $$WorkSamplesTableTableManager(
      $_db,
      $_db.workSamples,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolYearStart => $composableBuilder(
    column: $table.schoolYearStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolYearEnd => $composableBuilder(
    column: $table.schoolYearEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($$LogEntriesTableFilterComposer f) f,
  ) {
    final $$LogEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workSamplesRefs(
    Expression<bool> Function($$WorkSamplesTableFilterComposer f) f,
  ) {
    final $$WorkSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workSamples,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSamplesTableFilterComposer(
            $db: $db,
            $table: $db.workSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolYearStart => $composableBuilder(
    column: $table.schoolYearStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolYearEnd => $composableBuilder(
    column: $table.schoolYearEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<String> get schoolYearStart => $composableBuilder(
    column: $table.schoolYearStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schoolYearEnd => $composableBuilder(
    column: $table.schoolYearEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($$LogEntriesTableAnnotationComposer a) f,
  ) {
    final $$LogEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workSamplesRefs<T extends Object>(
    Expression<T> Function($$WorkSamplesTableAnnotationComposer a) f,
  ) {
    final $$WorkSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workSamples,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.workSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          Child,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (Child, $$ChildrenTableReferences),
          Child,
          PrefetchHooks Function({bool logEntriesRefs, bool workSamplesRefs})
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> schoolYearStart = const Value.absent(),
                Value<String> schoolYearEnd = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ChildrenCompanion(
                id: id,
                name: name,
                ruleId: ruleId,
                schoolYearStart: schoolYearStart,
                schoolYearEnd: schoolYearEnd,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String ruleId,
                required String schoolYearStart,
                required String schoolYearEnd,
                required int createdAt,
              }) => ChildrenCompanion.insert(
                id: id,
                name: name,
                ruleId: ruleId,
                schoolYearStart: schoolYearStart,
                schoolYearEnd: schoolYearEnd,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildrenTable, Child>(table),
                  $$ChildrenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({logEntriesRefs = false, workSamplesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (logEntriesRefs) db.logEntries,
                    if (workSamplesRefs) db.workSamples,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (logEntriesRefs)
                        await $_getPrefetchedData<
                          Child,
                          $ChildrenTable,
                          LogEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._logEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).logEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workSamplesRefs)
                        await $_getPrefetchedData<
                          Child,
                          $ChildrenTable,
                          WorkSample
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._workSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).workSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      Child,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (Child, $$ChildrenTableReferences),
      Child,
      PrefetchHooks Function({bool logEntriesRefs, bool workSamplesRefs})
    >;
typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> isCore,
  Value<int> sortOrder,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> isCore,
  Value<int> sortOrder,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LogEntriesTable, List<LogEntry>>
  _logEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: 'subjects__id__log_entries__subject_id',
  );

  $$LogEntriesTableProcessedTableManager get logEntriesRefs {
    final manager = $$LogEntriesTableTableManager(
      $_db,
      $_db.logEntries,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkSamplesTable, List<WorkSample>>
  _workSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workSamples,
    aliasName: 'subjects__id__work_samples__subject_id',
  );

  $$WorkSamplesTableProcessedTableManager get workSamplesRefs {
    final manager = $$WorkSamplesTableTableManager(
      $_db,
      $_db.workSamples,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCore => $composableBuilder(
    column: $table.isCore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($$LogEntriesTableFilterComposer f) f,
  ) {
    final $$LogEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workSamplesRefs(
    Expression<bool> Function($$WorkSamplesTableFilterComposer f) f,
  ) {
    final $$WorkSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workSamples,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSamplesTableFilterComposer(
            $db: $db,
            $table: $db.workSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCore => $composableBuilder(
    column: $table.isCore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isCore =>
      $composableBuilder(column: $table.isCore, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($$LogEntriesTableAnnotationComposer a) f,
  ) {
    final $$LogEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workSamplesRefs<T extends Object>(
    Expression<T> Function($$WorkSamplesTableAnnotationComposer a) f,
  ) {
    final $$WorkSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workSamples,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.workSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, $$SubjectsTableReferences),
          Subject,
          PrefetchHooks Function({bool logEntriesRefs, bool workSamplesRefs})
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isCore = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                name: name,
                isCore: isCore,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isCore = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                name: name,
                isCore: isCore,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, Subject>(table),
                  $$SubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({logEntriesRefs = false, workSamplesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (logEntriesRefs) db.logEntries,
                    if (workSamplesRefs) db.workSamples,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (logEntriesRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          LogEntry
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._logEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).logEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workSamplesRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          WorkSample
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._workSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).workSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, $$SubjectsTableReferences),
      Subject,
      PrefetchHooks Function({bool logEntriesRefs, bool workSamplesRefs})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  required int childId,
  required int subjectId,
  required String day,
  required int minutes,
  Value<String?> note,
  required int createdAt,
});
typedef $$LogEntriesTableUpdateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<int> childId,
  Value<int> subjectId,
  Value<String> day,
  Value<int> minutes,
  Value<String?> note,
  Value<int> createdAt,
});

final class $$LogEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry> {
  $$LogEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('log_entries__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<int>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('log_entries__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, $$LogEntriesTableReferences),
          LogEntry,
          PrefetchHooks Function({bool childId, bool subjectId})
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> childId = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                childId: childId,
                subjectId: subjectId,
                day: day,
                minutes: minutes,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int childId,
                required int subjectId,
                required String day,
                required int minutes,
                Value<String?> note = const Value.absent(),
                required int createdAt,
              }) => LogEntriesCompanion.insert(
                id: id,
                childId: childId,
                subjectId: subjectId,
                day: day,
                minutes: minutes,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogEntriesTable, LogEntry>(table),
                  $$LogEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false, subjectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$LogEntriesTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$LogEntriesTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (subjectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.subjectId,
                        referencedTable: $$LogEntriesTableReferences
                            ._subjectIdTable(db),
                        referencedColumn: $$LogEntriesTableReferences
                            ._subjectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, $$LogEntriesTableReferences),
      LogEntry,
      PrefetchHooks Function({bool childId, bool subjectId})
    >;
typedef $$WorkSamplesTableCreateCompanionBuilder =
    WorkSamplesCompanion Function({
      Value<int> id,
      required int childId,
      Value<int?> subjectId,
      required String day,
      Value<String?> title,
      required String filePath,
      required int createdAt,
    });
typedef $$WorkSamplesTableUpdateCompanionBuilder =
    WorkSamplesCompanion Function({
      Value<int> id,
      Value<int> childId,
      Value<int?> subjectId,
      Value<String> day,
      Value<String?> title,
      Value<String> filePath,
      Value<int> createdAt,
    });

final class $$WorkSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkSamplesTable, WorkSample> {
  $$WorkSamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('work_samples__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<int>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('work_samples__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager? get subjectId {
    final $_column = $_itemColumn<int>('subject_id');
    if ($_column == null) return null;
    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkSamplesTable> {
  $$WorkSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkSamplesTable> {
  $$WorkSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkSamplesTable> {
  $$WorkSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkSamplesTable,
          WorkSample,
          $$WorkSamplesTableFilterComposer,
          $$WorkSamplesTableOrderingComposer,
          $$WorkSamplesTableAnnotationComposer,
          $$WorkSamplesTableCreateCompanionBuilder,
          $$WorkSamplesTableUpdateCompanionBuilder,
          (WorkSample, $$WorkSamplesTableReferences),
          WorkSample,
          PrefetchHooks Function({bool childId, bool subjectId})
        > {
  $$WorkSamplesTableTableManager(_$AppDatabase db, $WorkSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> childId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => WorkSamplesCompanion(
                id: id,
                childId: childId,
                subjectId: subjectId,
                day: day,
                title: title,
                filePath: filePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int childId,
                Value<int?> subjectId = const Value.absent(),
                required String day,
                Value<String?> title = const Value.absent(),
                required String filePath,
                required int createdAt,
              }) => WorkSamplesCompanion.insert(
                id: id,
                childId: childId,
                subjectId: subjectId,
                day: day,
                title: title,
                filePath: filePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkSamplesTable, WorkSample>(table),
                  $$WorkSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false, subjectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$WorkSamplesTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$WorkSamplesTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (subjectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.subjectId,
                        referencedTable: $$WorkSamplesTableReferences
                            ._subjectIdTable(db),
                        referencedColumn: $$WorkSamplesTableReferences
                            ._subjectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkSamplesTable,
      WorkSample,
      $$WorkSamplesTableFilterComposer,
      $$WorkSamplesTableOrderingComposer,
      $$WorkSamplesTableAnnotationComposer,
      $$WorkSamplesTableCreateCompanionBuilder,
      $$WorkSamplesTableUpdateCompanionBuilder,
      (WorkSample, $$WorkSamplesTableReferences),
      WorkSample,
      PrefetchHooks Function({bool childId, bool subjectId})
    >;
typedef $$CustomRulesTableCreateCompanionBuilder =
    CustomRulesCompanion Function({
      Value<int> id,
      required String label,
      Value<int?> requiredHours,
      Value<int?> requiredDays,
    });
typedef $$CustomRulesTableUpdateCompanionBuilder =
    CustomRulesCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<int?> requiredHours,
      Value<int?> requiredDays,
    });

class $$CustomRulesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomRulesTable> {
  $$CustomRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredHours => $composableBuilder(
    column: $table.requiredHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredDays => $composableBuilder(
    column: $table.requiredDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomRulesTable> {
  $$CustomRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredHours => $composableBuilder(
    column: $table.requiredHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredDays => $composableBuilder(
    column: $table.requiredDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomRulesTable> {
  $$CustomRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get requiredHours => $composableBuilder(
    column: $table.requiredHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requiredDays => $composableBuilder(
    column: $table.requiredDays,
    builder: (column) => column,
  );
}

class $$CustomRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomRulesTable,
          CustomRule,
          $$CustomRulesTableFilterComposer,
          $$CustomRulesTableOrderingComposer,
          $$CustomRulesTableAnnotationComposer,
          $$CustomRulesTableCreateCompanionBuilder,
          $$CustomRulesTableUpdateCompanionBuilder,
          (
            CustomRule,
            BaseReferences<_$AppDatabase, $CustomRulesTable, CustomRule>,
          ),
          CustomRule,
          PrefetchHooks Function()
        > {
  $$CustomRulesTableTableManager(_$AppDatabase db, $CustomRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> requiredHours = const Value.absent(),
                Value<int?> requiredDays = const Value.absent(),
              }) => CustomRulesCompanion(
                id: id,
                label: label,
                requiredHours: requiredHours,
                requiredDays: requiredDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                Value<int?> requiredHours = const Value.absent(),
                Value<int?> requiredDays = const Value.absent(),
              }) => CustomRulesCompanion.insert(
                id: id,
                label: label,
                requiredHours: requiredHours,
                requiredDays: requiredDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomRulesTable, CustomRule>(table),
                  BaseReferences<_$AppDatabase, $CustomRulesTable, CustomRule>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomRulesTable,
      CustomRule,
      $$CustomRulesTableFilterComposer,
      $$CustomRulesTableOrderingComposer,
      $$CustomRulesTableAnnotationComposer,
      $$CustomRulesTableCreateCompanionBuilder,
      $$CustomRulesTableUpdateCompanionBuilder,
      (
        CustomRule,
        BaseReferences<_$AppDatabase, $CustomRulesTable, CustomRule>,
      ),
      CustomRule,
      PrefetchHooks Function()
    >;
typedef $$EntitlementsTableCreateCompanionBuilder =
    EntitlementsCompanion Function({
      Value<int> id,
      Value<String?> paidUntil,
      Value<String?> lastVerifiedAt,
      Value<String> plan,
    });
typedef $$EntitlementsTableUpdateCompanionBuilder =
    EntitlementsCompanion Function({
      Value<int> id,
      Value<String?> paidUntil,
      Value<String?> lastVerifiedAt,
      Value<String> plan,
    });

class $$EntitlementsTableFilterComposer
    extends Composer<_$AppDatabase, $EntitlementsTable> {
  $$EntitlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidUntil => $composableBuilder(
    column: $table.paidUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntitlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitlementsTable> {
  $$EntitlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidUntil => $composableBuilder(
    column: $table.paidUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntitlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitlementsTable> {
  $$EntitlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get paidUntil =>
      $composableBuilder(column: $table.paidUntil, builder: (column) => column);

  GeneratedColumn<String> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);
}

class $$EntitlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitlementsTable,
          EntitlementData,
          $$EntitlementsTableFilterComposer,
          $$EntitlementsTableOrderingComposer,
          $$EntitlementsTableAnnotationComposer,
          $$EntitlementsTableCreateCompanionBuilder,
          $$EntitlementsTableUpdateCompanionBuilder,
          (
            EntitlementData,
            BaseReferences<_$AppDatabase, $EntitlementsTable, EntitlementData>,
          ),
          EntitlementData,
          PrefetchHooks Function()
        > {
  $$EntitlementsTableTableManager(_$AppDatabase db, $EntitlementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> paidUntil = const Value.absent(),
                Value<String?> lastVerifiedAt = const Value.absent(),
                Value<String> plan = const Value.absent(),
              }) => EntitlementsCompanion(
                id: id,
                paidUntil: paidUntil,
                lastVerifiedAt: lastVerifiedAt,
                plan: plan,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> paidUntil = const Value.absent(),
                Value<String?> lastVerifiedAt = const Value.absent(),
                Value<String> plan = const Value.absent(),
              }) => EntitlementsCompanion.insert(
                id: id,
                paidUntil: paidUntil,
                lastVerifiedAt: lastVerifiedAt,
                plan: plan,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitlementsTable, EntitlementData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EntitlementsTable,
                    EntitlementData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntitlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitlementsTable,
      EntitlementData,
      $$EntitlementsTableFilterComposer,
      $$EntitlementsTableOrderingComposer,
      $$EntitlementsTableAnnotationComposer,
      $$EntitlementsTableCreateCompanionBuilder,
      $$EntitlementsTableUpdateCompanionBuilder,
      (
        EntitlementData,
        BaseReferences<_$AppDatabase, $EntitlementsTable, EntitlementData>,
      ),
      EntitlementData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$WorkSamplesTableTableManager get workSamples =>
      $$WorkSamplesTableTableManager(_db, _db.workSamples);
  $$CustomRulesTableTableManager get customRules =>
      $$CustomRulesTableTableManager(_db, _db.customRules);
  $$EntitlementsTableTableManager get entitlements =>
      $$EntitlementsTableTableManager(_db, _db.entitlements);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
