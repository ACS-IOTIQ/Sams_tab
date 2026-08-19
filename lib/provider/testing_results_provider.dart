import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/testing_result_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/token_http_client.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class TestingResultsProvider extends ChangeNotifier {
  final Map<String, List<TestingResultItem>> _resultsByStructure =
      <String, List<TestingResultItem>>{};
  final Set<String> _loadingStructures = <String>{};
  final Set<String> _savingKeys = <String>{};

  List<TestingResultItem> resultsForStructure(String structureId) {
    return _resultsByStructure[structureId] ?? const <TestingResultItem>[];
  }

  bool isLoadingStructure(String structureId) {
    return _loadingStructures.contains(structureId);
  }

  bool isSaving(String structureId, String testName) {
    return _savingKeys.contains(_saveKey(structureId, testName));
  }

  TestingResultItem? findStructureResult(
    String structureId,
    String testName, {
    String componentId = 'structure_main',
  }) {
    final results = resultsForStructure(structureId);
    for (final result in results) {
      if (result.testName == testName && result.componentId == componentId) {
        return result;
      }
    }
    return null;
  }

  Future<void> fetchStructureResults(
    BuildContext context,
    String structureId,
  ) async {
    if (structureId.trim().isEmpty) return;

    _loadingStructures.add(structureId);
    notifyListeners();

    try {
      final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
      final url = Uri.parse(
        '${CommonProvider.baseUrl}/api/structures/$structureId/test-results',
      );

      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = TestingResultListResponse.fromJson(decoded);
        _resultsByStructure[structureId] = parsed.results;
      } else {
        CustomToast.showErrorToast(msg: _extractErrorMessage(response.body));
      }
    } catch (_) {
      CustomToast.showErrorToast(msg: 'Failed to load test results.');
    } finally {
      _loadingStructures.remove(structureId);
      notifyListeners();
    }
  }

  Future<bool> upsertStructureResult(
    BuildContext context,
    String structureId, {
    required Map<String, dynamic> payload,
  }) async {
    final testName = (payload['test_name'] ?? '').toString().trim();
    if (structureId.trim().isEmpty || testName.isEmpty) return false;

    final existing = findStructureResult(structureId, testName);
    final saveKey = _saveKey(structureId, testName);
    _savingKeys.add(saveKey);
    notifyListeners();

    try {
      final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
      final isUpdate = existing != null;
      final url = Uri.parse(
        isUpdate
            ? '${CommonProvider.baseUrl}/api/structures/$structureId/test-results/${existing.testId}'
            : '${CommonProvider.baseUrl}/api/structures/$structureId/test-results',
      );

      final response = isUpdate
          ? await TokenAwareHttpClient.put(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await TokenAwareHttpClient.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = TestingResultMutationResponse.fromJson(decoded);
        final updatedResult = parsed.result;
        if (updatedResult != null) {
          final current = List<TestingResultItem>.from(
            _resultsByStructure[structureId] ?? const <TestingResultItem>[],
          );
          final index = current.indexWhere((item) => item.testId == updatedResult.testId);
          if (index >= 0) {
            current[index] = updatedResult;
          } else {
            current.add(updatedResult);
          }
          _resultsByStructure[structureId] = current;
        }
        await CustomToast.showSuccessToast(msg: parsed.message.isNotEmpty ? parsed.message : 'Test result saved successfully');
        notifyListeners();
        return true;
      }

      CustomToast.showErrorToast(msg: _extractErrorMessage(response.body));
      return false;
    } catch (_) {
      CustomToast.showErrorToast(msg: 'Failed to save test result.');
      return false;
    } finally {
      _savingKeys.remove(saveKey);
      notifyListeners();
    }
  }

  String _saveKey(String structureId, String testName) {
    return '$structureId::$testName';
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['error'] ?? decoded['message'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {}
    return 'Request failed. Please try again.';
  }
}
