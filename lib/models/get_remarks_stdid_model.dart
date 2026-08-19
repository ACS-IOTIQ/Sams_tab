// To parse this JSON data, do
//
//     final getRemarksByStrId = getRemarksByStrIdFromJson(jsonString);

import 'dart:convert';

GetRemarksByStrId getRemarksByStrIdFromJson(String str) => GetRemarksByStrId.fromJson(json.decode(str));

String getRemarksByStrIdToJson(GetRemarksByStrId data) => json.encode(data.toJson());

class GetRemarksByStrId {
    bool success;
    String message;
    Data data;

    GetRemarksByStrId({
        required this.success,
        required this.message,
        required this.data,
    });

    factory GetRemarksByStrId.fromJson(Map<String, dynamic> json) => GetRemarksByStrId(
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
  String uid;
  List<Remark> feRemarks;
  List<Remark> veRemarks; // ✅ Changed from List<dynamic> to List<Remark>
  List<Remark> teRemarks; // ✅ Changed from List<dynamic> to List<Remark>
  int totalFeRemarks;
  int totalVeRemarks;
  int totalTeRemarks;
  LastUpdatedBy lastUpdatedBy;

  Data({
    required this.structureId,
    required this.uid,
    required this.feRemarks,
    required this.veRemarks,
    required this.teRemarks,
    required this.totalFeRemarks,
    required this.totalVeRemarks,
    required this.totalTeRemarks,
    required this.lastUpdatedBy,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"] ?? "",
        uid: json["uid"] ?? "",
        feRemarks: json["fe_remarks"] != null
            ? List<Remark>.from(json["fe_remarks"].map((x) => Remark.fromJson(x)))
            : [],
        veRemarks: json["ve_remarks"] != null
            ? List<Remark>.from(json["ve_remarks"].map((x) => Remark.fromJson(x)))
            : [], // ✅ Now properly parsing VE remarks
        teRemarks: json["te_remarks"] != null
            ? List<Remark>.from(json["te_remarks"].map((x) => Remark.fromJson(x)))
            : [], // ✅ Now properly parsing TE remarks
        totalFeRemarks: json["total_fe_remarks"] ?? 0,
        totalVeRemarks: json["total_ve_remarks"] ?? 0,
        totalTeRemarks: json["total_te_remarks"] ?? 0,
        lastUpdatedBy: json["last_updated_by"] != null
            ? LastUpdatedBy.fromJson(json["last_updated_by"])
            : LastUpdatedBy(role: "", name: "", date: DateTime.now()),
      );

  Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "uid": uid,
        "fe_remarks": List<dynamic>.from(feRemarks.map((x) => x.toJson())),
        "ve_remarks": List<dynamic>.from(veRemarks.map((x) => x.toJson())),
        "te_remarks": List<dynamic>.from(teRemarks.map((x) => x.toJson())),
        "total_fe_remarks": totalFeRemarks,
        "total_ve_remarks": totalVeRemarks,
        "total_te_remarks": totalTeRemarks,
        "last_updated_by": lastUpdatedBy.toJson(),
      };
}

// ✅ Renamed from FeRemark to Remark since all remarks have the same structure
class Remark {
    String text;
    String authorName;
    String authorRole;
    DateTime createdAt;
    DateTime updatedAt;
    String id;

    Remark({
        required this.text,
        required this.authorName,
        required this.authorRole,
        required this.createdAt,
        required this.updatedAt,
        required this.id,
    });

    factory Remark.fromJson(Map<String, dynamic> json) => Remark(
        text: json["text"] ?? "",
        authorName: json["author_name"] ?? "",
        authorRole: json["author_role"] ?? "",
        createdAt: json["created_at"] != null 
            ? DateTime.parse(json["created_at"])
            : DateTime.now(),
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : DateTime.now(),
        id: json["_id"] ?? "",
    );

    Map<String, dynamic> toJson() => {
        "text": text,
        "author_name": authorName,
        "author_role": authorRole,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "_id": id,
    };
}

class LastUpdatedBy {
    String role;
    String name;
    DateTime date;

    LastUpdatedBy({
        required this.role,
        required this.name,
        required this.date,
    });

    factory LastUpdatedBy.fromJson(Map<String, dynamic> json) => LastUpdatedBy(
        role: json["role"] ?? "",
        name: json["name"] ?? "",
        date: json["date"] != null 
            ? DateTime.parse(json["date"])
            : DateTime.now(),
    );

    Map<String, dynamic> toJson() => {
        "role": role,
        "name": name,
        "date": date.toIso8601String(),
    };
}