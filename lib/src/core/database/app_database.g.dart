// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescribedDryWeightKgMeta =
      const VerificationMeta('prescribedDryWeightKg');
  @override
  late final GeneratedColumn<double> prescribedDryWeightKg =
      GeneratedColumn<double>(
        'prescribed_dry_weight_kg',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dailyFluidAllowanceMlMeta =
      const VerificationMeta('dailyFluidAllowanceMl');
  @override
  late final GeneratedColumn<int> dailyFluidAllowanceMl = GeneratedColumn<int>(
    'daily_fluid_allowance_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCaregiverMirrorMeta = const VerificationMeta(
    'isCaregiverMirror',
  );
  @override
  late final GeneratedColumn<bool> isCaregiverMirror = GeneratedColumn<bool>(
    'is_caregiver_mirror',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_caregiver_mirror" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    diagnosis,
    prescribedDryWeightKg,
    dailyFluidAllowanceMl,
    isCaregiverMirror,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Patient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    } else if (isInserting) {
      context.missing(_diagnosisMeta);
    }
    if (data.containsKey('prescribed_dry_weight_kg')) {
      context.handle(
        _prescribedDryWeightKgMeta,
        prescribedDryWeightKg.isAcceptableOrUnknown(
          data['prescribed_dry_weight_kg']!,
          _prescribedDryWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('daily_fluid_allowance_ml')) {
      context.handle(
        _dailyFluidAllowanceMlMeta,
        dailyFluidAllowanceMl.isAcceptableOrUnknown(
          data['daily_fluid_allowance_ml']!,
          _dailyFluidAllowanceMlMeta,
        ),
      );
    }
    if (data.containsKey('is_caregiver_mirror')) {
      context.handle(
        _isCaregiverMirrorMeta,
        isCaregiverMirror.isAcceptableOrUnknown(
          data['is_caregiver_mirror']!,
          _isCaregiverMirrorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      )!,
      prescribedDryWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prescribed_dry_weight_kg'],
      ),
      dailyFluidAllowanceMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_fluid_allowance_ml'],
      ),
      isCaregiverMirror: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_caregiver_mirror'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final String id;
  final String name;
  final String diagnosis;
  final double? prescribedDryWeightKg;
  final int? dailyFluidAllowanceMl;
  final bool isCaregiverMirror;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Patient({
    required this.id,
    required this.name,
    required this.diagnosis,
    this.prescribedDryWeightKg,
    this.dailyFluidAllowanceMl,
    required this.isCaregiverMirror,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['diagnosis'] = Variable<String>(diagnosis);
    if (!nullToAbsent || prescribedDryWeightKg != null) {
      map['prescribed_dry_weight_kg'] = Variable<double>(prescribedDryWeightKg);
    }
    if (!nullToAbsent || dailyFluidAllowanceMl != null) {
      map['daily_fluid_allowance_ml'] = Variable<int>(dailyFluidAllowanceMl);
    }
    map['is_caregiver_mirror'] = Variable<bool>(isCaregiverMirror);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      name: Value(name),
      diagnosis: Value(diagnosis),
      prescribedDryWeightKg: prescribedDryWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: dailyFluidAllowanceMl == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyFluidAllowanceMl),
      isCaregiverMirror: Value(isCaregiverMirror),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      diagnosis: serializer.fromJson<String>(json['diagnosis']),
      prescribedDryWeightKg: serializer.fromJson<double?>(
        json['prescribedDryWeightKg'],
      ),
      dailyFluidAllowanceMl: serializer.fromJson<int?>(
        json['dailyFluidAllowanceMl'],
      ),
      isCaregiverMirror: serializer.fromJson<bool>(json['isCaregiverMirror']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'diagnosis': serializer.toJson<String>(diagnosis),
      'prescribedDryWeightKg': serializer.toJson<double?>(
        prescribedDryWeightKg,
      ),
      'dailyFluidAllowanceMl': serializer.toJson<int?>(dailyFluidAllowanceMl),
      'isCaregiverMirror': serializer.toJson<bool>(isCaregiverMirror),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    String? diagnosis,
    Value<double?> prescribedDryWeightKg = const Value.absent(),
    Value<int?> dailyFluidAllowanceMl = const Value.absent(),
    bool? isCaregiverMirror,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Patient(
    id: id ?? this.id,
    name: name ?? this.name,
    diagnosis: diagnosis ?? this.diagnosis,
    prescribedDryWeightKg: prescribedDryWeightKg.present
        ? prescribedDryWeightKg.value
        : this.prescribedDryWeightKg,
    dailyFluidAllowanceMl: dailyFluidAllowanceMl.present
        ? dailyFluidAllowanceMl.value
        : this.dailyFluidAllowanceMl,
    isCaregiverMirror: isCaregiverMirror ?? this.isCaregiverMirror,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      prescribedDryWeightKg: data.prescribedDryWeightKg.present
          ? data.prescribedDryWeightKg.value
          : this.prescribedDryWeightKg,
      dailyFluidAllowanceMl: data.dailyFluidAllowanceMl.present
          ? data.dailyFluidAllowanceMl.value
          : this.dailyFluidAllowanceMl,
      isCaregiverMirror: data.isCaregiverMirror.present
          ? data.isCaregiverMirror.value
          : this.isCaregiverMirror,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('prescribedDryWeightKg: $prescribedDryWeightKg, ')
          ..write('dailyFluidAllowanceMl: $dailyFluidAllowanceMl, ')
          ..write('isCaregiverMirror: $isCaregiverMirror, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    diagnosis,
    prescribedDryWeightKg,
    dailyFluidAllowanceMl,
    isCaregiverMirror,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.name == this.name &&
          other.diagnosis == this.diagnosis &&
          other.prescribedDryWeightKg == this.prescribedDryWeightKg &&
          other.dailyFluidAllowanceMl == this.dailyFluidAllowanceMl &&
          other.isCaregiverMirror == this.isCaregiverMirror &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> diagnosis;
  final Value<double?> prescribedDryWeightKg;
  final Value<int?> dailyFluidAllowanceMl;
  final Value<bool> isCaregiverMirror;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.prescribedDryWeightKg = const Value.absent(),
    this.dailyFluidAllowanceMl = const Value.absent(),
    this.isCaregiverMirror = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientsCompanion.insert({
    required String id,
    required String name,
    required String diagnosis,
    this.prescribedDryWeightKg = const Value.absent(),
    this.dailyFluidAllowanceMl = const Value.absent(),
    this.isCaregiverMirror = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       diagnosis = Value(diagnosis);
  static Insertable<Patient> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? diagnosis,
    Expression<double>? prescribedDryWeightKg,
    Expression<int>? dailyFluidAllowanceMl,
    Expression<bool>? isCaregiverMirror,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (prescribedDryWeightKg != null)
        'prescribed_dry_weight_kg': prescribedDryWeightKg,
      if (dailyFluidAllowanceMl != null)
        'daily_fluid_allowance_ml': dailyFluidAllowanceMl,
      if (isCaregiverMirror != null) 'is_caregiver_mirror': isCaregiverMirror,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? diagnosis,
    Value<double?>? prescribedDryWeightKg,
    Value<int?>? dailyFluidAllowanceMl,
    Value<bool>? isCaregiverMirror,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PatientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      diagnosis: diagnosis ?? this.diagnosis,
      prescribedDryWeightKg:
          prescribedDryWeightKg ?? this.prescribedDryWeightKg,
      dailyFluidAllowanceMl:
          dailyFluidAllowanceMl ?? this.dailyFluidAllowanceMl,
      isCaregiverMirror: isCaregiverMirror ?? this.isCaregiverMirror,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (prescribedDryWeightKg.present) {
      map['prescribed_dry_weight_kg'] = Variable<double>(
        prescribedDryWeightKg.value,
      );
    }
    if (dailyFluidAllowanceMl.present) {
      map['daily_fluid_allowance_ml'] = Variable<int>(
        dailyFluidAllowanceMl.value,
      );
    }
    if (isCaregiverMirror.present) {
      map['is_caregiver_mirror'] = Variable<bool>(isCaregiverMirror.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('prescribedDryWeightKg: $prescribedDryWeightKg, ')
          ..write('dailyFluidAllowanceMl: $dailyFluidAllowanceMl, ')
          ..write('isCaregiverMirror: $isCaregiverMirror, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DialysisSessionsTable extends DialysisSessions
    with TableInfo<$DialysisSessionsTable, DialysisSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DialysisSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preWeightKgMeta = const VerificationMeta(
    'preWeightKg',
  );
  @override
  late final GeneratedColumn<double> preWeightKg = GeneratedColumn<double>(
    'pre_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postWeightKgMeta = const VerificationMeta(
    'postWeightKg',
  );
  @override
  late final GeneratedColumn<double> postWeightKg = GeneratedColumn<double>(
    'post_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calculatedInterdialyticWeightGainKgMeta =
      const VerificationMeta('calculatedInterdialyticWeightGainKg');
  @override
  late final GeneratedColumn<double> calculatedInterdialyticWeightGainKg =
      GeneratedColumn<double>(
        'calculated_interdialytic_weight_gain_kg',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _calculatedUltrafiltrationGoalMlMeta =
      const VerificationMeta('calculatedUltrafiltrationGoalMl');
  @override
  late final GeneratedColumn<int> calculatedUltrafiltrationGoalMl =
      GeneratedColumn<int>(
        'calculated_ultrafiltration_goal_ml',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetFluidRemovalMlMeta =
      const VerificationMeta('targetFluidRemovalMl');
  @override
  late final GeneratedColumn<int> targetFluidRemovalMl = GeneratedColumn<int>(
    'target_fluid_removal_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualFluidRemovedMlMeta =
      const VerificationMeta('actualFluidRemovedMl');
  @override
  late final GeneratedColumn<int> actualFluidRemovedMl = GeneratedColumn<int>(
    'actual_fluid_removed_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _symptomsMeta = const VerificationMeta(
    'symptoms',
  );
  @override
  late final GeneratedColumn<String> symptoms = GeneratedColumn<String>(
    'symptoms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    sessionType,
    startedAt,
    endedAt,
    preWeightKg,
    postWeightKg,
    calculatedInterdialyticWeightGainKg,
    calculatedUltrafiltrationGoalMl,
    targetFluidRemovalMl,
    actualFluidRemovedMl,
    notes,
    symptoms,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dialysis_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DialysisSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('pre_weight_kg')) {
      context.handle(
        _preWeightKgMeta,
        preWeightKg.isAcceptableOrUnknown(
          data['pre_weight_kg']!,
          _preWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('post_weight_kg')) {
      context.handle(
        _postWeightKgMeta,
        postWeightKg.isAcceptableOrUnknown(
          data['post_weight_kg']!,
          _postWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('calculated_interdialytic_weight_gain_kg')) {
      context.handle(
        _calculatedInterdialyticWeightGainKgMeta,
        calculatedInterdialyticWeightGainKg.isAcceptableOrUnknown(
          data['calculated_interdialytic_weight_gain_kg']!,
          _calculatedInterdialyticWeightGainKgMeta,
        ),
      );
    }
    if (data.containsKey('calculated_ultrafiltration_goal_ml')) {
      context.handle(
        _calculatedUltrafiltrationGoalMlMeta,
        calculatedUltrafiltrationGoalMl.isAcceptableOrUnknown(
          data['calculated_ultrafiltration_goal_ml']!,
          _calculatedUltrafiltrationGoalMlMeta,
        ),
      );
    }
    if (data.containsKey('target_fluid_removal_ml')) {
      context.handle(
        _targetFluidRemovalMlMeta,
        targetFluidRemovalMl.isAcceptableOrUnknown(
          data['target_fluid_removal_ml']!,
          _targetFluidRemovalMlMeta,
        ),
      );
    }
    if (data.containsKey('actual_fluid_removed_ml')) {
      context.handle(
        _actualFluidRemovedMlMeta,
        actualFluidRemovedMl.isAcceptableOrUnknown(
          data['actual_fluid_removed_ml']!,
          _actualFluidRemovedMlMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('symptoms')) {
      context.handle(
        _symptomsMeta,
        symptoms.isAcceptableOrUnknown(data['symptoms']!, _symptomsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DialysisSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DialysisSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      preWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pre_weight_kg'],
      ),
      postWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}post_weight_kg'],
      ),
      calculatedInterdialyticWeightGainKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calculated_interdialytic_weight_gain_kg'],
      ),
      calculatedUltrafiltrationGoalMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculated_ultrafiltration_goal_ml'],
      ),
      targetFluidRemovalMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_fluid_removal_ml'],
      ),
      actualFluidRemovedMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_fluid_removed_ml'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      symptoms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptoms'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DialysisSessionsTable createAlias(String alias) {
    return $DialysisSessionsTable(attachedDatabase, alias);
  }
}

class DialysisSession extends DataClass implements Insertable<DialysisSession> {
  final String id;
  final String patientId;
  final String sessionType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? preWeightKg;
  final double? postWeightKg;
  final double? calculatedInterdialyticWeightGainKg;
  final int? calculatedUltrafiltrationGoalMl;
  final int? targetFluidRemovalMl;
  final int? actualFluidRemovedMl;
  final String? notes;
  final String? symptoms;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DialysisSession({
    required this.id,
    required this.patientId,
    required this.sessionType,
    required this.startedAt,
    this.endedAt,
    this.preWeightKg,
    this.postWeightKg,
    this.calculatedInterdialyticWeightGainKg,
    this.calculatedUltrafiltrationGoalMl,
    this.targetFluidRemovalMl,
    this.actualFluidRemovedMl,
    this.notes,
    this.symptoms,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['session_type'] = Variable<String>(sessionType);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || preWeightKg != null) {
      map['pre_weight_kg'] = Variable<double>(preWeightKg);
    }
    if (!nullToAbsent || postWeightKg != null) {
      map['post_weight_kg'] = Variable<double>(postWeightKg);
    }
    if (!nullToAbsent || calculatedInterdialyticWeightGainKg != null) {
      map['calculated_interdialytic_weight_gain_kg'] = Variable<double>(
        calculatedInterdialyticWeightGainKg,
      );
    }
    if (!nullToAbsent || calculatedUltrafiltrationGoalMl != null) {
      map['calculated_ultrafiltration_goal_ml'] = Variable<int>(
        calculatedUltrafiltrationGoalMl,
      );
    }
    if (!nullToAbsent || targetFluidRemovalMl != null) {
      map['target_fluid_removal_ml'] = Variable<int>(targetFluidRemovalMl);
    }
    if (!nullToAbsent || actualFluidRemovedMl != null) {
      map['actual_fluid_removed_ml'] = Variable<int>(actualFluidRemovedMl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || symptoms != null) {
      map['symptoms'] = Variable<String>(symptoms);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DialysisSessionsCompanion toCompanion(bool nullToAbsent) {
    return DialysisSessionsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      sessionType: Value(sessionType),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      preWeightKg: preWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(preWeightKg),
      postWeightKg: postWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(postWeightKg),
      calculatedInterdialyticWeightGainKg:
          calculatedInterdialyticWeightGainKg == null && nullToAbsent
          ? const Value.absent()
          : Value(calculatedInterdialyticWeightGainKg),
      calculatedUltrafiltrationGoalMl:
          calculatedUltrafiltrationGoalMl == null && nullToAbsent
          ? const Value.absent()
          : Value(calculatedUltrafiltrationGoalMl),
      targetFluidRemovalMl: targetFluidRemovalMl == null && nullToAbsent
          ? const Value.absent()
          : Value(targetFluidRemovalMl),
      actualFluidRemovedMl: actualFluidRemovedMl == null && nullToAbsent
          ? const Value.absent()
          : Value(actualFluidRemovedMl),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      symptoms: symptoms == null && nullToAbsent
          ? const Value.absent()
          : Value(symptoms),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DialysisSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DialysisSession(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      preWeightKg: serializer.fromJson<double?>(json['preWeightKg']),
      postWeightKg: serializer.fromJson<double?>(json['postWeightKg']),
      calculatedInterdialyticWeightGainKg: serializer.fromJson<double?>(
        json['calculatedInterdialyticWeightGainKg'],
      ),
      calculatedUltrafiltrationGoalMl: serializer.fromJson<int?>(
        json['calculatedUltrafiltrationGoalMl'],
      ),
      targetFluidRemovalMl: serializer.fromJson<int?>(
        json['targetFluidRemovalMl'],
      ),
      actualFluidRemovedMl: serializer.fromJson<int?>(
        json['actualFluidRemovedMl'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      symptoms: serializer.fromJson<String?>(json['symptoms']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'sessionType': serializer.toJson<String>(sessionType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'preWeightKg': serializer.toJson<double?>(preWeightKg),
      'postWeightKg': serializer.toJson<double?>(postWeightKg),
      'calculatedInterdialyticWeightGainKg': serializer.toJson<double?>(
        calculatedInterdialyticWeightGainKg,
      ),
      'calculatedUltrafiltrationGoalMl': serializer.toJson<int?>(
        calculatedUltrafiltrationGoalMl,
      ),
      'targetFluidRemovalMl': serializer.toJson<int?>(targetFluidRemovalMl),
      'actualFluidRemovedMl': serializer.toJson<int?>(actualFluidRemovedMl),
      'notes': serializer.toJson<String?>(notes),
      'symptoms': serializer.toJson<String?>(symptoms),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DialysisSession copyWith({
    String? id,
    String? patientId,
    String? sessionType,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<double?> preWeightKg = const Value.absent(),
    Value<double?> postWeightKg = const Value.absent(),
    Value<double?> calculatedInterdialyticWeightGainKg = const Value.absent(),
    Value<int?> calculatedUltrafiltrationGoalMl = const Value.absent(),
    Value<int?> targetFluidRemovalMl = const Value.absent(),
    Value<int?> actualFluidRemovedMl = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> symptoms = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DialysisSession(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    sessionType: sessionType ?? this.sessionType,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    preWeightKg: preWeightKg.present ? preWeightKg.value : this.preWeightKg,
    postWeightKg: postWeightKg.present ? postWeightKg.value : this.postWeightKg,
    calculatedInterdialyticWeightGainKg:
        calculatedInterdialyticWeightGainKg.present
        ? calculatedInterdialyticWeightGainKg.value
        : this.calculatedInterdialyticWeightGainKg,
    calculatedUltrafiltrationGoalMl: calculatedUltrafiltrationGoalMl.present
        ? calculatedUltrafiltrationGoalMl.value
        : this.calculatedUltrafiltrationGoalMl,
    targetFluidRemovalMl: targetFluidRemovalMl.present
        ? targetFluidRemovalMl.value
        : this.targetFluidRemovalMl,
    actualFluidRemovedMl: actualFluidRemovedMl.present
        ? actualFluidRemovedMl.value
        : this.actualFluidRemovedMl,
    notes: notes.present ? notes.value : this.notes,
    symptoms: symptoms.present ? symptoms.value : this.symptoms,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DialysisSession copyWithCompanion(DialysisSessionsCompanion data) {
    return DialysisSession(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      preWeightKg: data.preWeightKg.present
          ? data.preWeightKg.value
          : this.preWeightKg,
      postWeightKg: data.postWeightKg.present
          ? data.postWeightKg.value
          : this.postWeightKg,
      calculatedInterdialyticWeightGainKg:
          data.calculatedInterdialyticWeightGainKg.present
          ? data.calculatedInterdialyticWeightGainKg.value
          : this.calculatedInterdialyticWeightGainKg,
      calculatedUltrafiltrationGoalMl:
          data.calculatedUltrafiltrationGoalMl.present
          ? data.calculatedUltrafiltrationGoalMl.value
          : this.calculatedUltrafiltrationGoalMl,
      targetFluidRemovalMl: data.targetFluidRemovalMl.present
          ? data.targetFluidRemovalMl.value
          : this.targetFluidRemovalMl,
      actualFluidRemovedMl: data.actualFluidRemovedMl.present
          ? data.actualFluidRemovedMl.value
          : this.actualFluidRemovedMl,
      notes: data.notes.present ? data.notes.value : this.notes,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DialysisSession(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('preWeightKg: $preWeightKg, ')
          ..write('postWeightKg: $postWeightKg, ')
          ..write(
            'calculatedInterdialyticWeightGainKg: $calculatedInterdialyticWeightGainKg, ',
          )
          ..write(
            'calculatedUltrafiltrationGoalMl: $calculatedUltrafiltrationGoalMl, ',
          )
          ..write('targetFluidRemovalMl: $targetFluidRemovalMl, ')
          ..write('actualFluidRemovedMl: $actualFluidRemovedMl, ')
          ..write('notes: $notes, ')
          ..write('symptoms: $symptoms, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    sessionType,
    startedAt,
    endedAt,
    preWeightKg,
    postWeightKg,
    calculatedInterdialyticWeightGainKg,
    calculatedUltrafiltrationGoalMl,
    targetFluidRemovalMl,
    actualFluidRemovedMl,
    notes,
    symptoms,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialysisSession &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.sessionType == this.sessionType &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.preWeightKg == this.preWeightKg &&
          other.postWeightKg == this.postWeightKg &&
          other.calculatedInterdialyticWeightGainKg ==
              this.calculatedInterdialyticWeightGainKg &&
          other.calculatedUltrafiltrationGoalMl ==
              this.calculatedUltrafiltrationGoalMl &&
          other.targetFluidRemovalMl == this.targetFluidRemovalMl &&
          other.actualFluidRemovedMl == this.actualFluidRemovedMl &&
          other.notes == this.notes &&
          other.symptoms == this.symptoms &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DialysisSessionsCompanion extends UpdateCompanion<DialysisSession> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> sessionType;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double?> preWeightKg;
  final Value<double?> postWeightKg;
  final Value<double?> calculatedInterdialyticWeightGainKg;
  final Value<int?> calculatedUltrafiltrationGoalMl;
  final Value<int?> targetFluidRemovalMl;
  final Value<int?> actualFluidRemovedMl;
  final Value<String?> notes;
  final Value<String?> symptoms;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DialysisSessionsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.preWeightKg = const Value.absent(),
    this.postWeightKg = const Value.absent(),
    this.calculatedInterdialyticWeightGainKg = const Value.absent(),
    this.calculatedUltrafiltrationGoalMl = const Value.absent(),
    this.targetFluidRemovalMl = const Value.absent(),
    this.actualFluidRemovedMl = const Value.absent(),
    this.notes = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DialysisSessionsCompanion.insert({
    required String id,
    required String patientId,
    required String sessionType,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.preWeightKg = const Value.absent(),
    this.postWeightKg = const Value.absent(),
    this.calculatedInterdialyticWeightGainKg = const Value.absent(),
    this.calculatedUltrafiltrationGoalMl = const Value.absent(),
    this.targetFluidRemovalMl = const Value.absent(),
    this.actualFluidRemovedMl = const Value.absent(),
    this.notes = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       sessionType = Value(sessionType),
       startedAt = Value(startedAt);
  static Insertable<DialysisSession> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? sessionType,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? preWeightKg,
    Expression<double>? postWeightKg,
    Expression<double>? calculatedInterdialyticWeightGainKg,
    Expression<int>? calculatedUltrafiltrationGoalMl,
    Expression<int>? targetFluidRemovalMl,
    Expression<int>? actualFluidRemovedMl,
    Expression<String>? notes,
    Expression<String>? symptoms,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (sessionType != null) 'session_type': sessionType,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (preWeightKg != null) 'pre_weight_kg': preWeightKg,
      if (postWeightKg != null) 'post_weight_kg': postWeightKg,
      if (calculatedInterdialyticWeightGainKg != null)
        'calculated_interdialytic_weight_gain_kg':
            calculatedInterdialyticWeightGainKg,
      if (calculatedUltrafiltrationGoalMl != null)
        'calculated_ultrafiltration_goal_ml': calculatedUltrafiltrationGoalMl,
      if (targetFluidRemovalMl != null)
        'target_fluid_removal_ml': targetFluidRemovalMl,
      if (actualFluidRemovedMl != null)
        'actual_fluid_removed_ml': actualFluidRemovedMl,
      if (notes != null) 'notes': notes,
      if (symptoms != null) 'symptoms': symptoms,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DialysisSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? sessionType,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double?>? preWeightKg,
    Value<double?>? postWeightKg,
    Value<double?>? calculatedInterdialyticWeightGainKg,
    Value<int?>? calculatedUltrafiltrationGoalMl,
    Value<int?>? targetFluidRemovalMl,
    Value<int?>? actualFluidRemovedMl,
    Value<String?>? notes,
    Value<String?>? symptoms,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DialysisSessionsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      sessionType: sessionType ?? this.sessionType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      preWeightKg: preWeightKg ?? this.preWeightKg,
      postWeightKg: postWeightKg ?? this.postWeightKg,
      calculatedInterdialyticWeightGainKg:
          calculatedInterdialyticWeightGainKg ??
          this.calculatedInterdialyticWeightGainKg,
      calculatedUltrafiltrationGoalMl:
          calculatedUltrafiltrationGoalMl ??
          this.calculatedUltrafiltrationGoalMl,
      targetFluidRemovalMl: targetFluidRemovalMl ?? this.targetFluidRemovalMl,
      actualFluidRemovedMl: actualFluidRemovedMl ?? this.actualFluidRemovedMl,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (preWeightKg.present) {
      map['pre_weight_kg'] = Variable<double>(preWeightKg.value);
    }
    if (postWeightKg.present) {
      map['post_weight_kg'] = Variable<double>(postWeightKg.value);
    }
    if (calculatedInterdialyticWeightGainKg.present) {
      map['calculated_interdialytic_weight_gain_kg'] = Variable<double>(
        calculatedInterdialyticWeightGainKg.value,
      );
    }
    if (calculatedUltrafiltrationGoalMl.present) {
      map['calculated_ultrafiltration_goal_ml'] = Variable<int>(
        calculatedUltrafiltrationGoalMl.value,
      );
    }
    if (targetFluidRemovalMl.present) {
      map['target_fluid_removal_ml'] = Variable<int>(
        targetFluidRemovalMl.value,
      );
    }
    if (actualFluidRemovedMl.present) {
      map['actual_fluid_removed_ml'] = Variable<int>(
        actualFluidRemovedMl.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(symptoms.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DialysisSessionsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('preWeightKg: $preWeightKg, ')
          ..write('postWeightKg: $postWeightKg, ')
          ..write(
            'calculatedInterdialyticWeightGainKg: $calculatedInterdialyticWeightGainKg, ',
          )
          ..write(
            'calculatedUltrafiltrationGoalMl: $calculatedUltrafiltrationGoalMl, ',
          )
          ..write('targetFluidRemovalMl: $targetFluidRemovalMl, ')
          ..write('actualFluidRemovedMl: $actualFluidRemovedMl, ')
          ..write('notes: $notes, ')
          ..write('symptoms: $symptoms, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BloodPressureLogsTable extends BloodPressureLogs
    with TableInfo<$BloodPressureLogsTable, BloodPressureLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BloodPressureLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _systolicMeta = const VerificationMeta(
    'systolic',
  );
  @override
  late final GeneratedColumn<int> systolic = GeneratedColumn<int>(
    'systolic',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diastolicMeta = const VerificationMeta(
    'diastolic',
  );
  @override
  late final GeneratedColumn<int> diastolic = GeneratedColumn<int>(
    'diastolic',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pulseMeta = const VerificationMeta('pulse');
  @override
  late final GeneratedColumn<int> pulse = GeneratedColumn<int>(
    'pulse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _armUsedMeta = const VerificationMeta(
    'armUsed',
  );
  @override
  late final GeneratedColumn<String> armUsed = GeneratedColumn<String>(
    'arm_used',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSafeArmMeta = const VerificationMeta(
    'isSafeArm',
  );
  @override
  late final GeneratedColumn<bool> isSafeArm = GeneratedColumn<bool>(
    'is_safe_arm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_safe_arm" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    systolic,
    diastolic,
    pulse,
    armUsed,
    isSafeArm,
    recordedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blood_pressure_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BloodPressureLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('systolic')) {
      context.handle(
        _systolicMeta,
        systolic.isAcceptableOrUnknown(data['systolic']!, _systolicMeta),
      );
    } else if (isInserting) {
      context.missing(_systolicMeta);
    }
    if (data.containsKey('diastolic')) {
      context.handle(
        _diastolicMeta,
        diastolic.isAcceptableOrUnknown(data['diastolic']!, _diastolicMeta),
      );
    } else if (isInserting) {
      context.missing(_diastolicMeta);
    }
    if (data.containsKey('pulse')) {
      context.handle(
        _pulseMeta,
        pulse.isAcceptableOrUnknown(data['pulse']!, _pulseMeta),
      );
    } else if (isInserting) {
      context.missing(_pulseMeta);
    }
    if (data.containsKey('arm_used')) {
      context.handle(
        _armUsedMeta,
        armUsed.isAcceptableOrUnknown(data['arm_used']!, _armUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_armUsedMeta);
    }
    if (data.containsKey('is_safe_arm')) {
      context.handle(
        _isSafeArmMeta,
        isSafeArm.isAcceptableOrUnknown(data['is_safe_arm']!, _isSafeArmMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BloodPressureLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BloodPressureLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      systolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}systolic'],
      )!,
      diastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diastolic'],
      )!,
      pulse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse'],
      )!,
      armUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arm_used'],
      )!,
      isSafeArm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_safe_arm'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BloodPressureLogsTable createAlias(String alias) {
    return $BloodPressureLogsTable(attachedDatabase, alias);
  }
}

class BloodPressureLog extends DataClass
    implements Insertable<BloodPressureLog> {
  final String id;
  final String patientId;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String armUsed;
  final bool isSafeArm;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BloodPressureLog({
    required this.id,
    required this.patientId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.armUsed,
    required this.isSafeArm,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['systolic'] = Variable<int>(systolic);
    map['diastolic'] = Variable<int>(diastolic);
    map['pulse'] = Variable<int>(pulse);
    map['arm_used'] = Variable<String>(armUsed);
    map['is_safe_arm'] = Variable<bool>(isSafeArm);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BloodPressureLogsCompanion toCompanion(bool nullToAbsent) {
    return BloodPressureLogsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      systolic: Value(systolic),
      diastolic: Value(diastolic),
      pulse: Value(pulse),
      armUsed: Value(armUsed),
      isSafeArm: Value(isSafeArm),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BloodPressureLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BloodPressureLog(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      systolic: serializer.fromJson<int>(json['systolic']),
      diastolic: serializer.fromJson<int>(json['diastolic']),
      pulse: serializer.fromJson<int>(json['pulse']),
      armUsed: serializer.fromJson<String>(json['armUsed']),
      isSafeArm: serializer.fromJson<bool>(json['isSafeArm']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'systolic': serializer.toJson<int>(systolic),
      'diastolic': serializer.toJson<int>(diastolic),
      'pulse': serializer.toJson<int>(pulse),
      'armUsed': serializer.toJson<String>(armUsed),
      'isSafeArm': serializer.toJson<bool>(isSafeArm),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BloodPressureLog copyWith({
    String? id,
    String? patientId,
    int? systolic,
    int? diastolic,
    int? pulse,
    String? armUsed,
    bool? isSafeArm,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BloodPressureLog(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    systolic: systolic ?? this.systolic,
    diastolic: diastolic ?? this.diastolic,
    pulse: pulse ?? this.pulse,
    armUsed: armUsed ?? this.armUsed,
    isSafeArm: isSafeArm ?? this.isSafeArm,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BloodPressureLog copyWithCompanion(BloodPressureLogsCompanion data) {
    return BloodPressureLog(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      systolic: data.systolic.present ? data.systolic.value : this.systolic,
      diastolic: data.diastolic.present ? data.diastolic.value : this.diastolic,
      pulse: data.pulse.present ? data.pulse.value : this.pulse,
      armUsed: data.armUsed.present ? data.armUsed.value : this.armUsed,
      isSafeArm: data.isSafeArm.present ? data.isSafeArm.value : this.isSafeArm,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BloodPressureLog(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('armUsed: $armUsed, ')
          ..write('isSafeArm: $isSafeArm, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    systolic,
    diastolic,
    pulse,
    armUsed,
    isSafeArm,
    recordedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BloodPressureLog &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.systolic == this.systolic &&
          other.diastolic == this.diastolic &&
          other.pulse == this.pulse &&
          other.armUsed == this.armUsed &&
          other.isSafeArm == this.isSafeArm &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BloodPressureLogsCompanion extends UpdateCompanion<BloodPressureLog> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<int> systolic;
  final Value<int> diastolic;
  final Value<int> pulse;
  final Value<String> armUsed;
  final Value<bool> isSafeArm;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BloodPressureLogsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.pulse = const Value.absent(),
    this.armUsed = const Value.absent(),
    this.isSafeArm = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BloodPressureLogsCompanion.insert({
    required String id,
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    this.isSafeArm = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       systolic = Value(systolic),
       diastolic = Value(diastolic),
       pulse = Value(pulse),
       armUsed = Value(armUsed),
       recordedAt = Value(recordedAt);
  static Insertable<BloodPressureLog> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<int>? systolic,
    Expression<int>? diastolic,
    Expression<int>? pulse,
    Expression<String>? armUsed,
    Expression<bool>? isSafeArm,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (pulse != null) 'pulse': pulse,
      if (armUsed != null) 'arm_used': armUsed,
      if (isSafeArm != null) 'is_safe_arm': isSafeArm,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BloodPressureLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<int>? systolic,
    Value<int>? diastolic,
    Value<int>? pulse,
    Value<String>? armUsed,
    Value<bool>? isSafeArm,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BloodPressureLogsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      armUsed: armUsed ?? this.armUsed,
      isSafeArm: isSafeArm ?? this.isSafeArm,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (systolic.present) {
      map['systolic'] = Variable<int>(systolic.value);
    }
    if (diastolic.present) {
      map['diastolic'] = Variable<int>(diastolic.value);
    }
    if (pulse.present) {
      map['pulse'] = Variable<int>(pulse.value);
    }
    if (armUsed.present) {
      map['arm_used'] = Variable<String>(armUsed.value);
    }
    if (isSafeArm.present) {
      map['is_safe_arm'] = Variable<bool>(isSafeArm.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BloodPressureLogsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('armUsed: $armUsed, ')
          ..write('isSafeArm: $isSafeArm, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FluidIntakeLogsTable extends FluidIntakeLogs
    with TableInfo<$FluidIntakeLogsTable, FluidIntakeLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FluidIntakeLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _volumeMlMeta = const VerificationMeta(
    'volumeMl',
  );
  @override
  late final GeneratedColumn<int> volumeMl = GeneratedColumn<int>(
    'volume_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beverageTypeMeta = const VerificationMeta(
    'beverageType',
  );
  @override
  late final GeneratedColumn<String> beverageType = GeneratedColumn<String>(
    'beverage_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phosphateBinderTakenMeta =
      const VerificationMeta('phosphateBinderTaken');
  @override
  late final GeneratedColumn<bool> phosphateBinderTaken = GeneratedColumn<bool>(
    'phosphate_binder_taken',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("phosphate_binder_taken" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    volumeMl,
    beverageType,
    phosphateBinderTaken,
    recordedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fluid_intake_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FluidIntakeLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('volume_ml')) {
      context.handle(
        _volumeMlMeta,
        volumeMl.isAcceptableOrUnknown(data['volume_ml']!, _volumeMlMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeMlMeta);
    }
    if (data.containsKey('beverage_type')) {
      context.handle(
        _beverageTypeMeta,
        beverageType.isAcceptableOrUnknown(
          data['beverage_type']!,
          _beverageTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beverageTypeMeta);
    }
    if (data.containsKey('phosphate_binder_taken')) {
      context.handle(
        _phosphateBinderTakenMeta,
        phosphateBinderTaken.isAcceptableOrUnknown(
          data['phosphate_binder_taken']!,
          _phosphateBinderTakenMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FluidIntakeLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FluidIntakeLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      volumeMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_ml'],
      )!,
      beverageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beverage_type'],
      )!,
      phosphateBinderTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}phosphate_binder_taken'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FluidIntakeLogsTable createAlias(String alias) {
    return $FluidIntakeLogsTable(attachedDatabase, alias);
  }
}

class FluidIntakeLog extends DataClass implements Insertable<FluidIntakeLog> {
  final String id;
  final String patientId;
  final int volumeMl;
  final String beverageType;
  final bool phosphateBinderTaken;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FluidIntakeLog({
    required this.id,
    required this.patientId,
    required this.volumeMl,
    required this.beverageType,
    required this.phosphateBinderTaken,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['volume_ml'] = Variable<int>(volumeMl);
    map['beverage_type'] = Variable<String>(beverageType);
    map['phosphate_binder_taken'] = Variable<bool>(phosphateBinderTaken);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FluidIntakeLogsCompanion toCompanion(bool nullToAbsent) {
    return FluidIntakeLogsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      volumeMl: Value(volumeMl),
      beverageType: Value(beverageType),
      phosphateBinderTaken: Value(phosphateBinderTaken),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FluidIntakeLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FluidIntakeLog(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      volumeMl: serializer.fromJson<int>(json['volumeMl']),
      beverageType: serializer.fromJson<String>(json['beverageType']),
      phosphateBinderTaken: serializer.fromJson<bool>(
        json['phosphateBinderTaken'],
      ),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'volumeMl': serializer.toJson<int>(volumeMl),
      'beverageType': serializer.toJson<String>(beverageType),
      'phosphateBinderTaken': serializer.toJson<bool>(phosphateBinderTaken),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FluidIntakeLog copyWith({
    String? id,
    String? patientId,
    int? volumeMl,
    String? beverageType,
    bool? phosphateBinderTaken,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FluidIntakeLog(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    volumeMl: volumeMl ?? this.volumeMl,
    beverageType: beverageType ?? this.beverageType,
    phosphateBinderTaken: phosphateBinderTaken ?? this.phosphateBinderTaken,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FluidIntakeLog copyWithCompanion(FluidIntakeLogsCompanion data) {
    return FluidIntakeLog(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      volumeMl: data.volumeMl.present ? data.volumeMl.value : this.volumeMl,
      beverageType: data.beverageType.present
          ? data.beverageType.value
          : this.beverageType,
      phosphateBinderTaken: data.phosphateBinderTaken.present
          ? data.phosphateBinderTaken.value
          : this.phosphateBinderTaken,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FluidIntakeLog(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('beverageType: $beverageType, ')
          ..write('phosphateBinderTaken: $phosphateBinderTaken, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    volumeMl,
    beverageType,
    phosphateBinderTaken,
    recordedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FluidIntakeLog &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.volumeMl == this.volumeMl &&
          other.beverageType == this.beverageType &&
          other.phosphateBinderTaken == this.phosphateBinderTaken &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FluidIntakeLogsCompanion extends UpdateCompanion<FluidIntakeLog> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<int> volumeMl;
  final Value<String> beverageType;
  final Value<bool> phosphateBinderTaken;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FluidIntakeLogsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.volumeMl = const Value.absent(),
    this.beverageType = const Value.absent(),
    this.phosphateBinderTaken = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FluidIntakeLogsCompanion.insert({
    required String id,
    required String patientId,
    required int volumeMl,
    required String beverageType,
    this.phosphateBinderTaken = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       volumeMl = Value(volumeMl),
       beverageType = Value(beverageType),
       recordedAt = Value(recordedAt);
  static Insertable<FluidIntakeLog> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<int>? volumeMl,
    Expression<String>? beverageType,
    Expression<bool>? phosphateBinderTaken,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (beverageType != null) 'beverage_type': beverageType,
      if (phosphateBinderTaken != null)
        'phosphate_binder_taken': phosphateBinderTaken,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FluidIntakeLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<int>? volumeMl,
    Value<String>? beverageType,
    Value<bool>? phosphateBinderTaken,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FluidIntakeLogsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      volumeMl: volumeMl ?? this.volumeMl,
      beverageType: beverageType ?? this.beverageType,
      phosphateBinderTaken: phosphateBinderTaken ?? this.phosphateBinderTaken,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (volumeMl.present) {
      map['volume_ml'] = Variable<int>(volumeMl.value);
    }
    if (beverageType.present) {
      map['beverage_type'] = Variable<String>(beverageType.value);
    }
    if (phosphateBinderTaken.present) {
      map['phosphate_binder_taken'] = Variable<bool>(
        phosphateBinderTaken.value,
      );
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FluidIntakeLogsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('beverageType: $beverageType, ')
          ..write('phosphateBinderTaken: $phosphateBinderTaken, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FluidOutputLogsTable extends FluidOutputLogs
    with TableInfo<$FluidOutputLogsTable, FluidOutputLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FluidOutputLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _volumeMlMeta = const VerificationMeta(
    'volumeMl',
  );
  @override
  late final GeneratedColumn<int> volumeMl = GeneratedColumn<int>(
    'volume_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputTypeMeta = const VerificationMeta(
    'outputType',
  );
  @override
  late final GeneratedColumn<String> outputType = GeneratedColumn<String>(
    'output_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hematuriaGradeMeta = const VerificationMeta(
    'hematuriaGrade',
  );
  @override
  late final GeneratedColumn<int> hematuriaGrade = GeneratedColumn<int>(
    'hematuria_grade',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    volumeMl,
    outputType,
    hematuriaGrade,
    recordedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fluid_output_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FluidOutputLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('volume_ml')) {
      context.handle(
        _volumeMlMeta,
        volumeMl.isAcceptableOrUnknown(data['volume_ml']!, _volumeMlMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeMlMeta);
    }
    if (data.containsKey('output_type')) {
      context.handle(
        _outputTypeMeta,
        outputType.isAcceptableOrUnknown(data['output_type']!, _outputTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_outputTypeMeta);
    }
    if (data.containsKey('hematuria_grade')) {
      context.handle(
        _hematuriaGradeMeta,
        hematuriaGrade.isAcceptableOrUnknown(
          data['hematuria_grade']!,
          _hematuriaGradeMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FluidOutputLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FluidOutputLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      volumeMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_ml'],
      )!,
      outputType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_type'],
      )!,
      hematuriaGrade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hematuria_grade'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FluidOutputLogsTable createAlias(String alias) {
    return $FluidOutputLogsTable(attachedDatabase, alias);
  }
}

class FluidOutputLog extends DataClass implements Insertable<FluidOutputLog> {
  final String id;
  final String patientId;
  final int volumeMl;
  final String outputType;
  final int? hematuriaGrade;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FluidOutputLog({
    required this.id,
    required this.patientId,
    required this.volumeMl,
    required this.outputType,
    this.hematuriaGrade,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['volume_ml'] = Variable<int>(volumeMl);
    map['output_type'] = Variable<String>(outputType);
    if (!nullToAbsent || hematuriaGrade != null) {
      map['hematuria_grade'] = Variable<int>(hematuriaGrade);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FluidOutputLogsCompanion toCompanion(bool nullToAbsent) {
    return FluidOutputLogsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      volumeMl: Value(volumeMl),
      outputType: Value(outputType),
      hematuriaGrade: hematuriaGrade == null && nullToAbsent
          ? const Value.absent()
          : Value(hematuriaGrade),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FluidOutputLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FluidOutputLog(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      volumeMl: serializer.fromJson<int>(json['volumeMl']),
      outputType: serializer.fromJson<String>(json['outputType']),
      hematuriaGrade: serializer.fromJson<int?>(json['hematuriaGrade']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'volumeMl': serializer.toJson<int>(volumeMl),
      'outputType': serializer.toJson<String>(outputType),
      'hematuriaGrade': serializer.toJson<int?>(hematuriaGrade),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FluidOutputLog copyWith({
    String? id,
    String? patientId,
    int? volumeMl,
    String? outputType,
    Value<int?> hematuriaGrade = const Value.absent(),
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FluidOutputLog(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    volumeMl: volumeMl ?? this.volumeMl,
    outputType: outputType ?? this.outputType,
    hematuriaGrade: hematuriaGrade.present
        ? hematuriaGrade.value
        : this.hematuriaGrade,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FluidOutputLog copyWithCompanion(FluidOutputLogsCompanion data) {
    return FluidOutputLog(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      volumeMl: data.volumeMl.present ? data.volumeMl.value : this.volumeMl,
      outputType: data.outputType.present
          ? data.outputType.value
          : this.outputType,
      hematuriaGrade: data.hematuriaGrade.present
          ? data.hematuriaGrade.value
          : this.hematuriaGrade,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FluidOutputLog(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('outputType: $outputType, ')
          ..write('hematuriaGrade: $hematuriaGrade, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    volumeMl,
    outputType,
    hematuriaGrade,
    recordedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FluidOutputLog &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.volumeMl == this.volumeMl &&
          other.outputType == this.outputType &&
          other.hematuriaGrade == this.hematuriaGrade &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FluidOutputLogsCompanion extends UpdateCompanion<FluidOutputLog> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<int> volumeMl;
  final Value<String> outputType;
  final Value<int?> hematuriaGrade;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FluidOutputLogsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.volumeMl = const Value.absent(),
    this.outputType = const Value.absent(),
    this.hematuriaGrade = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FluidOutputLogsCompanion.insert({
    required String id,
    required String patientId,
    required int volumeMl,
    required String outputType,
    this.hematuriaGrade = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       volumeMl = Value(volumeMl),
       outputType = Value(outputType),
       recordedAt = Value(recordedAt);
  static Insertable<FluidOutputLog> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<int>? volumeMl,
    Expression<String>? outputType,
    Expression<int>? hematuriaGrade,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (outputType != null) 'output_type': outputType,
      if (hematuriaGrade != null) 'hematuria_grade': hematuriaGrade,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FluidOutputLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<int>? volumeMl,
    Value<String>? outputType,
    Value<int?>? hematuriaGrade,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FluidOutputLogsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      volumeMl: volumeMl ?? this.volumeMl,
      outputType: outputType ?? this.outputType,
      hematuriaGrade: hematuriaGrade ?? this.hematuriaGrade,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (volumeMl.present) {
      map['volume_ml'] = Variable<int>(volumeMl.value);
    }
    if (outputType.present) {
      map['output_type'] = Variable<String>(outputType.value);
    }
    if (hematuriaGrade.present) {
      map['hematuria_grade'] = Variable<int>(hematuriaGrade.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FluidOutputLogsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('outputType: $outputType, ')
          ..write('hematuriaGrade: $hematuriaGrade, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatheterEventsTable extends CatheterEvents
    with TableInfo<$CatheterEventsTable, CatheterEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatheterEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _catheterTypeMeta = const VerificationMeta(
    'catheterType',
  );
  @override
  late final GeneratedColumn<String> catheterType = GeneratedColumn<String>(
    'catheter_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insertionDateMeta = const VerificationMeta(
    'insertionDate',
  );
  @override
  late final GeneratedColumn<DateTime> insertionDate =
      GeneratedColumn<DateTime>(
        'insertion_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _replacementDueDateMeta =
      const VerificationMeta('replacementDueDate');
  @override
  late final GeneratedColumn<DateTime> replacementDueDate =
      GeneratedColumn<DateTime>(
        'replacement_due_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    catheterType,
    insertionDate,
    replacementDueDate,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catheter_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatheterEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('catheter_type')) {
      context.handle(
        _catheterTypeMeta,
        catheterType.isAcceptableOrUnknown(
          data['catheter_type']!,
          _catheterTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catheterTypeMeta);
    }
    if (data.containsKey('insertion_date')) {
      context.handle(
        _insertionDateMeta,
        insertionDate.isAcceptableOrUnknown(
          data['insertion_date']!,
          _insertionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_insertionDateMeta);
    }
    if (data.containsKey('replacement_due_date')) {
      context.handle(
        _replacementDueDateMeta,
        replacementDueDate.isAcceptableOrUnknown(
          data['replacement_due_date']!,
          _replacementDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_replacementDueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatheterEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatheterEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      catheterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catheter_type'],
      )!,
      insertionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}insertion_date'],
      )!,
      replacementDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}replacement_due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CatheterEventsTable createAlias(String alias) {
    return $CatheterEventsTable(attachedDatabase, alias);
  }
}

class CatheterEvent extends DataClass implements Insertable<CatheterEvent> {
  final String id;
  final String patientId;
  final String catheterType;
  final DateTime insertionDate;
  final DateTime replacementDueDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CatheterEvent({
    required this.id,
    required this.patientId,
    required this.catheterType,
    required this.insertionDate,
    required this.replacementDueDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['catheter_type'] = Variable<String>(catheterType);
    map['insertion_date'] = Variable<DateTime>(insertionDate);
    map['replacement_due_date'] = Variable<DateTime>(replacementDueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CatheterEventsCompanion toCompanion(bool nullToAbsent) {
    return CatheterEventsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      catheterType: Value(catheterType),
      insertionDate: Value(insertionDate),
      replacementDueDate: Value(replacementDueDate),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CatheterEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatheterEvent(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      catheterType: serializer.fromJson<String>(json['catheterType']),
      insertionDate: serializer.fromJson<DateTime>(json['insertionDate']),
      replacementDueDate: serializer.fromJson<DateTime>(
        json['replacementDueDate'],
      ),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'catheterType': serializer.toJson<String>(catheterType),
      'insertionDate': serializer.toJson<DateTime>(insertionDate),
      'replacementDueDate': serializer.toJson<DateTime>(replacementDueDate),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CatheterEvent copyWith({
    String? id,
    String? patientId,
    String? catheterType,
    DateTime? insertionDate,
    DateTime? replacementDueDate,
    String? status,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CatheterEvent(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    catheterType: catheterType ?? this.catheterType,
    insertionDate: insertionDate ?? this.insertionDate,
    replacementDueDate: replacementDueDate ?? this.replacementDueDate,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CatheterEvent copyWithCompanion(CatheterEventsCompanion data) {
    return CatheterEvent(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      catheterType: data.catheterType.present
          ? data.catheterType.value
          : this.catheterType,
      insertionDate: data.insertionDate.present
          ? data.insertionDate.value
          : this.insertionDate,
      replacementDueDate: data.replacementDueDate.present
          ? data.replacementDueDate.value
          : this.replacementDueDate,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatheterEvent(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('catheterType: $catheterType, ')
          ..write('insertionDate: $insertionDate, ')
          ..write('replacementDueDate: $replacementDueDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    catheterType,
    insertionDate,
    replacementDueDate,
    status,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatheterEvent &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.catheterType == this.catheterType &&
          other.insertionDate == this.insertionDate &&
          other.replacementDueDate == this.replacementDueDate &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CatheterEventsCompanion extends UpdateCompanion<CatheterEvent> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> catheterType;
  final Value<DateTime> insertionDate;
  final Value<DateTime> replacementDueDate;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CatheterEventsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.catheterType = const Value.absent(),
    this.insertionDate = const Value.absent(),
    this.replacementDueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatheterEventsCompanion.insert({
    required String id,
    required String patientId,
    required String catheterType,
    required DateTime insertionDate,
    required DateTime replacementDueDate,
    required String status,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       catheterType = Value(catheterType),
       insertionDate = Value(insertionDate),
       replacementDueDate = Value(replacementDueDate),
       status = Value(status);
  static Insertable<CatheterEvent> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? catheterType,
    Expression<DateTime>? insertionDate,
    Expression<DateTime>? replacementDueDate,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (catheterType != null) 'catheter_type': catheterType,
      if (insertionDate != null) 'insertion_date': insertionDate,
      if (replacementDueDate != null)
        'replacement_due_date': replacementDueDate,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatheterEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? catheterType,
    Value<DateTime>? insertionDate,
    Value<DateTime>? replacementDueDate,
    Value<String>? status,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CatheterEventsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      catheterType: catheterType ?? this.catheterType,
      insertionDate: insertionDate ?? this.insertionDate,
      replacementDueDate: replacementDueDate ?? this.replacementDueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (catheterType.present) {
      map['catheter_type'] = Variable<String>(catheterType.value);
    }
    if (insertionDate.present) {
      map['insertion_date'] = Variable<DateTime>(insertionDate.value);
    }
    if (replacementDueDate.present) {
      map['replacement_due_date'] = Variable<DateTime>(
        replacementDueDate.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatheterEventsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('catheterType: $catheterType, ')
          ..write('insertionDate: $insertionDate, ')
          ..write('replacementDueDate: $replacementDueDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccessInspectionsTable extends AccessInspections
    with TableInfo<$AccessInspectionsTable, AccessInspection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccessInspectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id)',
    ),
  );
  static const VerificationMeta _accessTypeMeta = const VerificationMeta(
    'accessType',
  );
  @override
  late final GeneratedColumn<String> accessType = GeneratedColumn<String>(
    'access_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anatomicalLocationMeta =
      const VerificationMeta('anatomicalLocation');
  @override
  late final GeneratedColumn<String> anatomicalLocation =
      GeneratedColumn<String>(
        'anatomical_location',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _thrillPresentMeta = const VerificationMeta(
    'thrillPresent',
  );
  @override
  late final GeneratedColumn<bool> thrillPresent = GeneratedColumn<bool>(
    'thrill_present',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("thrill_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _bruitPresentMeta = const VerificationMeta(
    'bruitPresent',
  );
  @override
  late final GeneratedColumn<bool> bruitPresent = GeneratedColumn<bool>(
    'bruit_present',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bruit_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _rednessPresentMeta = const VerificationMeta(
    'rednessPresent',
  );
  @override
  late final GeneratedColumn<bool> rednessPresent = GeneratedColumn<bool>(
    'redness_present',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("redness_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dischargePresentMeta = const VerificationMeta(
    'dischargePresent',
  );
  @override
  late final GeneratedColumn<bool> dischargePresent = GeneratedColumn<bool>(
    'discharge_present',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("discharge_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _painPresentMeta = const VerificationMeta(
    'painPresent',
  );
  @override
  late final GeneratedColumn<bool> painPresent = GeneratedColumn<bool>(
    'pain_present',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pain_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    accessType,
    anatomicalLocation,
    thrillPresent,
    bruitPresent,
    rednessPresent,
    dischargePresent,
    painPresent,
    notes,
    recordedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'access_inspections';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccessInspection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('access_type')) {
      context.handle(
        _accessTypeMeta,
        accessType.isAcceptableOrUnknown(data['access_type']!, _accessTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_accessTypeMeta);
    }
    if (data.containsKey('anatomical_location')) {
      context.handle(
        _anatomicalLocationMeta,
        anatomicalLocation.isAcceptableOrUnknown(
          data['anatomical_location']!,
          _anatomicalLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_anatomicalLocationMeta);
    }
    if (data.containsKey('thrill_present')) {
      context.handle(
        _thrillPresentMeta,
        thrillPresent.isAcceptableOrUnknown(
          data['thrill_present']!,
          _thrillPresentMeta,
        ),
      );
    }
    if (data.containsKey('bruit_present')) {
      context.handle(
        _bruitPresentMeta,
        bruitPresent.isAcceptableOrUnknown(
          data['bruit_present']!,
          _bruitPresentMeta,
        ),
      );
    }
    if (data.containsKey('redness_present')) {
      context.handle(
        _rednessPresentMeta,
        rednessPresent.isAcceptableOrUnknown(
          data['redness_present']!,
          _rednessPresentMeta,
        ),
      );
    }
    if (data.containsKey('discharge_present')) {
      context.handle(
        _dischargePresentMeta,
        dischargePresent.isAcceptableOrUnknown(
          data['discharge_present']!,
          _dischargePresentMeta,
        ),
      );
    }
    if (data.containsKey('pain_present')) {
      context.handle(
        _painPresentMeta,
        painPresent.isAcceptableOrUnknown(
          data['pain_present']!,
          _painPresentMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccessInspection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccessInspection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      accessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_type'],
      )!,
      anatomicalLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anatomical_location'],
      )!,
      thrillPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thrill_present'],
      ),
      bruitPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bruit_present'],
      ),
      rednessPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}redness_present'],
      ),
      dischargePresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}discharge_present'],
      ),
      painPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pain_present'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccessInspectionsTable createAlias(String alias) {
    return $AccessInspectionsTable(attachedDatabase, alias);
  }
}

class AccessInspection extends DataClass
    implements Insertable<AccessInspection> {
  final String id;
  final String patientId;
  final String accessType;
  final String anatomicalLocation;
  final bool? thrillPresent;
  final bool? bruitPresent;
  final bool? rednessPresent;
  final bool? dischargePresent;
  final bool? painPresent;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AccessInspection({
    required this.id,
    required this.patientId,
    required this.accessType,
    required this.anatomicalLocation,
    this.thrillPresent,
    this.bruitPresent,
    this.rednessPresent,
    this.dischargePresent,
    this.painPresent,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['access_type'] = Variable<String>(accessType);
    map['anatomical_location'] = Variable<String>(anatomicalLocation);
    if (!nullToAbsent || thrillPresent != null) {
      map['thrill_present'] = Variable<bool>(thrillPresent);
    }
    if (!nullToAbsent || bruitPresent != null) {
      map['bruit_present'] = Variable<bool>(bruitPresent);
    }
    if (!nullToAbsent || rednessPresent != null) {
      map['redness_present'] = Variable<bool>(rednessPresent);
    }
    if (!nullToAbsent || dischargePresent != null) {
      map['discharge_present'] = Variable<bool>(dischargePresent);
    }
    if (!nullToAbsent || painPresent != null) {
      map['pain_present'] = Variable<bool>(painPresent);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccessInspectionsCompanion toCompanion(bool nullToAbsent) {
    return AccessInspectionsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      accessType: Value(accessType),
      anatomicalLocation: Value(anatomicalLocation),
      thrillPresent: thrillPresent == null && nullToAbsent
          ? const Value.absent()
          : Value(thrillPresent),
      bruitPresent: bruitPresent == null && nullToAbsent
          ? const Value.absent()
          : Value(bruitPresent),
      rednessPresent: rednessPresent == null && nullToAbsent
          ? const Value.absent()
          : Value(rednessPresent),
      dischargePresent: dischargePresent == null && nullToAbsent
          ? const Value.absent()
          : Value(dischargePresent),
      painPresent: painPresent == null && nullToAbsent
          ? const Value.absent()
          : Value(painPresent),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccessInspection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccessInspection(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      accessType: serializer.fromJson<String>(json['accessType']),
      anatomicalLocation: serializer.fromJson<String>(
        json['anatomicalLocation'],
      ),
      thrillPresent: serializer.fromJson<bool?>(json['thrillPresent']),
      bruitPresent: serializer.fromJson<bool?>(json['bruitPresent']),
      rednessPresent: serializer.fromJson<bool?>(json['rednessPresent']),
      dischargePresent: serializer.fromJson<bool?>(json['dischargePresent']),
      painPresent: serializer.fromJson<bool?>(json['painPresent']),
      notes: serializer.fromJson<String?>(json['notes']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'accessType': serializer.toJson<String>(accessType),
      'anatomicalLocation': serializer.toJson<String>(anatomicalLocation),
      'thrillPresent': serializer.toJson<bool?>(thrillPresent),
      'bruitPresent': serializer.toJson<bool?>(bruitPresent),
      'rednessPresent': serializer.toJson<bool?>(rednessPresent),
      'dischargePresent': serializer.toJson<bool?>(dischargePresent),
      'painPresent': serializer.toJson<bool?>(painPresent),
      'notes': serializer.toJson<String?>(notes),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AccessInspection copyWith({
    String? id,
    String? patientId,
    String? accessType,
    String? anatomicalLocation,
    Value<bool?> thrillPresent = const Value.absent(),
    Value<bool?> bruitPresent = const Value.absent(),
    Value<bool?> rednessPresent = const Value.absent(),
    Value<bool?> dischargePresent = const Value.absent(),
    Value<bool?> painPresent = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccessInspection(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    accessType: accessType ?? this.accessType,
    anatomicalLocation: anatomicalLocation ?? this.anatomicalLocation,
    thrillPresent: thrillPresent.present
        ? thrillPresent.value
        : this.thrillPresent,
    bruitPresent: bruitPresent.present ? bruitPresent.value : this.bruitPresent,
    rednessPresent: rednessPresent.present
        ? rednessPresent.value
        : this.rednessPresent,
    dischargePresent: dischargePresent.present
        ? dischargePresent.value
        : this.dischargePresent,
    painPresent: painPresent.present ? painPresent.value : this.painPresent,
    notes: notes.present ? notes.value : this.notes,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccessInspection copyWithCompanion(AccessInspectionsCompanion data) {
    return AccessInspection(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      accessType: data.accessType.present
          ? data.accessType.value
          : this.accessType,
      anatomicalLocation: data.anatomicalLocation.present
          ? data.anatomicalLocation.value
          : this.anatomicalLocation,
      thrillPresent: data.thrillPresent.present
          ? data.thrillPresent.value
          : this.thrillPresent,
      bruitPresent: data.bruitPresent.present
          ? data.bruitPresent.value
          : this.bruitPresent,
      rednessPresent: data.rednessPresent.present
          ? data.rednessPresent.value
          : this.rednessPresent,
      dischargePresent: data.dischargePresent.present
          ? data.dischargePresent.value
          : this.dischargePresent,
      painPresent: data.painPresent.present
          ? data.painPresent.value
          : this.painPresent,
      notes: data.notes.present ? data.notes.value : this.notes,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccessInspection(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('accessType: $accessType, ')
          ..write('anatomicalLocation: $anatomicalLocation, ')
          ..write('thrillPresent: $thrillPresent, ')
          ..write('bruitPresent: $bruitPresent, ')
          ..write('rednessPresent: $rednessPresent, ')
          ..write('dischargePresent: $dischargePresent, ')
          ..write('painPresent: $painPresent, ')
          ..write('notes: $notes, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    accessType,
    anatomicalLocation,
    thrillPresent,
    bruitPresent,
    rednessPresent,
    dischargePresent,
    painPresent,
    notes,
    recordedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccessInspection &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.accessType == this.accessType &&
          other.anatomicalLocation == this.anatomicalLocation &&
          other.thrillPresent == this.thrillPresent &&
          other.bruitPresent == this.bruitPresent &&
          other.rednessPresent == this.rednessPresent &&
          other.dischargePresent == this.dischargePresent &&
          other.painPresent == this.painPresent &&
          other.notes == this.notes &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccessInspectionsCompanion extends UpdateCompanion<AccessInspection> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> accessType;
  final Value<String> anatomicalLocation;
  final Value<bool?> thrillPresent;
  final Value<bool?> bruitPresent;
  final Value<bool?> rednessPresent;
  final Value<bool?> dischargePresent;
  final Value<bool?> painPresent;
  final Value<String?> notes;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AccessInspectionsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.accessType = const Value.absent(),
    this.anatomicalLocation = const Value.absent(),
    this.thrillPresent = const Value.absent(),
    this.bruitPresent = const Value.absent(),
    this.rednessPresent = const Value.absent(),
    this.dischargePresent = const Value.absent(),
    this.painPresent = const Value.absent(),
    this.notes = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccessInspectionsCompanion.insert({
    required String id,
    required String patientId,
    required String accessType,
    required String anatomicalLocation,
    this.thrillPresent = const Value.absent(),
    this.bruitPresent = const Value.absent(),
    this.rednessPresent = const Value.absent(),
    this.dischargePresent = const Value.absent(),
    this.painPresent = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       accessType = Value(accessType),
       anatomicalLocation = Value(anatomicalLocation),
       recordedAt = Value(recordedAt);
  static Insertable<AccessInspection> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? accessType,
    Expression<String>? anatomicalLocation,
    Expression<bool>? thrillPresent,
    Expression<bool>? bruitPresent,
    Expression<bool>? rednessPresent,
    Expression<bool>? dischargePresent,
    Expression<bool>? painPresent,
    Expression<String>? notes,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (accessType != null) 'access_type': accessType,
      if (anatomicalLocation != null) 'anatomical_location': anatomicalLocation,
      if (thrillPresent != null) 'thrill_present': thrillPresent,
      if (bruitPresent != null) 'bruit_present': bruitPresent,
      if (rednessPresent != null) 'redness_present': rednessPresent,
      if (dischargePresent != null) 'discharge_present': dischargePresent,
      if (painPresent != null) 'pain_present': painPresent,
      if (notes != null) 'notes': notes,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccessInspectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? accessType,
    Value<String>? anatomicalLocation,
    Value<bool?>? thrillPresent,
    Value<bool?>? bruitPresent,
    Value<bool?>? rednessPresent,
    Value<bool?>? dischargePresent,
    Value<bool?>? painPresent,
    Value<String?>? notes,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccessInspectionsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      accessType: accessType ?? this.accessType,
      anatomicalLocation: anatomicalLocation ?? this.anatomicalLocation,
      thrillPresent: thrillPresent ?? this.thrillPresent,
      bruitPresent: bruitPresent ?? this.bruitPresent,
      rednessPresent: rednessPresent ?? this.rednessPresent,
      dischargePresent: dischargePresent ?? this.dischargePresent,
      painPresent: painPresent ?? this.painPresent,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (accessType.present) {
      map['access_type'] = Variable<String>(accessType.value);
    }
    if (anatomicalLocation.present) {
      map['anatomical_location'] = Variable<String>(anatomicalLocation.value);
    }
    if (thrillPresent.present) {
      map['thrill_present'] = Variable<bool>(thrillPresent.value);
    }
    if (bruitPresent.present) {
      map['bruit_present'] = Variable<bool>(bruitPresent.value);
    }
    if (rednessPresent.present) {
      map['redness_present'] = Variable<bool>(rednessPresent.value);
    }
    if (dischargePresent.present) {
      map['discharge_present'] = Variable<bool>(dischargePresent.value);
    }
    if (painPresent.present) {
      map['pain_present'] = Variable<bool>(painPresent.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccessInspectionsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('accessType: $accessType, ')
          ..write('anatomicalLocation: $anatomicalLocation, ')
          ..write('thrillPresent: $thrillPresent, ')
          ..write('bruitPresent: $bruitPresent, ')
          ..write('rednessPresent: $rednessPresent, ')
          ..write('dischargePresent: $dischargePresent, ')
          ..write('painPresent: $painPresent, ')
          ..write('notes: $notes, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $DialysisSessionsTable dialysisSessions = $DialysisSessionsTable(
    this,
  );
  late final $BloodPressureLogsTable bloodPressureLogs =
      $BloodPressureLogsTable(this);
  late final $FluidIntakeLogsTable fluidIntakeLogs = $FluidIntakeLogsTable(
    this,
  );
  late final $FluidOutputLogsTable fluidOutputLogs = $FluidOutputLogsTable(
    this,
  );
  late final $CatheterEventsTable catheterEvents = $CatheterEventsTable(this);
  late final $AccessInspectionsTable accessInspections =
      $AccessInspectionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    patients,
    dialysisSessions,
    bloodPressureLogs,
    fluidIntakeLogs,
    fluidOutputLogs,
    catheterEvents,
    accessInspections,
  ];
}

typedef $$PatientsTableCreateCompanionBuilder =
    PatientsCompanion Function({
      required String id,
      required String name,
      required String diagnosis,
      Value<double?> prescribedDryWeightKg,
      Value<int?> dailyFluidAllowanceMl,
      Value<bool> isCaregiverMirror,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PatientsTableUpdateCompanionBuilder =
    PatientsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> diagnosis,
      Value<double?> prescribedDryWeightKg,
      Value<int?> dailyFluidAllowanceMl,
      Value<bool> isCaregiverMirror,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PatientsTableReferences
    extends BaseReferences<_$AppDatabase, $PatientsTable, Patient> {
  $$PatientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DialysisSessionsTable, List<DialysisSession>>
  _dialysisSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dialysisSessions,
    aliasName: 'patients__id__dialysis_sessions__patient_id',
  );

  $$DialysisSessionsTableProcessedTableManager get dialysisSessionsRefs {
    final manager = $$DialysisSessionsTableTableManager(
      $_db,
      $_db.dialysisSessions,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dialysisSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BloodPressureLogsTable, List<BloodPressureLog>>
  _bloodPressureLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bloodPressureLogs,
        aliasName: 'patients__id__blood_pressure_logs__patient_id',
      );

  $$BloodPressureLogsTableProcessedTableManager get bloodPressureLogsRefs {
    final manager = $$BloodPressureLogsTableTableManager(
      $_db,
      $_db.bloodPressureLogs,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bloodPressureLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FluidIntakeLogsTable, List<FluidIntakeLog>>
  _fluidIntakeLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fluidIntakeLogs,
    aliasName: 'patients__id__fluid_intake_logs__patient_id',
  );

  $$FluidIntakeLogsTableProcessedTableManager get fluidIntakeLogsRefs {
    final manager = $$FluidIntakeLogsTableTableManager(
      $_db,
      $_db.fluidIntakeLogs,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fluidIntakeLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FluidOutputLogsTable, List<FluidOutputLog>>
  _fluidOutputLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fluidOutputLogs,
    aliasName: 'patients__id__fluid_output_logs__patient_id',
  );

  $$FluidOutputLogsTableProcessedTableManager get fluidOutputLogsRefs {
    final manager = $$FluidOutputLogsTableTableManager(
      $_db,
      $_db.fluidOutputLogs,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fluidOutputLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CatheterEventsTable, List<CatheterEvent>>
  _catheterEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.catheterEvents,
    aliasName: 'patients__id__catheter_events__patient_id',
  );

  $$CatheterEventsTableProcessedTableManager get catheterEventsRefs {
    final manager = $$CatheterEventsTableTableManager(
      $_db,
      $_db.catheterEvents,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_catheterEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccessInspectionsTable, List<AccessInspection>>
  _accessInspectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accessInspections,
        aliasName: 'patients__id__access_inspections__patient_id',
      );

  $$AccessInspectionsTableProcessedTableManager get accessInspectionsRefs {
    final manager = $$AccessInspectionsTableTableManager(
      $_db,
      $_db.accessInspections,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accessInspectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prescribedDryWeightKg => $composableBuilder(
    column: $table.prescribedDryWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyFluidAllowanceMl => $composableBuilder(
    column: $table.dailyFluidAllowanceMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCaregiverMirror => $composableBuilder(
    column: $table.isCaregiverMirror,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dialysisSessionsRefs(
    Expression<bool> Function($$DialysisSessionsTableFilterComposer f) f,
  ) {
    final $$DialysisSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dialysisSessions,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DialysisSessionsTableFilterComposer(
            $db: $db,
            $table: $db.dialysisSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bloodPressureLogsRefs(
    Expression<bool> Function($$BloodPressureLogsTableFilterComposer f) f,
  ) {
    final $$BloodPressureLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bloodPressureLogs,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BloodPressureLogsTableFilterComposer(
            $db: $db,
            $table: $db.bloodPressureLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fluidIntakeLogsRefs(
    Expression<bool> Function($$FluidIntakeLogsTableFilterComposer f) f,
  ) {
    final $$FluidIntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fluidIntakeLogs,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FluidIntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.fluidIntakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fluidOutputLogsRefs(
    Expression<bool> Function($$FluidOutputLogsTableFilterComposer f) f,
  ) {
    final $$FluidOutputLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fluidOutputLogs,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FluidOutputLogsTableFilterComposer(
            $db: $db,
            $table: $db.fluidOutputLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> catheterEventsRefs(
    Expression<bool> Function($$CatheterEventsTableFilterComposer f) f,
  ) {
    final $$CatheterEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catheterEvents,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatheterEventsTableFilterComposer(
            $db: $db,
            $table: $db.catheterEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accessInspectionsRefs(
    Expression<bool> Function($$AccessInspectionsTableFilterComposer f) f,
  ) {
    final $$AccessInspectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accessInspections,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessInspectionsTableFilterComposer(
            $db: $db,
            $table: $db.accessInspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prescribedDryWeightKg => $composableBuilder(
    column: $table.prescribedDryWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyFluidAllowanceMl => $composableBuilder(
    column: $table.dailyFluidAllowanceMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCaregiverMirror => $composableBuilder(
    column: $table.isCaregiverMirror,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<double> get prescribedDryWeightKg => $composableBuilder(
    column: $table.prescribedDryWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyFluidAllowanceMl => $composableBuilder(
    column: $table.dailyFluidAllowanceMl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCaregiverMirror => $composableBuilder(
    column: $table.isCaregiverMirror,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> dialysisSessionsRefs<T extends Object>(
    Expression<T> Function($$DialysisSessionsTableAnnotationComposer a) f,
  ) {
    final $$DialysisSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dialysisSessions,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DialysisSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.dialysisSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bloodPressureLogsRefs<T extends Object>(
    Expression<T> Function($$BloodPressureLogsTableAnnotationComposer a) f,
  ) {
    final $$BloodPressureLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bloodPressureLogs,
          getReferencedColumn: (t) => t.patientId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BloodPressureLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.bloodPressureLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> fluidIntakeLogsRefs<T extends Object>(
    Expression<T> Function($$FluidIntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$FluidIntakeLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fluidIntakeLogs,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FluidIntakeLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.fluidIntakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fluidOutputLogsRefs<T extends Object>(
    Expression<T> Function($$FluidOutputLogsTableAnnotationComposer a) f,
  ) {
    final $$FluidOutputLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fluidOutputLogs,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FluidOutputLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.fluidOutputLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> catheterEventsRefs<T extends Object>(
    Expression<T> Function($$CatheterEventsTableAnnotationComposer a) f,
  ) {
    final $$CatheterEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catheterEvents,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatheterEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.catheterEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accessInspectionsRefs<T extends Object>(
    Expression<T> Function($$AccessInspectionsTableAnnotationComposer a) f,
  ) {
    final $$AccessInspectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accessInspections,
          getReferencedColumn: (t) => t.patientId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccessInspectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.accessInspections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PatientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatientsTable,
          Patient,
          $$PatientsTableFilterComposer,
          $$PatientsTableOrderingComposer,
          $$PatientsTableAnnotationComposer,
          $$PatientsTableCreateCompanionBuilder,
          $$PatientsTableUpdateCompanionBuilder,
          (Patient, $$PatientsTableReferences),
          Patient,
          PrefetchHooks Function({
            bool dialysisSessionsRefs,
            bool bloodPressureLogsRefs,
            bool fluidIntakeLogsRefs,
            bool fluidOutputLogsRefs,
            bool catheterEventsRefs,
            bool accessInspectionsRefs,
          })
        > {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> diagnosis = const Value.absent(),
                Value<double?> prescribedDryWeightKg = const Value.absent(),
                Value<int?> dailyFluidAllowanceMl = const Value.absent(),
                Value<bool> isCaregiverMirror = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientsCompanion(
                id: id,
                name: name,
                diagnosis: diagnosis,
                prescribedDryWeightKg: prescribedDryWeightKg,
                dailyFluidAllowanceMl: dailyFluidAllowanceMl,
                isCaregiverMirror: isCaregiverMirror,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String diagnosis,
                Value<double?> prescribedDryWeightKg = const Value.absent(),
                Value<int?> dailyFluidAllowanceMl = const Value.absent(),
                Value<bool> isCaregiverMirror = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientsCompanion.insert(
                id: id,
                name: name,
                diagnosis: diagnosis,
                prescribedDryWeightKg: prescribedDryWeightKg,
                dailyFluidAllowanceMl: dailyFluidAllowanceMl,
                isCaregiverMirror: isCaregiverMirror,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PatientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dialysisSessionsRefs = false,
                bloodPressureLogsRefs = false,
                fluidIntakeLogsRefs = false,
                fluidOutputLogsRefs = false,
                catheterEventsRefs = false,
                accessInspectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dialysisSessionsRefs) db.dialysisSessions,
                    if (bloodPressureLogsRefs) db.bloodPressureLogs,
                    if (fluidIntakeLogsRefs) db.fluidIntakeLogs,
                    if (fluidOutputLogsRefs) db.fluidOutputLogs,
                    if (catheterEventsRefs) db.catheterEvents,
                    if (accessInspectionsRefs) db.accessInspections,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dialysisSessionsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          DialysisSession
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._dialysisSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).dialysisSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bloodPressureLogsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          BloodPressureLog
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._bloodPressureLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).bloodPressureLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fluidIntakeLogsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          FluidIntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._fluidIntakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).fluidIntakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fluidOutputLogsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          FluidOutputLog
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._fluidOutputLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).fluidOutputLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (catheterEventsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          CatheterEvent
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._catheterEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).catheterEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (accessInspectionsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          AccessInspection
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._accessInspectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).accessInspectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
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

typedef $$PatientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatientsTable,
      Patient,
      $$PatientsTableFilterComposer,
      $$PatientsTableOrderingComposer,
      $$PatientsTableAnnotationComposer,
      $$PatientsTableCreateCompanionBuilder,
      $$PatientsTableUpdateCompanionBuilder,
      (Patient, $$PatientsTableReferences),
      Patient,
      PrefetchHooks Function({
        bool dialysisSessionsRefs,
        bool bloodPressureLogsRefs,
        bool fluidIntakeLogsRefs,
        bool fluidOutputLogsRefs,
        bool catheterEventsRefs,
        bool accessInspectionsRefs,
      })
    >;
typedef $$DialysisSessionsTableCreateCompanionBuilder =
    DialysisSessionsCompanion Function({
      required String id,
      required String patientId,
      required String sessionType,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<double?> preWeightKg,
      Value<double?> postWeightKg,
      Value<double?> calculatedInterdialyticWeightGainKg,
      Value<int?> calculatedUltrafiltrationGoalMl,
      Value<int?> targetFluidRemovalMl,
      Value<int?> actualFluidRemovedMl,
      Value<String?> notes,
      Value<String?> symptoms,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DialysisSessionsTableUpdateCompanionBuilder =
    DialysisSessionsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> sessionType,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<double?> preWeightKg,
      Value<double?> postWeightKg,
      Value<double?> calculatedInterdialyticWeightGainKg,
      Value<int?> calculatedUltrafiltrationGoalMl,
      Value<int?> targetFluidRemovalMl,
      Value<int?> actualFluidRemovedMl,
      Value<String?> notes,
      Value<String?> symptoms,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DialysisSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DialysisSessionsTable, DialysisSession> {
  $$DialysisSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('dialysis_sessions__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DialysisSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $DialysisSessionsTable> {
  $$DialysisSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get preWeightKg => $composableBuilder(
    column: $table.preWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get postWeightKg => $composableBuilder(
    column: $table.postWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calculatedInterdialyticWeightGainKg =>
      $composableBuilder(
        column: $table.calculatedInterdialyticWeightGainKg,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<int> get calculatedUltrafiltrationGoalMl => $composableBuilder(
    column: $table.calculatedUltrafiltrationGoalMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetFluidRemovalMl => $composableBuilder(
    column: $table.targetFluidRemovalMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualFluidRemovedMl => $composableBuilder(
    column: $table.actualFluidRemovedMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DialysisSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DialysisSessionsTable> {
  $$DialysisSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get preWeightKg => $composableBuilder(
    column: $table.preWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get postWeightKg => $composableBuilder(
    column: $table.postWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calculatedInterdialyticWeightGainKg =>
      $composableBuilder(
        column: $table.calculatedInterdialyticWeightGainKg,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get calculatedUltrafiltrationGoalMl =>
      $composableBuilder(
        column: $table.calculatedUltrafiltrationGoalMl,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get targetFluidRemovalMl => $composableBuilder(
    column: $table.targetFluidRemovalMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualFluidRemovedMl => $composableBuilder(
    column: $table.actualFluidRemovedMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DialysisSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DialysisSessionsTable> {
  $$DialysisSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get preWeightKg => $composableBuilder(
    column: $table.preWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get postWeightKg => $composableBuilder(
    column: $table.postWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calculatedInterdialyticWeightGainKg =>
      $composableBuilder(
        column: $table.calculatedInterdialyticWeightGainKg,
        builder: (column) => column,
      );

  GeneratedColumn<int> get calculatedUltrafiltrationGoalMl =>
      $composableBuilder(
        column: $table.calculatedUltrafiltrationGoalMl,
        builder: (column) => column,
      );

  GeneratedColumn<int> get targetFluidRemovalMl => $composableBuilder(
    column: $table.targetFluidRemovalMl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualFluidRemovedMl => $composableBuilder(
    column: $table.actualFluidRemovedMl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get symptoms =>
      $composableBuilder(column: $table.symptoms, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DialysisSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DialysisSessionsTable,
          DialysisSession,
          $$DialysisSessionsTableFilterComposer,
          $$DialysisSessionsTableOrderingComposer,
          $$DialysisSessionsTableAnnotationComposer,
          $$DialysisSessionsTableCreateCompanionBuilder,
          $$DialysisSessionsTableUpdateCompanionBuilder,
          (DialysisSession, $$DialysisSessionsTableReferences),
          DialysisSession,
          PrefetchHooks Function({bool patientId})
        > {
  $$DialysisSessionsTableTableManager(
    _$AppDatabase db,
    $DialysisSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DialysisSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DialysisSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DialysisSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> preWeightKg = const Value.absent(),
                Value<double?> postWeightKg = const Value.absent(),
                Value<double?> calculatedInterdialyticWeightGainKg =
                    const Value.absent(),
                Value<int?> calculatedUltrafiltrationGoalMl =
                    const Value.absent(),
                Value<int?> targetFluidRemovalMl = const Value.absent(),
                Value<int?> actualFluidRemovedMl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> symptoms = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DialysisSessionsCompanion(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                preWeightKg: preWeightKg,
                postWeightKg: postWeightKg,
                calculatedInterdialyticWeightGainKg:
                    calculatedInterdialyticWeightGainKg,
                calculatedUltrafiltrationGoalMl:
                    calculatedUltrafiltrationGoalMl,
                targetFluidRemovalMl: targetFluidRemovalMl,
                actualFluidRemovedMl: actualFluidRemovedMl,
                notes: notes,
                symptoms: symptoms,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String sessionType,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> preWeightKg = const Value.absent(),
                Value<double?> postWeightKg = const Value.absent(),
                Value<double?> calculatedInterdialyticWeightGainKg =
                    const Value.absent(),
                Value<int?> calculatedUltrafiltrationGoalMl =
                    const Value.absent(),
                Value<int?> targetFluidRemovalMl = const Value.absent(),
                Value<int?> actualFluidRemovedMl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> symptoms = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DialysisSessionsCompanion.insert(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                preWeightKg: preWeightKg,
                postWeightKg: postWeightKg,
                calculatedInterdialyticWeightGainKg:
                    calculatedInterdialyticWeightGainKg,
                calculatedUltrafiltrationGoalMl:
                    calculatedUltrafiltrationGoalMl,
                targetFluidRemovalMl: targetFluidRemovalMl,
                actualFluidRemovedMl: actualFluidRemovedMl,
                notes: notes,
                symptoms: symptoms,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DialysisSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable:
                                    $$DialysisSessionsTableReferences
                                        ._patientIdTable(db),
                                referencedColumn:
                                    $$DialysisSessionsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$DialysisSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DialysisSessionsTable,
      DialysisSession,
      $$DialysisSessionsTableFilterComposer,
      $$DialysisSessionsTableOrderingComposer,
      $$DialysisSessionsTableAnnotationComposer,
      $$DialysisSessionsTableCreateCompanionBuilder,
      $$DialysisSessionsTableUpdateCompanionBuilder,
      (DialysisSession, $$DialysisSessionsTableReferences),
      DialysisSession,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$BloodPressureLogsTableCreateCompanionBuilder =
    BloodPressureLogsCompanion Function({
      required String id,
      required String patientId,
      required int systolic,
      required int diastolic,
      required int pulse,
      required String armUsed,
      Value<bool> isSafeArm,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BloodPressureLogsTableUpdateCompanionBuilder =
    BloodPressureLogsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<int> systolic,
      Value<int> diastolic,
      Value<int> pulse,
      Value<String> armUsed,
      Value<bool> isSafeArm,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BloodPressureLogsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BloodPressureLogsTable,
          BloodPressureLog
        > {
  $$BloodPressureLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('blood_pressure_logs__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BloodPressureLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BloodPressureLogsTable> {
  $$BloodPressureLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get armUsed => $composableBuilder(
    column: $table.armUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSafeArm => $composableBuilder(
    column: $table.isSafeArm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BloodPressureLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BloodPressureLogsTable> {
  $$BloodPressureLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get armUsed => $composableBuilder(
    column: $table.armUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSafeArm => $composableBuilder(
    column: $table.isSafeArm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BloodPressureLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BloodPressureLogsTable> {
  $$BloodPressureLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get systolic =>
      $composableBuilder(column: $table.systolic, builder: (column) => column);

  GeneratedColumn<int> get diastolic =>
      $composableBuilder(column: $table.diastolic, builder: (column) => column);

  GeneratedColumn<int> get pulse =>
      $composableBuilder(column: $table.pulse, builder: (column) => column);

  GeneratedColumn<String> get armUsed =>
      $composableBuilder(column: $table.armUsed, builder: (column) => column);

  GeneratedColumn<bool> get isSafeArm =>
      $composableBuilder(column: $table.isSafeArm, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BloodPressureLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BloodPressureLogsTable,
          BloodPressureLog,
          $$BloodPressureLogsTableFilterComposer,
          $$BloodPressureLogsTableOrderingComposer,
          $$BloodPressureLogsTableAnnotationComposer,
          $$BloodPressureLogsTableCreateCompanionBuilder,
          $$BloodPressureLogsTableUpdateCompanionBuilder,
          (BloodPressureLog, $$BloodPressureLogsTableReferences),
          BloodPressureLog,
          PrefetchHooks Function({bool patientId})
        > {
  $$BloodPressureLogsTableTableManager(
    _$AppDatabase db,
    $BloodPressureLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BloodPressureLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BloodPressureLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BloodPressureLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<int> systolic = const Value.absent(),
                Value<int> diastolic = const Value.absent(),
                Value<int> pulse = const Value.absent(),
                Value<String> armUsed = const Value.absent(),
                Value<bool> isSafeArm = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BloodPressureLogsCompanion(
                id: id,
                patientId: patientId,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                armUsed: armUsed,
                isSafeArm: isSafeArm,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required int systolic,
                required int diastolic,
                required int pulse,
                required String armUsed,
                Value<bool> isSafeArm = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BloodPressureLogsCompanion.insert(
                id: id,
                patientId: patientId,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                armUsed: armUsed,
                isSafeArm: isSafeArm,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BloodPressureLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable:
                                    $$BloodPressureLogsTableReferences
                                        ._patientIdTable(db),
                                referencedColumn:
                                    $$BloodPressureLogsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$BloodPressureLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BloodPressureLogsTable,
      BloodPressureLog,
      $$BloodPressureLogsTableFilterComposer,
      $$BloodPressureLogsTableOrderingComposer,
      $$BloodPressureLogsTableAnnotationComposer,
      $$BloodPressureLogsTableCreateCompanionBuilder,
      $$BloodPressureLogsTableUpdateCompanionBuilder,
      (BloodPressureLog, $$BloodPressureLogsTableReferences),
      BloodPressureLog,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$FluidIntakeLogsTableCreateCompanionBuilder =
    FluidIntakeLogsCompanion Function({
      required String id,
      required String patientId,
      required int volumeMl,
      required String beverageType,
      Value<bool> phosphateBinderTaken,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FluidIntakeLogsTableUpdateCompanionBuilder =
    FluidIntakeLogsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<int> volumeMl,
      Value<String> beverageType,
      Value<bool> phosphateBinderTaken,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FluidIntakeLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FluidIntakeLogsTable, FluidIntakeLog> {
  $$FluidIntakeLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('fluid_intake_logs__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FluidIntakeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FluidIntakeLogsTable> {
  $$FluidIntakeLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beverageType => $composableBuilder(
    column: $table.beverageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get phosphateBinderTaken => $composableBuilder(
    column: $table.phosphateBinderTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidIntakeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FluidIntakeLogsTable> {
  $$FluidIntakeLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beverageType => $composableBuilder(
    column: $table.beverageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get phosphateBinderTaken => $composableBuilder(
    column: $table.phosphateBinderTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidIntakeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FluidIntakeLogsTable> {
  $$FluidIntakeLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get volumeMl =>
      $composableBuilder(column: $table.volumeMl, builder: (column) => column);

  GeneratedColumn<String> get beverageType => $composableBuilder(
    column: $table.beverageType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get phosphateBinderTaken => $composableBuilder(
    column: $table.phosphateBinderTaken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidIntakeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FluidIntakeLogsTable,
          FluidIntakeLog,
          $$FluidIntakeLogsTableFilterComposer,
          $$FluidIntakeLogsTableOrderingComposer,
          $$FluidIntakeLogsTableAnnotationComposer,
          $$FluidIntakeLogsTableCreateCompanionBuilder,
          $$FluidIntakeLogsTableUpdateCompanionBuilder,
          (FluidIntakeLog, $$FluidIntakeLogsTableReferences),
          FluidIntakeLog,
          PrefetchHooks Function({bool patientId})
        > {
  $$FluidIntakeLogsTableTableManager(
    _$AppDatabase db,
    $FluidIntakeLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FluidIntakeLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FluidIntakeLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FluidIntakeLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<int> volumeMl = const Value.absent(),
                Value<String> beverageType = const Value.absent(),
                Value<bool> phosphateBinderTaken = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FluidIntakeLogsCompanion(
                id: id,
                patientId: patientId,
                volumeMl: volumeMl,
                beverageType: beverageType,
                phosphateBinderTaken: phosphateBinderTaken,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required int volumeMl,
                required String beverageType,
                Value<bool> phosphateBinderTaken = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FluidIntakeLogsCompanion.insert(
                id: id,
                patientId: patientId,
                volumeMl: volumeMl,
                beverageType: beverageType,
                phosphateBinderTaken: phosphateBinderTaken,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FluidIntakeLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable:
                                    $$FluidIntakeLogsTableReferences
                                        ._patientIdTable(db),
                                referencedColumn:
                                    $$FluidIntakeLogsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$FluidIntakeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FluidIntakeLogsTable,
      FluidIntakeLog,
      $$FluidIntakeLogsTableFilterComposer,
      $$FluidIntakeLogsTableOrderingComposer,
      $$FluidIntakeLogsTableAnnotationComposer,
      $$FluidIntakeLogsTableCreateCompanionBuilder,
      $$FluidIntakeLogsTableUpdateCompanionBuilder,
      (FluidIntakeLog, $$FluidIntakeLogsTableReferences),
      FluidIntakeLog,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$FluidOutputLogsTableCreateCompanionBuilder =
    FluidOutputLogsCompanion Function({
      required String id,
      required String patientId,
      required int volumeMl,
      required String outputType,
      Value<int?> hematuriaGrade,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FluidOutputLogsTableUpdateCompanionBuilder =
    FluidOutputLogsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<int> volumeMl,
      Value<String> outputType,
      Value<int?> hematuriaGrade,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FluidOutputLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FluidOutputLogsTable, FluidOutputLog> {
  $$FluidOutputLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('fluid_output_logs__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FluidOutputLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FluidOutputLogsTable> {
  $$FluidOutputLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hematuriaGrade => $composableBuilder(
    column: $table.hematuriaGrade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidOutputLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FluidOutputLogsTable> {
  $$FluidOutputLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hematuriaGrade => $composableBuilder(
    column: $table.hematuriaGrade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidOutputLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FluidOutputLogsTable> {
  $$FluidOutputLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get volumeMl =>
      $composableBuilder(column: $table.volumeMl, builder: (column) => column);

  GeneratedColumn<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hematuriaGrade => $composableBuilder(
    column: $table.hematuriaGrade,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FluidOutputLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FluidOutputLogsTable,
          FluidOutputLog,
          $$FluidOutputLogsTableFilterComposer,
          $$FluidOutputLogsTableOrderingComposer,
          $$FluidOutputLogsTableAnnotationComposer,
          $$FluidOutputLogsTableCreateCompanionBuilder,
          $$FluidOutputLogsTableUpdateCompanionBuilder,
          (FluidOutputLog, $$FluidOutputLogsTableReferences),
          FluidOutputLog,
          PrefetchHooks Function({bool patientId})
        > {
  $$FluidOutputLogsTableTableManager(
    _$AppDatabase db,
    $FluidOutputLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FluidOutputLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FluidOutputLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FluidOutputLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<int> volumeMl = const Value.absent(),
                Value<String> outputType = const Value.absent(),
                Value<int?> hematuriaGrade = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FluidOutputLogsCompanion(
                id: id,
                patientId: patientId,
                volumeMl: volumeMl,
                outputType: outputType,
                hematuriaGrade: hematuriaGrade,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required int volumeMl,
                required String outputType,
                Value<int?> hematuriaGrade = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FluidOutputLogsCompanion.insert(
                id: id,
                patientId: patientId,
                volumeMl: volumeMl,
                outputType: outputType,
                hematuriaGrade: hematuriaGrade,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FluidOutputLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable:
                                    $$FluidOutputLogsTableReferences
                                        ._patientIdTable(db),
                                referencedColumn:
                                    $$FluidOutputLogsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$FluidOutputLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FluidOutputLogsTable,
      FluidOutputLog,
      $$FluidOutputLogsTableFilterComposer,
      $$FluidOutputLogsTableOrderingComposer,
      $$FluidOutputLogsTableAnnotationComposer,
      $$FluidOutputLogsTableCreateCompanionBuilder,
      $$FluidOutputLogsTableUpdateCompanionBuilder,
      (FluidOutputLog, $$FluidOutputLogsTableReferences),
      FluidOutputLog,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$CatheterEventsTableCreateCompanionBuilder =
    CatheterEventsCompanion Function({
      required String id,
      required String patientId,
      required String catheterType,
      required DateTime insertionDate,
      required DateTime replacementDueDate,
      required String status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CatheterEventsTableUpdateCompanionBuilder =
    CatheterEventsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> catheterType,
      Value<DateTime> insertionDate,
      Value<DateTime> replacementDueDate,
      Value<String> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CatheterEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CatheterEventsTable, CatheterEvent> {
  $$CatheterEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('catheter_events__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CatheterEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CatheterEventsTable> {
  $$CatheterEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catheterType => $composableBuilder(
    column: $table.catheterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get insertionDate => $composableBuilder(
    column: $table.insertionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get replacementDueDate => $composableBuilder(
    column: $table.replacementDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatheterEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatheterEventsTable> {
  $$CatheterEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catheterType => $composableBuilder(
    column: $table.catheterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get insertionDate => $composableBuilder(
    column: $table.insertionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get replacementDueDate => $composableBuilder(
    column: $table.replacementDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatheterEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatheterEventsTable> {
  $$CatheterEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get catheterType => $composableBuilder(
    column: $table.catheterType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get insertionDate => $composableBuilder(
    column: $table.insertionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get replacementDueDate => $composableBuilder(
    column: $table.replacementDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatheterEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatheterEventsTable,
          CatheterEvent,
          $$CatheterEventsTableFilterComposer,
          $$CatheterEventsTableOrderingComposer,
          $$CatheterEventsTableAnnotationComposer,
          $$CatheterEventsTableCreateCompanionBuilder,
          $$CatheterEventsTableUpdateCompanionBuilder,
          (CatheterEvent, $$CatheterEventsTableReferences),
          CatheterEvent,
          PrefetchHooks Function({bool patientId})
        > {
  $$CatheterEventsTableTableManager(
    _$AppDatabase db,
    $CatheterEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatheterEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatheterEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatheterEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> catheterType = const Value.absent(),
                Value<DateTime> insertionDate = const Value.absent(),
                Value<DateTime> replacementDueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatheterEventsCompanion(
                id: id,
                patientId: patientId,
                catheterType: catheterType,
                insertionDate: insertionDate,
                replacementDueDate: replacementDueDate,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String catheterType,
                required DateTime insertionDate,
                required DateTime replacementDueDate,
                required String status,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatheterEventsCompanion.insert(
                id: id,
                patientId: patientId,
                catheterType: catheterType,
                insertionDate: insertionDate,
                replacementDueDate: replacementDueDate,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CatheterEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable: $$CatheterEventsTableReferences
                                    ._patientIdTable(db),
                                referencedColumn:
                                    $$CatheterEventsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$CatheterEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatheterEventsTable,
      CatheterEvent,
      $$CatheterEventsTableFilterComposer,
      $$CatheterEventsTableOrderingComposer,
      $$CatheterEventsTableAnnotationComposer,
      $$CatheterEventsTableCreateCompanionBuilder,
      $$CatheterEventsTableUpdateCompanionBuilder,
      (CatheterEvent, $$CatheterEventsTableReferences),
      CatheterEvent,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$AccessInspectionsTableCreateCompanionBuilder =
    AccessInspectionsCompanion Function({
      required String id,
      required String patientId,
      required String accessType,
      required String anatomicalLocation,
      Value<bool?> thrillPresent,
      Value<bool?> bruitPresent,
      Value<bool?> rednessPresent,
      Value<bool?> dischargePresent,
      Value<bool?> painPresent,
      Value<String?> notes,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AccessInspectionsTableUpdateCompanionBuilder =
    AccessInspectionsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> accessType,
      Value<String> anatomicalLocation,
      Value<bool?> thrillPresent,
      Value<bool?> bruitPresent,
      Value<bool?> rednessPresent,
      Value<bool?> dischargePresent,
      Value<bool?> painPresent,
      Value<String?> notes,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AccessInspectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccessInspectionsTable,
          AccessInspection
        > {
  $$AccessInspectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('access_inspections__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccessInspectionsTableFilterComposer
    extends Composer<_$AppDatabase, $AccessInspectionsTable> {
  $$AccessInspectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anatomicalLocation => $composableBuilder(
    column: $table.anatomicalLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thrillPresent => $composableBuilder(
    column: $table.thrillPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bruitPresent => $composableBuilder(
    column: $table.bruitPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rednessPresent => $composableBuilder(
    column: $table.rednessPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dischargePresent => $composableBuilder(
    column: $table.dischargePresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get painPresent => $composableBuilder(
    column: $table.painPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessInspectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccessInspectionsTable> {
  $$AccessInspectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anatomicalLocation => $composableBuilder(
    column: $table.anatomicalLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thrillPresent => $composableBuilder(
    column: $table.thrillPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bruitPresent => $composableBuilder(
    column: $table.bruitPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rednessPresent => $composableBuilder(
    column: $table.rednessPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dischargePresent => $composableBuilder(
    column: $table.dischargePresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get painPresent => $composableBuilder(
    column: $table.painPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessInspectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccessInspectionsTable> {
  $$AccessInspectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anatomicalLocation => $composableBuilder(
    column: $table.anatomicalLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get thrillPresent => $composableBuilder(
    column: $table.thrillPresent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bruitPresent => $composableBuilder(
    column: $table.bruitPresent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rednessPresent => $composableBuilder(
    column: $table.rednessPresent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dischargePresent => $composableBuilder(
    column: $table.dischargePresent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get painPresent => $composableBuilder(
    column: $table.painPresent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessInspectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccessInspectionsTable,
          AccessInspection,
          $$AccessInspectionsTableFilterComposer,
          $$AccessInspectionsTableOrderingComposer,
          $$AccessInspectionsTableAnnotationComposer,
          $$AccessInspectionsTableCreateCompanionBuilder,
          $$AccessInspectionsTableUpdateCompanionBuilder,
          (AccessInspection, $$AccessInspectionsTableReferences),
          AccessInspection,
          PrefetchHooks Function({bool patientId})
        > {
  $$AccessInspectionsTableTableManager(
    _$AppDatabase db,
    $AccessInspectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccessInspectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccessInspectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccessInspectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> accessType = const Value.absent(),
                Value<String> anatomicalLocation = const Value.absent(),
                Value<bool?> thrillPresent = const Value.absent(),
                Value<bool?> bruitPresent = const Value.absent(),
                Value<bool?> rednessPresent = const Value.absent(),
                Value<bool?> dischargePresent = const Value.absent(),
                Value<bool?> painPresent = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccessInspectionsCompanion(
                id: id,
                patientId: patientId,
                accessType: accessType,
                anatomicalLocation: anatomicalLocation,
                thrillPresent: thrillPresent,
                bruitPresent: bruitPresent,
                rednessPresent: rednessPresent,
                dischargePresent: dischargePresent,
                painPresent: painPresent,
                notes: notes,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String accessType,
                required String anatomicalLocation,
                Value<bool?> thrillPresent = const Value.absent(),
                Value<bool?> bruitPresent = const Value.absent(),
                Value<bool?> rednessPresent = const Value.absent(),
                Value<bool?> dischargePresent = const Value.absent(),
                Value<bool?> painPresent = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccessInspectionsCompanion.insert(
                id: id,
                patientId: patientId,
                accessType: accessType,
                anatomicalLocation: anatomicalLocation,
                thrillPresent: thrillPresent,
                bruitPresent: bruitPresent,
                rednessPresent: rednessPresent,
                dischargePresent: dischargePresent,
                painPresent: painPresent,
                notes: notes,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccessInspectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable:
                                    $$AccessInspectionsTableReferences
                                        ._patientIdTable(db),
                                referencedColumn:
                                    $$AccessInspectionsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$AccessInspectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccessInspectionsTable,
      AccessInspection,
      $$AccessInspectionsTableFilterComposer,
      $$AccessInspectionsTableOrderingComposer,
      $$AccessInspectionsTableAnnotationComposer,
      $$AccessInspectionsTableCreateCompanionBuilder,
      $$AccessInspectionsTableUpdateCompanionBuilder,
      (AccessInspection, $$AccessInspectionsTableReferences),
      AccessInspection,
      PrefetchHooks Function({bool patientId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$DialysisSessionsTableTableManager get dialysisSessions =>
      $$DialysisSessionsTableTableManager(_db, _db.dialysisSessions);
  $$BloodPressureLogsTableTableManager get bloodPressureLogs =>
      $$BloodPressureLogsTableTableManager(_db, _db.bloodPressureLogs);
  $$FluidIntakeLogsTableTableManager get fluidIntakeLogs =>
      $$FluidIntakeLogsTableTableManager(_db, _db.fluidIntakeLogs);
  $$FluidOutputLogsTableTableManager get fluidOutputLogs =>
      $$FluidOutputLogsTableTableManager(_db, _db.fluidOutputLogs);
  $$CatheterEventsTableTableManager get catheterEvents =>
      $$CatheterEventsTableTableManager(_db, _db.catheterEvents);
  $$AccessInspectionsTableTableManager get accessInspections =>
      $$AccessInspectionsTableTableManager(_db, _db.accessInspections);
}
