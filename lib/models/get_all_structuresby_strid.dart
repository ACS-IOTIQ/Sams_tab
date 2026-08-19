// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

GetRatingsFLoorIdbyFlatId getRatingsFLoorIdbyFlatIdFromJson(String str) =>
    GetRatingsFLoorIdbyFlatId.fromJson(json.decode(str));

String getRatingsFLoorIdbyFlatIdToJson(GetRatingsFLoorIdbyFlatId data) =>
    json.encode(data.toJson());

class GetRatingsFLoorIdbyFlatId {
  bool? success;
  String? message;
  Data? data;

  GetRatingsFLoorIdbyFlatId({this.success, this.message, this.data});

  GetRatingsFLoorIdbyFlatId.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

// FIXED: Removed extra fields that don't exist in the API response
class Data {
  final StructuralRating? structuralRating;
  final NonStructuralRating? nonStructuralRating;

  Data({this.structuralRating, this.nonStructuralRating});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    structuralRating: json["structural_rating"] == null
        ? null
        : StructuralRating.fromJson(json["structural_rating"]),
    nonStructuralRating: json["non_structural_rating"] == null
        ? null
        : NonStructuralRating.fromJson(json["non_structural_rating"]),
  );

  Map<String, dynamic> toJson() => {
    "structural_rating": structuralRating?.toJson(),
    "non_structural_rating": nonStructuralRating?.toJson(),
  };
}

class StructuralRating {
  RatingItem? beams;
  RatingItem? columns;
  RatingItem? slab;
  RatingItem? foundation;
  double? overallAverage;
  String? healthStatus;
  String? assessmentDate;

  StructuralRating({
    this.beams,
    this.columns,
    this.slab,
    this.foundation,
    this.overallAverage,
    this.healthStatus,
    this.assessmentDate,
  });

  StructuralRating.fromJson(Map<String, dynamic> json) {
    beams = json['beams'] != null ? RatingItem.fromJson(json['beams']) : null;
    columns = json['columns'] != null
        ? RatingItem.fromJson(json['columns'])
        : null;
    slab = json['slab'] != null ? RatingItem.fromJson(json['slab']) : null;
    foundation = json['foundation'] != null
        ? RatingItem.fromJson(json['foundation'])
        : null;
    overallAverage = json['overall_average']?.toDouble();
    healthStatus = json['health_status'];
    assessmentDate = json['assessment_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (beams != null) data['beams'] = beams!.toJson();
    if (columns != null) data['columns'] = columns!.toJson();
    if (slab != null) data['slab'] = slab!.toJson();
    if (foundation != null) data['foundation'] = foundation!.toJson();
    data['overall_average'] = overallAverage;
    data['health_status'] = healthStatus;
    data['assessment_date'] = assessmentDate;
    return data;
  }
}

class NonStructuralRating {
  RatingItem? brickPlaster;
  RatingItem? doorsWindows;
  RatingItem? flooringTiles;
  RatingItem? electricalWiring;
  RatingItem? sanitaryFittings;
  RatingItem? railings;
  RatingItem? waterTanks;
  RatingItem? plumbing;
  RatingItem? sewageSystem;
  RatingItem? panelBoard;
  RatingItem? lifts;
  double? overallAverage;
  String? assessmentDate;

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

  NonStructuralRating.fromJson(Map<String, dynamic> json) {
    // Note: API uses snake_case, so we map them correctly
    brickPlaster = json['brick_plaster'] != null
        ? RatingItem.fromJson(json['brick_plaster'])
        : null;
    doorsWindows = json['doors_windows'] != null
        ? RatingItem.fromJson(json['doors_windows'])
        : null;
    flooringTiles = json['flooring_tiles'] != null
        ? RatingItem.fromJson(json['flooring_tiles'])
        : null;
    electricalWiring = json['electrical_wiring'] != null
        ? RatingItem.fromJson(json['electrical_wiring'])
        : null;
    sanitaryFittings = json['sanitary_fittings'] != null
        ? RatingItem.fromJson(json['sanitary_fittings'])
        : null;
    railings = json['railings'] != null
        ? RatingItem.fromJson(json['railings'])
        : null;
    waterTanks = json['water_tanks'] != null
        ? RatingItem.fromJson(json['water_tanks'])
        : null;
    plumbing = json['plumbing'] != null
        ? RatingItem.fromJson(json['plumbing'])
        : null;
    sewageSystem = json['sewage_system'] != null
        ? RatingItem.fromJson(json['sewage_system'])
        : null;
    panelBoard = json['panel_board'] != null
        ? RatingItem.fromJson(json['panel_board'])
        : null;
    lifts = json['lifts'] != null ? RatingItem.fromJson(json['lifts']) : null;

    overallAverage = json['overall_average']?.toDouble();
    assessmentDate = json['assessment_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (brickPlaster != null) data['brick_plaster'] = brickPlaster!.toJson();
    if (doorsWindows != null) data['doors_windows'] = doorsWindows!.toJson();
    if (flooringTiles != null) data['flooring_tiles'] = flooringTiles!.toJson();
    if (electricalWiring != null)
      data['electrical_wiring'] = electricalWiring!.toJson();
    if (sanitaryFittings != null)
      data['sanitary_fittings'] = sanitaryFittings!.toJson();
    if (railings != null) data['railings'] = railings!.toJson();
    if (waterTanks != null) data['water_tanks'] = waterTanks!.toJson();
    if (plumbing != null) data['plumbing'] = plumbing!.toJson();
    if (sewageSystem != null) data['sewage_system'] = sewageSystem!.toJson();
    if (panelBoard != null) data['panel_board'] = panelBoard!.toJson();
    if (lifts != null) data['lifts'] = lifts!.toJson();
    data['overall_average'] = overallAverage;
    data['assessment_date'] = assessmentDate;
    return data;
  }
}

class RatingItem {
  int? rating;
  String? conditionComment;
  String? inspectionDate;
  List<String>? photos;
  String? inspectorNotes;

  RatingItem({
    this.rating,
    this.conditionComment,
    this.inspectionDate,
    this.photos,
    this.inspectorNotes,
  });

  RatingItem.fromJson(Map<String, dynamic> json) {
    rating = json['rating'];
    conditionComment = json['condition_comment'];
    inspectionDate = json['inspection_date'];
    photos = json['photos']?.cast<String>();
    inspectorNotes = json['inspector_notes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rating'] = rating;
    data['condition_comment'] = conditionComment;
    data['inspection_date'] = inspectionDate;
    data['photos'] = photos;
    data['inspector_notes'] = inspectorNotes;
    return data;
  }
}

class FlatOverallRating {
  double? combinedScore;
  String? healthStatus;
  String? priority;
  String? lastAssessmentDate;

  FlatOverallRating({
    this.combinedScore,
    this.healthStatus,
    this.priority,
    this.lastAssessmentDate,
  });

  FlatOverallRating.fromJson(Map<String, dynamic> json) {
    combinedScore = json['combined_score']?.toDouble();
    healthStatus = json['health_status'];
    priority = json['priority'];
    lastAssessmentDate = json['last_assessment_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['combined_score'] = combinedScore;
    data['health_status'] = healthStatus;
    data['priority'] = priority;
    data['last_assessment_date'] = lastAssessmentDate;
    return data;
  }
}
