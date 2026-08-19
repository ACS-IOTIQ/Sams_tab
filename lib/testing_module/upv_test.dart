import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/testing_result_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/testing_results_provider.dart';
import 'package:sams_engineering_console/testing_module/evidence_section.dart';
import 'package:sams_engineering_console/testing_module/testing_form_ui.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:sams_engineering_console/utils/module_header.dart';

const List<String> _allGrades = [
  "M10",
  "M15",
  "M20",
  "M25",
  "M30",
  "M35",
  "M40",
  "M45",
  "M50",
];

String _determineCondition(double avgVelocityKmps, String? grade) {
  if (grade == null || avgVelocityKmps <= 0) return "--";
  final isLowGrade = ["M10", "M15", "M20", "M25"].contains(grade); // ≤ M25

  if (isLowGrade) {
    if (avgVelocityKmps >= 4.5) return "Excellent";
    if (avgVelocityKmps >= 3.5) return "Good";
    return "Doubtful";
  } else {
    if (avgVelocityKmps >= 4.5) return "Excellent";
    if (avgVelocityKmps >= 3.75) return "Good";
    return "Doubtful";
  }
}

// ── Reading row model ──────────────────────────────────────────────────────

class _ReadingRow {
  final TextEditingController distanceController; // mm
  final TextEditingController timeController; // μs

  _ReadingRow()
    : distanceController = TextEditingController(),
      timeController = TextEditingController();

  double get velocity {
    final d = double.tryParse(distanceController.text) ?? 0;
    final t = double.tryParse(timeController.text) ?? 0;
    return (d > 0 && t > 0) ? d / t : 0;
  }

  void dispose() {
    distanceController.dispose();
    timeController.dispose();
  }
}

// ── Location entry model ───────────────────────────────────────────────────

class _LocationEntry {
  final TextEditingController locationController;
  final TextEditingController remarksController;
  String type; // "D" | "ID"
  String? grade;
  List<_ReadingRow> readings;
  double averageVelocity;
  String condition;
  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      remarksController = TextEditingController(),
      type = "D",
      grade = null,
      readings = [],
      averageVelocity = 0.0,
      condition = "--",
      isExpanded = true {
    // Default 3 readings to match common test practice
    readings = List.generate(3, (_) => _ReadingRow());
  }

  void addReading() => readings.add(_ReadingRow());

  void removeReading(int index) {
    if (readings.length > 1) {
      readings[index].dispose();
      readings.removeAt(index);
    }
  }

  void recalculate() {
    final velocities = readings
        .map((r) => r.velocity)
        .where((v) => v > 0)
        .toList();
    if (velocities.isNotEmpty) {
      averageVelocity = velocities.reduce((a, b) => a + b) / velocities.length;
      condition = _determineCondition(averageVelocity, grade);
    } else {
      averageVelocity = 0.0;
      condition = "--";
    }
  }

