class QuantificationEntry {
  String entryId;
  String category;
  String locationOfDistress;
  double? nos;
  double? length;
  double? breadth;
  double? height;
  double? quantity;
  String unit;
  String repairMethodology;

  QuantificationEntry({
    required this.entryId,
    required this.category,
    required this.locationOfDistress,
    required this.nos,
    required this.length,
    required this.breadth,
    required this.height,
    required this.quantity,
    required this.unit,
    required this.repairMethodology,
  });

  factory QuantificationEntry.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

    return QuantificationEntry(
      entryId: json['entry_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      locationOfDistress: json['location_of_distress']?.toString() ?? '',
      nos: toDouble(json['nos']),
      length: toDouble(json['length']),
      breadth: toDouble(json['breadth']),
      height: toDouble(json['height']),
      quantity: toDouble(json['quantity']),
      unit: json['unit']?.toString() ?? '',
      repairMethodology: json['repair_methodology']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'category': category,
      'location_of_distress': locationOfDistress,
      'nos': nos,
      'length': length,
      'breadth': breadth,
      'height': height,
      'quantity': quantity,
      'unit': unit,
      'repair_methodology': repairMethodology,
    };
  }
}
