import 'dart:convert';

GetAllRatingsFlatsModel getAllRatingsFlatsModelFromJson(String str) =>
    GetAllRatingsFlatsModel.fromJson(json.decode(str));

String getAllRatingsFlatsModelToJson(GetAllRatingsFlatsModel data) =>
    json.encode(data.toJson());

class GetAllRatingsFlatsModel {
  bool success;
  String message;
  Data data;

  GetAllRatingsFlatsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory GetAllRatingsFlatsModel.fromJson(Map<String, dynamic> json) =>
      GetAllRatingsFlatsModel(
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
  String floorType;
  String floorLabelName;
  double floorHeight;
  int totalAreaSqMts;
  StructuralRating structuralRating;
  NonStructuralRating nonStructuralRating;
  FlatOverallRating flatOverallRating;
  Statistics statistics;

  Data({
    required this.structureId,
    required this.floorId,
    required this.floorNumber,
    required this.floorType,
    required this.floorLabelName,
    required this.floorHeight,
    required this.totalAreaSqMts,
    required this.structuralRating,
    required this.nonStructuralRating,
    required this.flatOverallRating,
    required this.statistics,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    structureId: json["structure_id"],
    floorId: json["floor_id"],
    floorNumber: json["floor_number"],
    floorType: json["floor_type"],
    floorLabelName: json["floor_label_name"],
    floorHeight: json["floor_height"]?.toDouble(),
    totalAreaSqMts: json["total_area_sq_mts"],
    structuralRating: StructuralRating.fromJson(json["structural_rating"]),
    nonStructuralRating: NonStructuralRating.fromJson(
      json["non_structural_rating"],
    ),
    flatOverallRating: FlatOverallRating.fromJson(json["flat_overall_rating"]),
    statistics: Statistics.fromJson(json["statistics"]),
  );

  Map<String, dynamic> toJson() => {
    "structure_id": structureId,

    "floor_id": floorId,
    "floor_number": floorNumber,
    "floor_type": floorType,
    "floor_label_name": floorLabelName,
    "floor_height": floorHeight,
    "total_area_sq_mts": totalAreaSqMts,
    "structural_rating": structuralRating.toJson(),
    "non_structural_rating": nonStructuralRating.toJson(),
    "flat_overall_rating": flatOverallRating.toJson(),
    "statistics": statistics.toJson(),
  };
}

class FlatOverallRating {
  double combinedScore;
  String healthStatus;
  String priority;
  DateTime lastAssessmentDate;

  FlatOverallRating({
    required this.combinedScore,
    required this.healthStatus,
    required this.priority,
    required this.lastAssessmentDate,
  });

  factory FlatOverallRating.fromJson(Map<String, dynamic> json) =>
      FlatOverallRating(
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

class NonStructuralRating {
  BrickPlaster brickPlaster;
  BrickPlaster doorsWindows;
  BrickPlaster flooringTiles;
  BrickPlaster walls;
  BrickPlaster paintings;
  BrickPlaster electricalWiring;
  BrickPlaster sanitaryFittings;
  BrickPlaster railings;
  BrickPlaster waterTanks;
  BrickPlaster plumbing;
  BrickPlaster sewageSystem;
  BrickPlaster panelBoard;
  BrickPlaster lifts;
  double overallAverage;
  DateTime assessmentDate;

  NonStructuralRating({
    required this.brickPlaster,
    required this.doorsWindows,
    required this.flooringTiles,
    required this.walls,
    required this.paintings,
    required this.electricalWiring,
    required this.sanitaryFittings,
    required this.railings,
    required this.waterTanks,
    required this.plumbing,
    required this.sewageSystem,
    required this.panelBoard,
    required this.lifts,
    required this.overallAverage,
    required this.assessmentDate,
  });

  factory NonStructuralRating.fromJson(Map<String, dynamic> json) =>
      NonStructuralRating(
        brickPlaster: BrickPlaster.fromJson(json["brick_plaster"]),
        doorsWindows: BrickPlaster.fromJson(json["doors_windows"]),
        flooringTiles: BrickPlaster.fromJson(json["flooring_tiles"]),
        walls: BrickPlaster.fromJson(json["walls"]),
        paintings: BrickPlaster.fromJson(json["paintings"]),
        electricalWiring: BrickPlaster.fromJson(json["electrical_wiring"]),
        sanitaryFittings: BrickPlaster.fromJson(json["sanitary_fittings"]),
        railings: BrickPlaster.fromJson(json["railings"]),
        waterTanks: BrickPlaster.fromJson(json["water_tanks"]),
        plumbing: BrickPlaster.fromJson(json["plumbing"]),
        sewageSystem: BrickPlaster.fromJson(json["sewage_system"]),
        panelBoard: BrickPlaster.fromJson(json["panel_board"]),
        lifts: BrickPlaster.fromJson(json["lifts"]),
        overallAverage: json["overall_average"]?.toDouble(),
        assessmentDate: DateTime.parse(json["assessment_date"]),
      );

  Map<String, dynamic> toJson() => {
    "brick_plaster": brickPlaster.toJson(),
    "doors_windows": doorsWindows.toJson(),
    "flooring_tiles": flooringTiles.toJson(),
    "walls": walls.toJson(),
    "paintings": paintings.toJson(),
    "electrical_wiring": electricalWiring.toJson(),
    "sanitary_fittings": sanitaryFittings.toJson(),
    "railings": railings.toJson(),
    "water_tanks": waterTanks.toJson(),
    "plumbing": plumbing.toJson(),
    "sewage_system": sewageSystem.toJson(),
    "panel_board": panelBoard.toJson(),
    "lifts": lifts.toJson(),
    "overall_average": overallAverage,
    "assessment_date": assessmentDate.toIso8601String(),
  };
}

class BrickPlaster {
  DistressDimensions distressDimensions;
  int rating;
  String conditionComment;
  String photo;
  List<String> photos;
  List<dynamic> pdfFiles;
  DateTime inspectionDate;
  String inspectorNotes;
  String id;
  String name;
  String repairMethodology;
  List<String> distressTypes;

  BrickPlaster({
    required this.distressDimensions,
    required this.rating,
    required this.conditionComment,
    required this.photo,
    required this.photos,
    required this.pdfFiles,
    required this.inspectionDate,
    required this.inspectorNotes,
    required this.id,
    required this.name,
    required this.repairMethodology,
    required this.distressTypes,
  });

  factory BrickPlaster.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    final rawPhotos = json["photos"];
    if (rawPhotos is List) {
      parsedPhotos = List<String>.from(rawPhotos.map((x) => x.toString()));
    } else if (rawPhotos is String && rawPhotos.isNotEmpty) {
      parsedPhotos = [rawPhotos];
    }

    List<dynamic> parsedPdfFiles = [];
    final rawPdfFiles = json["pdf_files"];
    if (rawPdfFiles is List) {
      parsedPdfFiles = List<dynamic>.from(rawPdfFiles);
    } else if (rawPdfFiles is String && rawPdfFiles.isNotEmpty) {
      parsedPdfFiles = [rawPdfFiles];
    }

    List<String> parsedDistressTypes = [];
    final rawDistress = json["distress_types"];
    if (rawDistress is String && rawDistress.isNotEmpty) {
      parsedDistressTypes = [rawDistress];
    } else if (rawDistress is List && rawDistress.isNotEmpty) {
      parsedDistressTypes = rawDistress.map((e) => e.toString()).toList();
    }

    return BrickPlaster(
      distressDimensions: DistressDimensions.fromJson(
        json["distress_dimensions"] ?? {},
      ),
      rating: json["rating"],
      conditionComment: json["condition_comment"],
      photo: json["photo"] ?? "",
      photos: parsedPhotos,
      pdfFiles: parsedPdfFiles,
      inspectionDate: json["inspection_date"] != null
          ? DateTime.parse(json["inspection_date"])
          : DateTime.now(),
      inspectorNotes: json["inspector_notes"] ?? "",
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      repairMethodology: json["repair_methodology"] ?? "",
      distressTypes: parsedDistressTypes,
    );
  }

  Map<String, dynamic> toJson() => {
    "distress_dimensions": distressDimensions.toJson(),
    "rating": rating,
    "condition_comment": conditionComment,
    "photo": photo,
    "photos": List<dynamic>.from(photos.map((x) => x)),
    "pdf_files": pdfFiles,
    "inspection_date": inspectionDate.toIso8601String(),
    "inspector_notes": inspectorNotes,
    "_id": id,
    "name": name,
    "repair_methodology": repairMethodology,
    "distress_types": distressTypes,
  };
}

class DistressDimensions {
  double? number;
  double length;
  double? breadth;
  double? height;
  String unit;

  DistressDimensions({
    this.number,
    required this.length,
    this.breadth,
    this.height,
    required this.unit,
  });

  factory DistressDimensions.fromJson(
    Map<String, dynamic> json,
  ) => DistressDimensions(
    number: (json["number"] is num) ? (json["number"] as num).toDouble() : null,
    length: (json["length"] is num) ? (json["length"] as num).toDouble() : 0,
    breadth: (json["breadth"] is num)
        ? (json["breadth"] as num).toDouble()
        : null,
    height: (json["height"] is num) ? (json["height"] as num).toDouble() : null,
    unit: json["unit"] ?? "NO'S",
  );

  Map<String, dynamic> toJson() => {
    "number": number,
    "length": length,
    "breadth": breadth,
    "height": height,
    "unit": unit,
  };
}

class DoorsWindows {
  dynamic rating;
  String conditionComment;
  String photo;
  dynamic inspectionDate;

  DoorsWindows({
    required this.rating,
    required this.conditionComment,
    required this.photo,
    required this.inspectionDate,
  });

  factory DoorsWindows.fromJson(Map<String, dynamic> json) => DoorsWindows(
    rating: json["rating"],
    conditionComment: json["condition_comment"],
    photo: json["photo"],
    inspectionDate: json["inspection_date"],
  );

  Map<String, dynamic> toJson() => {
    "rating": rating,
    "condition_comment": conditionComment,
    "photo": photo,
    "inspection_date": inspectionDate,
  };
}

class StructuralRating {
  BrickPlaster beams;
  BrickPlaster columns;
  BrickPlaster slab;
  BrickPlaster foundation;
  double overallAverage;
  String healthStatus;
  DateTime assessmentDate;

  StructuralRating({
    required this.beams,
    required this.columns,
    required this.slab,
    required this.foundation,
    required this.overallAverage,
    required this.healthStatus,
    required this.assessmentDate,
  });

  factory StructuralRating.fromJson(Map<String, dynamic> json) =>
      StructuralRating(
        beams: BrickPlaster.fromJson(json["beams"]),
        columns: BrickPlaster.fromJson(json["columns"]),
        slab: BrickPlaster.fromJson(json["slab"]),
        foundation: BrickPlaster.fromJson(json["foundation"]),
        overallAverage: json["overall_average"]?.toDouble(),
        healthStatus: json["health_status"],
        assessmentDate: DateTime.parse(json["assessment_date"]),
      );

  Map<String, dynamic> toJson() => {
    "beams": beams.toJson(),
    "columns": columns.toJson(),
    "slab": slab.toJson(),
    "foundation": foundation.toJson(),
    "overall_average": overallAverage,
    "health_status": healthStatus,
    "assessment_date": assessmentDate.toIso8601String(),
  };
}

class Statistics {
  int totalStructuralComponents;
  int totalNonStructuralComponents;
  int componentsWithPhotos;
  int componentsBelowRating3;
  bool hasStructuralRatings;
  bool hasNonStructuralRatings;
  DateTime lastStructuralUpdate;
  DateTime lastNonStructuralUpdate;

  Statistics({
    required this.totalStructuralComponents,
    required this.totalNonStructuralComponents,
    required this.componentsWithPhotos,
    required this.componentsBelowRating3,
    required this.hasStructuralRatings,
    required this.hasNonStructuralRatings,
    required this.lastStructuralUpdate,
    required this.lastNonStructuralUpdate,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
    totalStructuralComponents: json["total_structural_components"],
    totalNonStructuralComponents: json["total_non_structural_components"],
    componentsWithPhotos: json["components_with_photos"],
    componentsBelowRating3: json["components_below_rating_3"],
    hasStructuralRatings: json["has_structural_ratings"],
    hasNonStructuralRatings: json["has_non_structural_ratings"],
    lastStructuralUpdate: DateTime.parse(json["last_structural_update"]),
    lastNonStructuralUpdate: DateTime.parse(json["last_non_structural_update"]),
  );

  Map<String, dynamic> toJson() => {
    "total_structural_components": totalStructuralComponents,
    "total_non_structural_components": totalNonStructuralComponents,
    "components_with_photos": componentsWithPhotos,
    "components_below_rating_3": componentsBelowRating3,
    "has_structural_ratings": hasStructuralRatings,
    "has_non_structural_ratings": hasNonStructuralRatings,
    "last_structural_update": lastStructuralUpdate.toIso8601String(),
    "last_non_structural_update": lastNonStructuralUpdate.toIso8601String(),
  };
}
