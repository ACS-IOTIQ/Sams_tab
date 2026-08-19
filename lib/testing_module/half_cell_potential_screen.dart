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

// ── HCP % corrosion activity lookup (IS 516 Part 5/Sec 2: 2021) ───────────
//
// Potential Level (mV)  →  % Chances of Corrosion Activity
//   Less than 200       →  10%
//   200 to 350          →  Uncertain
//   350 to 500          →  90%
//   Above 500           →  95%

String _determineCorrosion(double avgHcp) {
  final abs = avgHcp.abs();
  if (abs < 200) return "10%";
  if (abs <= 350) return "Uncertain";
  if (abs <= 500) return "90%";
  return "95%";
}

// ── Location entry model ───────────────────────────────────────────────────

class _LocationEntry {
  final TextEditingController locationController;
  final TextEditingController remarksController;
  int gridSize;
  List<List<TextEditingController>> rowControllers;
  double averageHcp;
  String corrosionProbability;
  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      remarksController = TextEditingController(),
      gridSize = 6,
      rowControllers = [],
      averageHcp = 0.0,
      corrosionProbability = "--",
      isExpanded = true {
    _rebuildControllers();
  }

  /// Grid sizes 6, 9, 12, 15 are all multiples of 3 → 2/3/4/5 rows of 3.
  int get rowCount => gridSize ~/ 3;

  List<TextEditingController> get allControllers =>
      rowControllers.expand((r) => r).toList();

