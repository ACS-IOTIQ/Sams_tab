import 'dart:math' as math;
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
  final TextEditingController anchorDepthController; // D – mm
  final TextEditingController anchorDiaController; // mm (manual input)
  final TextEditingController loadAppliedController; // N
  final TextEditingController remarksController;

  // Auto-calculated fields
  double surfaceLength; // π × Dia of anchor  (mm)
  double surfaceArea; // Surface Length × Depth of anchor  (mm²)
  double pullOutStrength; // Load Applied / Surface Area  (N/mm²)

  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      anchorDepthController = TextEditingController(),
      anchorDiaController = TextEditingController(),
      loadAppliedController = TextEditingController(),
      remarksController = TextEditingController(),
      surfaceLength = 0.0,
      surfaceArea = 0.0,
      pullOutStrength = 0.0,
      isExpanded = true;

  /// Live recalculation per spec:
  ///   Surface Length  = π × Dia of Anchor
  ///   Surface Area    = Surface Length × Depth of Anchor
  ///   Pull-out Strength = Load Applied (N) / Surface Area (mm²)  → N/mm²
  void recalculate() {
    final depth = double.tryParse(anchorDepthController.text) ?? 0;
    final dia = double.tryParse(anchorDiaController.text) ?? 0;
    final load = double.tryParse(loadAppliedController.text) ?? 0;

    if (depth > 0 && dia > 0) {
      surfaceLength = math.pi * dia;
      surfaceArea = surfaceLength * depth;
      pullOutStrength = (load > 0 && surfaceArea > 0)
          ? load / surfaceArea
          : 0.0;
    } else {
      surfaceLength = 0.0;
      surfaceArea = 0.0;
      pullOutStrength = 0.0;
    }
  }

  void dispose() {
    locationController.dispose();
    anchorDepthController.dispose();
    anchorDiaController.dispose();
    loadAppliedController.dispose();
    remarksController.dispose();
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────

class PullOutTestScreen extends StatefulWidget {
  const PullOutTestScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<PullOutTestScreen> createState() => _PullOutTestScreenState();
}

class _PullOutTestScreenState extends State<PullOutTestScreen> {
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
        'pull_out',
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
      entry.anchorDepthController.text = (map['anchor_depth_mm'] ?? '')
          .toString();
      entry.anchorDiaController.text = (map['anchor_diameter_mm'] ?? '')
          .toString();
      entry.loadAppliedController.text = (map['load_applied_n'] ?? '')
          .toString();
      entry.remarksController.text = (map['remarks'] ?? '').toString();
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
      final depth = double.tryParse(entry.anchorDepthController.text) ?? 0;
      final diameter = double.tryParse(entry.anchorDiaController.text) ?? 0;
      final load = double.tryParse(entry.loadAppliedController.text) ?? 0;
      return <String, dynamic>{
        'location': entry.locationController.text.trim(),
        'anchor_depth_mm': depth,
        'anchor_diameter_mm': diameter,
        'load_applied_n': load,
        'surface_length_mm': entry.surfaceLength,
        'surface_area_mm2': entry.surfaceArea,
        'pull_out_strength_n_per_mm2': entry.pullOutStrength,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final loads = mappedEntries
        .map((entry) => (entry['load_applied_n'] as num?)?.toDouble() ?? 0)
        .where((value) => value > 0)
        .toList();
    final strengths = mappedEntries
        .map(
          (entry) =>
              (entry['pull_out_strength_n_per_mm2'] as num?)?.toDouble() ?? 0,
        )
        .where((value) => value > 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'pull_out',
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
        'anchor_type': 'Standard',
        'peak_load_kn': loads.isNotEmpty
            ? loads.reduce((a, b) => a + b) / loads.length / 1000
            : 0,
        'estimated_strength_mpa': strengths.isNotEmpty
            ? strengths.reduce((a, b) => a + b) / strengths.length
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
          title: 'Pull-Out Test',
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
                    'pull_out',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save Pull-Out Result',
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

  const _LocationCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
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
                  if (!entry.isExpanded && entry.pullOutStrength > 0) ...[
                    _Chip(
                      label: "Pull-out",
                      value:
                          "${entry.pullOutStrength.toStringAsFixed(2)} N/mm²",
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

                  // Location (full width)
                  _buildTextField(
                    context,
                    label: "Location",
                    controller: entry.locationController,
                    width: MediaQuery.of(context).size.width * 0.65,
                    onChanged: (_) => onChanged(),
                  ),
                  height10,

                  // ── Manual inputs ──────────────────────────────────
                  Text("Manual Inputs", style: w500_18Poppins()),
                  height5,
                  Row(
                    children: [
                      _buildTextField(
                        context,
                        label: "Depth of Anchor (mm)",
                        controller: entry.anchorDepthController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => onChanged(),
                      ),
                      width10,
                      _buildTextField(
                        context,
                        label: "Dia of Anchor (mm)",
                        controller: entry.anchorDiaController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => onChanged(),
                      ),
                    ],
                  ),
                  height10,
                  _buildTextField(
                    context,
                    label: "Load Applied (N)",
                    controller: entry.loadAppliedController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                  height15,

                  // ── Auto-calculated results ────────────────────────
                  Text("Auto-Calculated Results", style: w500_18Poppins()),
                  height8,
                  Row(
                    children: [
                      Expanded(
                        child: _CalcTile(
                          label: "Surface Length",
                          formula: "π × Dia",
                          value: entry.surfaceLength > 0
                              ? "${entry.surfaceLength.toStringAsFixed(2)} mm"
                              : "--",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CalcTile(
                          label: "Surface Area",
                          formula: "Length × Depth",
                          value: entry.surfaceArea > 0
                              ? "${entry.surfaceArea.toStringAsFixed(2)} mm²"
                              : "--",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CalcTile(
                          label: "Pull-out Strength",
                          formula: "Load ÷ Area",
                          value: entry.pullOutStrength > 0
                              ? "${entry.pullOutStrength.toStringAsFixed(2)} N/mm²"
                              : "--",
                          highlight: true,
                        ),
                      ),
                    ],
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

  // ── Field builders ─────────────────────────────────────────────────────

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

// ── Consolidated Results Summary Table ────────────────────────────────────
// Columns: S.No(55) + Location(200) + Depth(110) + Dia(100) +
//          SurfLen(130) + Load(120) + SurfArea(130) + Strength(150) + Remarks(180) = 1175

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
                width: 1175,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(55),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(110),
                    3: FixedColumnWidth(100),
                    4: FixedColumnWidth(130),
                    5: FixedColumnWidth(120),
                    6: FixedColumnWidth(130),
                    7: FixedColumnWidth(150),
                    8: FixedColumnWidth(180),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Depth of\nAnchor\n(mm)"),
                        _th("Dia of\nAnchor\n(mm)"),
                        _th("Surface\nLength\n(mm)"),
                        _th("Load\nApplied\n(N)"),
                        _th("Surface\nArea\n(mm²)"),
                        _th("Pull-out\nStrength\n(N/mm²)"),
                        _th("Remarks"),
                      ],
                    ),
                    // Data rows
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
                          _td(
                            e.anchorDepthController.text.isNotEmpty
                                ? "${e.anchorDepthController.text} mm"
                                : "—",
                          ),
                          _td(
                            e.anchorDiaController.text.isNotEmpty
                                ? "${e.anchorDiaController.text} mm"
                                : "—",
                          ),
                          // Auto-calculated — highlighted
                          _tdCalc(
                            e.surfaceLength > 0
                                ? e.surfaceLength.toStringAsFixed(2)
                                : "—",
                          ),
                          _td(
                            e.loadAppliedController.text.isNotEmpty
                                ? "${e.loadAppliedController.text} N"
                                : "—",
                          ),
                          // Auto-calculated — highlighted
                          _tdCalc(
                            e.surfaceArea > 0
                                ? e.surfaceArea.toStringAsFixed(2)
                                : "—",
                          ),
                          // Pull-out strength — bold highlighted
                          _tdStrength(
                            e.pullOutStrength > 0
                                ? e.pullOutStrength.toStringAsFixed(2)
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
    padding: const EdgeInsets.all(8),
    child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
  );

  Widget _td(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Text(text, style: w400_14Poppins(), textAlign: TextAlign.center),
  );

  /// Light blue cell for auto-calculated intermediate values
  Widget _tdCalc(String text) => Padding(
    padding: const EdgeInsets.all(5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text, style: w400_14Poppins(), textAlign: TextAlign.center),
    ),
  );

  /// Green cell for the final pull-out strength result
  Widget _tdStrength(String text) => Padding(
    padding: const EdgeInsets.all(5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Text(text, style: w500_18Poppins(), textAlign: TextAlign.center),
    ),
  );
}

// ── Helper widgets ─────────────────────────────────────────────────────────

/// Tile showing a calculated field with its formula label
class _CalcTile extends StatelessWidget {
  final String label;
  final String formula;
  final String value;
  final bool highlight;

  const _CalcTile({
    required this.label,
    required this.formula,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? Colors.green.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: w500_16Poppins(), overflow: TextOverflow.ellipsis),
          height5,
          Text("($formula)", style: w400_14Poppins()),
          height5,
          Text(value, style: highlight ? w600_24Poppins() : w500_20Poppins()),
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
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
