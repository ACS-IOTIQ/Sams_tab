// To parse this JSON data, do
//
//     final getFloorsIdByFlatByStrId = getFloorsIdByFlatByStrIdFromJson(jsonString);

import 'dart:convert';

GetFloorsIdByFlatByStrId getFloorsIdByFlatByStrIdFromJson(String str) => GetFloorsIdByFlatByStrId.fromJson(json.decode(str));

String getFloorsIdByFlatByStrIdToJson(GetFloorsIdByFlatByStrId data) => json.encode(data.toJson());

class GetFloorsIdByFlatByStrId {
    bool success;
    String message;
    Data data;

    GetFloorsIdByFlatByStrId({
        required this.success,
        required this.message,
        required this.data,
    });

    factory GetFloorsIdByFlatByStrId.fromJson(Map<String, dynamic> json) => GetFloorsIdByFlatByStrId(
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
    int totalFlats;
    List<Flat> flats;

    Data({
        required this.structureId,
        required this.floorId,
        required this.floorNumber,
        required this.totalFlats,
        required this.flats,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"],
        floorId: json["floor_id"],
        floorNumber: json["floor_number"],
        totalFlats: json["total_flats"],
        flats: List<Flat>.from(json["flats"].map((x) => Flat.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "floor_id": floorId,
        "floor_number": floorNumber,
        "total_flats": totalFlats,
        "flats": List<dynamic>.from(flats.map((x) => x.toJson())),
    };
}

class Flat {
    String flatId;
    String mongodbId;
    String flatNumber;
    String flatType;
    int areaSqMts;
    String directionFacing;
    String occupancyStatus;
    String flatNotes;
    StructuralRating structuralRating;
    StructuralRating nonStructuralRating;
    FlatOverallRating flatOverallRating;
    dynamic healthStatus;
    dynamic priority;
    dynamic combinedScore;

    Flat({
        required this.flatId,
        required this.mongodbId,
        required this.flatNumber,
        required this.flatType,
        required this.areaSqMts,
        required this.directionFacing,
        required this.occupancyStatus,
        required this.flatNotes,
        required this.structuralRating,
        required this.nonStructuralRating,
        required this.flatOverallRating,
        required this.healthStatus,
        required this.priority,
        required this.combinedScore,
    });

    factory Flat.fromJson(Map<String, dynamic> json) => Flat(
        flatId: json["flat_id"],
        mongodbId: json["mongodb_id"],
        flatNumber: json["flat_number"],
        flatType: json["flat_type"],
        areaSqMts: json["area_sq_mts"],
        directionFacing: json["direction_facing"],
        occupancyStatus: json["occupancy_status"],
        flatNotes: json["flat_notes"],
        structuralRating: StructuralRating.fromJson(json["structural_rating"]),
        nonStructuralRating: StructuralRating.fromJson(json["non_structural_rating"]),
        flatOverallRating: FlatOverallRating.fromJson(json["flat_overall_rating"]),
        healthStatus: json["health_status"],
        priority: json["priority"],
        combinedScore: json["combined_score"],
    );

    Map<String, dynamic> toJson() => {
        "flat_id": flatId,
        "mongodb_id": mongodbId,
        "flat_number": flatNumber,
        "flat_type": flatType,
        "area_sq_mts": areaSqMts,
        "direction_facing": directionFacing,
        "occupancy_status": occupancyStatus,
        "flat_notes": flatNotes,
        "structural_rating": structuralRating.toJson(),
        "non_structural_rating": nonStructuralRating.toJson(),
        "flat_overall_rating": flatOverallRating.toJson(),
        "health_status": healthStatus,
        "priority": priority,
        "combined_score": combinedScore,
    };
}

class FlatOverallRating {
    DateTime lastAssessmentDate;

    FlatOverallRating({
        required this.lastAssessmentDate,
    });

    factory FlatOverallRating.fromJson(Map<String, dynamic> json) => FlatOverallRating(
        lastAssessmentDate: DateTime.parse(json["last_assessment_date"]),
    );

    Map<String, dynamic> toJson() => {
        "last_assessment_date": lastAssessmentDate.toIso8601String(),
    };
}

class StructuralRating {
    DateTime assessmentDate;

    StructuralRating({
        required this.assessmentDate,
    });

    factory StructuralRating.fromJson(Map<String, dynamic> json) => StructuralRating(
        assessmentDate: DateTime.parse(json["assessment_date"]),
    );

    Map<String, dynamic> toJson() => {
        "assessment_date": assessmentDate.toIso8601String(),
    };
}
