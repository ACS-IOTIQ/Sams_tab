import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/testing_module/testing_format_catalog.dart';

void main() {
  _assertFallbackFormats();
  _assertAliasDeduplication();
  _assertDynamicFormatPreserved();
  print('All testing format scenario checks passed.');
}

void _assertFallbackFormats() {
  final formats = TestingFormatCatalog.resolveFormats(const <TestingFormat>[]);
  final ids = formats.map((format) => format.id).toList();
  const expected = <String>[
    'rebound_hammer',
    'upv_test',
    'half_cell_potential',
    'carbonation_depth',
    'cover_meter',
    'pull_out_test',
    'core_cutting_test',
  ];

  if (ids.length != expected.length || !_sameValues(ids, expected)) {
    throw StateError(
      'Fallback format mismatch. Expected $expected, got $ids',
    );
  }
}

void _assertAliasDeduplication() {
  final formats = TestingFormatCatalog.resolveFormats(<TestingFormat>[
    const TestingFormat(
      id: '',
      name: 'UPV',
      slug: 'upv',
      formatType: '',
      layout: '',
      fields: <TestingDynamicField>[],
    ),
    const TestingFormat(
      id: '',
      name: 'UPV Test',
      slug: 'ultra_pulse_velocity',
      formatType: '',
      layout: '',
      fields: <TestingDynamicField>[],
    ),
  ]);

  if (formats.length != 1 || formats.first.id != 'upv_test') {
    throw StateError(
      'Alias deduplication failed. Got ${formats.map((e) => e.id).toList()}',
    );
  }
}

void _assertDynamicFormatPreserved() {
  final formats = TestingFormatCatalog.resolveFormats(<TestingFormat>[
    const TestingFormat(
      id: 'fmt-2',
      name: 'Custom Corrosion Audit',
      slug: 'custom_corrosion_audit',
      formatType: 'dynamic',
      layout: 'form',
      fields: <TestingDynamicField>[
        TestingDynamicField(
          key: 'remarks',
          label: 'Remarks',
          type: 'textarea',
          required: false,
          options: <String>[],
          readOnly: false,
        ),
      ],
    ),
  ]);

  if (formats.length != 1 || !formats.first.isDynamic) {
    throw StateError('Dynamic format was not preserved correctly.');
  }
}

bool _sameValues(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
