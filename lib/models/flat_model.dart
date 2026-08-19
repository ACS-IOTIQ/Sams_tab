class Flat {
  final String flatNumber;
  final String flatType;
  final double areaSqMts;
  final String directionFacing;
  final String occupancyStatus;

  Flat({
    required this.flatNumber,
    required this.flatType,
    required this.areaSqMts,
    required this.directionFacing,
    required this.occupancyStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      "flat_number": flatNumber,
      "flat_type": flatType,
      "area_sq_mts": areaSqMts,
      "direction_facing": directionFacing,
      "occupancy_status": occupancyStatus,
    };
  }
}

class Floor {
  final int floorNumber;
  final String floorType;
  final double floorHeight;
  final double totalAreaSqMts;
  final String floorLabelName;
  final int numberOfFlats;
  final List<Flat> flats;

  Floor({
    required this.floorNumber,
    required this.floorType,
    required this.floorHeight,
    required this.totalAreaSqMts,
    required this.floorLabelName,
    required this.numberOfFlats,
    required this.flats,
  });

  Map<String, dynamic> toJson() {
    return {
      "floor_number": floorNumber,
      "floor_type": floorType,
      "floor_height": floorHeight,
      "total_area_sq_mts": totalAreaSqMts,
      "floor_label_name": floorLabelName,
      "number_of_flats": numberOfFlats,
      "flats": flats.map((flat) => flat.toJson()).toList(),
    };
  }
}
