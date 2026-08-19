// To parse this JSON data, do
//
//     final getGeometricDetailsByStrId = getGeometricDetailsByStrIdFromJson(jsonString);

import 'dart:convert';

GetGeometricDetailsByStrId getGeometricDetailsByStrIdFromJson(String str) => GetGeometricDetailsByStrId.fromJson(json.decode(str));

String getGeometricDetailsByStrIdToJson(GetGeometricDetailsByStrId data) => json.encode(data.toJson());

class GetGeometricDetailsByStrId {
    final bool? success;
    final String? message;
    final Data? data;

    GetGeometricDetailsByStrId({
        this.success,
        this.message,
        this.data,
    });

    factory GetGeometricDetailsByStrId.fromJson(Map<String, dynamic> json) => GetGeometricDetailsByStrId(
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
    final String? uid;
    final GeometricDetails? geometricDetails;

    Data({
        this.structureId,
        this.uid,
        this.geometricDetails,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"],
        uid: json["uid"],
        geometricDetails: json["geometric_details"] == null ? null : GeometricDetails.fromJson(json["geometric_details"]),
    );

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "uid": uid,
        "geometric_details": geometricDetails?.toJson(),
    };
}

class GeometricDetails {
    final int? numberOfFloors;
    final double? structureWidth;
    final int? structureLength;
    final int? structureHeight;
    final int? totalArea;

    GeometricDetails({
        this.numberOfFloors,
        this.structureWidth,
        this.structureLength,
        this.structureHeight,
        this.totalArea,
    });

    factory GeometricDetails.fromJson(Map<String, dynamic> json) => GeometricDetails(
        numberOfFloors: json["number_of_floors"],
        structureWidth: json["structure_width"]?.toDouble(),
        structureLength: json["structure_length"],
        structureHeight: json["structure_height"],
        totalArea: json["total_area"],
    );

    Map<String, dynamic> toJson() => {
        "number_of_floors": numberOfFloors,
        "structure_width": structureWidth,
        "structure_length": structureLength,
        "structure_height": structureHeight,
        "total_area": totalArea,
    };
}
