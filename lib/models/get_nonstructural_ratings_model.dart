// To parse this JSON data, do
//
//     final getNonStructuralRatingsFLoorIdbyFlatId = getNonStructuralRatingsFLoorIdbyFlatIdFromJson(jsonString);

// ignore_for_file: constant_identifier_names

import 'dart:convert';

GetNonStructuralRatingsFLoorIdbyFlatId
getNonStructuralRatingsFLoorIdbyFlatIdFromJson(String str) =>
    GetNonStructuralRatingsFLoorIdbyFlatId.fromJson(json.decode(str));

String getNonStructuralRatingsFLoorIdbyFlatIdToJson(
  GetNonStructuralRatingsFLoorIdbyFlatId data,
) => json.encode(data.toJson());

class GetNonStructuralRatingsFLoorIdbyFlatId {
  final bool? success;
  final String? message;
  final Data? data;

  GetNonStructuralRatingsFLoorIdbyFlatId({
    this.success,
    this.message,
    this.data,
  });

  factory GetNonStructuralRatingsFLoorIdbyFlatId.fromJson(
    Map<String, dynamic> json,
  ) => GetNonStructuralRatingsFLoorIdbyFlatId(
    success: json["success"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  final String? structureId;
  final String? floorId;
  final String? flatId;
  final String? flatNumber;
  final NonStructuralRating? nonStructuralRating;

  Data({
    this.structureId,
    this.floorId,
    this.flatId,
    this.flatNumber,
    this.nonStructuralRating,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    structureId: json["structure_id"],
    floorId: json["floor_id"],
    flatId: json["flat_id"],
    flatNumber: json["flat_number"],
    nonStructuralRating: json["non_structural_rating"] == null
        ? null
        : NonStructuralRating.fromJson(json["non_structural_rating"]),
  );

  Map<String, dynamic> toJson() => {
    "structure_id": structureId,
    "floor_id": floorId,
    "flat_id": flatId,
    "flat_number": flatNumber,
    "non_structural_rating": nonStructuralRating?.toJson(),
  };
}

class NonStructuralRating {
  final BrickPlaster? brickPlaster;
  final BrickPlaster? doorsWindows;
  final BrickPlaster? flooringTiles;
  final BrickPlaster? electricalWiring;
  final BrickPlaster? sanitaryFittings;
  final BrickPlaster? railings;
  final BrickPlaster? waterTanks;
  final BrickPlaster? plumbing;
  final BrickPlaster? sewageSystem;
  final BrickPlaster? panelBoard;
  final BrickPlaster? lifts;
  final double? overallAverage;
  final DateTime? assessmentDate;

  NonStructuralRating({
    this.brickPlaster,
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
    this.overallAverage,
    this.assessmentDate,
  });

  factory NonStructuralRating.fromJson(Map<String, dynamic> json) =>
      NonStructuralRating(
        brickPlaster: json["brick_plaster"] == null
            ? null
            : BrickPlaster.fromJson(json["brick_plaster"]),
        doorsWindows: json["doors_windows"] == null
            ? null
            : BrickPlaster.fromJson(json["doors_windows"]),
        flooringTiles: json["flooring_tiles"] == null
            ? null
            : BrickPlaster.fromJson(json["flooring_tiles"]),
        electricalWiring: json["electrical_wiring"] == null
            ? null
            : BrickPlaster.fromJson(json["electrical_wiring"]),
        sanitaryFittings: json["sanitary_fittings"] == null
            ? null
            : BrickPlaster.fromJson(json["sanitary_fittings"]),
        railings: json["railings"] == null
            ? null
            : BrickPlaster.fromJson(json["railings"]),
        waterTanks: json["water_tanks"] == null
            ? null
            : BrickPlaster.fromJson(json["water_tanks"]),
        plumbing: json["plumbing"] == null
            ? null
            : BrickPlaster.fromJson(json["plumbing"]),
        sewageSystem: json["sewage_system"] == null
            ? null
            : BrickPlaster.fromJson(json["sewage_system"]),
        panelBoard: json["panel_board"] == null
            ? null
            : BrickPlaster.fromJson(json["panel_board"]),
        lifts: json["lifts"] == null
            ? null
            : BrickPlaster.fromJson(json["lifts"]),
        overallAverage: json["overall_average"]?.toDouble(),
        assessmentDate: json["assessment_date"] == null
            ? null
            : DateTime.parse(json["assessment_date"]),
      );

  Map<String, dynamic> toJson() => {
    "brick_plaster": brickPlaster?.toJson(),
    "doors_windows": doorsWindows?.toJson(),
    "flooring_tiles": flooringTiles?.toJson(),
    "electrical_wiring": electricalWiring?.toJson(),
    "sanitary_fittings": sanitaryFittings?.toJson(),
    "railings": railings?.toJson(),
    "water_tanks": waterTanks?.toJson(),
    "plumbing": plumbing?.toJson(),
    "sewage_system": sewageSystem?.toJson(),
    "panel_board": panelBoard?.toJson(),
    "lifts": lifts?.toJson(),
    "overall_average": overallAverage,
    "assessment_date": assessmentDate?.toIso8601String(),
  };
}

class BrickPlaster {
  final int? rating;
  final ConditionComment? conditionComment;
  final DateTime? inspectionDate;
  final List<String>? photos;
  final String? inspectorNotes;

  BrickPlaster({
    this.rating,
    this.conditionComment,
    this.inspectionDate,
    this.photos,
    this.inspectorNotes,
  });
  factory BrickPlaster.fromJson(Map<String, dynamic> json) => BrickPlaster(
    rating: json["rating"],
    conditionComment: json["condition_comment"] == null
        ? null
        : conditionCommentValues.map[json["condition_comment"]],
    inspectionDate: json["inspection_date"] == null
        ? null
        : DateTime.parse(json["inspection_date"]),
    photos: json["photos"] == null
        ? []
        : List<String>.from(json["photos"]!.map((x) => x)),
    inspectorNotes: json["inspector_notes"],
  );

  Map<String, dynamic> toJson() => {
    "rating": rating,
    "condition_comment": conditionCommentValues.reverse[conditionComment],
    "inspection_date": inspectionDate?.toIso8601String(),
    "photos": photos == null ? [] : List<dynamic>.from(photos!.map((x) => x)),
    "inspector_notes": inspectorNotes,
  };
}

enum ConditionComment { EMPTY, GOOD }

final conditionCommentValues = EnumValues({
  "": ConditionComment.EMPTY,
  "good": ConditionComment.GOOD,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
