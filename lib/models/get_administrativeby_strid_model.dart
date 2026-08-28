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
        data: json["data"] is Map
            ? Data.fromJson(Map<String, dynamic>.from(json["data"]))
            : Data.fromJson(json),
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

    factory Data.fromJson(Map<String, dynamic> json) {
        final rawAdministration =
            json["administrative"] ?? json["administration"];
        final administrationJson = rawAdministration is Map
            ? Map<String, dynamic>.from(rawAdministration)
            : (json.containsKey("client_name") ? json : null);

        return Data(
            structureId: json["structure_id"] ?? json["structureId"],
            uid: json["uid"],
            administration: administrationJson == null
                ? null
                : Administration.fromJson(administrationJson),
        );
    }

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
        contactDetails: json["contact_details"] ?? json["contact"],
        emailId: json["email_id"] ?? json["email"],
    );

    Map<String, dynamic> toJson() => {
        "client_name": clientName,
        "custodian": custodian,
        "engineer_designation": engineerDesignation,
        "contact_details": contactDetails,
        "email_id": emailId,
    };
}
