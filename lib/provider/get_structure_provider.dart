// ignore_for_file: avoid_print, use_build_context_synchronously, prefer_final_fields

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/floor_idby_flatby_strid_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_administrativeby_strId_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_all_structures_model.dart';
import 'package:sams_engineering_console/models/get_floor_bystrid_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_geometricby_strid_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_locationby_strid_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_all_ratings_flat_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_all_ratings_floors_model.dart'
    hide Data;
import 'package:sams_engineering_console/models/get_remarks_stdid_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/token_http_client.dart';
import 'package:sams_engineering_console/utils/custom_bottomsheet.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

enum ReportDownloadFormat { pdf, word }

extension ReportDownloadFormatX on ReportDownloadFormat {
  String get label => this == ReportDownloadFormat.pdf ? 'PDF' : 'Word';

  String get queryValue => this == ReportDownloadFormat.pdf ? 'pdf' : 'word';

  String get defaultExtension =>
      this == ReportDownloadFormat.pdf ? 'pdf' : 'doc';

  String get mimeType => this == ReportDownloadFormat.pdf
      ? 'application/pdf'
      : 'application/msword';
}

class _StoragePermissionSheet extends StatelessWidget {
  const _StoragePermissionSheet({
    required this.title,
    required this.message,
    required this.showSettingsButton,
  });

  final String title;
  final String message;
  final bool showSettingsButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xffD0D5DD),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: Color(0xff155EEF),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xff101828),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xff475467),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (showSettingsButton) {
                        await openAppSettings();
                      }
                    },
                    child: Text(
                      showSettingsButton ? 'Open settings' : 'Continue',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportDownloadState {
  const ReportDownloadState({
    this.isDownloading = false,
    this.progress,
    this.format,
    this.errorMessage,
    this.savedPath,
  });

  final bool isDownloading;
  final double? progress;
  final ReportDownloadFormat? format;
  final String? errorMessage;
  final String? savedPath;

  ReportDownloadState copyWith({
    bool? isDownloading,
    double? progress,
    bool clearProgress = false,
    ReportDownloadFormat? format,
    bool clearFormat = false,
    String? errorMessage,
    bool clearError = false,
    String? savedPath,
    bool clearSavedPath = false,
  }) {
    return ReportDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: clearProgress ? null : (progress ?? this.progress),
      format: clearFormat ? null : (format ?? this.format),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedPath: clearSavedPath ? null : (savedPath ?? this.savedPath),
    );
  }
}

class GetstructureProvider extends ChangeNotifier {
  static const String baseUrl = 'https://sams.acstechnologies.co.in';
  static const int _downloadRetryAttempts = 2;
  final Map<String, GetFloorsDetailsByStrId> _floorsCacheByStructureId = {};
  final Set<String> _floorsRequestsInFlight = <String>{};
  final Map<String, ReportDownloadState> _reportDownloads =
      <String, ReportDownloadState>{};
  bool _isLoadingFloors = false;
  String? _floorsError;

  GetAllStructures? _structureData;

  GetAllStructures? get structureData => _structureData;

  /// Return the list of structures (Datum) safely
  List<Datum> get structureList => _structureData?.data ?? [];

  Future<void> getStructures(BuildContext context, {int page = 1}) async {
    final url = Uri.parse('$baseUrl/api/structures?page=$page');

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final response = await TokenAwareHttpClient.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      context: context,
    );

