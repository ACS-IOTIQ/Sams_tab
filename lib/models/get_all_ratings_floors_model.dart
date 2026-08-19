import 'dart:convert';

GetAllRatingsFloorsModel getAllRatingsFloorsModelFromJson(String str) =>
    GetAllRatingsFloorsModel.fromJson(json.decode(str));

String getAllRatingsFloorsModelToJson(GetAllRatingsFloorsModel data) =>
    json.encode(data.toJson());

class GetAllRatingsFloorsModel {
  bool success;
  String message;
  Data data;

  GetAllRatingsFloorsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory GetAllRatingsFloorsModel.fromJson(Map<String, dynamic> json) =>
      GetAllRatingsFloorsModel(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  String structureId;
  String floorId;
  int floorNumber;
  String? floorType;
  String floorLabelName;
  double floorHeight;
  int totalAreaSqMts;
  bool testingRequired;
  StructuralRatingFloor structuralRating;
  NonStructuralRatingFloor? nonStructuralRating;
  FloorOverallRating? floorOverallRating;
  Statistics? statistics;

  Data({
    required this.structureId,
    required this.floorId,
    required this.floorNumber,
    this.floorType,
    required this.floorLabelName,
    required this.floorHeight,
    required this.totalAreaSqMts,
    required this.testingRequired,
    required this.structuralRating,
    this.nonStructuralRating,
    this.floorOverallRating,
    this.statistics,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    structureId: json["structure_id"],
    floorId: json["floor_id"],
    floorNumber: json["floor_number"],
    floorType: json["floor_type"],
    floorLabelName: json["floor_label_name"],
    floorHeight: json["floor_height"]?.toDouble(),
    totalAreaSqMts: json["total_area_sq_mts"],
    testingRequired: json["testing_required"] == true,
    structuralRating: StructuralRatingFloor.fromJson(json["structural_rating"]),
    nonStructuralRating: json["non_structural_rating"] != null
        ? NonStructuralRatingFloor.fromJson(json["non_structural_rating"])
        : null,
    floorOverallRating: json["floor_overall_rating"] != null
        ? FloorOverallRating.fromJson(json["floor_overall_rating"])
        : null,
    statistics: json["statistics"] != null
        ? Statistics.fromJson(json["statistics"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "structure_id": structureId,
    "floor_id": floorId,
    "floor_number": floorNumber,
    "floor_type": floorType,
    "floor_label_name": floorLabelName,
    "floor_height": floorHeight,
    "total_area_sq_mts": totalAreaSqMts,
    "testing_required": testingRequired,
    "structural_rating": structuralRating.toJson(),
    "non_structural_rating": nonStructuralRating?.toJson(),
    "floor_overall_rating": floorOverallRating?.toJson(),
    "statistics": statistics?.toJson(),
  };
}

class FloorOverallRating {
  double? combinedScore;
  String? healthStatus;
  String? priority;
  DateTime lastAssessmentDate;

  FloorOverallRating({
    this.combinedScore,
    this.healthStatus,
    this.priority,
    required this.lastAssessmentDate,
  });

  factory FloorOverallRating.fromJson(Map<String, dynamic> json) =>
      FloorOverallRating(
        combinedScore: json["combined_score"]?.toDouble(),
        healthStatus: json["health_status"],
        priority: json["priority"],
        lastAssessmentDate: DateTime.parse(json["last_assessment_date"]),
      );

  Map<String, dynamic> toJson() => {
    "combined_score": combinedScore,
    "health_status": healthStatus,
    "priority": priority,
    "last_assessment_date": lastAssessmentDate.toIso8601String(),
  };
}

class Statistics {
  int totalStructuralComponents;
  int totalNonStructuralComponents;
  int componentsWithPhotos;
  int componentsBelowRating3;
  bool hasStructuralRatings;
  bool hasNonStructuralRatings;
  DateTime? lastStructuralUpdate;
  DateTime? lastNonStructuralUpdate;

  Statistics({
    required this.totalStructuralComponents,
    required this.totalNonStructuralComponents,
    required this.componentsWithPhotos,
    required this.componentsBelowRating3,
    required this.hasStructuralRatings,
    required this.hasNonStructuralRatings,
    this.lastStructuralUpdate,
    this.lastNonStructuralUpdate,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
    totalStructuralComponents: json["total_structural_components"],
    totalNonStructuralComponents: json["total_non_structural_components"],
    componentsWithPhotos: json["components_with_photos"],
    componentsBelowRating3: json["components_below_rating_3"],
    hasStructuralRatings: json["has_structural_ratings"],
    hasNonStructuralRatings: json["has_non_structural_ratings"],
    lastStructuralUpdate: json["last_structural_update"] != null
        ? DateTime.parse(json["last_structural_update"])
        : null,
    lastNonStructuralUpdate: json["last_non_structural_update"] != null
        ? DateTime.parse(json["last_non_structural_update"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "total_structural_components": totalStructuralComponents,
    "total_non_structural_components": totalNonStructuralComponents,
    "components_with_photos": componentsWithPhotos,
    "components_below_rating_3": componentsBelowRating3,
    "has_structural_ratings": hasStructuralRatings,
    "has_non_structural_ratings": hasNonStructuralRatings,
    "last_structural_update": lastStructuralUpdate?.toIso8601String(),
    "last_non_structural_update": lastNonStructuralUpdate?.toIso8601String(),
  };
}

// ✅ FIXED: NonStructuralRatingFloor now uses Lists for all components
class NonStructuralRatingFloor {
  List<BrickPlasterFloor>
  brickPlaster; // Brick/Plaster components (if returned)
  List<BrickPlasterFloor> walls; // Changed to List (was brickPlaster)
  List<BrickPlasterFloor> paintings;
  List<BrickPlasterFloor> doorsWindows; // Changed to List
  List<BrickPlasterFloor> flooringTiles; // Changed to List
  List<BrickPlasterFloor> electricalWiring; // Changed to List
  List<BrickPlasterFloor> sanitaryFittings; // Changed to List
  List<BrickPlasterFloor> railings; // Changed to List
  List<BrickPlasterFloor> waterTanks; // Changed to List
  List<BrickPlasterFloor> plumbing; // Changed to List
  List<BrickPlasterFloor> sewageSystem; // Changed to List
  List<BrickPlasterFloor> panelBoard; // Changed to List
  List<BrickPlasterFloor> lifts; // Changed to List
  double? overallAverage;
  DateTime? assessmentDate;
  String? inspectorNotes;
  Averages? averages;

  NonStructuralRatingFloor({
    required this.brickPlaster,
    required this.walls,
    required this.paintings,
    required this.doorsWindows,
    required this.flooringTiles,
    required this.electricalWiring,
    required this.sanitaryFittings,
    required this.railings,
    required this.waterTanks,
    required this.plumbing,
    required this.sewageSystem,
    required this.panelBoard,
    required this.lifts,
    this.overallAverage,
    this.assessmentDate,
    this.inspectorNotes,
    this.averages,
  });

  factory NonStructuralRatingFloor.fromJson(
    Map<String, dynamic> json,
  ) => NonStructuralRatingFloor(
    brickPlaster: json["brick_plaster"] != null
        ? List<BrickPlasterFloor>.from(
            json["brick_plaster"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    walls: json["walls"] != null
        ? List<BrickPlasterFloor>.from(
            json["walls"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    paintings: json["paintings"] != null
        ? List<BrickPlasterFloor>.from(
            json["paintings"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    doorsWindows: json["doors_windows"] != null
        ? List<BrickPlasterFloor>.from(
            json["doors_windows"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    flooringTiles: json["flooring_tiles"] != null
        ? List<BrickPlasterFloor>.from(
            json["flooring_tiles"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    electricalWiring: json["electrical_wiring"] != null
        ? List<BrickPlasterFloor>.from(
            json["electrical_wiring"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    sanitaryFittings: json["sanitary_fittings"] != null
        ? List<BrickPlasterFloor>.from(
            json["sanitary_fittings"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    railings: json["railings"] != null
        ? List<BrickPlasterFloor>.from(
            json["railings"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    waterTanks: json["water_tanks"] != null
        ? List<BrickPlasterFloor>.from(
            json["water_tanks"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    plumbing: json["plumbing"] != null
        ? List<BrickPlasterFloor>.from(
            json["plumbing"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    sewageSystem: json["sewage_system"] != null
        ? List<BrickPlasterFloor>.from(
            json["sewage_system"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    panelBoard: json["panel_board"] != null
        ? List<BrickPlasterFloor>.from(
            json["panel_board"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    lifts: json["lifts"] != null
        ? List<BrickPlasterFloor>.from(
            json["lifts"].map((x) => BrickPlasterFloor.fromJson(x)),
          )
        : [],
    overallAverage: json["overall_average"]?.toDouble(),
    assessmentDate: json["assessment_date"] != null
        ? DateTime.parse(json["assessment_date"])
        : null,
    inspectorNotes: json["inspector_notes"],
    averages: json["averages"] != null
        ? Averages.fromJson(json["averages"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "brick_plaster": List<dynamic>.from(brickPlaster.map((x) => x.toJson())),
    "walls": List<dynamic>.from(walls.map((x) => x.toJson())),
    "paintings": List<dynamic>.from(paintings.map((x) => x.toJson())),
    "doors_windows": List<dynamic>.from(doorsWindows.map((x) => x.toJson())),
    "flooring_tiles": List<dynamic>.from(flooringTiles.map((x) => x.toJson())),
    "electrical_wiring": List<dynamic>.from(
      electricalWiring.map((x) => x.toJson()),
    ),
    "sanitary_fittings": List<dynamic>.from(
      sanitaryFittings.map((x) => x.toJson()),
    ),
    "railings": List<dynamic>.from(railings.map((x) => x.toJson())),
    "water_tanks": List<dynamic>.from(waterTanks.map((x) => x.toJson())),
    "plumbing": List<dynamic>.from(plumbing.map((x) => x.toJson())),
    "sewage_system": List<dynamic>.from(sewageSystem.map((x) => x.toJson())),
    "panel_board": List<dynamic>.from(panelBoard.map((x) => x.toJson())),
    "lifts": List<dynamic>.from(lifts.map((x) => x.toJson())),
    "overall_average": overallAverage,
    "assessment_date": assessmentDate?.toIso8601String(),
    "inspector_notes": inspectorNotes,
    "averages": averages?.toJson(),
  };
}

class BrickPlasterFloor {
  DistressDimensions distressDimensions;
  String id;
  String name;
  int rating;
  String conditionComment;
  String inspectorNotes;
  DateTime? inspectionDate; // ✅ Nullable — newly saved components may omit this
  String repairMethodology;
  List<String> distressTypes; // ✅ Multi-select list
  List<dynamic> pdfFiles;
  List<dynamic> photos;

  BrickPlasterFloor({
    required this.distressDimensions,
    required this.id,
    required this.name,
    required this.rating,
    required this.conditionComment,
    required this.inspectorNotes,
    this.inspectionDate,
    required this.repairMethodology,
    required this.distressTypes,
    required this.pdfFiles,
    required this.photos,
  });

  factory BrickPlasterFloor.fromJson(Map<String, dynamic> json) {
    // ✅ Normalize distress_types to List<String>
    List<String> parsedDistressTypes = [];
    final rawDistress = json["distress_types"];
    if (rawDistress is String && rawDistress.isNotEmpty) {
      parsedDistressTypes = [rawDistress];
    } else if (rawDistress is List && rawDistress.isNotEmpty) {
      parsedDistressTypes = rawDistress.map((e) => e.toString()).toList();
    }

    // ✅ Safely parse photos — guard against String instead of List
    List<dynamic> parsedPhotos = [];
    final rawPhotos = json["photos"];
    if (rawPhotos is List) {
      parsedPhotos = List<dynamic>.from(rawPhotos);
    } else if (rawPhotos is String && rawPhotos.isNotEmpty) {
      parsedPhotos = [rawPhotos];
    }

    // ✅ Safely parse pdf_files — guard against String instead of List
    List<dynamic> parsedPdfFiles = [];
    final rawPdfFiles = json["pdf_files"];
    if (rawPdfFiles is List) {
      parsedPdfFiles = List<dynamic>.from(rawPdfFiles);
    } else if (rawPdfFiles is String && rawPdfFiles.isNotEmpty) {
      parsedPdfFiles = [rawPdfFiles];
    }

    return BrickPlasterFloor(
      distressDimensions: DistressDimensions.fromJson(
        json["distress_dimensions"] ?? {},
      ),
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      rating: json["rating"] ?? 0,
      conditionComment: json["condition_comment"] ?? "",
      inspectorNotes: json["inspector_notes"] ?? "",
      inspectionDate: json["inspection_date"] != null
          ? DateTime.tryParse(json["inspection_date"])
          : null,
      repairMethodology: json["repair_methodology"] ?? "",
      distressTypes: parsedDistressTypes,
      pdfFiles: parsedPdfFiles,
      photos: parsedPhotos,
    );
  }

  Map<String, dynamic> toJson() => {
    "distress_dimensions": distressDimensions.toJson(),
    "_id": id,
    "name": name,
    "rating": rating,
    "condition_comment": conditionComment,
    "inspector_notes": inspectorNotes,
    "inspection_date": inspectionDate?.toIso8601String(),
    "repair_methodology": repairMethodology,
    "distress_types": distressTypes,
    "pdf_files": pdfFiles,
    "photos": photos,
  };
}

class DistressDimensions {
  double length;
  double? breadth; // ✅ Made nullable
  double? height; // ✅ Made nullable
  String unit;

  DistressDimensions({
    required this.length,
    this.breadth, // ✅ Optional
    this.height, // ✅ Optional
    required this.unit,
  });

  factory DistressDimensions.fromJson(
    Map<String, dynamic> json,
  ) => DistressDimensions(
    length: (json["length"] is num) ? (json["length"] as num).toDouble() : 0,
    breadth: (json["breadth"] is num)
        ? (json["breadth"] as num).toDouble()
        : null,
    height: (json["height"] is num) ? (json["height"] as num).toDouble() : null,
    unit: json["unit"] ?? "NO'S",
  );

  Map<String, dynamic> toJson() => {
    "length": length,
    "breadth": breadth,
    "height": height,
    "unit": unit,
  };
}

// ✅ FIXED: StructuralRatingFloor now uses Lists for all components
class StructuralRatingFloor {
  List<BrickPlasterFloor> beams; // Changed to List
  List<BrickPlasterFloor> columns; // Changed to List
  List<BrickPlasterFloor> slabs; // Changed to List (note: plural)
  List<BrickPlasterFloor> foundations; // Changed to List (note: plural)
  double? overallAverage;
  String? healthStatus;
  DateTime? assessmentDate;
  String? inspectorNotes;
  Averages? averages;

  StructuralRatingFloor({
    required this.beams,
    required this.columns,
    required this.slabs,
    required this.foundations,
    this.overallAverage,
    this.healthStatus,
    this.assessmentDate,
    this.inspectorNotes,
    this.averages,
  });

  factory StructuralRatingFloor.fromJson(Map<String, dynamic> json) =>
      StructuralRatingFloor(
        beams: json["beams"] != null
            ? List<BrickPlasterFloor>.from(
                json["beams"].map((x) => BrickPlasterFloor.fromJson(x)),
              )
            : [],
        columns: json["columns"] != null
            ? List<BrickPlasterFloor>.from(
                json["columns"].map((x) => BrickPlasterFloor.fromJson(x)),
              )
            : [],
        slabs: json["slabs"] != null
            ? List<BrickPlasterFloor>.from(
                json["slabs"].map((x) => BrickPlasterFloor.fromJson(x)),
              )
            : [],
        foundations: json["foundations"] != null
            ? List<BrickPlasterFloor>.from(
                json["foundations"].map((x) => BrickPlasterFloor.fromJson(x)),
              )
            : [],
        overallAverage: json["overall_average"]?.toDouble(),
        healthStatus: json["health_status"],
        assessmentDate: json["assessment_date"] != null
            ? DateTime.parse(json["assessment_date"])
            : null,
        inspectorNotes: json["inspector_notes"],
        averages: json["averages"] != null
            ? Averages.fromJson(json["averages"])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "beams": List<dynamic>.from(beams.map((x) => x.toJson())),
    "columns": List<dynamic>.from(columns.map((x) => x.toJson())),
    "slabs": List<dynamic>.from(slabs.map((x) => x.toJson())),
    "foundations": List<dynamic>.from(foundations.map((x) => x.toJson())),
    "overall_average": overallAverage,
    "health_status": healthStatus,
    "assessment_date": assessmentDate?.toIso8601String(),
    "inspector_notes": inspectorNotes,
    "averages": averages?.toJson(),
  };
}

// Helper class for averages
class Averages {
  double? beams;
  double? columns;
  double? slabs;
  double? foundations;
  double? brickPlaster;
  double? walls;
  double? paintings;
  double? doorsWindows;
  double? flooringTiles;
  double? electricalWiring;
  double? sanitaryFittings;
  double? railings;
  double? waterTanks;
  double? plumbing;
  double? sewageSystem;
  double? panelBoard;
  double? lifts;

  Averages({
    this.beams,
    this.columns,
    this.slabs,
    this.foundations,
    this.brickPlaster,
    this.walls,
    this.paintings,
    this.doorsWindows,
    this.flooringTiles,
    this.electricalWiring,
    this.sanitaryFittings,
    this.railings,
    this.waterTanks,
    this.plumbing,
    this.sewageSystem,
    this.panelBoard,
    this.lifts,
  });

  factory Averages.fromJson(Map<String, dynamic> json) => Averages(
    beams: json["beams"]?.toDouble(),
    columns: json["columns"]?.toDouble(),
    slabs: json["slabs"]?.toDouble(),
    foundations: json["foundations"]?.toDouble(),
    brickPlaster: json["brick_plaster"]?.toDouble(),
    walls: json["walls"]?.toDouble(),
    paintings: json["paintings"]?.toDouble(),
    doorsWindows: json["doors_windows"]?.toDouble(),
    flooringTiles: json["flooring_tiles"]?.toDouble(),
    electricalWiring: json["electrical_wiring"]?.toDouble(),
    sanitaryFittings: json["sanitary_fittings"]?.toDouble(),
    railings: json["railings"]?.toDouble(),
    waterTanks: json["water_tanks"]?.toDouble(),
    plumbing: json["plumbing"]?.toDouble(),
    sewageSystem: json["sewage_system"]?.toDouble(),
    panelBoard: json["panel_board"]?.toDouble(),
    lifts: json["lifts"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "beams": beams,
    "columns": columns,
    "slabs": slabs,
    "foundations": foundations,
    "brick_plaster": brickPlaster,
    "walls": walls,
    "paintings": paintings,
    "doors_windows": doorsWindows,
    "flooring_tiles": flooringTiles,
    "electrical_wiring": electricalWiring,
    "sanitary_fittings": sanitaryFittings,
    "railings": railings,
    "water_tanks": waterTanks,
    "plumbing": plumbing,
    "sewage_system": sewageSystem,
    "panel_board": panelBoard,
    "lifts": lifts,
  };
}
