// To parse this JSON data, do
//
//     final getFloorsDetailsByStrId = getFloorsDetailsByStrIdFromJson(jsonString);

import 'dart:convert';

GetFloorsDetailsByStrId getFloorsDetailsByStrIdFromJson(String str) => GetFloorsDetailsByStrId.fromJson(json.decode(str));

String getFloorsDetailsByStrIdToJson(GetFloorsDetailsByStrId data) => json.encode(data.toJson());

class GetFloorsDetailsByStrId {
    final bool? success;
    final String? message;
    final Data? data;

    GetFloorsDetailsByStrId({
        this.success,
        this.message,
        this.data,
    });

    factory GetFloorsDetailsByStrId.fromJson(Map<String, dynamic> json) => GetFloorsDetailsByStrId(
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
    final int? totalFloors;
    final List<Floor>? floors;

    Data({
        this.structureId,
        this.totalFloors,
        this.floors,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"],
        totalFloors: json["total_floors"],
        floors: json["floors"] == null ? [] : List<Floor>.from(json["floors"]!.map((x) => Floor.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "total_floors": totalFloors,
        "floors": floors == null ? [] : List<dynamic>.from(floors!.map((x) => x.toJson())),
    };
}

class Floor {
    final String? floorId;
    final String? mongodbId;
    final int? floorNumber;
    final String? parkingFloorType;
    final bool? isParkingFloor;
    final double? floorHeight;
    final int? totalAreaSqMts;
    final String? floorLabelName;
    final int? numberOfFlats;
    final String? floorNotes;

    Floor({
        this.floorId,
        this.mongodbId,
        this.floorNumber,
        this.parkingFloorType,
        this.isParkingFloor,
        this.floorHeight,
        this.totalAreaSqMts,
        this.floorLabelName,
        this.numberOfFlats,
        this.floorNotes,
    });

    factory Floor.fromJson(Map<String, dynamic> json) => Floor(
        floorId: json["floor_id"],
        mongodbId: json["mongodb_id"],
        floorNumber: json["floor_number"],
        parkingFloorType: json["parking_floor_type"],
        isParkingFloor: json["is_parking_floor"],
        floorHeight: json["floor_height"]?.toDouble(),
        totalAreaSqMts: json["total_area_sq_mts"],
        floorLabelName: json["floor_label_name"],
        numberOfFlats: json["number_of_flats"],
        floorNotes: json["floor_notes"],
    );

    Map<String, dynamic> toJson() => {
        "floor_id": floorId,
        "mongodb_id": mongodbId,
        "floor_number": floorNumber,
        "is_parking_floor": isParkingFloor,
        "parking_floor_type": parkingFloorType,
        "floor_height": floorHeight,
        "total_area_sq_mts": totalAreaSqMts,
        "floor_label_name": floorLabelName,
        "number_of_flats": numberOfFlats,
        "floor_notes": floorNotes,
    };
}
