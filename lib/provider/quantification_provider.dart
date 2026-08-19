import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/quantification_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class QuantificationProvider extends ChangeNotifier {
  static const String baseUrl = 'https://sams.acstechnologies.co.in';

  List<QuantificationEntry> structural = [];
  List<QuantificationEntry> nonStructural = [];
  bool isLoading = false;

  void setQuantifications({
    required List<QuantificationEntry> structuralEntries,
    required List<QuantificationEntry> nonStructuralEntries,
  }) {
    structural = structuralEntries;
    nonStructural = nonStructuralEntries;
    notifyListeners();
  }

  Future<bool> loadForFlat({
    required String structureId,
    required String floorId,
    required String flatId,
    required BuildContext context,
  }) async {
    final dio = Dio();
    final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
    isLoading = true;
    notifyListeners();
    try {
      final response = await dio.get(
        '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/quantifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      final quantifications = data['data']?['quantifications'] ?? {};
      final structuralRaw = (quantifications['structural'] ?? []) as List;
      final nonStructuralRaw = (quantifications['non_structural'] ?? []) as List;

      structural = structuralRaw.map((e) => QuantificationEntry.fromJson(Map<String, dynamic>.from(e))).toList();
      nonStructural = nonStructuralRaw.map((e) => QuantificationEntry.fromJson(Map<String, dynamic>.from(e))).toList();
      return true;
    } catch (e) {
      // If nothing saved yet, keep empty lists
      structural = [];
      nonStructural = [];
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadForFloor({
    required String structureId,
    required String floorId,
    required BuildContext context,
  }) async {
    final dio = Dio();
    final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
    isLoading = true;
    notifyListeners();
    try {
      final response = await dio.get(
        '$baseUrl/api/structures/$structureId/floors/$floorId/quantifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      final quantifications = data['data']?['quantifications'] ?? {};
      final structuralRaw = (quantifications['structural'] ?? []) as List;
      final nonStructuralRaw = (quantifications['non_structural'] ?? []) as List;

      structural = structuralRaw.map((e) => QuantificationEntry.fromJson(Map<String, dynamic>.from(e))).toList();
      nonStructural = nonStructuralRaw.map((e) => QuantificationEntry.fromJson(Map<String, dynamic>.from(e))).toList();
      return true;
    } catch (e) {
      structural = [];
      nonStructural = [];
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveForFlat({
    required String structureId,
    required String floorId,
    required String flatId,
    required BuildContext context,
    required List<QuantificationEntry> structuralEntries,
    required List<QuantificationEntry> nonStructuralEntries,
  }) async {
    final dio = Dio();
    final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
    try {
      await dio.post(
        '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/quantifications',
        data: {
          'structural': structuralEntries.map((e) => e.toJson()).toList(),
          'non_structural': nonStructuralEntries.map((e) => e.toJson()).toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      CustomToast.showSuccessToast(msg: 'Quantifications saved successfully');
    } catch (e) {
      CustomToast.showErrorToast(msg: 'Failed to save quantifications');
      rethrow;
    }
  }

  Future<void> saveForFloor({
    required String structureId,
    required String floorId,
    required BuildContext context,
    required List<QuantificationEntry> structuralEntries,
    required List<QuantificationEntry> nonStructuralEntries,
  }) async {
    final dio = Dio();
    final token = Provider.of<CommonProvider>(context, listen: false).accessToken;
    try {
      await dio.post(
        '$baseUrl/api/structures/$structureId/floors/$floorId/quantifications',
        data: {
          'structural': structuralEntries.map((e) => e.toJson()).toList(),
          'non_structural': nonStructuralEntries.map((e) => e.toJson()).toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      CustomToast.showSuccessToast(msg: 'Quantifications saved successfully');
    } catch (e) {
      CustomToast.showErrorToast(msg: 'Failed to save quantifications');
      rethrow;
    }
  }
}
