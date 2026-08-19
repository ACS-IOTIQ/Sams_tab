// To parse this JSON data, do
//
//     final getLocationDetailsByStrId = getLocationDetailsByStrIdFromJson(jsonString);

import 'dart:convert';

GetLocationDetailsByStrId getLocationDetailsByStrIdFromJson(String str) => 
    GetLocationDetailsByStrId.fromJson(json.decode(str));

String getLocationDetailsByStrIdToJson(GetLocationDetailsByStrId data) => 
    json.encode(data.toJson());

class GetLocationDetailsByStrId {
    bool success;
    int message;
    Data data;

    GetLocationDetailsByStrId({
        required this.success,
        required this.message,
        required this.data,
    });

    factory GetLocationDetailsByStrId.fromJson(Map<String, dynamic> json) => 
        GetLocationDetailsByStrId(
            success: json["success"] ?? false,
            message: json["message"] ?? 0,
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
    StructuralIdentity structuralIdentity;
    Location location;

    Data({
        required this.structureId,
        required this.uid,
        required this.structuralIdentity,
        required this.location,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"]?.toString() ?? '',
        uid: json["uid"]?.toString() ?? '',
        structuralIdentity: StructuralIdentity.fromJson(json["structural_identity"]),
        location: Location.fromJson(json["location"]),
    );

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "uid": uid,
        "structural_identity": structuralIdentity.toJson(),
        "location": location.toJson(),
    };
}

class Location {
    String structureName;
    String zipCode;
    String stateCode;
    String districtCode;
    String cityName;
    String locationCode;
    double? longitude;  // ✅ Made nullable
    double? latitude;   // ✅ Made nullable
    String address;
    String structureImage;

    Location({
        required this.structureName,
        required this.zipCode,
        required this.stateCode,
        required this.districtCode,
        required this.cityName,
        required this.locationCode,
        this.longitude,     // ✅ Not required anymore
        this.latitude,      // ✅ Not required anymore
        required this.address,
        required this.structureImage,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        structureName: json["structure_name"]?.toString() ?? '',
        zipCode: json["zip_code"]?.toString() ?? '',
        stateCode: json["state_code"]?.toString() ?? '',
        districtCode: json["district_code"]?.toString() ?? '',
        cityName: json["city_name"]?.toString() ?? '',
        locationCode: json["location_code"]?.toString() ?? '',
        longitude: json["longitude"] != null 
            ? (json["longitude"] as num).toDouble() 
            : null,
        latitude: json["latitude"] != null 
            ? (json["latitude"] as num).toDouble() 
            : null,
        address: json["address"]?.toString() ?? '',
        structureImage: json["structure_image"]?.toString() ?? '',
    );

    Map<String, dynamic> toJson() => {
        "structure_name": structureName,
        "zip_code": zipCode,
        "state_code": stateCode,
        "district_code": districtCode,
        "city_name": cityName,
        "location_code": locationCode,
        "longitude": longitude,
        "latitude": latitude,
        "address": address,
        "structure_image": structureImage,
    };
}

class StructuralIdentity {
    String structuralIdentityNumber;
    String uid;
    String typeOfStructure;
    String structureSubtype;
    String? commercialSubtype;  // ✅ Made nullable
    int ageOfStructure;

    StructuralIdentity({
        required this.structuralIdentityNumber,
        required this.uid,
        required this.typeOfStructure,
        required this.structureSubtype,
        this.commercialSubtype,  // ✅ Not required anymore
        required this.ageOfStructure,
    });

    factory StructuralIdentity.fromJson(Map<String, dynamic> json) => 
        StructuralIdentity(
            structuralIdentityNumber: json["structural_identity_number"]?.toString() ?? '',
            uid: json["uid"]?.toString() ?? '',
            typeOfStructure: json["type_of_structure"]?.toString() ?? '',
            structureSubtype: json["structure_subtype"]?.toString() ?? '',
            commercialSubtype: json["commercial_subtype"]?.toString(),
            ageOfStructure: json["age_of_structure"] ?? 0,
        );

    Map<String, dynamic> toJson() => {
        "structural_identity_number": structuralIdentityNumber,
        "uid": uid,
        "type_of_structure": typeOfStructure,
        "structure_subtype": structureSubtype,
        "age_of_structure": ageOfStructure,
        "commercial_subtype": commercialSubtype,
    };
}
