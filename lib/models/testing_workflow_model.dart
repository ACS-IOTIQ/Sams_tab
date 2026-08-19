class TestingWorkflowResponse {
  final bool success;
  final String message;
  final TestingWorkflowData data;

  const TestingWorkflowResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TestingWorkflowResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = _asMap(json['data']) ?? json;

    return TestingWorkflowResponse(
      success: json['success'] == true,
      message: _asString(json['message']) ?? '',
      data: TestingWorkflowData.fromJson(dataMap),
    );
  }
}

class TestingWorkflowData {
  final String structureId;
  final TestingWorkflow workflow;
  final TestingAssignment? testingAssignment;
  final List<TestingTimelineItem> timeline;

  const TestingWorkflowData({
    required this.structureId,
    required this.workflow,
    required this.testingAssignment,
    required this.timeline,
  });

  factory TestingWorkflowData.fromJson(Map<String, dynamic> json) {
    final workflowMap =
        _asMap(json['workflow']) ?? _asMap(json['data']) ?? json;
    final assignmentMap = _asMap(json['testing_assignment']);

    final timelineSource =
        _asList(json['timeline']) ??
        _asList(json['history']) ??
        _asList(workflowMap['timeline']) ??
        _asList(workflowMap['history']) ??
        const <dynamic>[];

    return TestingWorkflowData(
      structureId:
          _asString(json['structure_id']) ??
          _asString(workflowMap['structure_id']) ??
          '',
      workflow: TestingWorkflow.fromJson(workflowMap),
      testingAssignment: assignmentMap == null
          ? null
          : TestingAssignment.fromJson(assignmentMap),
      timeline: timelineSource
          .map((item) => TestingTimelineItem.fromJson(_asMap(item)))
          .whereType<TestingTimelineItem>()
          .toList(),
    );
  }
}

class TestingWorkflow {
  final String status;
  final String assignedAt;
  final String updatedAt;

  const TestingWorkflow({
    required this.status,
    required this.assignedAt,
    required this.updatedAt,
  });

  factory TestingWorkflow.fromJson(Map<String, dynamic>? json) {
    final map = json ?? <String, dynamic>{};
    return TestingWorkflow(
      status:
          _asString(map['status']) ??
          _asString(map['current_status']) ??
          _asString(map['workflow_status']) ??
          '',
      assignedAt:
          _asString(map['assigned_at']) ??
          _asString(map['submitted_at']) ??
          '',
      updatedAt:
          _asString(map['updated_at']) ??
          _asString(map['last_updated_at']) ??
          '',
    );
  }
}

class TestingAssignment {
  final String assignedAt;
  final TestingActor? assignedBy;
  final List<TestingActor> testers;
  final List<TestingFormat> testingFormats;

  const TestingAssignment({
    required this.assignedAt,
    required this.assignedBy,
    required this.testers,
    required this.testingFormats,
  });

  factory TestingAssignment.fromJson(Map<String, dynamic> json) {
    final testersList = _asList(json['testers']) ?? const <dynamic>[];
    final formatsList = _asList(json['testing_formats']) ?? const <dynamic>[];

    return TestingAssignment(
      assignedAt: _asString(json['assigned_at']) ?? '',
      assignedBy: TestingActor.fromUnknown(json['assigned_by']),
      testers: testersList
          .map(TestingActor.fromUnknown)
          .whereType<TestingActor>()
          .toList(),
      testingFormats: formatsList
          .map(TestingFormat.fromUnknown)
          .whereType<TestingFormat>()
          .toList(),
    );
  }
}

class TestingActor {
  final String id;
  final String name;
  final String role;

  const TestingActor({
    required this.id,
    required this.name,
    required this.role,
  });

  String get displayLabel {
    if (role.isEmpty) return name;
    if (name.isEmpty) return role;
    return '$name ($role)';
  }

  static TestingActor? fromUnknown(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return TestingActor(id: '', name: value.trim(), role: '');
    }

    final map = _asMap(value);
    if (map == null) return null;

    return TestingActor(
      id: _asString(map['_id']) ?? _asString(map['id']) ?? '',
      name:
          _asString(map['name']) ??
          _asString(map['username']) ??
          _asString(map['email']) ??
          '',
      role: _asString(map['role']) ?? '',
    );
  }
}

