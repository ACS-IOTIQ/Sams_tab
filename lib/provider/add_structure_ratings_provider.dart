import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/get_all_ratings_flat_model.dart';
import 'package:sams_engineering_console/models/get_all_ratings_floors_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

/// Returns the first validation error for a rating collection, if any.
/// Dimensions are optional, but every distress entry must have a count.
String? validateRatingsForSubmission(Map<String, List<RatingItem>> ratings) {
  for (final entry in ratings.entries) {
    for (final item in entry.value) {
      if (item.rating == null || item.rating! < 1 || item.rating! > 5) {
        return 'Please enter valid ratings (1-5) for all items';
      }
      if (item.distressUnit == DistressMeasurementUnit.nos) {
        return 'Please select a measurement unit for all items';
      }
      if (item.numberController.text.trim().isEmpty) {
        return 'Please enter No. for all items';
      }
    }
  }
  return null;
}

class AddRatingsStructureProvider extends ChangeNotifier {
  static const String baseUrl = 'https://sams.acstechnologies.co.in';

  final Map<String, List<RatingItem>> structuralRatingMap = {};
  final Map<String, List<RatingItem>> nonStructuralRatingMap = {};

  Map<String, dynamic> _buildDistressDimensionsPayload(RatingItem item) {
    final unit = item.distressUnit;
    final number = double.tryParse(item.numberController.text.trim()) ?? 0;
    final length = double.tryParse(item.lengthController.text.trim()) ??
        0;
    final breadth = double.tryParse(item.widthController.text.trim()) ?? 0;
    final height = double.tryParse(item.heightController.text.trim()) ?? 0;

    switch (unit) {
      case DistressMeasurementUnit.rm:
        return {
          "number": number,
          "length": length,
          "breadth": 0,
          "height": 0,
          "unit": unit.apiValue,
        };
      case DistressMeasurementUnit.sqm:
        return {
          "number": number,
          "length": length,
          "breadth": breadth,
          "height": 0,
          "unit": unit.apiValue,
        };
      case DistressMeasurementUnit.cum:
        return {
          "number": number,
          "length": length,
          "breadth": breadth,
          "height": height,
          "unit": unit.apiValue,
        };
      case DistressMeasurementUnit.nos:
        return {
          // Retained for reading and resubmitting older records.
          "number": number,
          "length": 0,
          "breadth": 0,
          "height": 0,
          "unit": unit.apiValue,
        };
    }
  }

  void updateDistressUnit(
    RatingItem item,
    DistressMeasurementUnit unit, {
    bool clearIrrelevantFields = true,
  }) {
    item.distressUnit = unit;

    if (clearIrrelevantFields) {
      if (unit == DistressMeasurementUnit.nos) {
        item.lengthController.clear();
        item.widthController.clear();
        item.heightController.clear();
      } else if (unit == DistressMeasurementUnit.rm) {
        item.widthController.clear();
        item.heightController.clear();
      } else if (unit == DistressMeasurementUnit.sqm) {
        item.heightController.clear();
      }
    }

    notifyListeners();
  }

  // ==========================================
  // STRUCTURAL RATING METHODS
  // ==========================================

  void addStructuralStructureType(String type) {
    if (!structuralRatingMap.containsKey(type)) {
      structuralRatingMap[type] = [RatingItem(type: type)];
      notifyListeners();
    }
  }

  void addItemToStructuralType(String type) {
    if (structuralRatingMap.containsKey(type)) {
      structuralRatingMap[type]!.add(RatingItem(type: type));
      notifyListeners();
    }
  }

  void removeStructuralStructureType(String type) {
    structuralRatingMap.remove(type);
    notifyListeners();
  }

  void addStructuralRatingItem(String type) {
    structuralRatingMap[type]?.add(RatingItem(type: type));
    notifyListeners();
  }

  void removeStructuralRatingItem(String type, int index) {
    if (structuralRatingMap.containsKey(type) &&
        structuralRatingMap[type]!.length > 1) {
      structuralRatingMap[type]!.removeAt(index);
      notifyListeners();
    }
  }

  void clearStructuralRatings() {
    structuralRatingMap.clear();
    notifyListeners();
  }

  // ==========================================
  // NON-STRUCTURAL RATING METHODS
  // ==========================================

  void addNonStructuralStructureType(String type) {
    if (!nonStructuralRatingMap.containsKey(type)) {
      nonStructuralRatingMap[type] = [RatingItem(type: type)];
      notifyListeners();
    }
  }

  void addItemToNonStructuralType(String type) {
    if (nonStructuralRatingMap.containsKey(type)) {
      nonStructuralRatingMap[type]!.add(RatingItem(type: type));
      notifyListeners();
    }
  }

  void removeNonStructuralStructureType(String type) {
    nonStructuralRatingMap.remove(type);
    notifyListeners();
  }

  void addNonStructuralRatingItem(String type) {
    nonStructuralRatingMap[type]?.add(RatingItem(type: type));
    notifyListeners();
  }

  void removeNonStructuralRatingItem(String type, int index) {
    if (nonStructuralRatingMap.containsKey(type) &&
        nonStructuralRatingMap[type]!.length > 1) {
      nonStructuralRatingMap[type]!.removeAt(index);
      notifyListeners();
    }
  }

