import 'package:flutter/material.dart';
import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/testing_module/carbonation_depth_screen.dart';
import 'package:sams_engineering_console/testing_module/core_cutting_screen.dart';
import 'package:sams_engineering_console/testing_module/cover_meter_screen.dart';
import 'package:sams_engineering_console/testing_module/dynamic_test_format_screen.dart';
import 'package:sams_engineering_console/testing_module/half_cell_potential_screen.dart';
import 'package:sams_engineering_console/testing_module/pull_out_screen.dart';
import 'package:sams_engineering_console/testing_module/rebound_hammer_screen.dart';
import 'package:sams_engineering_console/testing_module/testing_format_catalog.dart';
import 'package:sams_engineering_console/testing_module/upv_test.dart';

class TabletTestingFormatDescriptor {
  final String id;
  final String name;
  final Widget Function(String structureId) builder;
  final bool isDynamic;

  const TabletTestingFormatDescriptor({
    required this.id,
    required this.name,
    required this.builder,
    this.isDynamic = false,
  });
}

class TestingFormatRegistry {
  static List<TabletTestingFormatDescriptor> resolveFormats(
    List<TestingFormat> assignedFormats,
  ) {
    final resolvedFormats = TestingFormatCatalog.resolveFormats(assignedFormats);
    if (assignedFormats.isEmpty) {
      return resolvedFormats
          .map(
            (format) => TabletTestingFormatDescriptor(
              id: format.id,
              name: format.name,
              builder: _knownBuilders[format.normalizedKey]!,
            ),
          )
          .toList();
    }

    return resolvedFormats
        .map((format) => _fromResolvedFormat(format, assignedFormats))
        .toList();
  }

  static TabletTestingFormatDescriptor _fromResolvedFormat(
    ResolvedTestingFormat resolvedFormat,
    List<TestingFormat> assignedFormats,
  ) {
    final originalFormat = assignedFormats.firstWhere(
      (format) {
        final canonical = TestingFormatCatalog.resolveFormats(<TestingFormat>[
          format,
        ]).first.normalizedKey;
        return (format.id.isNotEmpty ? format.id : canonical) == resolvedFormat.id;
      },
    );
    final knownBuilder = _knownBuilders[resolvedFormat.normalizedKey];

    if (knownBuilder != null && !resolvedFormat.isDynamic) {
      return TabletTestingFormatDescriptor(
        id: resolvedFormat.id,
        name: originalFormat.name,
        builder: knownBuilder,
      );
    }

    return TabletTestingFormatDescriptor(
      id: resolvedFormat.id,
      name: originalFormat.name,
      isDynamic: true,
      builder: (_) => DynamicTestFormatScreen(format: originalFormat),
    );
  }

  static final Map<String, Widget Function(String structureId)> _knownBuilders =
      <String, Widget Function(String structureId)>{
    'rebound_hammer': (structureId) => ReboundHammerScreen(structureId: structureId),
    'rebound_hammer_test': (structureId) => ReboundHammerScreen(structureId: structureId),
    'ultra_pulse_velocity_test': (structureId) => UpvTestScreen(structureId: structureId),
    'ultra_pulse_velocity': (structureId) => UpvTestScreen(structureId: structureId),
    'upv_test': (structureId) => UpvTestScreen(structureId: structureId),
    'upv': (structureId) => UpvTestScreen(structureId: structureId),
    'half_cell_potential': (structureId) => HalfCellPotentialScreen(structureId: structureId),
    'half_cell_potential_test': (structureId) => HalfCellPotentialScreen(structureId: structureId),
    'carbonation_depth': (structureId) => CarbonationDepthScreen(structureId: structureId),
    'carbonation_depth_test': (structureId) => CarbonationDepthScreen(structureId: structureId),
    'cover_meter': (structureId) => CoverMeterScreen(structureId: structureId),
    'cover_meter_test': (structureId) => CoverMeterScreen(structureId: structureId),
    'pull_out_test': (structureId) => PullOutTestScreen(structureId: structureId),
    'pull_out': (structureId) => PullOutTestScreen(structureId: structureId),
    'core_cutting_test': (structureId) => CoreCuttingScreen(structureId: structureId),
    'core_cutting': (structureId) => CoreCuttingScreen(structureId: structureId),
  };
}
