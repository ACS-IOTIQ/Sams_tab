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

class _LocationEntry {
  final TextEditingController locationController;
  final TextEditingController
  strengthController; // Equivalent Cube Compressive Strength N/mm²
  final TextEditingController remarksController;
  bool isExpanded;

  _LocationEntry()
    : locationController = TextEditingController(),
      strengthController = TextEditingController(),
      remarksController = TextEditingController(),
      isExpanded = true;

  void dispose() {
    locationController.dispose();
    strengthController.dispose();
    remarksController.dispose();
  }
}

class CoreCuttingScreen extends StatefulWidget {
  const CoreCuttingScreen({super.key, this.structureId = ''});

  final String structureId;

  @override
  State<CoreCuttingScreen> createState() => _CoreCuttingScreenState();
}

class _CoreCuttingScreenState extends State<CoreCuttingScreen> {
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
        'core_cutting',
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
      entry.strengthController.text =
          (map['equivalent_cube_compressive_strength_mpa'] ?? '').toString();
      entry.remarksController.text = (map['remarks'] ?? '').toString();
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
      final strength = double.tryParse(entry.strengthController.text) ?? 0;
      return <String, dynamic>{
        'location': entry.locationController.text.trim(),
        'equivalent_cube_compressive_strength_mpa': strength,
        'remarks': entry.remarksController.text.trim(),
      };
    }).toList();

    final strengths = mappedEntries
        .map(
          (entry) =>
              (entry['equivalent_cube_compressive_strength_mpa'] as num?)
                  ?.toDouble() ??
              0,
        )
        .where((value) => value > 0)
        .toList();

    return <String, dynamic>{
      'test_name': 'core_cutting',
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
        'core_diameter_mm': null,
        'core_length_mm': null,
        'compressive_strength_mpa': strengths.isNotEmpty
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
          title: 'Core Cutting Test',
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
                onChanged: () => setState(() {}),
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
                    'core_cutting',
                  );
                  return TestingPrimaryActionButton(
                    label: 'Save Core Cutting Result',
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
                  // Collapsed chip showing strength value
                  if (!entry.isExpanded &&
                      entry.strengthController.text.isNotEmpty) ...[
                    _Chip(
                      label: "Strength",
                      value: "${entry.strengthController.text} N/mm²",
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

                  // Equivalent Cube Compressive Strength
                  _buildTextField(
                    context,
                    label: "Equivalent Cube Compressive Strength (N/mm²)",
                    controller: entry.strengthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    width: MediaQuery.of(context).size.width * 0.45,
                    onChanged: (_) => onChanged(),
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
// Columns: S.No(60) + Location(280) + Strength(260) + Remarks(220) = 820

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
                width: 820,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(280),
                    2: FixedColumnWidth(260),
                    3: FixedColumnWidth(220),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        _th("S.No"),
                        _th("Location"),
                        _th("Equivalent Cube\nCompressive Strength\n(N/mm²)"),
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
                          _tdStrength(
                            e.strengthController.text.isNotEmpty
                                ? e.strengthController.text
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

  /// Highlighted cell for the compressive strength value
  Widget _tdStrength(String text) => Padding(
    padding: const EdgeInsets.all(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: text == "—" ? Colors.transparent : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: text == "—" ? null : Border.all(color: Colors.green.shade300),
      ),
      child: Text(
        text == "—" ? text : "$text N/mm²",
        style: w500_18Poppins(),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ── Helper widgets ─────────────────────────────────────────────────────────

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