class TestingFormat {
  final String id;
  final String name;
  final String slug;
  final String formatType;
  final String layout;
  final List<TestingDynamicField> fields;

  const TestingFormat({
    required this.id,
    required this.name,
    required this.slug,
    required this.formatType,
    required this.layout,
    required this.fields,
  });

  String get normalizedKey {
    if (slug.isNotEmpty) return slug;
    return name
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool get isDynamic =>
      formatType.toLowerCase() == 'dynamic' ||
      layout.isNotEmpty ||
      fields.isNotEmpty;

  static TestingFormat? fromUnknown(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return TestingFormat(
        id: '',
        name: value.trim(),
        slug: '',
        formatType: '',
        layout: '',
        fields: const [],
      );
    }

    final map = _asMap(value);
    if (map == null) return null;

    final name =
        _asString(map['name']) ??
        _asString(map['format']) ??
        _asString(map['label']) ??
        '';
    if (name.isEmpty) return null;

    return TestingFormat(
      id: _asString(map['_id']) ?? _asString(map['id']) ?? '',
      name: name,
      slug:
          _asString(map['slug']) ??
          _asString(map['code']) ??
          _asString(map['key']) ??
          '',
      formatType:
          _asString(map['type']) ??
          _asString(map['format_type']) ??
          '',
      layout:
          _asString(map['layout']) ??
          _asString(map['view_type']) ??
          '',
      fields: (_asList(map['fields']) ?? const <dynamic>[])
          .map((field) => TestingDynamicField.fromJson(_asMap(field)))
          .whereType<TestingDynamicField>()
          .toList(),
    );
  }
}

class TestingDynamicField {
  final String key;
  final String label;
  final String type;
  final bool required;
  final List<String> options;
  final bool readOnly;

  const TestingDynamicField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.options,
    required this.readOnly,
  });

  factory TestingDynamicField.fromJson(Map<String, dynamic>? json) {
    final map = json ?? <String, dynamic>{};
    final options = (_asList(map['options']) ?? const <dynamic>[])
        .map((option) => _asString(option) ?? '')
        .where((option) => option.isNotEmpty)
        .toList();

    return TestingDynamicField(
      key: _asString(map['key']) ?? '',
      label:
          _asString(map['label']) ??
          _asString(map['name']) ??
          _asString(map['key']) ??
          'Field',
      type: _asString(map['type']) ?? 'text',
      required: map['required'] == true,
      options: options,
      readOnly: map['read_only'] == true || map['readonly'] == true,
    );
  }
}

class TestingTimelineItem {
  final String title;
  final String status;
  final String actor;
  final String timestamp;
  final String notes;

  const TestingTimelineItem({
    required this.title,
    required this.status,
    required this.actor,
    required this.timestamp,
    required this.notes,
  });

  factory TestingTimelineItem.fromJson(Map<String, dynamic>? json) {
    final map = json ?? <String, dynamic>{};
    return TestingTimelineItem(
      title:
          _asString(map['title']) ??
          _asString(map['action']) ??
          _asString(map['event']) ??
          _asString(map['status']) ??
          'Workflow update',
      status: _asString(map['status']) ?? '',
      actor:
          _asString(map['actor_name']) ??
          _asString(map['performed_by']) ??
          _asString(map['user_name']) ??
          '',
      timestamp:
          _asString(map['created_at']) ??
          _asString(map['timestamp']) ??
          _asString(map['date']) ??
          '',
      notes:
          _asString(map['notes']) ??
          _asString(map['test_notes']) ??
          _asString(map['rejection_reason']) ??
          '',
    );
  }
}

class CompleteTestingRequest {
  final String status;
  final String? testNotes;
  final String? rejectionReason;

  const CompleteTestingRequest({
    required this.status,
    this.testNotes,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      if (testNotes != null && testNotes!.trim().isNotEmpty)
        'test_notes': testNotes!.trim(),
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty)
        'rejection_reason': rejectionReason!.trim(),
    };
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
  }
  return null;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List) return value;
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  return null;
}
