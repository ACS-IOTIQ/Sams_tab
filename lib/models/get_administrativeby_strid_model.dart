// To parse this JSON data, do
//
//     final getAdminstrativeDetailsByStrId = getAdminstrativeDetailsByStrIdFromJson(jsonString);

import 'dart:convert';

GetAdminstrativeDetailsByStrId getAdminstrativeDetailsByStrIdFromJson(String str) => GetAdminstrativeDetailsByStrId.fromJson(json.decode(str));

String getAdminstrativeDetailsByStrIdToJson(GetAdminstrativeDetailsByStrId data) => json.encode(data.toJson());

class GetAdminstrativeDetailsByStrId {
    final bool? success;
    final String? message;
    final Data? data;

    GetAdminstrativeDetailsByStrId({
        this.success,
        this.message,
        this.data,
    });

    factory GetAdminstrativeDetailsByStrId.fromJson(Map<String, dynamic> json) => GetAdminstrativeDetailsByStrId(
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
    final Administration? administration;

    Data({
        this.structureId,
        this.uid,
        this.administration,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        structureId: json["structure_id"],
        uid: json["uid"],
        // ✅ Fixed: Changed from "administration" to "administrative"
        administration: json["administrative"] == null ? null : Administration.fromJson(json["administrative"]),
    );

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "uid": uid,
        // ✅ Fixed: Changed from "administration" to "administrative"
        "administrative": administration?.toJson(),
    };
}

class Administration {
    final String? clientName;
    final String? custodian;
    final String? engineerDesignation;
    final String? contactDetails;
    final String? emailId;

    Administration({
        this.clientName,
        this.custodian,
        this.engineerDesignation,
        this.contactDetails,
        this.emailId,
    });

    factory Administration.fromJson(Map<String, dynamic> json) => Administration(
        clientName: json["client_name"],
        custodian: json["custodian"],
        engineerDesignation: json["engineer_designation"],
        contactDetails: json["contact_details"],
        emailId: json["email_id"],
    );

    Map<String, dynamic> toJson() => {
        "client_name": clientName,
        "custodian": custodian,
        "engineer_designation": engineerDesignation,
        "contact_details": contactDetails,
        "email_id": emailId,
    };
}