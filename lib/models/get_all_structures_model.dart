// To parse this JSON data, do
//
//     final getAllStructures = getAllStructuresFromJson(jsonString);

// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

GetAllStructures getAllStructuresFromJson(String str) => GetAllStructures.fromJson(json.decode(str));

String getAllStructuresToJson(GetAllStructures data) => json.encode(data.toJson());

class GetAllStructures {
    bool success;
    String message;
    List<Datum> data;
    Pagination pagination;

    GetAllStructures({
        required this.success,
        required this.message,
        required this.data,
        required this.pagination,
    });

    factory GetAllStructures.fromJson(Map<String, dynamic> json) {
        // Helper function to safely convert any value to String
        String _safeString(dynamic value) {
            if (value == null) return "";
            if (value is String) return value;
            if (value is List) return value.join(", ");
            return value.toString();
        }

        // Parse data array with error handling
        List<Datum> dataList = [];
        try {
            if (json["data"] != null && json["data"] is List) {
                dataList = (json["data"] as List)
                    .map((x) {
                        try {
                            return Datum.fromJson(x as Map<String, dynamic>);
                        } catch (e) {
                            print("Error parsing datum: $e");
                            print("Problematic datum: $x");
                            return null;
                        }
                    })
                    .whereType<Datum>()
                    .toList();
            }
        } catch (e) {
            print("Error parsing data array: $e");
        }

        // Parse pagination with error handling
        Pagination paginationObj;
        try {
            paginationObj = json["pagination"] != null 
                ? Pagination.fromJson(json["pagination"])
                : Pagination(
                    currentPage: 1,
                    totalPages: 1,
                    totalItems: 0,
                    itemsPerPage: 10,
                    hasNextPage: false,
                    hasPrevPage: false,
                    nextPage: null,
                    prevPage: null,
                  );
        } catch (e) {
            print("Error parsing pagination: $e");
            paginationObj = Pagination(
                currentPage: 1,
                totalPages: 1,
                totalItems: 0,
                itemsPerPage: 10,
                hasNextPage: false,
                hasPrevPage: false,
                nextPage: null,
                prevPage: null,
            );
        }

        return GetAllStructures(
            success: json["success"] ?? false,
            message: _safeString(json["message"]),
            data: dataList,
            pagination: paginationObj,
        );
    }

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "pagination": pagination.toJson(),
    };
}

class Datum {
    String structureId;
    String? uid;
    String structuralIdentityNumber;
    String? clientName;
    Location location;
    String typeOfStructure;
    Dimensions dimensions;
    String status;
    Progress progress;
    RatingsSummary ratingsSummary;
    Timestamps timestamps;

    Datum({
        required this.structureId,
        this.uid,
        required this.structuralIdentityNumber,
        this.clientName,
        required this.location,
        required this.typeOfStructure,
        required this.dimensions,
        required this.status,
        required this.progress,
        required this.ratingsSummary,
        required this.timestamps,
    });

    factory Datum.fromJson(Map<String, dynamic> json) {
        // Helper function to safely convert to String
        String _safeString(dynamic value, [String defaultValue = ""]) {
            if (value == null) return defaultValue;
            if (value is String) return value;
            if (value is List) return value.join(", ");
            return value.toString();
        }

        try {
            return Datum(
                structureId: _safeString(json["structure_id"]),
                uid: json["uid"] != null ? _safeString(json["uid"]) : null,
                structuralIdentityNumber: _safeString(json["structural_identity_number"]),
                clientName: json["client_name"] != null ? _safeString(json["client_name"]) : null,
                location: json["location"] != null 
                    ? Location.fromJson(json["location"]) 
                    : Location(cityName: "", stateCode: "", address: "", structureImage: "", coordinates: Coordinates(latitude: 0.0, longitude: 0.0)),
                typeOfStructure: _safeString(json["type_of_structure"]),
                dimensions: json["dimensions"] != null 
                    ? Dimensions.fromJson(json["dimensions"]) 
                    : Dimensions(),
                status: _safeString(json["status"], "Unknown"),
                progress: json["progress"] != null 
                    ? Progress.fromJson(json["progress"]) 
                    : Progress(
                        location: false,
                        administrative: false,
                        geometricDetails: false,
                        floorsAdded: false,
                        unitsAdded: false,
                        ratingsCompleted: false,
                        overallPercentage: 0,
                      ),
                ratingsSummary: json["ratings_summary"] != null 
                    ? RatingsSummary.fromJson(json["ratings_summary"]) 
                    : RatingsSummary(
                        totalFlats: 0,
                        ratedFlats: 0,
                        completionPercentage: 0,
                        avgStructuralRating: null,
                        avgNonStructuralRating: null,
                        overallHealth: null,
                      ),
                timestamps: json["timestamps"] != null 
                    ? Timestamps.fromJson(json["timestamps"]) 
                    : Timestamps(createdDate: DateTime.now(), lastUpdatedDate: DateTime.now()),
            );
        } catch (e) {
            print("Error parsing Datum: $e");
            print("JSON: $json");
            rethrow;
        }
    }