  void dispose() {
    locationController.dispose();
    remarksController.dispose();
    for (final r in readings) {
      r.dispose();
    }
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────

class UpvTestScreen extends StatefulWidget {
  const UpvTestScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<UpvTestScreen> createState() => _UpvTestScreenState();
}

class _UpvTestScreenState extends State<UpvTestScreen> {
  final List<_LocationEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _addEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.structureId.trim().isEmpty) return;
      final provider = context.read<TestingResultsProvider>();
      await provider.fetchStructureResults(context, widget.structureId);
      final existing = provider.findStructureResult(
        widget.structureId,
        'ultra_pulse_velocity',
      );
      if (existing != null && mounted) {
        setState(() => _hydrateFromExisting(existing));
      }
    });
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addEntry() => setState(() => _entries.add(_LocationEntry()));

  void _removeEntry(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  void _onChanged(int index) => setState(() => _entries[index].recalculate());

  void _hydrateFromExisting(TestingResultItem existing) {
    for (final entry in _entries) {
      entry.dispose();
    }
    _entries.clear();

    final entries = (existing.testResults['entries'] as List?) ?? const [];
    for (final dynamic rawEntry in entries) {
      if (rawEntry is! Map) continue;
      final map = rawEntry.map((key, value) => MapEntry(key.toString(), value));
      final entry = _LocationEntry();
      entry.locationController.text = (map['location'] ?? '').toString();
      entry.remarksController.text = (map['remarks'] ?? '').toString();
      entry.type = (map['type'] ?? 'D').toString();
      final grade = (map['grade'] ?? '').toString();
      entry.grade = grade.isEmpty ? null : grade;
      for (final row in entry.readings) {
        row.dispose();
      }
      entry.readings.clear();
      final readings = (map['readings'] as List?) ?? const [];
      for (final dynamic rawReading in readings) {
        if (rawReading is! Map) continue;
        final readingMap = rawReading.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final row = _ReadingRow();
        row.distanceController.text = (readingMap['distance_mm'] ?? '')
            .toString();
        row.timeController.text = (readingMap['time_us'] ?? '').toString();
        entry.readings.add(row);
      }
      if (entry.readings.isEmpty) {
        entry.readings = List.generate(3, (_) => _ReadingRow());
      }
      entry.recalculate();
      _entries.add(entry);
    }

    if (_entries.isEmpty) {
      _addEntry();
    }
  }

  Map<String, dynamic> _buildPayload(BuildContext context) {
    final commonProvider = context.read<CommonProvider>();
    final testedBy = commonProvider.userName?.trim().isNotEmpty == true
        ? commonProvider.userName!.trim()
        : 'TE User';

    final mappedEntries = _entries.map((entry) {
      final readings = entry.readings.map((row) {
        final distance = double.tryParse(row.distanceController.text) ?? 0;
        final time = double.tryParse(row.timeController.text) ?? 0;
        return <String, dynamic>{
          'distance_mm': distance,
          'time_us': time,
          'velocity_km_s': row.velocity,
        };
      }).toList();

      return <String, dynamic>{
        'location': entry.locationController.text.trim(),
        'type': entry.type,
        'grade': entry.grade,
        'readings': readings,
        'average_velocity_km_s': entry.averageVelocity,
        'condition': entry.condition,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final firstReading = mappedEntries
        .expand(
          (entry) => (entry['readings'] as List).cast<Map<String, dynamic>>(),
        )
        .firstWhere(
          (reading) =>
              ((reading['distance_mm'] as num?)?.toDouble() ?? 0) > 0 &&
              ((reading['time_us'] as num?)?.toDouble() ?? 0) > 0,
          orElse: () => <String, dynamic>{},
        );

    final velocities = mappedEntries
        .map(
          (entry) => (entry['average_velocity_km_s'] as num?)?.toDouble() ?? 0,
        )
        .where((value) => value > 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'ultra_pulse_velocity',
      'component_type': 'structure',
      'component_id': 'structure_main',
      'test_date': _todayDate(),
      'tested_by': testedBy,
      'remarks': mappedEntries
          .map((entry) => (entry['remarks'] ?? '').toString().trim())
          .where((value) => value.isNotEmpty)
          .join(' | '),
      'test_results': <String, dynamic>{
        'entries': mappedEntries,
        'path_length_mm':
            (firstReading['distance_mm'] as num?)?.toDouble() ?? 0,
        'transit_time_us': (firstReading['time_us'] as num?)?.toDouble() ?? 0,
        'velocity_km_s': velocities.isNotEmpty
            ? velocities.reduce((a, b) => a + b) / velocities.length
            : 0,
      },
    };
  }

  Future<void> _saveResult(BuildContext context) async {
    if (widget.structureId.trim().isEmpty) return;
    await context.read<TestingResultsProvider>().upsertStructureResult(
      context,
      widget.structureId,
      payload: _buildPayload(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: const ModuleBackArrow(),
        titleSpacing: 2,
        title: const ModuleHeaderTitle(
          title: 'UPV Test',
          subtitle: 'Inspect, input and test structures.',
        ),
      ),
      body: SingleChildScrollView(
        padding: testingFormContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location cards ─────────────────────────────────────────
            ...List.generate(_entries.length, (i) {
              return _LocationCard(
                index: i,
                entry: _entries[i],
                canRemove: _entries.length > 1,
                onChanged: () => _onChanged(i),
                onRemove: () => _removeEntry(i),
                onGradeChanged: (g) => setState(() {
                  _entries[i].grade = g;
                  _entries[i].recalculate();
                }),
                onTypeChanged: (t) => setState(() {
                  _entries[i].type = t;
                }),
                onExpandChanged: (v) =>
                    setState(() => _entries[i].isExpanded = v),
                onAddReading: () => setState(() => _entries[i].addReading()),
                onRemoveReading: (ri) => setState(() {
                  _entries[i].removeReading(ri);
                  _entries[i].recalculate();
                }),
              );
            }),

            // ── Add Location button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text("Add Location", style: w500_16Poppins()),
              ),
            ),

            const SizedBox(height: 8),

            // ── Results summary table ──────────────────────────────────
            _ResultsSummaryTable(entries: _entries),

            const SizedBox(height: 16),

            // ── Remarks & Evidence ─────────────────────────────────────
            const EvidenceSection(),
            if (widget.structureId.trim().isNotEmpty) ...[
              Consumer<TestingResultsProvider>(
                builder: (context, provider, child) {
                  final isSaving = provider.isSaving(
                    widget.structureId,
                    'ultra_pulse_velocity',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save UPV Result',
                    isLoading: isSaving,
                    onPressed: () => _saveResult(context),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Location Card ──────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final int index;
  final _LocationEntry entry;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final ValueChanged<String?> onGradeChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onExpandChanged;
  final VoidCallback onAddReading;
  final ValueChanged<int> onRemoveReading;

  const _LocationCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onGradeChanged,
    required this.onTypeChanged,
    required this.onExpandChanged,
    required this.onAddReading,
    required this.onRemoveReading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: () => onExpandChanged(!entry.isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    entry.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Location ${index + 1}"
                      "${entry.locationController.text.isNotEmpty ? ' – ${entry.locationController.text}' : ''}",
                      style: w500_18Poppins(),
                    ),
                  ),
                  // Collapsed result chips
                  if (!entry.isExpanded && entry.averageVelocity > 0) ...[
                    _Chip(
                      label: "Avg",
                      value: "${entry.averageVelocity.toStringAsFixed(2)} km/s",
                    ),
                    const SizedBox(width: 6),
                    _Chip(label: "Condition", value: entry.condition),
                    const SizedBox(width: 8),
                  ],
                  if (canRemove)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Remove location",
                      onPressed: onRemove,
                    ),
                ],
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────
          if (entry.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Location + Type
                  Row(
                    children: [
                      _buildTextField(
                        context,
                        label: "Location",
                        controller: entry.locationController,
                        onChanged: (_) => onChanged(),
                      ),
                      width10,
                      _buildTypeDropdown(context),
                    ],
                  ),
                  height5,

                  // Grade of Concrete
                  _buildGradeDropdown(context),
                  height10,

                  // Readings table
                  _ReadingsTable(
                    entry: entry,
                    onChanged: onChanged,
                    onRemoveReading: onRemoveReading,
                  ),
                  height5,

                  // Add Reading button
                  TextButton.icon(
                    onPressed: onAddReading,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text("Add Reading", style: w400_14Poppins()),
                  ),
                  height10,

                  // Per-location result tiles
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          title: "Avg. Velocity (km/s)",
                          value: entry.averageVelocity > 0
                              ? "${entry.averageVelocity.toStringAsFixed(2)} km/s"
                              : "--",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(
                          title: "Condition",
                          value: entry.condition,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: CommonTextFormField(
            fillColor: Appcolors.textformFillColor,
            borderColor: Colors.grey.shade400,
            controller: controller,
            hintText: "Enter $label",
            keyboardType: keyboardType,
            hintStyle: w400_17Poppins(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Type (ID/D):", style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: DropdownButtonFormField<String>(
            dropdownColor: Appcolors.textformFillColor,
            value: entry.type,
            decoration: _dropdownDecoration(),
            isExpanded: true,
            items: ["D", "ID"].map((t) {
              return DropdownMenuItem<String>(
                value: t,
                child: Text(
                  t == "D" ? "D – Direct" : "ID – Indirect",
                  style: w400_15Poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Grade of Concrete:", style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: DropdownButtonFormField<String>(
            dropdownColor: Appcolors.textformFillColor,
            hint: Text("Select Grade", style: w400_15Poppins()),
            value: entry.grade,
            decoration: _dropdownDecoration(),
            isExpanded: true,
            items: _allGrades.map((g) {
              return DropdownMenuItem<String>(
                value: g,
                child: Text(g, style: w400_15Poppins()),
              );
            }).toList(),
            onChanged: onGradeChanged,
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Appcolors.textformFillColor,
    focusColor: Appcolors.textformFillColor,
    hoverColor: Appcolors.textformFillColor,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

// ── Readings Table ─────────────────────────────────────────────────────────

class _ReadingsTable extends StatelessWidget {
  final _LocationEntry entry;
  final VoidCallback onChanged;
  final ValueChanged<int> onRemoveReading;

  const _ReadingsTable({
    required this.entry,
    required this.onChanged,
    required this.onRemoveReading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 620,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(55),
            1: FixedColumnWidth(170),
            2: FixedColumnWidth(170),
            3: FixedColumnWidth(170),
            4: FixedColumnWidth(55),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _th("No"),
                _th("Dist. (mm)"),
                _th("Time (μs)"),
                _th("Velocity\n(km/s)"),
                _th(""),
              ],
            ),
            // Data rows
            ...List.generate(entry.readings.length, (i) {
              final row = entry.readings[i];
              final vel = row.velocity;
              return TableRow(
                children: [
                  _td(
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 8),
                      child: Text("${i + 1}", style: w400_14Poppins()),
                    ),
                  ),
                  _td(
                    CommonTextFormField(
                      controller: row.distanceController,
                      keyboardType: TextInputType.number,
                      borderColor: Colors.transparent,
                      fillColor: Colors.transparent,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  _td(
                    SizedBox(
                      width: double.infinity,
                      child: CommonTextFormField(
                        controller: row.timeController,
                        keyboardType: TextInputType.number,
                        borderColor: Colors.transparent,
                        fillColor: Colors.transparent,
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ),
                  // Auto-calculated velocity cell
                  _td(
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        vel > 0 ? vel.toStringAsFixed(2) : "--",
                        style: w400_14Poppins(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Remove row button
                  _td(
                    entry.readings.length > 1
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => onRemoveReading(i),
                            padding: EdgeInsets.zero,
                          )
                        : const SizedBox(),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
  );

  Widget _td(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: child,
  );
}

// ── Consolidated Results Summary Table ────────────────────────────────────

class _ResultsSummaryTable extends StatelessWidget {
  final List<_LocationEntry> entries;

  const _ResultsSummaryTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Results Summary", style: w600_18Poppins()),
            height10,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 975,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(55),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(90),
                    3: FixedColumnWidth(120),
                    4: FixedColumnWidth(180),
                    5: FixedColumnWidth(130),
                    6: FixedColumnWidth(200),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Type\nID/D"),
                        _th("Grade"),
                        _th("Avg. Velocity\n(km/s)"),
                        _th("Condition"),
                        _th("Remarks"),
                      ],
                    ),
                    ...List.generate(entries.length, (i) {
                      final e = entries[i];
                      return TableRow(
                        children: [
                          _td("${i + 1}"),
                          _td(
                            e.locationController.text.isNotEmpty
                                ? e.locationController.text
                                : "—",
                          ),
                          _td(e.type),
                          _td(e.grade ?? "—"),
                          _td(
                            e.averageVelocity > 0
                                ? e.averageVelocity.toStringAsFixed(2)
                                : "—",
                          ),
                          _tdCondition(e.condition),
                          _tdEditable(e.remarksController),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
  );

  Widget _td(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    child: Text(text, style: w400_14Poppins(), textAlign: TextAlign.center),
  );

  /// Condition cell with colour coding
  Widget _tdCondition(String condition) {
    Color color;
    switch (condition) {
      case "Excellent":
        color = Colors.green.shade100;
        break;
      case "Good":
        color = Colors.lightGreen.shade100;
        break;
      case "Doubtful":
        color = Colors.orange.shade100;
        break;
      default:
        color = Colors.transparent;
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          condition,
          style: w400_14Poppins(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _tdEditable(TextEditingController controller) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: CommonTextFormField(
      controller: controller,
      borderColor: Colors.transparent,
      fillColor: Colors.transparent,
      hintText: "Add remark",
    ),
  );
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: w400_14Poppins()),
          height5,
          Text(value, style: w600_24Poppins()),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;

  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text("$label: $value", style: w400_14Poppins()),
    );
  }
}

String _todayDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
