// To parse this JSON data, do
//
//     final getStructuralRatingsFLoorIdbyFlatId = getStructuralRatingsFLoorIdbyFlatIdFromJson(jsonString);

import 'dart:convert';

GetStructuralRatingsFLoorIdbyFlatId getStructuralRatingsFLoorIdbyFlatIdFromJson(
  String str,
) => GetStructuralRatingsFLoorIdbyFlatId.fromJson(json.decode(str));

String getStructuralRatingsFLoorIdbyFlatIdToJson(
  GetStructuralRatingsFLoorIdbyFlatId data,
) => json.encode(data.toJson());

class GetStructuralRatingsFLoorIdbyFlatId {
  final bool? success;
  final String? message;
  final Data? data;

  GetStructuralRatingsFLoorIdbyFlatId({this.success, this.message, this.data});

  factory GetStructuralRatingsFLoorIdbyFlatId.fromJson(
    Map<String, dynamic> json,
  ) => GetStructuralRatingsFLoorIdbyFlatId(
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
  final StructuralRating? structuralRating;

  Data({
    this.structureId,
    this.floorId,
    this.flatId,
    this.flatNumber,
    this.structuralRating,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    structureId: json["structure_id"],
    floorId: json["floor_id"],
    flatId: json["flat_id"],
    flatNumber: json["flat_number"],
    structuralRating: json["structural_rating"] == null
        ? null
        : StructuralRating.fromJson(json["structural_rating"]),
  );

  Map<String, dynamic> toJson() => {
    "structure_id": structureId,
    "floor_id": floorId,
    "flat_id": flatId,
    "flat_number": flatNumber,
    "structural_rating": structuralRating?.toJson(),
  };
}

class StructuralRating {
  final Beams? beams;
  final Beams? columns;
  final Beams? slab;
  final Beams? foundation;
  final int? overallAverage;
  final String? healthStatus;
  final DateTime? assessmentDate;

  StructuralRating({
    this.beams,
    this.columns,
    this.slab,
    this.foundation,
    this.overallAverage,
    this.healthStatus, 
    this.assessmentDate,
  });

  factory StructuralRating.fromJson(Map<String, dynamic> json) =>
      StructuralRating(
        beams: json["beams"] == null ? null : Beams.fromJson(json["beams"]),
        columns: json["columns"] == null
            ? null
            : Beams.fromJson(json["columns"]),
        slab: json["slab"] == null ? null : Beams.fromJson(json["slab"]),
        foundation: json["foundation"] == null
            ? null
            : Beams.fromJson(json["foundation"]),
        overallAverage: json["overall_average"] == null
            ? null
            : (json["overall_average"] as num).toInt(),
        healthStatus: json["health_status"],
        assessmentDate: json["assessment_date"] == null
            ? null
            : DateTime.parse(json["assessment_date"]),
      );

  Map<String, dynamic> toJson() => {
    "beams": beams?.toJson(),
    "columns": columns?.toJson(),
    "slab": slab?.toJson(),
    "foundation": foundation?.toJson(),
    "overall_average": overallAverage,
    "health_status": healthStatus,
    "assessment_date": assessmentDate?.toIso8601String(),
  };
}

class Beams {
  final int? rating;
  final String? conditionComment;
  final DateTime? inspectionDate;
  final List<dynamic>? photos;
  final String? inspectorNotes;

  Beams({
    this.rating,
    this.conditionComment,
    this.inspectionDate,
    this.photos,
    this.inspectorNotes,
  });

  factory Beams.fromJson(Map<String, dynamic> json) => Beams(
    rating: json["rating"] == null ? null : (json["rating"] as num).toInt(),

    conditionComment: json["condition_comment"],
    inspectionDate: json["inspection_date"] == null
        ? null
        : DateTime.parse(json["inspection_date"]),
    photos: json["photos"] == null
        ? []
        : List<dynamic>.from(json["photos"]!.map((x) => x)),
    inspectorNotes: json["inspector_notes"],
  );

  Map<String, dynamic> toJson() => {
    "rating": rating,
    "condition_comment": conditionComment,
    "inspection_date": inspectionDate?.toIso8601String(),
    "photos": photos == null ? [] : List<dynamic>.from(photos!.map((x) => x)),
    "inspector_notes": inspectorNotes,
  };
}
