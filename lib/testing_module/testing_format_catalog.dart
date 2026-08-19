import 'package:sams_engineering_console/models/testing_workflow_model.dart';

class ResolvedTestingFormat {
  const ResolvedTestingFormat({
    required this.id,
    required this.name,
    required this.normalizedKey,
    required this.isDynamic,
  });

  final String id;
  final String name;
  final String normalizedKey;
  final bool isDynamic;
}

class TestingFormatCatalog {
  static List<ResolvedTestingFormat> resolveFormats(
    List<TestingFormat> assignedFormats,
  ) {
    if (assignedFormats.isEmpty) {
      return _defaultFormatKeys
          .map(
            (key) => ResolvedTestingFormat(
              id: key,
              name: _defaultNameFor(key),
              normalizedKey: key,
              isDynamic: false,
            ),
          )
          .toList();
    }

    final resolved = <ResolvedTestingFormat>[];
    final seenFormatKeys = <String>{};

    for (final format in assignedFormats) {
      final normalizedKey = format.normalizedKey;
      final canonicalKey = _canonicalKeys[normalizedKey] ?? normalizedKey;
      final id = format.id.isNotEmpty ? format.id : canonicalKey;
      final isDynamic =
          format.isDynamic || !_canonicalKeys.containsKey(normalizedKey);
      final dedupeKey = isDynamic
          ? 'dynamic:${normalizedKey.isNotEmpty ? normalizedKey : format.name.trim().toLowerCase()}'
          : 'known:$canonicalKey';
      final descriptor = ResolvedTestingFormat(
        id: id,
        name: format.name,
        normalizedKey: canonicalKey,
        isDynamic: isDynamic,
      );
      if (seenFormatKeys.add(dedupeKey)) {
        resolved.add(descriptor);
      }
    }

    return resolved;
  }

  static String _defaultNameFor(String key) {
    switch (key) {
      case 'rebound_hammer':
        return 'Rebound Hammer';
      case 'upv_test':
        return 'UPV Test';
      case 'half_cell_potential':
        return 'Half Cell Potential';
      case 'carbonation_depth':
        return 'Carbonation Depth';
      case 'cover_meter':
        return 'Cover Meter';
      case 'pull_out_test':
        return 'Pull-Out Test';
      case 'core_cutting_test':
        return 'Core Cutting Test';
      default:
        return key;
    }
  }

  static const Map<String, String> _canonicalKeys = <String, String>{
    'rebound_hammer': 'rebound_hammer',
    'rebound_hammer_test': 'rebound_hammer',
    'ultra_pulse_velocity_test': 'upv_test',
    'ultra_pulse_velocity': 'upv_test',
    'upv_test': 'upv_test',
    'upv': 'upv_test',
    'half_cell_potential': 'half_cell_potential',
    'half_cell_potential_test': 'half_cell_potential',
    'carbonation_depth': 'carbonation_depth',
    'carbonation_depth_test': 'carbonation_depth',
    'cover_meter': 'cover_meter',
    'cover_meter_test': 'cover_meter',
    'pull_out_test': 'pull_out_test',
    'pull_out': 'pull_out_test',
    'core_cutting_test': 'core_cutting_test',
    'core_cutting': 'core_cutting_test',
  };

  static const List<String> _defaultFormatKeys = <String>[
    'rebound_hammer',
    'upv_test',
    'half_cell_potential',
    'carbonation_depth',
    'cover_meter',
    'pull_out_test',
    'core_cutting_test',
  ];
}