  void _rebuildControllers() {
    for (final row in rowControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    rowControllers = List.generate(
      rowCount,
      (_) => List.generate(3, (_) => TextEditingController()),
    );
  }

  void updateGridSize(int newSize) {
    gridSize = newSize;
    _rebuildControllers();
  }

  void recalculate() {
    final values = allControllers
        .map((c) => double.tryParse(c.text))
        .where((v) => v != null)
        .cast<double>()
        .toList();

    if (values.isNotEmpty) {
      averageHcp = values.reduce((a, b) => a + b) / values.length;
      corrosionProbability = _determineCorrosion(averageHcp);
    } else {
      averageHcp = 0.0;
      corrosionProbability = "--";
    }
  }

  void dispose() {
    locationController.dispose();
    remarksController.dispose();
    for (final row in rowControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────

class HalfCellPotentialScreen extends StatefulWidget {
  const HalfCellPotentialScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<HalfCellPotentialScreen> createState() =>
      _HalfCellPotentialScreenState();
}

class _HalfCellPotentialScreenState extends State<HalfCellPotentialScreen> {
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
        'half_cell_potential',
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
      entry.gridSize = int.tryParse((map['grid_size'] ?? '6').toString()) ?? 6;
      entry._rebuildControllers();
      final readings = (map['readings'] as List?) ?? const [];
      for (
        var i = 0;
        i < entry.allControllers.length && i < readings.length;
        i++
      ) {
        entry.allControllers[i].text = readings[i].toString();
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
      final readings = entry.allControllers
          .map((controller) => double.tryParse(controller.text))
          .whereType<double>()
          .toList();
      return <String, dynamic>{
        'location': entry.locationController.text.trim(),
        'grid_size': entry.gridSize,
        'readings': readings,
        'avg_potential_mv': entry.averageHcp,
        'corrosion_probability': entry.corrosionProbability,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final averages = mappedEntries
        .map((entry) => (entry['avg_potential_mv'] as num?)?.toDouble() ?? 0)
        .where((value) => value != 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'half_cell_potential',
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
        'grid_reference': mappedEntries.isNotEmpty
            ? (mappedEntries.first['location'] ?? '').toString()
            : '',
        'avg_potential_mv': averages.isNotEmpty
            ? averages.reduce((a, b) => a + b) / averages.length
            : 0,
        'corrosion_probability': mappedEntries.isNotEmpty
            ? (mappedEntries.first['corrosion_probability'] ?? '').toString()
            : '',
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
          title: 'Half Cell Potential Test',
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
                onGridSizeChanged: (size) => setState(() {
                  _entries[i].updateGridSize(size);
                  _entries[i].recalculate();
                }),
                onExpandChanged: (v) =>
                    setState(() => _entries[i].isExpanded = v),
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

            _ResultsSummaryTable(entries: _entries),

            const SizedBox(height: 16),

            const EvidenceSection(),
            if (widget.structureId.trim().isNotEmpty) ...[
              Consumer<TestingResultsProvider>(
                builder: (context, provider, child) {
                  final isSaving = provider.isSaving(
                    widget.structureId,
                    'half_cell_potential',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save Half Cell Potential Result',
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

class _LocationCard extends StatelessWidget {
  final int index;
  final _LocationEntry entry;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onGridSizeChanged;
  final ValueChanged<bool> onExpandChanged;

  const _LocationCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onGridSizeChanged,
    required this.onExpandChanged,
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
                  if (!entry.isExpanded && entry.averageHcp != 0) ...[
                    _Chip(
                      label: "Avg HCP",
                      value: "${entry.averageHcp.toStringAsFixed(1)} mV",
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      label: "Corrosion",
                      value: entry.corrosionProbability,
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Location + Grid Size
                  Row(
                    children: [
                      _buildTextField(
                        context,
                        label: "Location",
                        controller: entry.locationController,
                        onChanged: (_) => onChanged(),
                      ),
                      width10,
                      _buildGridDropdown(context),
                    ],
                  ),
                  height10,

                  // Reading grid
                  _ReadingGrid(entry: entry, onChanged: onChanged),
                  height10,

                  // Per-location result tiles
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          title: "Avg. HCP Reading (mV)",
                          value: entry.averageHcp != 0
                              ? "${entry.averageHcp.toStringAsFixed(2)} mV"
                              : "--",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(
                          title: "% of HCP\n(Corrosion Activity)",
                          value: entry.corrosionProbability,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          child: CommonTextFormField(
            fillColor: Appcolors.textformFillColor,
            borderColor: Colors.grey.shade400,
            controller: controller,
            hintText: "Enter $label",
            hintStyle: w400_17Poppins(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGridDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Grid Size:", style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.29,
          child: DropdownButtonFormField<int>(
            dropdownColor: Appcolors.textformFillColor,
            value: entry.gridSize,
            decoration: _dropdownDecoration(),
            isExpanded: true,
            // Spec: 6, 9, 12 or 15
            items: [6, 9, 12, 15].map((size) {
              return DropdownMenuItem<int>(
                value: size,
                child: Text(size.toString(), style: w400_15Poppins()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onGridSizeChanged(value);
            },
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

// ── Reading Grid (3 columns × rowCount rows) ───────────────────────────────
// Total width: 60 + 160 + 160 + 160 = 540

class _ReadingGrid extends StatelessWidget {
  final _LocationEntry entry;
  final VoidCallback onChanged;

  const _ReadingGrid({required this.entry, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 540,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FixedColumnWidth(160),
            2: FixedColumnWidth(160),
            3: FixedColumnWidth(160),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _th("No"),
                _th("Reading 1 (mV)"),
                _th("Reading 2 (mV)"),
                _th("Reading 3 (mV)"),
              ],
            ),
            // Data rows
            ...List.generate(entry.rowCount, (rowIndex) {
              return TableRow(
                children: [
                  _td(
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 12),
                      child: Text("${rowIndex + 1}", style: w400_14Poppins()),
                    ),
                  ),
                  ...List.generate(3, (colIndex) {
                    return _td(
                      SizedBox(
                        width: double.infinity,
                        child: CommonTextFormField(
                          controller: entry.rowControllers[rowIndex][colIndex],
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          borderColor: Colors.transparent,
                          fillColor: Colors.transparent,
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
  );

  Widget _td(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: child,
  );
}

// ── Consolidated Results Summary Table ────────────────────────────────────
// Total width: 60 + 200 + 100 + 190 + 180 + 200 = 930

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
                width: 930,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(100),
                    3: FixedColumnWidth(190),
                    4: FixedColumnWidth(180),
                    5: FixedColumnWidth(200),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Grid\nSize"),
                        _th("Avg. HCP\nReading (mV)"),
                        _th("% of HCP\n(Corrosion Activity)"),
                        _th("Remarks"),
                      ],
                    ),
                    // One row per location
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
                          _td("${e.gridSize}"),
                          _td(
                            e.averageHcp != 0
                                ? e.averageHcp.toStringAsFixed(2)
                                : "—",
                          ),
                          _tdCorrosion(e.corrosionProbability),
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

  /// Colour-coded corrosion probability cell
  Widget _tdCorrosion(String value) {
    Color color;
    switch (value) {
      case "10%":
        color = Colors.green.shade100;
        break;
      case "Uncertain":
        color = Colors.orange.shade100;
        break;
      case "90%":
        color = Colors.red.shade100;
        break;
      case "95%":
        color = Colors.red.shade200;
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
          value,
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
