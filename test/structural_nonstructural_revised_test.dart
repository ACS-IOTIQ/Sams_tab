import 'package:flutter_test/flutter_test.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/structural_nonstructural_revised.dart';

void main() {
  group('DistressMeasurementUnit', () {
    test('supports RM as a distinct unit', () {
      expect(DistressMeasurementUnit.rm.apiValue, 'RM');
      expect(DistressMeasurementUnit.rm.label, 'Running meter');
      expect(
        DistressMeasurementUnitX.fromApiValue('RM'),
        DistressMeasurementUnit.rm,
      );
      expect(
        DistressMeasurementUnitX.fromApiValue("NO'S"),
        DistressMeasurementUnit.nos,
      );
    });
  });

  group('collectPendingRatingSubmissions', () {
    test(
      'collects flat and floor submissions with parsed ids and testing flag',
      () {
        final structuralItem = RatingItem(type: 'Beams')..rating = 4;
        final nonStructuralItem = RatingItem(type: 'Walls')..rating = 3;

        final pending = collectPendingRatingSubmissions(
          savedStructuralRatings: {
            'floor_floor-1': {
              'Beams': [structuralItem],
            },
          },
          savedNonStructuralRatings: {
            'flat_flat-7': {
              'Walls': [nonStructuralItem],
            },
          },
          savedStructuralTestingRequired: {'floor_floor-1': true},
        );

        expect(pending, hasLength(2));

        final floorSubmission = pending.firstWhere((entry) => entry.isFloor);
        expect(floorSubmission.entityId, 'floor-1');
        expect(floorSubmission.testingRequired, isTrue);
        expect(floorSubmission.structuralRatings['Beams'], hasLength(1));
        expect(floorSubmission.nonStructuralRatings, isEmpty);

        final flatSubmission = pending.firstWhere((entry) => !entry.isFloor);
        expect(flatSubmission.entityId, 'flat-7');
        expect(flatSubmission.testingRequired, isFalse);
        expect(flatSubmission.structuralRatings, isEmpty);
        expect(flatSubmission.nonStructuralRatings['Walls'], hasLength(1));
      },
    );
  });

  group('validateRatingsForSubmission', () {
    test('allows optional dimensions and requires a No.s quantity', () {
      final item = RatingItem(type: 'Beams')..rating = 5;

      expect(
        validateRatingsForSubmission({
          'Beams': [item],
        }),
        contains('Please enter No.'),
      );

      item.numberController.text = '0';
      expect(
        validateRatingsForSubmission({
          'Beams': [item],
        }),
        isNull,
      );
    });
  });
}