    if (response.statusCode == 200) {
      final decodedJson = jsonDecode(response.body);
      print("API Response for page $page: $decodedJson");

      _structureData = GetAllStructures.fromJson(decodedJson);
      notifyListeners();
    } else {
      throw Exception(
        'Failed to load structures. Status code: ${response.statusCode}',
      );
    }
  }

  GetLocationDetailsByStrId? _getLocationDetailsByStrId;
  GetLocationDetailsByStrId? get getLocationDetailsByStrId =>
      _getLocationDetailsByStrId;

  Future<void> fetchLocationDetails({
    required String structureId,
    required BuildContext context,
  }) async {
    final url = Uri.parse('$baseUrl/api/structures/$structureId/location');
    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    try {
      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        // 🔍 DEBUGGING: Print the raw JSON response
        print('=== RAW API RESPONSE ===');
        print(response.body);
        print('======================');

        final jsonResponse = jsonDecode(response.body);

        // 🔍 DEBUGGING: Print the location object specifically
        print('=== LOCATION OBJECT ===');
        print('Location data: ${jsonResponse['data']['location']}');
        print(
          'Latitude in JSON: ${jsonResponse['data']['location']['latitude']}',
        );
        print(
          'Longitude in JSON: ${jsonResponse['data']['location']['longitude']}',
        );
        print('======================');

        final parsedData = GetLocationDetailsByStrId.fromJson(jsonResponse);

        // Your existing print statements
        print('Success: ${parsedData.success}');
        print('Structure ID: ${parsedData.data.structureId}');
        print('UID: ${parsedData.data.uid}');
        print('Address: ${parsedData.data.location.address}');
        print('Latitude: ${parsedData.data.location.latitude}');
        print('Longitude: ${parsedData.data.location.longitude}');
        print('City Name: ${parsedData.data.location.cityName}');
        print('Zip Code: ${parsedData.data.location.zipCode}');

        _getLocationDetailsByStrId = parsedData;
        notifyListeners();
      } else {
        print('Failed to fetch. Status code: ${response.statusCode}');
        throw Exception('Failed to load location details.');
      }
    } catch (e) {
      print('Error in getLocationDetailsByStructureId: $e');
      throw Exception('Error fetching location details: $e');
    }
  }

  GetAdminstrativeDetailsByStrId? _getAdminstrativeDetailsByStrIdModel;

  GetAdminstrativeDetailsByStrId? get getAdminstrativeDetailsByStrIdModel =>
      _getAdminstrativeDetailsByStrIdModel;

  void clearAdministrativeDetails() {
    _getAdminstrativeDetailsByStrIdModel = null;
    notifyListeners();
  }

  Future<void> getAdministrativeDetailsByStructureId({
    required String structureId,
    required BuildContext context,
  }) async {
    print(
      "🔵 Starting getAdministrativeDetailsByStructureId for ID: $structureId",
    );

    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/administrative',
    );

    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    print("🔵 URL: $url");
    print("🔵 Token exists: ${token.isNotEmpty}");

    try {
      print("🔵 About to make HTTP request...");

      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      print("🔵 Response received - Status: ${response.statusCode}");
      print("🔵 Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("🔵 Parsing response...");

        final parsedData = GetAdminstrativeDetailsByStrId.fromJson(
          jsonDecode(response.body),
        );

        _getAdminstrativeDetailsByStrIdModel = parsedData;
        print("🔵 Data successfully parsed and stored");
        notifyListeners();
      } else {
        print('🔴 Failed to fetch. Status code: ${response.statusCode}');
        print('🔴 Response body: ${response.body}');
        throw Exception('Failed to load administrative details.');
      }
    } catch (e, stackTrace) {
      print('🔴 Error in getAdministrativeDetailsByStructureId: $e');
      print('🔴 Stack trace: $stackTrace');
      // Don't rethrow - this might be causing issues
      // throw Exception('Error fetching administrative details: $e');
    }
  }

  GetGeometricDetailsByStrId? _getGeometricDetailsByStrId;

  GetGeometricDetailsByStrId? get getGeometricDetailsByStrId =>
      _getGeometricDetailsByStrId;

  Future<void> getGeometricDetailsByStructureId({
    required String structureId,
    required BuildContext context,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/geometric-details',
    );
    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    try {
      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final parsedData = GetGeometricDetailsByStrId.fromJson(
          jsonDecode(response.body),
        );

        // 👇 Print key geometric fields
        print('Success: ${parsedData.success}');
        print('Message: ${parsedData.message}');
        print('Structure ID: ${parsedData.data?.structureId}');
        print('UID: ${parsedData.data?.uid}');
        print(
          'Number of Floors: ${parsedData.data?.geometricDetails?.numberOfFloors}',
        );
        print(
          'Structure Width: ${parsedData.data?.geometricDetails?.structureWidth}',
        );
        print(
          'Structure Length: ${parsedData.data?.geometricDetails?.structureLength}',
        );
        print(
          'Structure Height: ${parsedData.data?.geometricDetails?.structureHeight}',
        );
        print('Total Area: ${parsedData.data?.geometricDetails?.totalArea}');
        _getGeometricDetailsByStrId = parsedData;
        notifyListeners();
      } else {
        print('Failed to fetch. Status code: ${response.statusCode}');
        throw Exception('Failed to load geometric details.');
      }
    } catch (e) {
      print('Error in getGeometricDetailsByStructureId: $e');
      throw Exception('Error fetching geometric details: $e');
    }
  }

  GetFloorsDetailsByStrId? _getFloorsDetailsByStrId;

  GetFloorsDetailsByStrId? get getFloorsDetailsByStrId =>
      _getFloorsDetailsByStrId;
  bool get isLoadingFloors => _isLoadingFloors;
  String? get floorsError => _floorsError;
  Future<void> getFloorsByStructureId({
    required String structureId,
    required BuildContext context,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedFloors = _floorsCacheByStructureId[structureId];
      if (cachedFloors != null) {
        _getFloorsDetailsByStrId = cachedFloors;
        _floorsError = null;
        notifyListeners();
        return;
      }

      if (_floorsRequestsInFlight.contains(structureId)) {
        return;
      }
    }

    final url = Uri.parse('$baseUrl/api/structures/$structureId/floors');

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    try {
      _floorsRequestsInFlight.add(structureId);
      _isLoadingFloors = true;
      _floorsError = null;
      notifyListeners();

      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("object $decoded");

        /// ✅ Parse and assign to private variable
        _getFloorsDetailsByStrId = GetFloorsDetailsByStrId.fromJson(decoded);
        _floorsCacheByStructureId[structureId] = _getFloorsDetailsByStrId!;

        /// ✅ Notify UI about update
        notifyListeners();
      } else {
        print('Failed to fetch floors. Status code: ${response.statusCode}');
        _floorsError = 'Failed to load floor data';
        throw Exception('Failed to load floor data.');
      }
    } catch (e) {
      print('Error fetching floors: $e');
      _floorsError = e.toString();
      throw Exception('Error fetching floors: $e');
    } finally {
      _floorsRequestsInFlight.remove(structureId);
      _isLoadingFloors = false;
      notifyListeners();
    }
  }

  GetRemarksByStrId? _getRemarksByStrId;

  GetRemarksByStrId? get getRemarksByStrId => _getRemarksByStrId;

  Future<void> getRemarksByStructureId({
    required String structureId,
    required BuildContext context,
  }) async {
    final url = Uri.parse('$baseUrl/api/structures/$structureId/remarks');

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    try {
      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Check if the expected keys exist
        if (decoded != null &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          _getRemarksByStrId = GetRemarksByStrId.fromJson(decoded);
        } else {}

        print("remarks by str id: ${jsonEncode(_getRemarksByStrId!.toJson())}");
        notifyListeners();
      } else if (response.statusCode == 404) {
        // Remark not found → assign empty object to avoid crashes

        notifyListeners();
      } else {
        print('Failed to fetch remarks. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch remarks.');
      }
    } catch (e) {
      print('Error fetching remarks: $e');

      // Assign empty object to avoid null crashes in UI

      notifyListeners();
    }
  }

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // In your provider
  String remarkId = ''; // will store the FE remark ID

  Future<void> addRemarks(
    BuildContext context,
    String strID,
    String text,
  ) async {
    final url = '$baseUrl/api/structures/$strID/remarks';
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({"text": text});

    try {
      final response = await TokenAwareHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // ✅ store the returned remark ID
          remarkId = data['data']['remark_id'];
          print('New remarkId: $remarkId');
        }
      }
    } catch (e) {
      print('Error adding remark: $e');
    }
  }

  // Update method
  Future<void> updateRemarks(
    BuildContext context,
    String strID,
    String text,
    String remarkIdUp,
  ) async {
    if (remarkIdUp.isEmpty) {
      // ✅ check the correct variable
      print('Cannot update remark: remarkId is empty');
      CustomToast.showErrorToast(msg: "No remark to update");
      return;
    }

    final url = '$baseUrl/api/structures/$strID/remarks/$remarkIdUp';
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({"text": text});
    print("Updating remark at URL: $url");

    try {
      final response = await TokenAwareHttpClient.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          CustomToast.showSuccessToast(msg: data['message']);
        }
      } else {
        final data = jsonDecode(response.body);
        CustomToast.showErrorToast(msg: data['error'] ?? 'Update failed');
        print("update remark error $data");
      }
    } catch (e) {
      print('Error updating remark: $e');
      CustomToast.showErrorToast(msg: "$e");
    }
  }

  GetFloorsIdByFlatByStrId? _getFloorsIdByFlatByStrId;
  GetFloorsIdByFlatByStrId? get getFloorsIdByFlatByStrId =>
      _getFloorsIdByFlatByStrId;

  final Map<String, GetFloorsIdByFlatByStrId> _flatsPerFloor = {};

  GetFloorsIdByFlatByStrId? getFlatsByFloorId(String floorId) =>
      _flatsPerFloor[floorId];

  // In your provider, add this debugging:
  Future<void> getFlatsWithDetailsByFloorId({
    required String structureId,
    required String floorId,
    required BuildContext context,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId/flats',
    );
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    print('🌐 API URL: $url');
    print('🔑 Token available: $token');

    try {
      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('📝 Raw JSON response: $jsonData');

        final parsed = GetFloorsIdByFlatByStrId.fromJson(jsonData);
        _flatsPerFloor[floorId] = parsed;

        print('💾 Stored data for floorId: $floorId');
        print('🏠 Number of flats: ${parsed.data.flats.length}');

        // Check if the first flat has ratings
        if (parsed.data.flats.isNotEmpty == true) {
          final firstFlat = parsed.data.flats.first;
          print('🔍 First flat: ${firstFlat.flatNumber}');
          print('📊 Has structural: ${firstFlat.structuralRating}');
          print('📊 Has non-structural: ${firstFlat.nonStructuralRating}');
        }

        notifyListeners();
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load flat details');
      }
    } catch (e) {
      print('💥 Exception: $e');
      throw Exception('Error fetching flat details: $e');
    }
  }

  ReportDownloadState reportDownloadStateFor(String structureKey) {
    return _reportDownloads[structureKey] ?? const ReportDownloadState();
  }

  bool isReportDownloading(String structureKey) {
    return reportDownloadStateFor(structureKey).isDownloading;
  }

  Future<void> downloadStructureReport(
    BuildContext context, {
    ReportDownloadFormat format = ReportDownloadFormat.pdf,
  }) async {
    await _downloadReport(
      context: context,
      stateKey: 'complete-report',
      endpoint: Uri.parse('$baseUrl/api/reports/structures/complete-download'),
      format: format,
      fallbackBaseName: _buildFallbackBaseName('Structure_Report'),
    );
  }

  Future<void> downloadStructureReportByStrId(
    BuildContext context,
    String structureId, {
    required ReportDownloadFormat format,
    String? displayName,
  }) async {
    final normalizedId = structureId.trim();
    await _downloadReport(
      context: context,
      stateKey: normalizedId,
      endpoint: Uri.parse(
        '$baseUrl/api/reports/structures/$normalizedId/download',
      ),
      format: format,
      fallbackBaseName: _buildFallbackBaseName(
        displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : 'Structure_Report_$normalizedId',
      ),
    );
  }

  Future<void> _downloadReport({
    required BuildContext context,
    required String stateKey,
    required Uri endpoint,
    required ReportDownloadFormat format,
    required String fallbackBaseName,
  }) async {
    if (isReportDownloading(stateKey)) {
      return;
    }

    _updateReportDownloadState(
      stateKey,
      const ReportDownloadState(isDownloading: true, progress: 0),
    );
    _updateReportDownloadState(
      stateKey,
      reportDownloadStateFor(
        stateKey,
      ).copyWith(format: format, clearError: true, clearSavedPath: true),
    );

    try {
      final hasPermission = await _ensureStoragePermission(context);
      if (!hasPermission) {
        _updateReportDownloadState(
          stateKey,
          reportDownloadStateFor(stateKey).copyWith(
            isDownloading: false,
            clearProgress: true,
            errorMessage: 'Storage permission is required to save the report.',
          ),
        );
        return;
      }

      final file = await _performReportDownload(
        context: context,
        endpoint: endpoint.replace(
          queryParameters: <String, String>{'format': format.queryValue},
        ),
        stateKey: stateKey,
        format: format,
        fallbackBaseName: fallbackBaseName,
      );

      _updateReportDownloadState(
        stateKey,
        reportDownloadStateFor(stateKey).copyWith(
          isDownloading: false,
          clearProgress: true,
          savedPath: file.path,
          clearError: true,
        ),
      );

      await CustomToast.showDownloadToast(
        msg: 'Saved ${file.uri.pathSegments.last} in Downloads. Tap to open.',
        onTap: () {
          OpenFile.open(file.path);
        },
      );
    } catch (error) {
      final message = _humanizeDownloadError(error);
      print('Download error for $stateKey: $error');
      _updateReportDownloadState(
        stateKey,
        reportDownloadStateFor(stateKey).copyWith(
          isDownloading: false,
          clearProgress: true,
          errorMessage: message,
        ),
      );
      await CustomToast.showErrorToast(msg: message);
    }
  }

  Future<File> _performReportDownload({
    required BuildContext context,
    required Uri endpoint,
    required String stateKey,
    required ReportDownloadFormat format,
    required String fallbackBaseName,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    final commonProvider = Provider.of<CommonProvider>(context, listen: false);
    var token = commonProvider.accessToken;
    Object? lastError;

    for (var attempt = 1; attempt <= _downloadRetryAttempts; attempt++) {
      try {
        final response = await dio.getUri<dynamic>(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': '${format.mimeType}, application/octet-stream',
            },
          ),
          onReceiveProgress: (received, total) {
            if (total > 0) {
              _updateReportDownloadState(
                stateKey,
                reportDownloadStateFor(
                  stateKey,
                ).copyWith(progress: received / total),
              );
            }
          },
        );

        if (response.statusCode == 401 &&
            await commonProvider.refreshAccessToken(context)) {
          token = commonProvider.accessToken;
          continue;
        }

        if (response.statusCode == 200) {
          return _saveResponseToFile(
            response: response,
            format: format,
            fallbackBaseName: fallbackBaseName,
          );
        }

        if ((response.statusCode ?? 0) >= 500 &&
            attempt < _downloadRetryAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          continue;
        }

        throw Exception(_extractServerMessage(response));
      } catch (error) {
        lastError = error;
        if (attempt >= _downloadRetryAttempts) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }

    throw lastError ?? Exception('Download failed');
  }

  Future<File> _saveResponseToFile({
    required Response<dynamic> response,
    required ReportDownloadFormat format,
    required String fallbackBaseName,
  }) async {
    final resolvedDownloadUrl = _extractDownloadUrl(response.data);
    if (resolvedDownloadUrl != null) {
      return _downloadFromResolvedUrl(
        url: resolvedDownloadUrl,
        format: format,
        fallbackBaseName: fallbackBaseName,
      );
    }

    final fileName = _resolveResponseFileName(
      response,
      format,
      fallbackBaseName,
    );
    final directory = await _resolveDownloadDirectory();
    await directory.create(recursive: true);
    final file = await _buildUniqueFile(directory, fileName);
    final bytes = _extractResponseBytes(response.data);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _downloadFromResolvedUrl({
    required String url,
    required ReportDownloadFormat format,
    required String fallbackBaseName,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        responseType: ResponseType.bytes,
      ),
    );
    final response = await dio.getUri<dynamic>(
      Uri.parse(url),
      options: Options(
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch the report file from the download URL.');
    }
    return _saveResponseToFile(
      response: response,
      format: format,
      fallbackBaseName: fallbackBaseName,
    );
  }

  Future<bool> _ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    if (await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    await _showStoragePermissionSheet(
      context,
      title: 'Allow file access',
      message:
          'We need file access to save reports in your Downloads folder so they stay visible in your file manager.',
      showSettingsButton: false,
    );

    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }

    status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    final permanentlyDenied =
        status.isPermanentlyDenied ||
        await Permission.manageExternalStorage.isPermanentlyDenied;
    if (permanentlyDenied && context.mounted) {
      await _showStoragePermissionSheet(
        context,
        title: 'Permission required',
        message:
            'Storage permission was denied permanently. Open app settings and allow file access to download reports.',
        showSettingsButton: true,
      );
    } else {
      await CustomToast.showWarningToast(
        msg: 'Storage permission is needed to download reports.',
      );
    }

    return false;
  }

  Future<void> _showStoragePermissionSheet(
    BuildContext context, {
    required String title,
    required String message,
    required bool showSettingsButton,
  }) async {
    await customShowDialog(
      context,
      _StoragePermissionSheet(
        title: title,
        message: message,
        showSettingsButton: showSettingsButton,
      ),
      height: 245,
      enableDrag: true,
      isDismissible: true,
      backGroundColor: Colors.white,
    );
  }

  Future<Directory> _resolveDownloadDirectory() async {
    // On Android, path_provider's download directory is app-specific, e.g.
    // Android/data/<package>/files/Download. That folder is often hidden by
    // file managers, so save reports in the device's public Downloads folder.
    if (Platform.isAndroid) {
      final appExternalDirectory = await getExternalStorageDirectory();
      if (appExternalDirectory != null) {
        const androidDataSegment = '/Android/data/';
        final androidDataIndex = appExternalDirectory.path.indexOf(
          androidDataSegment,
        );
        if (androidDataIndex != -1) {
          final storageRoot = appExternalDirectory.path.substring(
            0,
            androidDataIndex,
          );
          return Directory('$storageRoot/Download');
        }
      }

      // Standard Android primary shared-storage location.
      return Directory('/storage/emulated/0/Download');
    }

    final downloadDirectory = await getDownloadsDirectory();
    if (downloadDirectory != null) {
      return downloadDirectory;
    }

    final externalStorageDirectory = await getExternalStorageDirectory();
    if (externalStorageDirectory != null) {
      return externalStorageDirectory;
    }

    return getApplicationDocumentsDirectory();
  }

  Future<File> _buildUniqueFile(Directory directory, String fileName) async {
    final extensionIndex = fileName.lastIndexOf('.');
    final baseName = extensionIndex == -1
        ? fileName
        : fileName.substring(0, extensionIndex);
    final extension = extensionIndex == -1
        ? ''
        : fileName.substring(extensionIndex);

    var candidate = File('${directory.path}${Platform.pathSeparator}$fileName');
    var suffix = 1;

    while (await candidate.exists()) {
      candidate = File(
        '${directory.path}${Platform.pathSeparator}$baseName ($suffix)$extension',
      );
      suffix++;
    }

    return candidate;
  }

  String _resolveResponseFileName(
    Response<dynamic> response,
    ReportDownloadFormat format,
    String fallbackBaseName,
  ) {
    final headers = response.headers;
    final contentDisposition = headers.value('content-disposition') ?? '';
    final fileNameMatch = RegExp(
      'filename\\*?=(?:UTF-8\'\')?"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    final rawFileName = fileNameMatch?.group(1);
    final cleanedFileName = rawFileName == null
        ? ''
        : Uri.decodeFull(rawFileName).replaceAll('"', '').trim();

    if (cleanedFileName.isNotEmpty) {
      return _ensureExpectedExtension(cleanedFileName, format, headers);
    }

    return _ensureExpectedExtension(
      '$fallbackBaseName.${format.defaultExtension}',
      format,
      headers,
    );
  }

  String _ensureExpectedExtension(
    String fileName,
    ReportDownloadFormat format,
    Headers headers,
  ) {
    final lastDot = fileName.lastIndexOf('.');
    final effectiveExtension = _extensionFromMime(
      headers.value(Headers.contentTypeHeader),
      fallback: format.defaultExtension,
    );
    if (lastDot == -1) {
      return '$fileName.$effectiveExtension';
    }
    return '${fileName.substring(0, lastDot)}.$effectiveExtension';
  }

  String _extensionFromMime(String? contentType, {required String fallback}) {
    final normalized = (contentType ?? '').toLowerCase();
    if (normalized.contains('pdf')) {
      return 'pdf';
    }
    if (normalized.contains(
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    )) {
      return 'docx';
    }
    if (normalized.contains('msword')) {
      return 'doc';
    }
    return fallback;
  }

  List<int> _extractResponseBytes(dynamic data) {
    if (data is List<int>) {
      return data;
    }
    if (data is Uint8List) {
      return data;
    }
    throw Exception('The report response did not contain downloadable bytes.');
  }

  String? _extractDownloadUrl(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.startsWith('http') ? trimmed : null;
    }
    if (data is Map) {
      final candidates = <dynamic>[
        data['url'],
        data['downloadUrl'],
        data['download_url'],
        data['fileUrl'],
        data['file_url'],
        data['data'] is Map ? data['data']['url'] : null,
      ];
      for (final candidate in candidates) {
        final value = candidate?.toString().trim();
        if (value != null && value.startsWith('http')) {
          return value;
        }
      }
    }
    return null;
  }

  String _buildFallbackBaseName(String seed) {
    final now = DateTime.now();
    final sanitizedSeed = seed
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final normalizedSeed = sanitizedSeed.isEmpty ? 'Report' : sanitizedSeed;
    final date =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
    return '${normalizedSeed}_$date';
  }

  String _extractServerMessage(Response<dynamic> response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Download failed with status ${response.statusCode}.';
  }

  String _humanizeDownloadError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Unable to download the report right now.';
    }
    return message;
  }

  void _updateReportDownloadState(String stateKey, ReportDownloadState state) {
    _reportDownloads[stateKey] = state;
    notifyListeners();
  }

  // ignore: unused_element
  Future<void> _legacyDownloadStructureReport(BuildContext context) async {
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final url = Uri.parse('$baseUrl/api/reports/structures/complete-download');

    try {
      // Ask for permission on Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission not granted.");
        }
      }

      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/octet-stream', // or application/pdf, etc.
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final directory =
            await getApplicationDocumentsDirectory(); // or getDownloadsDirectory()
        final filePath =
            '${directory.path}/structure_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final file = File(filePath);
        await file.writeAsBytes(bytes);
        CustomToast.showSuccessToast(
          msg: "Report generated succesfully ${file.path}",
        );

        // Optional: Open the file automatically
        // await OpenFile.open(file.path);
      } else {
        throw Exception(
          "Failed to download file. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("❌ Error downloading file: $e");
      CustomToast.showSuccessToast(msg: "Download failed $e");
    }
  }

  // ignore: unused_element
  Future<void> _legacyDownloadStructureReportByStrId(
    BuildContext context,
    String structureId,
  ) async {
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final url = Uri.parse(
      '$baseUrl/api/reports/structures/$structureId/download',
    );

    try {
      if (Platform.isAndroid) {
        // Android 11+ support
        if (await Permission.manageExternalStorage.isGranted == false) {
          var status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            throw Exception("Storage permission not granted.");
          }
        }
      }

      final response = await TokenAwareHttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/octet-stream',
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final directory =
            await getExternalStorageDirectory(); // or getDownloadsDirectory()
        final filePath =
            '${directory!.path}/structure_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final file = File(filePath);
        await file.writeAsBytes(bytes);
        CustomToast.showSuccessToast(
          msg: "Report generated successfully ${file.path}",
        );
        print("object $response");

        // Optional: open the file
        // await OpenFile.open(file.path);
      } else {
        throw Exception("❌ Download failed. Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error downloading file: $e");
      CustomToast.showErrorToast(msg: "$e");
    }
  }

  // Add this to your GetstructureProvider class

  Future<GetAllRatingsFlatsModel> getAllRatingsForFlat({
    required String structureId,
    required String floorId,
    required String flatId,
    required BuildContext context,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/ratings',
      );

      print('Fetching ratings from: $url');
      final token = Provider.of<CommonProvider>(
        context,
        listen: false,
      ).accessToken;

      final response = await TokenAwareHttpClient.get(
        url,
        context: context,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GetAllRatingsFlatsModel.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load ratings. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      rethrow;
    }
  }

  Future<GetAllRatingsFloorsModel> getAllRatingsForFloor({
    required String structureId,
    required String floorId,
    required String flatId,
    required BuildContext context,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/structures/$structureId/floors/$floorId/ratings',
      );

      print('Fetching ratings from: $url');
      final token = Provider.of<CommonProvider>(
        context,
        listen: false,
      ).accessToken;

      final response = await TokenAwareHttpClient.get(
        url,
        context: context,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GetAllRatingsFloorsModel.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load ratings. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      rethrow;
    }
  }
  // // Instead of single variable, use maps
  // Map<String, GetStructuralRatingsFLoorIdbyFlatId> _structuralRatingsMap = {};
  // Map<String, GetNonStructuralRatingsFLoorIdbyFlatId> _nonStructuralRatingsMap =
  //     {};

  // GetStructuralRatingsFLoorIdbyFlatId? getStructuralRatingForFlat(
  //   String flatId,
  // ) => _structuralRatingsMap[flatId];

  // GetNonStructuralRatingsFLoorIdbyFlatId? getNonStructuralRatingForFlat(
  //   String flatId,
  // ) => _nonStructuralRatingsMap[flatId];

  // Future<GetStructuralRatingsFLoorIdbyFlatId?> getStructuralRatings({
  //   required String structureId,
  //   required String floorId,
  //   required String flatId,
  //   required BuildContext context,
  // }) async {
  //   final url = Uri.parse(
  //     '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/structural-rating',
  //   );
  //   final token = Provider.of<CommonProvider>(
  //     context,
  //     listen: false,
  //   ).accessToken;

  //   try {
  //     final response = await TokenAwareHttpClient.get(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //       context: context,
  //     );

  //     if (response.statusCode == 200) {
  //       final jsonData = jsonDecode(response.body);
  //       final ratingData = GetStructuralRatingsFLoorIdbyFlatId.fromJson(
  //         jsonData,
  //       );

  //       // Store in map for future reference
  //       _structuralRatingsMap[flatId] = ratingData;
  //       notifyListeners();

  //       return ratingData;
  //     } else if (response.statusCode == 404) {
  //       // No existing rating found, this is okay for new entries
  //       print('No existing structural rating found for flat $flatId');
  //       return null;
  //     } else {
  //       throw Exception(
  //         'Failed to load structural ratings: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     print('Error fetching structural ratings: $e');
  //     throw Exception('Error fetching structural ratings: $e');
  //   }
  // }

  // // Add method to clear cache when needed
  // void clearStructuralRatingCache(String flatId) {
  //   _structuralRatingsMap.remove(flatId);
  //   notifyListeners();
  // }

  // // Add method to clear all cache
  // void clearAllRatingsCache() {
  //   _structuralRatingsMap.clear();
  //   _nonStructuralRatingsMap.clear();
  //   notifyListeners();
  // }

  // Future<void> getNonStructuralRatings({
  //   required String structureId,
  //   required String floorId,
  //   required String flatId,
  //   required BuildContext context,
  // }) async {
  //   final url = Uri.parse(
  //     '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/non-structural-rating',
  //   );
  //   final token = Provider.of<CommonProvider>(
  //     context,
  //     listen: false,
  //   ).accessToken;

  //   try {
  //     final response = await TokenAwareHttpClient.get(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //       context: context,
  //     );

  //     if (response.statusCode == 200) {
  //       final jsonData = jsonDecode(response.body);
  //       _nonStructuralRatingsMap[flatId] =
  //           GetNonStructuralRatingsFLoorIdbyFlatId.fromJson(jsonData);
  //       notifyListeners();
  //     } else {
  //       throw Exception('Failed to load non-structural ratings');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching non-structural ratings: $e');
  //   }
  // }
}
