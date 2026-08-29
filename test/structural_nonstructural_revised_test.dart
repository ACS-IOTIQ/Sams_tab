import 'package:flutter_test/flutter_test.dart';
import 'package:sams_engineering_console/models/get_administrativeby_strid_model.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/structural_nonstructural_revised.dart';

void main() {
  group('administrative details response', () {
    test('accepts administration and administrative response keys', () {
      for (final key in ['administration', 'administrative']) {
        final response = GetAdminstrativeDetailsByStrId.fromJson({
          'success': true,
          'data': {
            key: {
              'client_name': 'Client',
              'contact': '9999999999',
              'email': 'client@example.com',
            },
          },
        });

        expect(response.data?.administration?.clientName, 'Client');
        expect(response.data?.administration?.contactDetails, '9999999999');
        expect(response.data?.administration?.emailId, 'client@example.com');
      }
    });
  });

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
    test('requires a rating but not a unit or a No. count', () {
      final item = RatingItem(type: 'Beams');

      expect(
        validateRatingsForSubmission({
          'Beams': [item],
        }),
        contains('valid ratings (1-5)'),
      );

      // A rating on its own is enough: the unit is still unset and the No.
      // field is still empty.
      item.rating = 5;
      expect(item.distressUnit, DistressMeasurementUnit.nos);
      expect(item.numberController.text, isEmpty);
      expect(
        validateRatingsForSubmission({
          'Beams': [item],
        }),
        isNull,
      );
    });

    test('rejects out-of-range ratings and names the component', () {
      final item = RatingItem(type: 'Beams')..rating = 9;

      expect(
        validateRatingsForSubmission({
          'Beams': [item],
        }),
        contains('Beams'),
      );
    });
  });

  group('removeExistingPhoto', () {
    test('drops the url and keeps the legacy photoUrl in step', () {
      final provider = AddRatingsStructureProvider();
      final item = RatingItem(type: 'Beams')
        ..photoUrls = ['https://host/a.jpg', 'https://host/b.jpg']
        ..photoUrl = 'https://host/a.jpg';

      provider.removeExistingPhoto(item, 'https://host/a.jpg');
      expect(item.photoUrls, ['https://host/b.jpg']);
      expect(item.photoUrl, 'https://host/b.jpg');

      // Removing the last photo must clear photoUrl too, otherwise the
      // submission payload falls back to it and restores the deleted photo.
      provider.removeExistingPhoto(item, 'https://host/b.jpg');
      expect(item.photoUrls, isEmpty);
      expect(item.photoUrl, isNull);
    });
  });

  group('rating map clearing', () {
    test('clearing one rating type preserves the other type', () {
      final provider = AddRatingsStructureProvider();
      provider.structuralRatingMap['Beams'] = [RatingItem(type: 'Beams')];
      provider.nonStructuralRatingMap['Walls'] = [RatingItem(type: 'Walls')];

      provider.clearNonStructuralRatings();
      expect(provider.structuralRatingMap.keys, contains('Beams'));
      expect(provider.nonStructuralRatingMap, isEmpty);

      provider.nonStructuralRatingMap['Walls'] = [RatingItem(type: 'Walls')];
      provider.clearStructuralRatings();
      expect(provider.structuralRatingMap, isEmpty);
      expect(provider.nonStructuralRatingMap.keys, contains('Walls'));
    });
  });
}