  void clearNonStructuralRatings() {
    nonStructuralRatingMap.clear();
    notifyListeners();
  }

  String _normalizeFileValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final raw = value['file_path'] ?? value['filename'] ?? '';
      return raw.toString();
    }
    return value.toString();
  }

  String _buildUploadUrl(String raw) {
    if (raw.isEmpty) return '';
    return raw.startsWith('http')
        ? raw
        : 'https://acs-sams-gdmi.onrender.com/uploads/$raw';
  }

  /// Populate structural ratings from fetched flat data
  void populateStructuralRatingsFromFlat(StructuralRating apiData) {
    structuralRatingMap.clear();

    // Helper function to process single item (not list)
    void processItem(String type, BrickPlaster? item) {
      if (item == null) return;
      final ratingItem = RatingItem(type: type);
      ratingItem.rating = item.rating;
      ratingItem.comment = item.conditionComment;
      ratingItem.ratingController.text = item.rating.toString();
      ratingItem.commentController.text = item.conditionComment;
      ratingItem.id = item.id;
      // Preserve all photos from API (photos list preferred, fallback to single photo)
      if (item.photos.isNotEmpty) {
        ratingItem.photoUrls = item.photos.map((p) {
          final n = p.toString();
          return n.startsWith('http')
              ? n
              : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
        }).toList();
        ratingItem.photoUrl = ratingItem.photoUrls.first;
      } else if (item.photo.isNotEmpty) {
        final n = item.photo.toString();
        ratingItem.photoUrl = n.startsWith('http')
            ? n
            : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
        ratingItem.photoUrls = [ratingItem.photoUrl!];
      }
      if (item.pdfFiles.isNotEmpty) {
        ratingItem.docUrls = item.pdfFiles
            .map((p) => _buildUploadUrl(_normalizeFileValue(p)))
            .where((u) => u.isNotEmpty)
            .toList();
      }
      ratingItem.inspectorNotes = item.inspectorNotes;
      ratingItem.repairMethodology = item.repairMethodology;
      ratingItem.repairMethodologyController.text = item.repairMethodology;
      ratingItem.distressTypes = List<String>.from(item.distressTypes);
      ratingItem.lengthController.text = item.distressDimensions.length
          .toString();
      ratingItem.widthController.text = (item.distressDimensions.breadth ?? 0)
          .toString();
      ratingItem.heightController.text = (item.distressDimensions.height ?? 0)
          .toString();
      ratingItem.distressUnit = DistressMeasurementUnitX.fromApiValue(
        item.distressDimensions.unit,
      );
      ratingItem.numberController.text =
          item.distressDimensions.number?.toString() ?? '';

      // Add as single-item list
      structuralRatingMap[type] = [ratingItem];
    }

    // Process each structural category (single items)
    processItem('Beams', apiData.beams);
    processItem('Columns', apiData.columns);
    processItem('Slab', apiData.slab);
    processItem('Foundation', apiData.foundation);
    apiData.steelComponents.forEach(
      (type, item) => processItem(type, item),
    );

    notifyListeners();
  }

  /// Populate non-structural ratings from fetched flat data
  void populateNonStructuralRatingsFromFlat(NonStructuralRating apiData) {
    nonStructuralRatingMap.clear();

    // Helper for BrickPlaster type (has all fields)
    void processItemFull(String type, BrickPlaster item) {
      final ratingItem = RatingItem(type: type);
      ratingItem.rating = item.rating;
      ratingItem.comment = item.conditionComment;
      ratingItem.ratingController.text = item.rating.toString();
      ratingItem.commentController.text = item.conditionComment;
      ratingItem.id = item.id;
      if (item.photos.isNotEmpty) {
        ratingItem.photoUrls = item.photos.map((p) {
          final n = p.toString();
          return n.startsWith('http')
              ? n
              : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
        }).toList();
        ratingItem.photoUrl = ratingItem.photoUrls.first;
      } else if (item.photo.isNotEmpty) {
        final n = item.photo.toString();
        ratingItem.photoUrl = n.startsWith('http')
            ? n
            : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
        ratingItem.photoUrls = [ratingItem.photoUrl!];
      }
      if (item.pdfFiles.isNotEmpty) {
        ratingItem.docUrls = item.pdfFiles
            .map((p) => _buildUploadUrl(_normalizeFileValue(p)))
            .where((u) => u.isNotEmpty)
            .toList();
      }
      ratingItem.inspectorNotes = item.inspectorNotes;
      ratingItem.repairMethodology = item.repairMethodology;
      ratingItem.repairMethodologyController.text = item.repairMethodology;
      ratingItem.distressTypes = List<String>.from(item.distressTypes);
      ratingItem.lengthController.text = item.distressDimensions.length
          .toString();
      ratingItem.widthController.text = (item.distressDimensions.breadth ?? 0)
          .toString();
      ratingItem.heightController.text = (item.distressDimensions.height ?? 0)
          .toString();
      ratingItem.distressUnit = DistressMeasurementUnitX.fromApiValue(
        item.distressDimensions.unit,
      );
      ratingItem.numberController.text =
          item.distressDimensions.number?.toString() ?? '';

      nonStructuralRatingMap[type] = [ratingItem];
    }

    // Process each non-structural category
    processItemFull('Brick Plaster', apiData.brickPlaster);
    processItemFull('Walls', apiData.walls);
    processItemFull('Paintings', apiData.paintings);
    processItemFull('Doors & Windows', apiData.doorsWindows);
    processItemFull('Flooring/Tiles', apiData.flooringTiles);
    processItemFull('Electrical Wiring', apiData.electricalWiring);
    processItemFull('Sanitary Fittings', apiData.sanitaryFittings);
    processItemFull('Railings', apiData.railings);
    processItemFull('Water Tanks', apiData.waterTanks);
    processItemFull('Plumbing', apiData.plumbing);
    processItemFull('Sewage System', apiData.sewageSystem);
    processItemFull(
      'Panel/Board Transformer',
      apiData.panelBoard,
    ); // Note: panelBoard not panelBoardTransformer
    processItemFull('Lift', apiData.lifts); // Note: lifts not lift

    notifyListeners();
  }

  /// ✅ FIXED: Populate structural ratings from fetched floor data (handles ARRAYS)
  void populateStructuralRatingsFromFloor(StructuralRatingFloor apiData) {
    print('🔄 Starting populateStructuralRatingsFromFloor...');
    structuralRatingMap.clear();

    // ✅ FIXED: Process arrays of BrickPlasterFloor items
    void processItemList(String type, List<BrickPlasterFloor> items) {
      print('   Processing $type: ${items.length} items');

      if (items.isEmpty) {
        print('   ⚠️ No items for $type, skipping...');
        return; // Skip empty arrays
      }

      final ratingItems = <RatingItem>[];

      for (var item in items) {
        try {
          final ratingItem = RatingItem(type: type);

          // Basic fields
          ratingItem.rating = item.rating;
          ratingItem.comment = item.conditionComment;
          ratingItem.ratingController.text = item.rating.toString();
          ratingItem.commentController.text = item.conditionComment;
          ratingItem.id = item.id;
          ratingItem.inspectorNotes = item.inspectorNotes;
          ratingItem.name = item.name;

          // ✅ NEW: Populate repair methodology
          ratingItem.repairMethodology = item.repairMethodology;
          ratingItem.repairMethodologyController.text = item.repairMethodology;

          // Distress types are already normalized in the model.
          ratingItem.distressTypes = List<String>.from(item.distressTypes);

          // ✅ NEW: Populate dimension controllers
          ratingItem.lengthController.text = item.distressDimensions.length
              .toString();
          ratingItem.widthController.text =
              (item.distressDimensions.breadth ?? 0).toString();
          ratingItem.heightController.text =
              (item.distressDimensions.height ?? 0).toString();
          ratingItem.distressUnit = DistressMeasurementUnitX.fromApiValue(
            item.distressDimensions.unit,
          );
          ratingItem.numberController.text =
              item.distressDimensions.number?.toString() ?? '';

          // ✅ FIXED: Handle photos from API and build full URLs
          print('   📸 Photo data for ${item.name}:');
          print('      - item.photos: ${item.photos}');
          print('      - item.pdfFiles: ${item.pdfFiles}');

          if (item.photos.isNotEmpty) {
            ratingItem.photoUrls = item.photos.map((p) {
              final n = p.toString();
              return n.startsWith('http')
                  ? n
                  : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
            }).toList();
            ratingItem.photoUrl = ratingItem.photoUrls.first;
          }

          // ✅ NEW: Populate document URLs from pdfFiles list if present
          if (item.pdfFiles.isNotEmpty) {
            ratingItem.docUrls = item.pdfFiles
                .map((p) => _buildUploadUrl(_normalizeFileValue(p)))
                .where((u) => u.isNotEmpty)
                .toList();
          }

          ratingItems.add(ratingItem);
          print('   ✅ Added ${item.name} with rating ${item.rating}');
        } catch (e) {
          print('   ❌ Error processing item in $type: $e');
          print('   Item data: $item');
        }
      }

      if (ratingItems.isNotEmpty) {
        structuralRatingMap[type] = ratingItems;
        print('   ✅ Successfully added ${ratingItems.length} items to $type');
      }
    }

    // Process each structural category (now handles arrays)
    try {
      processItemList('Beams', apiData.beams);
      processItemList('Columns', apiData.columns);
      processItemList('Slab', apiData.slabs);
      processItemList('Foundation', apiData.foundations);
      apiData.steelComponents.forEach(processItemList);

      print('✅ populateStructuralRatingsFromFloor completed');
      print('   Total types loaded: ${structuralRatingMap.length}');
      structuralRatingMap.forEach((key, value) {
        print('   - $key: ${value.length} items');
      });
    } catch (e) {
      print('❌ Error in populateStructuralRatingsFromFloor: $e');
      print('   Stack trace: ${StackTrace.current}');
      rethrow;
    }

    notifyListeners();
  }

  /// ✅ FIXED: Populate non-structural ratings from fetched floor data (handles ARRAYS)
  void populateNonStructuralRatingsFromFloor(NonStructuralRatingFloor apiData) {
    print('🔄 Starting populateNonStructuralRatingsFromFloor...');
    nonStructuralRatingMap.clear();

    // ✅ FIXED: Process arrays of BrickPlasterFloor items
    void processItemList(String type, List<BrickPlasterFloor> items) {
      print('   Processing $type: ${items.length} items');

      if (items.isEmpty) {
        print('   ⚠️ No items for $type, skipping...');
        return; // Skip empty arrays
      }

      final ratingItems = <RatingItem>[];

      for (var item in items) {
        try {
          final ratingItem = RatingItem(type: type);

          // Basic fields
          ratingItem.rating = item.rating;
          ratingItem.comment = item.conditionComment;
          ratingItem.ratingController.text = item.rating.toString();
          ratingItem.commentController.text = item.conditionComment;
          ratingItem.id = item.id;
          ratingItem.inspectorNotes = item.inspectorNotes;
          ratingItem.name = item.name;

          // ✅ NEW: Populate repair methodology
          ratingItem.repairMethodology = item.repairMethodology;
          ratingItem.repairMethodologyController.text = item.repairMethodology;

          // Distress types are already normalized in the model.
          ratingItem.distressTypes = List<String>.from(item.distressTypes);

          // ✅ NEW: Populate dimension controllers
          ratingItem.lengthController.text = item.distressDimensions.length
              .toString();
          ratingItem.widthController.text =
              (item.distressDimensions.breadth ?? 0).toString();
          ratingItem.heightController.text =
              (item.distressDimensions.height ?? 0).toString();
          ratingItem.distressUnit = DistressMeasurementUnitX.fromApiValue(
            item.distressDimensions.unit,
          );
          ratingItem.numberController.text =
              item.distressDimensions.number?.toString() ?? '';

          // ✅ FIXED: Handle photos from API and build full URLs
          print('   📸 Photo data for ${item.name}:');
          print('      - item.photos: ${item.photos}');
          print('      - item.pdfFiles: ${item.pdfFiles}');

          if (item.photos.isNotEmpty) {
            ratingItem.photoUrls = item.photos.map((p) {
              final n = p.toString();
              return n.startsWith('http')
                  ? n
                  : 'https://acs-sams-gdmi.onrender.com/uploads/$n';
            }).toList();
            ratingItem.photoUrl = ratingItem.photoUrls.first;
          }

          if (item.pdfFiles.isNotEmpty) {
            ratingItem.docUrls = item.pdfFiles
                .map((p) => _buildUploadUrl(_normalizeFileValue(p)))
                .where((u) => u.isNotEmpty)
                .toList();
          }

          ratingItems.add(ratingItem);
          print('   ✅ Added ${item.name} with rating ${item.rating}');
        } catch (e) {
          print('   ❌ Error processing item in $type: $e');
          print('   Item data: $item');
        }
      }

      if (ratingItems.isNotEmpty) {
        nonStructuralRatingMap[type] = ratingItems;
        print('   ✅ Successfully added ${ratingItems.length} items to $type');
      }
    }

    // Process each non-structural category (now handles arrays)
    try {
      processItemList('Brick Plaster', apiData.brickPlaster);
      processItemList('Walls', apiData.walls);
      processItemList('Paintings', apiData.paintings);
      processItemList('Doors & Windows', apiData.doorsWindows);
      processItemList('Flooring/Tiles', apiData.flooringTiles);
      processItemList('Electrical Wiring', apiData.electricalWiring);
      processItemList('Sanitary Fittings', apiData.sanitaryFittings);
      processItemList('Railings', apiData.railings);
      processItemList('Water Tanks', apiData.waterTanks);
      processItemList('Plumbing', apiData.plumbing);
      processItemList('Sewage System', apiData.sewageSystem);
      processItemList('Panel/Board Transformer', apiData.panelBoard);
      processItemList('Lift', apiData.lifts);

      print('✅ populateNonStructuralRatingsFromFloor completed');
      print('   Total types loaded: ${nonStructuralRatingMap.length}');
      nonStructuralRatingMap.forEach((key, value) {
        print('   - $key: ${value.length} items');
      });
    } catch (e) {
      print('❌ Error in populateNonStructuralRatingsFromFloor: $e');
      print('   Stack trace: ${StackTrace.current}');
      rethrow;
    }

    notifyListeners();
  }

  /// Clear all ratings data
  void clearAllRatings() {
    structuralRatingMap.clear();
    nonStructuralRatingMap.clear();
    notifyListeners();
  }

  /// Call this immediately when navigating to a new floor/flat
  /// so stale data from the previous floor never bleeds through
  void clearForNewFloor() {
    structuralRatingMap.clear();
    nonStructuralRatingMap.clear();
    notifyListeners();
  }

  /// Keeps server images while appending files selected during an edit.
  List<String> _collectPhotoValues(RatingItem item, List<File> uploadFiles) {
    final photos = <String>[...item.photoUrls];
    if (photos.isEmpty && item.photoUrl != null && item.photoUrl!.isNotEmpty) {
      photos.add(item.photoUrl!);
    }
    if (item.files != null && item.files!.isNotEmpty) {
      uploadFiles.addAll(item.files!);
      photos.addAll(item.files!.map((file) => path.basename(file.path)));
    }
    return photos;
  }

  Future<Response<dynamic>> _postMultipartWithTokenRefresh({
    required String url,
    required FormData formData,
    required BuildContext context,
  }) async {
    final commonProvider = Provider.of<CommonProvider>(context, listen: false);
    final dio = Dio();
    // Multipart streams are consumed by the first request. Clone before
    // sending so an expired-token retry has fresh file streams.
    final retryData = formData.clone();

    Future<Response<dynamic>> send(FormData data) => dio.post<dynamic>(
      url,
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${commonProvider.accessToken}',
        },
      ),
    );

    try {
      return await send(formData);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      final refreshed = await commonProvider.refreshAccessToken(context);
      if (!refreshed || commonProvider.accessToken.trim().isEmpty) rethrow;
      return send(retryData);
    }
  }

  // ==========================================
  // STRUCTURAL SUBMISSION METHODS
  // ==========================================

  Future<void> submitAllStructuralData(
    String structureId,
    String flatId,
    BuildContext context, {
    required String structureSubType,
    bool testingRequired = false,
  }) async {
    final List<Map<String, dynamic>> allComponents = [];
    final List<File> allImageFiles = [];
    final List<File> allDocFiles = [];

    structuralRatingMap.forEach((type, items) {
      final componentGroup = {
        "component_type": _mapStructuralComponentType(type, structureSubType),
        "components": items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final component = <String, dynamic>{
            "name": item.name ?? "$type Component ${index + 1}",
            "rating": item.rating ?? 0,
            "condition_comment": item.comment ?? '',
            "inspector_notes": item.inspectorNotes ?? "",
            "distress_dimensions": _buildDistressDimensionsPayload(item),
            "repair_methodology":
                item.repairMethodology ?? item.repairMethodologyController.text,
            "distress_types": item.distressTypes,
          };

          component["photo"] = _collectPhotoValues(item, allImageFiles);

          // Documents (pdf/xls/xlsx)
          final pdfFiles = <String>[];
          if (item.docFiles != null && item.docFiles!.isNotEmpty) {
            allDocFiles.addAll(item.docFiles!);
            pdfFiles.addAll(item.docFiles!.map((f) => path.basename(f.path)));
          }
          if (item.docUrls.isNotEmpty) {
            pdfFiles.addAll(item.docUrls);
          }
          if (pdfFiles.isNotEmpty) {
            component["pdf_files"] = pdfFiles;
          }

          return component;
        }).toList(),
      };
      allComponents.add(componentGroup);
    });

    // Build multipart FormData
    final formData = FormData();
    formData.fields.add(MapEntry('structures', jsonEncode(allComponents)));
    formData.fields.add(
      MapEntry('testing_required', testingRequired.toString()),
    );

    for (final file in allImageFiles) {
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }
    for (final file in allDocFiles) {
      formData.files.add(
        MapEntry(
          'docs',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    print("📤 [STRUCTURAL FLAT] structures JSON: ${jsonEncode(allComponents)}");
    print(
      "📤 [STRUCTURAL FLAT] Total images: ${allImageFiles.length}, docs: ${allDocFiles.length}",
    );
    print(
      "🔗 [STRUCTURAL FLAT] URL: $baseUrl/api/structures/$structureId/flats/$flatId/structural/bulk",
    );

    try {
      final response = await _postMultipartWithTokenRefresh(
        url: "$baseUrl/api/structures/$structureId/flats/$flatId/structural/bulk",
        formData: formData,
        context: context,
      );

      print("✅ [STRUCTURAL FLAT] Status Code: ${response.statusCode}");
      print("✅ [STRUCTURAL FLAT] Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.showSuccessToast(
          msg: "Structural data submitted successfully!",
        );
      } else {
        print("⚠️ [STRUCTURAL FLAT] Unexpected status: ${response.statusCode}");
        CustomToast.showErrorToast(msg: "Error: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ [STRUCTURAL FLAT] Submission error: $e");
      if (e is DioException) {
        final msg = _extractDioErrorMessage(
          e,
          "Error submitting structural data",
        );
        CustomToast.showErrorToast(msg: msg);
      } else {
        CustomToast.showErrorToast(msg: "Error submitting structural data: $e");
      }
      rethrow;
    }
  }

  Future<void> submitAllStructuralDataForFloor(
    String structureId,
    String floorId,
    BuildContext context, {
    required String structureSubType,
    bool testingRequired = false,
  }) async {
    final List<Map<String, dynamic>> allComponents = [];
    final List<File> allFiles = []; // images
    final List<File> allDocFiles = []; // docs
    // Build the structures JSON array and collect all files
    structuralRatingMap.forEach((type, items) {
      final componentGroup = {
        "component_type": _mapStructuralComponentType(type, structureSubType),
        "components": items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final component = <String, dynamic>{
            "name": item.name ?? "$type Component ${index + 1}",
            "rating": item.rating ?? 0,
            "condition_comment": item.comment ?? '',
            "inspector_notes": item.inspectorNotes ?? "",
            "distress_dimensions": _buildDistressDimensionsPayload(item),
            "repair_methodology":
                item.repairMethodology ?? item.repairMethodologyController.text,
            "distress_types": item.distressTypes,
          };

          component["photo"] = _collectPhotoValues(item, allFiles);

          // Documents
          final pdfFiles = <String>[];
          if (item.docFiles != null && item.docFiles!.isNotEmpty) {
            allDocFiles.addAll(item.docFiles!);
            pdfFiles.addAll(item.docFiles!.map((f) => path.basename(f.path)));
          }
          if (item.docUrls.isNotEmpty) {
            pdfFiles.addAll(item.docUrls);
          }
          if (pdfFiles.isNotEmpty) {
            component["pdf_files"] = pdfFiles;
          }

          return component;
        }).toList(),
      };
      allComponents.add(componentGroup);
    });

    // ✅ Build multipart FormData — same shape as Postman:
    //    field "structures" → JSON string of the array
    //    field "photo"      → one MultipartFile per image
    final formData = FormData();
    formData.fields.add(MapEntry('structures', jsonEncode(allComponents)));
    formData.fields.add(
      MapEntry('testing_required', testingRequired.toString()),
    );

    for (final file in allFiles) {
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }
    for (final file in allDocFiles) {
      formData.files.add(
        MapEntry(
          'docs',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    print(
      "📤 [STRUCTURAL FLOOR] structures JSON: ${jsonEncode(allComponents)}",
    );
    print(
      "📤 [STRUCTURAL FLOOR] Total images: ${allFiles.length}, docs: ${allDocFiles.length}",
    );
    print(
      "🔗 [STRUCTURAL FLOOR] URL: $baseUrl/api/structures/$structureId/floors/$floorId/structural/bulk",
    );

    try {
      final response = await _postMultipartWithTokenRefresh(
        url: "$baseUrl/api/structures/$structureId/floors/$floorId/structural/bulk",
        formData: formData,
        context: context,
      );

      print("✅ [STRUCTURAL FLOOR] Status Code: ${response.statusCode}");
      print("✅ [STRUCTURAL FLOOR] Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.showSuccessToast(
          msg: "Floor structural data submitted successfully.",
        );
      } else {
        print(
          "⚠️ [STRUCTURAL FLOOR] Unexpected status: ${response.statusCode}",
        );
        CustomToast.showErrorToast(msg: "Error: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ [STRUCTURAL FLOOR] Submission error: $e");
      if (e is DioException) {
        print("❌ [STRUCTURAL FLOOR] DioError type: ${e.type}");
        print("❌ [STRUCTURAL FLOOR] DioError response: ${e.response?.data}");
        print("❌ [STRUCTURAL FLOOR] DioError message: ${e.message}");
        final msg = _extractDioErrorMessage(
          e,
          "Error submitting floor structural data",
        );
        CustomToast.showErrorToast(msg: msg);
      } else {
        CustomToast.showErrorToast(
          msg: "Error submitting floor structural data: $e",
        );
      }
      rethrow;
    }
  }

  // ==========================================
  // NON-STRUCTURAL SUBMISSION METHODS
  // ==========================================

  // Helper: extract the most useful error message from a DioException response
  String _extractDioErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map && first['message'] != null) {
            return first['message'].toString();
          }
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  // Helper: normalize lookup key
  String _key(String type) => type.trim().toLowerCase();

  // Helper function to sanitize component type for API (fallback)
  String _sanitizeComponentType(String type) {
    return type
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w]'), '');
  }

  String _mapStructuralComponentType(String type, String structureSubType) {
    final key = _key(type);
    final isSteel = structureSubType.toLowerCase() == 'steel';

    const rccMap = {
      'beams': 'beams',
      'columns': 'columns',
      'slab': 'slab',
      'foundation': 'foundation',
    };

    const steelMap = {
      'foundation': 'foundation',
      'columns': 'columns',
      'beams': 'beams',
      'roof_truss': 'roof_truss',
      'roof truss': 'roof_truss',
      'connections': 'connections',
      'bracings': 'bracings',
      'purlins': 'purlins',
      'channels': 'channels',
      'steel_flooring': 'steel_flooring',
      'steel flooring': 'steel_flooring',
    };

    final mapped = isSteel ? steelMap[key] : rccMap[key];
    return mapped ?? _sanitizeComponentType(type);
  }

  String _mapNonStructuralComponentType(String type, String structureSubType) {
    final key = _key(type);
    final isSteel = structureSubType.toLowerCase() == 'steel';

    const rccMap = {
      'brick plaster': 'brick_plaster',
      'brick/plaster': 'brick_plaster',
      'doors & windows': 'doors_windows',
      'doors and windows': 'doors_windows',
      'flooring/tiles': 'flooring_tiles',
      'flooring tiles': 'flooring_tiles',
      'electrical wiring': 'electrical_wiring',
      'sanitary fittings': 'sanitary_fittings',
      'railings': 'railings',
      'water tanks': 'water_tanks',
      'plumbing': 'plumbing',
      'sewage system': 'sewage_system',
      'panel/board transformer': 'panel_board',
      'panel board transformer': 'panel_board',
      'lift': 'lifts',
      'lifts': 'lifts',
      'walls': 'walls',
      'paintings': 'paintings',
    };

    const steelMap = {
      'cladding_partition_panels': 'cladding_partition_panels',
      'cladding/partition panels': 'cladding_partition_panels',
      'roof_sheeting': 'roof_sheeting',
      'roof sheeting': 'roof_sheeting',
      'chequered_plate': 'chequered_plate',
      'chequered plate': 'chequered_plate',
      'doors & windows': 'doors_windows',
      'doors and windows': 'doors_windows',
      'industrial_flooring': 'flooring',
      'industrial flooring': 'flooring',
      'flooring': 'flooring',
      'electrical wiring': 'electrical_wiring',
      'sanitary fittings': 'sanitary_fittings',
      'railings': 'railings',
      'water tanks': 'water_tanks',
      'plumbing': 'plumbing',
      'sewage system': 'sewage_system',
      'transformer panel / board': 'panel_board_transformer',
      'transformer panel /board': 'panel_board_transformer',
      'panel board transformer': 'panel_board_transformer',
      'transformer panel board': 'panel_board_transformer',
      'lift system': 'lift',
      'lift': 'lift',
      'walls': 'walls',
      'paintings': 'paintings',
    };

    final mapped = isSteel ? steelMap[key] : rccMap[key];
    return mapped ?? _sanitizeComponentType(type);
  }

  Future<void> submitAllNonStructuralData(
    String structureId,
    String flatId,
    BuildContext context, {
    required String structureSubType,
  }) async {
    final List<Map<String, dynamic>> allComponents = [];
    final List<File> allImageFiles = [];
    final List<File> allDocFiles = [];
    nonStructuralRatingMap.forEach((type, items) {
      final componentGroup = {
        "component_type": _mapNonStructuralComponentType(
          type,
          structureSubType,
        ),
        "components": items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final component = <String, dynamic>{
            "name": item.name ?? "$type Component ${index + 1}",
            "rating": item.rating ?? 0,
            "condition_comment": item.comment ?? '',
            "inspector_notes": item.inspectorNotes ?? "",
            "distress_dimensions": _buildDistressDimensionsPayload(item),
            "repair_methodology":
                item.repairMethodology ?? item.repairMethodologyController.text,
          };

          component["photo"] = _collectPhotoValues(item, allImageFiles);

          // Documents
          final pdfFiles = <String>[];
          if (item.docFiles != null && item.docFiles!.isNotEmpty) {
            allDocFiles.addAll(item.docFiles!);
            pdfFiles.addAll(item.docFiles!.map((f) => path.basename(f.path)));
          }
          if (item.docUrls.isNotEmpty) {
            pdfFiles.addAll(item.docUrls);
          }
          if (pdfFiles.isNotEmpty) {
            component["pdf_files"] = pdfFiles;
          }

          return component;
        }).toList(),
      };
      allComponents.add(componentGroup);
    });

    final formData = FormData();
    formData.fields.add(MapEntry('structures', jsonEncode(allComponents)));

    for (final file in allImageFiles) {
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }
    for (final file in allDocFiles) {
      formData.files.add(
        MapEntry(
          'docs',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    print(
      "📤 [NON-STRUCTURAL FLAT] structures JSON: ${jsonEncode(allComponents)}",
    );
    print(
      "📤 [NON-STRUCTURAL FLAT] Total images: ${allImageFiles.length}, docs: ${allDocFiles.length}",
    );
    print(
      "🔗 [NON-STRUCTURAL FLAT] URL: $baseUrl/api/structures/$structureId/flats/$flatId/non-structural/bulk",
    );

    try {
      final response = await _postMultipartWithTokenRefresh(
        url: "$baseUrl/api/structures/$structureId/flats/$flatId/non-structural/bulk",
        formData: formData,
        context: context,
      );

      print("✅ [NON-STRUCTURAL FLAT] Status Code: ${response.statusCode}");
      print("✅ [NON-STRUCTURAL FLAT] Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.showSuccessToast(
          msg: "Non-structural data submitted successfully!",
        );
      } else {
        print(
          "⚠️ [NON-STRUCTURAL FLAT] Unexpected status: ${response.statusCode}",
        );
        CustomToast.showErrorToast(msg: "Error: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ [NON-STRUCTURAL FLAT] Submission error: $e");
      if (e is DioException) {
        final msg = _extractDioErrorMessage(
          e,
          "Error submitting non-structural data",
        );
        CustomToast.showErrorToast(msg: msg);
      } else {
        CustomToast.showErrorToast(
          msg: "Error submitting non-structural data: $e",
        );
      }
      rethrow;
    }
  }

  Future<void> submitAllNonStructuralDataForFloor(
    String structureId,
    String floorId,
    BuildContext context, {
    required String structureSubType,
  }) async {
    final List<Map<String, dynamic>> allComponents = [];
    final List<File> allFiles = [];
    final List<File> allDocFiles = [];
    nonStructuralRatingMap.forEach((type, items) {
      final componentGroup = {
        "component_type": _mapNonStructuralComponentType(
          type,
          structureSubType,
        ),
        "components": items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final component = <String, dynamic>{
            "name": item.name ?? "$type Component ${index + 1}",
            "rating": item.rating ?? 0,
            "condition_comment": item.comment ?? '',
            "inspector_notes":
                item.inspectorNotes ?? "Auto-generated via inspection form",
            "distress_dimensions": _buildDistressDimensionsPayload(item),
            "repair_methodology":
                item.repairMethodology ?? item.repairMethodologyController.text,
          };

          component["photo"] = _collectPhotoValues(item, allFiles);

          // Documents
          final pdfFiles = <String>[];
          if (item.docFiles != null && item.docFiles!.isNotEmpty) {
            allDocFiles.addAll(item.docFiles!);
            pdfFiles.addAll(item.docFiles!.map((f) => path.basename(f.path)));
          }
          if (item.docUrls.isNotEmpty) {
            pdfFiles.addAll(item.docUrls);
          }
          if (pdfFiles.isNotEmpty) {
            component["pdf_files"] = pdfFiles;
          }

          return component;
        }).toList(),
      };
      allComponents.add(componentGroup);
    });

    final formData = FormData();
    formData.fields.add(MapEntry('structures', jsonEncode(allComponents)));

    for (final file in allFiles) {
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }
    for (final file in allDocFiles) {
      formData.files.add(
        MapEntry(
          'docs',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    print(
      "📤 [NON-STRUCTURAL FLOOR] structures JSON: ${jsonEncode(allComponents)}",
    );
    print(
      "📤 [NON-STRUCTURAL FLOOR] Total images: ${allFiles.length}, docs: ${allDocFiles.length}",
    );
    print(
      "🔗 [NON-STRUCTURAL FLOOR] URL: $baseUrl/api/structures/$structureId/floors/$floorId/non-structural/bulk",
    );

    try {
      final response = await _postMultipartWithTokenRefresh(
        url: "$baseUrl/api/structures/$structureId/floors/$floorId/non-structural/bulk",
        formData: formData,
        context: context,
      );

      print("✅ [NON-STRUCTURAL FLOOR] Status Code: ${response.statusCode}");
      print("✅ [NON-STRUCTURAL FLOOR] Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.showSuccessToast(
          msg: "Non-structural floor data submitted successfully",
        );
      } else {
        print(
          "⚠️ [NON-STRUCTURAL FLOOR] Unexpected status: ${response.statusCode}",
        );
        CustomToast.showErrorToast(msg: "Error: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ [NON-STRUCTURAL FLOOR] Submission error: $e");
      if (e is DioException) {
        final msg = _extractDioErrorMessage(
          e,
          "Error submitting non-structural floor data",
        );
        CustomToast.showErrorToast(msg: msg);
      } else {
        CustomToast.showErrorToast(
          msg: "Error submitting non-structural floor data: $e",
        );
      }
      rethrow;
    }
  }
}

class RatingItem {
  String type;
  String? name; // ✅ Added: Store the name from API
  int? rating;
  String? comment;
  File? file; // ✅ Kept for backward compatibility
  String? fileName;
  List<File>? files; // ✅ NEW: Support multiple files
  List<File>? docFiles; // ✅ NEW: Support multiple documents (pdf/xls/etc)
  String? id; // Store API ID for potential updates
  String? photoUrl; // first photo URL (backward compat)
  List<String> photoUrls = []; // ALL server photos (populated from API)
  List<String> docUrls = []; // ALL server docs (populated from API)
  String? inspectorNotes; // Store inspector notes
  String? repairMethodology; // ✅ Added: Store repair methodology
  List<String> distressTypes = []; // ✅ Multi-select distress types
  DistressMeasurementUnit distressUnit = DistressMeasurementUnit.nos;
  TextEditingController ratingController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController repairMethodologyController =
      TextEditingController(); // ✅ Added controller

  RatingItem({required this.type}) {
    distressTypes = []; // Initialize as empty list
    files = []; // ✅ Initialize files list (images)
    docFiles = []; // ✅ Initialize doc files list
  }

  void dispose() {
    ratingController.dispose();
    commentController.dispose();
    heightController.dispose();
    lengthController.dispose();
    widthController.dispose();
    numberController.dispose();
    repairMethodologyController.dispose();
  }
}

enum DistressMeasurementUnit { nos, rm, sqm, cum }

extension DistressMeasurementUnitX on DistressMeasurementUnit {
  String get apiValue {
    switch (this) {
      case DistressMeasurementUnit.nos:
        return "NO'S";
      case DistressMeasurementUnit.rm:
        return 'RM';
      case DistressMeasurementUnit.sqm:
        return 'SQM';
      case DistressMeasurementUnit.cum:
        return 'CUM';
    }
  }

  String get label {
    switch (this) {
      case DistressMeasurementUnit.nos:
        return 'No.s';
      case DistressMeasurementUnit.rm:
        return 'Running meter';
      case DistressMeasurementUnit.sqm:
        return 'Sq. meter';
      case DistressMeasurementUnit.cum:
        return 'meter';
    }
  }

  static DistressMeasurementUnit fromApiValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'RM':
      case 'RUNNING METER':
      case 'RUNNING_METER':
        return DistressMeasurementUnit.rm;
      case 'SQM':
      case 'SQ METER':
      case 'SQ. METER':
        return DistressMeasurementUnit.sqm;
      case 'CUM':
      case 'CUBIC METER':
      case 'CUBIC_METER':
        return DistressMeasurementUnit.cum;
      default:
        return DistressMeasurementUnit.nos;
    }
  }
}
