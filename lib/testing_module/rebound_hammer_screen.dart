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

// ── Strength lookup tables from documentation ──────────────────────────────

const Map<int, int> _strengthAt0Degrees = {
  20: 10,
  21: 11,
  22: 12,
  23: 13,
  24: 15,
  25: 16,
  26: 17,
  27: 19,
  28: 20,
  29: 22,
  30: 23,
  31: 25,
  32: 27,
  33: 28,
  34: 30,
  35: 32,
  36: 33,
  37: 35,
  38: 37,
  39: 39,
  40: 40,
  41: 42,
  42: 44,
  43: 46,
  44: 48,
  45: 50,
  46: 51,
  47: 53,
  48: 54,
  49: 56,
  50: 58,
  51: 60,
  52: 62,
  53: 64,
  54: 66,
  55: 68,
};

const Map<int, int> _strengthAt90Degrees = {
  20: 10,
  21: 10,
  22: 10,
  23: 10,
  24: 10,
  25: 10,
  26: 11,
  27: 12,
  28: 13,
  29: 15,
  30: 16,
  31: 18,
  32: 19,
  33: 21,
  34: 23,
  35: 25,
  36: 26,
  37: 28,
  38: 29,
  39: 31,
  40: 33,
  41: 35,
  42: 37,
  43: 39,
  44: 41,
  45: 43,
  46: 45,
  47: 47,
  48: 49,
  49: 51,
  50: 53,
  51: 55,
  52: 57,
  53: 59,
  54: 61,
  55: 63,
};

double _lookupStrength(double avgRebound, String degrees) {
  final table = degrees == "0" ? _strengthAt0Degrees : _strengthAt90Degrees;
  final key = avgRebound.round().clamp(20, 55);
  return (table[key] ?? 0).toDouble();
}

// ── Location data model ────────────────────────────────────────────────────

class _LocationEntry {
  final TextEditingController locationController;
  final TextEditingController memberController;
  final TextEditingController remarksController;
  String degrees;
  int gridSize;
  List<List<TextEditingController>> rowControllers;
  double averageRebound;
  double surfaceStrength;
  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      memberController = TextEditingController(),
      remarksController = TextEditingController(),
      degrees = "0",
      gridSize = 6,
      rowControllers = [],
      averageRebound = 0.0,
      surfaceStrength = 0.0,
      isExpanded = true {
    _rebuildControllers();
  }

  int get rowCount => gridSize ~/ 3;

  List<TextEditingController> get allControllers =>
      rowControllers.expand((row) => row).toList();

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
        .map((c) => double.tryParse(c.text) ?? 0)
        .where((v) => v > 0)
        .toList();

