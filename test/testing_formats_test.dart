import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/testing_module/dynamic_test_format_screen.dart';
import 'package:sams_engineering_console/testing_module/testing_format_registry.dart';
import 'package:sams_engineering_console/testing_module/testing_screen.dart';

void main() {
  group('TestingFormatRegistry', () {
    test('returns a deduplicated canonical fallback list', () {
      final formats = TestingFormatRegistry.resolveFormats(const []);

      expect(formats.map((format) => format.id).toList(), <String>[
        'rebound_hammer',
        'upv_test',
        'half_cell_potential',
        'carbonation_depth',
        'cover_meter',
        'pull_out_test',
        'core_cutting_test',
      ]);
    });

    test(
      'deduplicates assigned alias formats and preserves dynamic formats',
      () {
        final formats = TestingFormatRegistry.resolveFormats(<TestingFormat>[
          const TestingFormat(
            id: 'format-a',
            name: 'UPV',
            slug: 'upv',
            formatType: '',
            layout: '',
            fields: <TestingDynamicField>[],
          ),
          const TestingFormat(
            id: 'format-b',
            name: 'Ultra Pulse Velocity',
            slug: 'ultra_pulse_velocity',
            formatType: '',
            layout: '',
            fields: <TestingDynamicField>[],
          ),
          const TestingFormat(
            id: '',
            name: 'UPV Test',
            slug: 'upv',
            formatType: '',
            layout: '',
            fields: <TestingDynamicField>[],
          ),
          const TestingFormat(
            id: 'dynamic-format',
            name: 'Custom Crack Mapping',
            slug: 'custom_crack_mapping',
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

        expect(formats, hasLength(2));
        expect(formats.first.id, 'format-a');
        expect(formats.first.isDynamic, isFalse);
        expect(formats.last.id, 'dynamic-format');
        expect(formats.last.isDynamic, isTrue);
      },
    );
  });

  group('TestingScreen', () {
    testWidgets('renders assigned dynamic formats for a structure scenario', (
      WidgetTester tester,
    ) async {
      final assignedFormats = <TestingFormat>[
        const TestingFormat(
          id: 'fmt-1',
          name: 'Custom Crack Mapping',
          slug: 'custom_crack_mapping',
          formatType: 'dynamic',
          layout: 'form',
          fields: <TestingDynamicField>[],
        ),
        const TestingFormat(
          id: 'fmt-2',
          name: 'Custom Corrosion Audit',
          slug: 'custom_corrosion_audit',
          formatType: 'dynamic',
          layout: 'form',
          fields: <TestingDynamicField>[],
        ),
      ];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => MaterialApp(
            home: TestingScreen(
              structureId: 'STR-1001',
              structureIdentityNumber: 'SID-42',
              initialStatus: 'submitted',
              assignedFormats: assignedFormats,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Testing Formats'), findsOneWidget);
      expect(
        find.text('Choose a format and enter the test details for SID-42'),
        findsOneWidget,
      );
      expect(find.text('Custom Crack Mapping'), findsWidgets);
      expect(find.byType(DynamicTestFormatScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Select test format'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom Corrosion Audit').last);
      await tester.pumpAndSettle();

      expect(find.text('Custom Corrosion Audit'), findsWidgets);
    });
  });
}
