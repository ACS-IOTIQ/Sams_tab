import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/token_http_client.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class TestingProvider extends ChangeNotifier {
  TestingWorkflowResponse? _workflowResponse;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  TestingWorkflowResponse? get workflowResponse => _workflowResponse;
  TestingWorkflowData? get workflowData => _workflowResponse?.data;
  TestingAssignment? get testingAssignment => workflowData?.testingAssignment;
  List<TestingTimelineItem> get timeline => workflowData?.timeline ?? const [];
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  String get workflowStatus => workflowData?.workflow.status ?? '';

  bool get canSubmitForTesting => workflowStatus.toLowerCase() == 'submitted';
  bool get canStartTesting => workflowStatus.toLowerCase() == 'submitted';
  bool get canCompleteTesting => workflowStatus.toLowerCase() == 'under_testing';

  Future<void> fetchWorkflow(
    BuildContext context,
    String structureId, {
    bool showLoader = true,
  }) async {
    if (showLoader) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final token = Provider.of<CommonProvider>(
        context,
        listen: false,
      ).accessToken;
      final url = Uri.parse(
        '${CommonProvider.baseUrl}/api/structures/$structureId/workflow',
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
        _workflowResponse = TestingWorkflowResponse.fromJson(decoded);
        _errorMessage = null;
      } else {
        _errorMessage = _extractErrorMessage(response.body);
      }
    } catch (e) {
      _errorMessage = 'Failed to load testing workflow.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitForTesting(
    BuildContext context,
    String structureId,
  ) async {
    return _postWorkflowAction(
      context: context,
      structureId: structureId,
      path: 'submit-for-testing',
      body: const <String, dynamic>{},
      fallbackSuccessMessage: 'Structure submitted for testing successfully.',
    );
  }

  Future<bool> startTesting(BuildContext context, String structureId) async {
    return _postWorkflowAction(
      context: context,
      structureId: structureId,
      path: 'start-testing',
      body: null,
      fallbackSuccessMessage: 'Testing started successfully.',
    );
  }

  Future<bool> completeTesting(
    BuildContext context,
    String structureId,
    CompleteTestingRequest request,
  ) async {
    return _postWorkflowAction(
      context: context,
      structureId: structureId,
      path: 'complete-testing',
      body: request.toJson(),
      fallbackSuccessMessage: request.status == 'rejected'
          ? 'Testing rejected successfully.'
          : 'Testing completed successfully.',
    );
  }

  Future<bool> _postWorkflowAction({
    required BuildContext context,
    required String structureId,
    required String path,
    required Map<String, dynamic>? body,
    required String fallbackSuccessMessage,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = Provider.of<CommonProvider>(
        context,
        listen: false,
      ).accessToken;
      final url = Uri.parse(
        '${CommonProvider.baseUrl}/api/structures/$structureId/$path',
      );

      final response = await TokenAwareHttpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = _extractSuccessMessage(response.body) ??
            fallbackSuccessMessage;
        await fetchWorkflow(context, structureId, showLoader: false);
        await CustomToast.showSuccessToast(msg: message);
        return true;
      }

      CustomToast.showErrorToast(
        msg: _extractErrorMessage(response.body),
      );
      return false;
    } catch (e) {
      CustomToast.showErrorToast(msg: 'Something went wrong. Please try again.');
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  String? _extractSuccessMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'] ?? decoded['message'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {}
    return 'Request failed. Please try again.';
  }
}
