import 'package:flutter_test/flutter_test.dart';
import 'package:sams_engineering_console/models/quantification_model.dart';
import 'package:sams_engineering_console/structure/add_structure/quantification_screen.dart';

void main() {
  test('Missing measurements survive loading and saving without becoming zero', () {
    final entry = QuantificationEntry.fromJson({
      'nos': null,
      'length': '',
      'breadth': '\u2014',
      'height': 0,
    });
    final row = QuantificationRow.fromEntry(entry);
    addTearDown(row.dispose);
    expect(row.nosController.text, isEmpty);
    expect(row.lengthController.text, isEmpty);
    expect(row.breadthController.text, isEmpty);
    expect(row.heightController.text, '0.0');
    final saved = row.toEntry(quantity: null, unit: '').toJson();
    expect(saved['nos'], isNull);
    expect(saved['length'], isNull);
    expect(saved['breadth'], isNull);
    expect(saved['height'], 0);
    expect(saved['quantity'], isNull);
  });

  test('New rows have no implicit count', () {
    final row = QuantificationRow.empty('new');
    addTearDown(row.dispose);
    expect(row.nosController.text, isEmpty);
    expect(row.toEntry(quantity: null, unit: '').nos, isNull);
  });
}