    if (values.isNotEmpty) {
      averageRebound = values.reduce((a, b) => a + b) / values.length;
      surfaceStrength = _lookupStrength(averageRebound, degrees);
    } else {
      averageRebound = 0.0;
      surfaceStrength = 0.0;
    }
  }

  void dispose() {
    locationController.dispose();
    memberController.dispose();
    remarksController.dispose();
    for (final row in rowControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────

class ReboundHammerScreen extends StatefulWidget {
  const ReboundHammerScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<ReboundHammerScreen> createState() => _ReboundHammerScreenState();
}

class _ReboundHammerScreenState extends State<ReboundHammerScreen> {
  final List<_LocationEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _addEntry(); // Start with one location by default
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.structureId.trim().isEmpty) return;
      final provider = context.read<TestingResultsProvider>();
      await provider.fetchStructureResults(context, widget.structureId);
      final existing = provider.findStructureResult(
        widget.structureId,
        'rebound_hammer',
      );
      if (existing != null && mounted) {
        setState(() {
          _hydrateFromExisting(existing);
        });
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

  void _onEntryChanged(int index) =>
      setState(() => _entries[index].recalculate());

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
      entry.memberController.text = (map['member'] ?? '').toString();
      entry.remarksController.text = (map['remarks'] ?? '').toString();
      entry.degrees = (map['degrees'] ?? '0').toString();
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
        'member': entry.memberController.text.trim(),
        'degrees': entry.degrees,
        'grid_size': entry.gridSize,
        'readings': readings,
        'avg_rebound_number': entry.averageRebound,
        'estimated_strength_mpa': entry.surfaceStrength,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final avgReboundValues = mappedEntries
        .map((entry) => (entry['avg_rebound_number'] as num?)?.toDouble() ?? 0)
        .where((value) => value > 0)
        .toList();
    final avgStrengthValues = mappedEntries
        .map(
          (entry) => (entry['estimated_strength_mpa'] as num?)?.toDouble() ?? 0,
        )
        .where((value) => value > 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'rebound_hammer',
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
        'element_count': mappedEntries.length,
        'avg_rebound_number': avgReboundValues.isNotEmpty
            ? avgReboundValues.reduce((a, b) => a + b) / avgReboundValues.length
            : 0,
        'estimated_strength_mpa': avgStrengthValues.isNotEmpty
            ? avgStrengthValues.reduce((a, b) => a + b) /
                  avgStrengthValues.length
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
          title: 'Rebound Hammer Test',
          subtitle: 'Inspect, input and test structures.',
        ),
      ),
      body: SingleChildScrollView(
        padding: testingFormContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location entry cards ───────────────────────────────────
            ...List.generate(_entries.length, (i) {
              return _LocationCard(
                index: i,
                entry: _entries[i],
                canRemove: _entries.length > 1,
                onChanged: () => _onEntryChanged(i),
                onRemove: () => _removeEntry(i),
                onGridSizeChanged: (size) => setState(() {
                  _entries[i].updateGridSize(size);
                  _entries[i].recalculate();
                }),
                onDegreesChanged: (deg) => setState(() {
                  _entries[i].degrees = deg;
                  _entries[i].recalculate();
                }),
                onExpandChanged: (val) =>
                    setState(() => _entries[i].isExpanded = val),
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

            // ── Consolidated results summary ───────────────────────────
            _ResultsSummaryTable(entries: _entries),

            const SizedBox(height: 16),

            // ── Remarks & Evidence card ────────────────────────────────
            const EvidenceSection(),
            if (widget.structureId.trim().isNotEmpty) ...[
              Consumer<TestingResultsProvider>(
                builder: (context, provider, child) {
                  final isSaving = provider.isSaving(
                    widget.structureId,
                    'rebound_hammer',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save Rebound Hammer Result',
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
  final ValueChanged<int> onGridSizeChanged;
  final ValueChanged<String> onDegreesChanged;
  final ValueChanged<bool> onExpandChanged;

  const _LocationCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onGridSizeChanged,
    required this.onDegreesChanged,
    required this.onExpandChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Header: expand toggle + title + result chips + delete ──
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
                  // Show mini result chips when card is collapsed
                  if (!entry.isExpanded && entry.averageRebound > 0) ...[
                    _ResultChip(
                      label: "Avg",
                      value: entry.averageRebound.toStringAsFixed(1),
                    ),
                    const SizedBox(width: 6),
                    _ResultChip(
                      label: "Strength",
                      value:
                          "${entry.surfaceStrength.toStringAsFixed(0)} N/mm²",
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (canRemove)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Remove this location",
                      onPressed: onRemove,
                    ),
                ],
              ),
            ),
          ),

          // ── Collapsible body ───────────────────────────────────────
          if (entry.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Location + Member
                  Row(
                    children: [
                      _buildField(
                        context,
                        label: "Location",
                        controller: entry.locationController,
                        onChanged: (_) => onChanged(),
                      ),
                      width10,
                      _buildField(
                        context,
                        label: "Member",
                        controller: entry.memberController,
                        onChanged: (_) => onChanged(),
                      ),
                    ],
                  ),
                  height5,

                  // Degrees + Grid Size
                  Row(
                    children: [
                      _buildDegreesDropdown(context),
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
                          title: "Avg. Rebound Number",
                          value: entry.averageRebound > 0
                              ? entry.averageRebound.toStringAsFixed(2)
                              : "--",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(
                          title: "Surface Strength (N/mm²)",
                          value: entry.surfaceStrength > 0
                              ? "${entry.surfaceStrength.toStringAsFixed(0)} N/mm²"
                              : "--",
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

  Widget _buildField(
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

  Widget _buildDegreesDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Degrees:", style: w600_16Poppins()),
        height5,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: DropdownButtonFormField<String>(
            dropdownColor: Appcolors.textformFillColor,
            value: entry.degrees,
            decoration: _dropdownDecoration(),
            isExpanded: true,
            items: ["0", "90"].map((deg) {
              return DropdownMenuItem<String>(
                value: deg,
                child: Text("$deg°", style: w400_15Poppins()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onDegreesChanged(value);
            },
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
          width: MediaQuery.of(context).size.width * 0.3,
          child: DropdownButtonFormField<int>(
            dropdownColor: Appcolors.textformFillColor,
            value: entry.gridSize,
            decoration: _dropdownDecoration(),
            isExpanded: true,
            items: [6, 9, 12].map((size) {
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

// ── Reading Grid (3 columns × n rows) ─────────────────────────────────────

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
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _header("No"),
                _header("Reading 1"),
                _header("Reading 2"),
                _header("Reading 3"),
              ],
            ),
            ...List.generate(entry.rowCount, (rowIndex) {
              return TableRow(
                children: [
                  _cell(
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 12),
                      child: Text("${rowIndex + 1}", style: w400_14Poppins()),
                    ),
                  ),
                  ...List.generate(3, (colIndex) {
                    return _cell(
                      SizedBox(
                        width: double.infinity,
                        child: CommonTextFormField(
                          controller: entry.rowControllers[rowIndex][colIndex],
                          keyboardType: TextInputType.number,
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

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
  );

  Widget _cell(Widget child) => Padding(
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
                width: 910,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(100),
                    3: FixedColumnWidth(160),
                    4: FixedColumnWidth(190),
                    5: FixedColumnWidth(200),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Degrees"),
                        _th("Avg. Rebound\nNumber"),
                        _th("Surface Strength\n(N/mm²)"),
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
                          _td("${e.degrees}°"),
                          _td(
                            e.averageRebound > 0
                                ? e.averageRebound.toStringAsFixed(2)
                                : "—",
                          ),
                          _td(
                            e.surfaceStrength > 0
                                ? e.surfaceStrength.toStringAsFixed(0)
                                : "—",
                          ),
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

// ── Small helper widgets ───────────────────────────────────────────────────

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

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;

  const _ResultChip({required this.label, required this.value});

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
