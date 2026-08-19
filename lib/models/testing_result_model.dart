class TestingResultItem {
  final String testId;
  final String testName;
  final String componentType;
  final String componentId;
  final String testDate;
  final Map<String, dynamic> testResults;
  final String testedBy;
  final String remarks;
  final Map<String, dynamic>? testReportPdf;

  const TestingResultItem({
    required this.testId,
    required this.testName,
    required this.componentType,
    required this.componentId,
    required this.testDate,
    required this.testResults,
    required this.testedBy,
    required this.remarks,
    required this.testReportPdf,
  });

  factory TestingResultItem.fromJson(Map<String, dynamic> json) {
    return TestingResultItem(
      testId: _asString(json['test_id']) ?? '',
      testName: _asString(json['test_name']) ?? '',
      componentType: _asString(json['component_type']) ?? '',
      componentId: _asString(json['component_id']) ?? '',
      testDate: _asString(json['test_date']) ?? '',
      testResults: _asMap(json['test_results']) ?? const <String, dynamic>{},
      testedBy: _asString(json['tested_by']) ?? '',
      remarks: _asString(json['remarks']) ?? '',
      testReportPdf: _asMap(json['test_report_pdf']),
    );
  }
}

class TestingResultListResponse {
  final bool success;
  final String message;
  final String scope;
  final String targetLabel;
  final List<TestingResultItem> results;

  const TestingResultListResponse({
    required this.success,
    required this.message,
    required this.scope,
    required this.targetLabel,
    required this.results,
  });

  factory TestingResultListResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? const <String, dynamic>{};
    final rawResults = _asList(data['results']) ?? const <dynamic>[];
    return TestingResultListResponse(
      success: json['success'] == true,
      message: _asString(json['message']) ?? '',
      scope: _asString(data['scope']) ?? '',
      targetLabel: _asString(data['target_label']) ?? '',
      results: rawResults
          .map((item) => _asMap(item))
          .whereType<Map<String, dynamic>>()
          .map(TestingResultItem.fromJson)
          .toList(),
    );
  }
}

class TestingResultMutationResponse {
  final bool success;
  final String message;
  final TestingResultItem? result;

  const TestingResultMutationResponse({
    required this.success,
    required this.message,
    required this.result,
  });

  factory TestingResultMutationResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? const <String, dynamic>{};
    return TestingResultMutationResponse(
      success: json['success'] == true,
      message: _asString(json['message']) ?? '',
      result: _asMap(data['result']) == null
          ? null
          : TestingResultItem.fromJson(_asMap(data['result'])!),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
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
