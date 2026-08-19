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

// ── Location entry model ───────────────────────────────────────────────────

class _LocationEntry {
  final TextEditingController locationController;
  final TextEditingController remarksController;
  List<TextEditingController> readingControllers;
  double averageValue;
  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      remarksController = TextEditingController(),
      readingControllers = [],
      averageValue = 0.0,
      isExpanded = true {
    // Start with 3 reading rows matching the smallest sample in the spec
    readingControllers = List.generate(3, (_) => TextEditingController());
  }

  void addReading() => readingControllers.add(TextEditingController());

  void removeReading(int index) {
    if (readingControllers.length > 1) {
      readingControllers[index].dispose();
      readingControllers.removeAt(index);
    }
  }

  /// Auto-calculates average from all non-empty readings (spec requirement).
  void recalculate() {
    final values = readingControllers
        .map((c) => double.tryParse(c.text))
        .where((v) => v != null && v > 0)
        .cast<double>()
        .toList();

    averageValue = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : 0.0;
  }

  void dispose() {
    locationController.dispose();
    remarksController.dispose();
    for (final c in readingControllers) {
      c.dispose();
    }
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────

class CoverMeterScreen extends StatefulWidget {
  const CoverMeterScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<CoverMeterScreen> createState() => _CoverMeterScreenState();
}

class _CoverMeterScreenState extends State<CoverMeterScreen> {
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
        'cover_meter',
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
      for (final controller in entry.readingControllers) {
        controller.dispose();
      }
      entry.readingControllers.clear();
      final readings = (map['readings'] as List?) ?? const [];
      for (final dynamic rawValue in readings) {
        final controller = TextEditingController(text: rawValue.toString());
        entry.readingControllers.add(controller);
      }
      if (entry.readingControllers.isEmpty) {
        entry.readingControllers = List.generate(
          3,
          (_) => TextEditingController(),
        );
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
      final readings = entry.readingControllers
          .map((controller) => double.tryParse(controller.text))
          .whereType<double>()
          .toList();
      return <String, dynamic>{
        'location': entry.locationController.text.trim(),
        'readings': readings,
        'avg_cover_mm': entry.averageValue,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final averages = mappedEntries
        .map((entry) => (entry['avg_cover_mm'] as num?)?.toDouble() ?? 0)
        .where((value) => value > 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'cover_meter',
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
        'bar_diameter_mm': null,
        'avg_cover_mm': averages.isNotEmpty
            ? averages.reduce((a, b) => a + b) / averages.length
            : 0,
        'cover_compliance': 'Adequate',
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
          title: 'Cover Meter Test',
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
                    'cover_meter',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save Cover Meter Result',
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
  final ValueChanged<bool> onExpandChanged;
  final VoidCallback onAddReading;
  final ValueChanged<int> onRemoveReading;

  const _LocationCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
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
                  // Collapsed chips
                  if (!entry.isExpanded && entry.averageValue > 0) ...[
                    _Chip(
                      label: "Avg",
                      value: "${entry.averageValue.toStringAsFixed(1)} mm",
                    ),
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Location field
                  _buildTextField(
                    context,
                    label: "Location",
                    controller: entry.locationController,
                    width: MediaQuery.of(context).size.width * 0.65,
                    onChanged: (_) => onChanged(),
                  ),
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

                  // Auto-calculated average tile
                  _SummaryTile(
                    title: "Average Value (mm)",
                    value: entry.averageValue > 0
                        ? "${entry.averageValue.toStringAsFixed(2)} mm"
                        : "--",
                  ),
                  height10,

                  // Remarks
                  _buildMultilineField(
                    context,
                    label: "Remarks",
                    controller: entry.remarksController,
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
    double? width,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: w600_16Poppins()),
        height5,
        SizedBox(
          width: width ?? MediaQuery.of(context).size.width * 0.3,
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

  Widget _buildMultilineField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: w600_16Poppins()),
        height5,
        CommonTextFormField(
          fillColor: Appcolors.textformFillColor,
          borderColor: Colors.grey.shade400,
          controller: controller,
          hintText: "Enter $label",
          hintStyle: w400_17Poppins(),
          maxLines: 3,
        ),
      ],
    );
  }
}

// ── Readings Table ─────────────────────────────────────────────────────────
// Columns: No(60) + Reading(200) + Remove(55) = 315

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
        width: 315,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FixedColumnWidth(200),
            2: FixedColumnWidth(55),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [_th("No"), _th("Cover Meter\nReading (MM)"), _th("")],
            ),
            // Data rows — one per reading
            ...List.generate(entry.readingControllers.length, (i) {
              return TableRow(
                children: [
                  _td(
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 12),
                      child: Text("${i + 1}", style: w400_14Poppins()),
                    ),
                  ),
                  _td(
                    SizedBox(
                      width: double.infinity,
                      child: CommonTextFormField(
                        controller: entry.readingControllers[i],
                        keyboardType: TextInputType.number,
                        borderColor: Colors.transparent,
                        fillColor: Colors.transparent,
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ),
                  _td(
                    entry.readingControllers.length > 1
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => onRemoveReading(i),
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
// Columns: S.No(60) + Location(250) + Readings(220) + Avg(160) + Remarks(200) = 890

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
                width: 890,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(250),
                    2: FixedColumnWidth(220),
                    3: FixedColumnWidth(160),
                    4: FixedColumnWidth(200),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Cover Meter\nReadings (MM)"),
                        _th("Average\nValue (MM)"),
                        _th("Remarks"),
                      ],
                    ),
                    // Data rows
                    ...List.generate(entries.length, (i) {
                      final e = entries[i];

                      // Build all non-empty readings as comma-separated string
                      final readingsList = e.readingControllers
                          .map((c) => c.text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      final readingsText = readingsList.isNotEmpty
                          ? readingsList.join(", ")
                          : "—";

                      return TableRow(
                        children: [
                          _td("${i + 1}"),
                          _td(
                            e.locationController.text.isNotEmpty
                                ? e.locationController.text
                                : "—",
                          ),
                          _td(readingsText),
                          _tdHighlight(
                            e.averageValue > 0
                                ? e.averageValue.toStringAsFixed(1)
                                : "—",
                          ),
                          _td(
                            e.remarksController.text.isNotEmpty
                                ? e.remarksController.text
                                : "—",
                          ),
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

  /// Highlighted cell for the auto-calculated average value
  Widget _tdHighlight(String text) => Padding(
    padding: const EdgeInsets.all(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(text, style: w400_14Poppins(), textAlign: TextAlign.center),
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Text("$title: ", style: w400_14Poppins()),
          Text(value, style: w600_24Poppins()),
        ],
      ),
    );
  }
}

String _todayDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
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