    Map<String, dynamic> toJson() => {
        "structure_id": structureId,
        "uid": uid,
        "structural_identity_number": structuralIdentityNumber,
        "client_name": clientName,
        "location": location.toJson(),
        "type_of_structure": typeOfStructure,
        "dimensions": dimensions.toJson(),
        "status": status,
        "progress": progress.toJson(),
        "ratings_summary": ratingsSummary.toJson(),
        "timestamps": timestamps.toJson(),
    };
}

class Dimensions {
    double? width;
    int? length;
    int? height;
    int? floors;

    Dimensions({
        this.width,
        this.length,
        this.height,
        this.floors,
    });

    factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        width: json["width"]?.toDouble(),
        length: json["length"],
        height: json["height"],
        floors: json["floors"],
    );

    Map<String, dynamic> toJson() => {
        "width": width,
        "length": length,
        "height": height,
        "floors": floors,
    };
}

class Location {
    String cityName;
    String stateCode;
    String address;
    String structureImage;
    Coordinates coordinates;

    Location({
        required this.cityName,
        required this.stateCode,
        required this.address,
        required this.structureImage,
        required this.coordinates,
    });

    factory Location.fromJson(Map<String, dynamic> json) {
        String _safeString(dynamic value) {
            if (value == null) return "";
            if (value is String) return value;
            if (value is List) return value.join(", ");
            return value.toString();
        }

        return Location(
            cityName: _safeString(json["city_name"]),
            stateCode: _safeString(json["state_code"]),
            address: _safeString(json["address"]),
            structureImage: _safeString(json["structure_image"]),
            coordinates: json["coordinates"] != null 
                ? Coordinates.fromJson(json["coordinates"])
                : Coordinates(latitude: 0.0, longitude: 0.0),
        );
    }

    Map<String, dynamic> toJson() => {
        "city_name": cityName,
        "state_code": stateCode,
        "address": address,
        "structure_image": structureImage,
        "coordinates": coordinates.toJson(),
    };
}

class Coordinates {
    double latitude;
    double longitude;

    Coordinates({
        required this.latitude,
        required this.longitude,
    });

    factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
        latitude: json["latitude"]?.toDouble() ?? 0.0,
        longitude: json["longitude"]?.toDouble() ?? 0.0,
    );

    Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
    };
}

class Progress {
    bool location;
    bool administrative;
    bool geometricDetails;
    bool floorsAdded;
    bool unitsAdded;
    bool ratingsCompleted;
    int overallPercentage;

    Progress({
        required this.location,
        required this.administrative,
        required this.geometricDetails,
        required this.floorsAdded,
        required this.unitsAdded,
        required this.ratingsCompleted,
        required this.overallPercentage,
    });

    factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        location: json["location"] ?? false,
        administrative: json["administrative"] ?? false,
        geometricDetails: json["geometric_details"] ?? false,
        floorsAdded: json["floors_added"] ?? false,
        unitsAdded: json["units_added"] ?? false,
        ratingsCompleted: json["ratings_completed"] ?? false,
        overallPercentage: json["overall_percentage"] ?? 0,
    );

    Map<String, dynamic> toJson() => {
        "location": location,
        "administrative": administrative,
        "geometric_details": geometricDetails,
        "floors_added": floorsAdded,
        "units_added": unitsAdded,
        "ratings_completed": ratingsCompleted,
        "overall_percentage": overallPercentage,
    };
}

class RatingsSummary {
    int totalFlats;
    int ratedFlats;
    int completionPercentage;
    double? avgStructuralRating;
    double? avgNonStructuralRating;
    String? overallHealth;

    RatingsSummary({
        required this.totalFlats,
        required this.ratedFlats,
        required this.completionPercentage,
        required this.avgStructuralRating,
        required this.avgNonStructuralRating,
        required this.overallHealth,
    });

    factory RatingsSummary.fromJson(Map<String, dynamic> json) => RatingsSummary(
        totalFlats: json["total_flats"] ?? 0,
        ratedFlats: json["rated_flats"] ?? 0,
        completionPercentage: json["completion_percentage"] ?? 0,
        avgStructuralRating: json["avg_structural_rating"]?.toDouble(),
        avgNonStructuralRating: json["avg_non_structural_rating"]?.toDouble(),
        overallHealth: json["overall_health"],
    );

    Map<String, dynamic> toJson() => {
        "total_flats": totalFlats,
        "rated_flats": ratedFlats,
        "completion_percentage": completionPercentage,
        "avg_structural_rating": avgStructuralRating,
        "avg_non_structural_rating": avgNonStructuralRating,
        "overall_health": overallHealth,
    };
}

class Timestamps {
    DateTime createdDate;
    DateTime lastUpdatedDate;

    Timestamps({
        required this.createdDate,
        required this.lastUpdatedDate,
    });

