class QuantificationEntry {
  String entryId;
  String category;
  String locationOfDistress;
  double nos;
  double length;
  double breadth;
  double height;
  double quantity;
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
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return QuantificationEntry(
      entryId: json['entry_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      locationOfDistress: json['location_of_distress']?.toString() ?? '',
      nos: _toDouble(json['nos']),
      length: _toDouble(json['length']),
      breadth: _toDouble(json['breadth']),
      height: _toDouble(json['height']),
      quantity: _toDouble(json['quantity']),
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