    factory Timestamps.fromJson(Map<String, dynamic> json) {
        DateTime now = DateTime.now();
        return Timestamps(
            createdDate: json["created_date"] != null 
                ? DateTime.tryParse(json["created_date"].toString()) ?? now
                : now,
            lastUpdatedDate: json["last_updated_date"] != null 
                ? DateTime.tryParse(json["last_updated_date"].toString()) ?? now
                : now,
        );
    }

    Map<String, dynamic> toJson() => {
        "created_date": createdDate.toIso8601String(),
        "last_updated_date": lastUpdatedDate.toIso8601String(),
    };
}

class Pagination {
    int currentPage;
    int totalPages;
    int totalItems;
    int itemsPerPage;
    bool hasNextPage;
    bool hasPrevPage;
    dynamic nextPage;
    dynamic prevPage;

    Pagination({
        required this.currentPage,
        required this.totalPages,
        required this.totalItems,
        required this.itemsPerPage,
        required this.hasNextPage,
        required this.hasPrevPage,
        required this.nextPage,
        required this.prevPage,
    });

    factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json["currentPage"] ?? 1,
        totalPages: json["totalPages"] ?? 1,
        totalItems: json["totalItems"] ?? 0,
        itemsPerPage: json["itemsPerPage"] ?? 10,
        hasNextPage: json["hasNextPage"] ?? false,
        hasPrevPage: json["hasPrevPage"] ?? false,
        nextPage: json["nextPage"],
        prevPage: json["prevPage"],
    );

    Map<String, dynamic> toJson() => {
        "currentPage": currentPage,
        "totalPages": totalPages,
        "totalItems": totalItems,
        "itemsPerPage": itemsPerPage,
        "hasNextPage": hasNextPage,
        "hasPrevPage": hasPrevPage,
        "nextPage": nextPage,
        "prevPage": prevPage,
    };
}

class Remarks {
    List<ERemark> feRemarks;
    List<ERemark> veRemarks;
    int totalFeRemarks;
    int totalVeRemarks;
    LastUpdatedBy lastUpdatedBy;
    UserPermissions userPermissions;

    Remarks({
        required this.feRemarks,
        required this.veRemarks,
        required this.totalFeRemarks,
        required this.totalVeRemarks,
        required this.lastUpdatedBy,
        required this.userPermissions,
    });

    factory Remarks.fromJson(Map<String, dynamic> json) => Remarks(
        feRemarks: List<ERemark>.from(json["fe_remarks"].map((x) => ERemark.fromJson(x))),
        veRemarks: List<ERemark>.from(json["ve_remarks"].map((x) => ERemark.fromJson(x))),
        totalFeRemarks: json["total_fe_remarks"],
        totalVeRemarks: json["total_ve_remarks"],
        lastUpdatedBy: LastUpdatedBy.fromJson(json["last_updated_by"]),
        userPermissions: UserPermissions.fromJson(json["user_permissions"]),
    );

    Map<String, dynamic> toJson() => {
        "fe_remarks": List<dynamic>.from(feRemarks.map((x) => x.toJson())),
        "ve_remarks": List<dynamic>.from(veRemarks.map((x) => x.toJson())),
        "total_fe_remarks": totalFeRemarks,
        "total_ve_remarks": totalVeRemarks,
        "last_updated_by": lastUpdatedBy.toJson(),
        "user_permissions": userPermissions.toJson(),
    };
}

class ERemark {
    String text;
    String authorName;
    String authorRole;
    DateTime createdAt;
    DateTime updatedAt;
    String id;

    ERemark({
        required this.text,
        required this.authorName,
        required this.authorRole,
        required this.createdAt,
        required this.updatedAt,
        required this.id,
    });

    factory ERemark.fromJson(Map<String, dynamic> json) => ERemark(
        text: json["text"],
        authorName: json["author_name"],
        authorRole: json["author_role"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        id: json["_id"],
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
        role: json["role"],
        name: json["name"],
        date: DateTime.parse(json["date"]),
    );

    Map<String, dynamic> toJson() => {
        "role": role,
        "name": name,
        "date": date.toIso8601String(),
    };
}

class UserPermissions {
    bool canViewRemarks;
    bool canAddRemarks;
    bool canEditOwnRemarks;
    dynamic userRole;

    UserPermissions({
        required this.canViewRemarks,
        required this.canAddRemarks,
        required this.canEditOwnRemarks,
        required this.userRole,
    });

    factory UserPermissions.fromJson(Map<String, dynamic> json) => UserPermissions(
        canViewRemarks: json["can_view_remarks"],
        canAddRemarks: json["can_add_remarks"],
        canEditOwnRemarks: json["can_edit_own_remarks"],
        userRole: json["user_role"],
    );

    Map<String, dynamic> toJson() => {
        "can_view_remarks": canViewRemarks,
        "can_add_remarks": canAddRemarks,
        "can_edit_own_remarks": canEditOwnRemarks,
        "user_role": userRole,
    };
}
