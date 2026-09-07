import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/quantification_model.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/provider/quantification_provider.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';

class QuantificationScreen extends StatefulWidget {
  final String structureId;
  final String? floorId;
  final String? flatId;

  const QuantificationScreen({
    super.key,
    required this.structureId,
    this.floorId,
    this.flatId,
  });

  @override
  State<QuantificationScreen> createState() => _QuantificationScreenState();
}

class _QuantificationScreenState extends State<QuantificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final List<QuantificationRow> _structuralRows = [];
  final List<QuantificationRow> _nonStructuralRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuantifications();
  }

  @override
  void dispose() {
    for (final row in _structuralRows) {
      row.dispose();
    }
    for (final row in _nonStructuralRows) {
      row.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuantifications() async {
    setState(() => _isLoading = true);

    final quantProvider = Provider.of<QuantificationProvider>(
      context,
      listen: false,
    );
    bool loaded = false;

    if (widget.flatId != null) {
      loaded = await quantProvider.loadForFlat(
        structureId: widget.structureId,
        floorId: widget.floorId ?? '',
        flatId: widget.flatId!,
        context: context,
      );
    } else if (widget.floorId != null) {
      loaded = await quantProvider.loadForFloor(
        structureId: widget.structureId,
        floorId: widget.floorId!,
        context: context,
      );
    }

    if (loaded &&
        (quantProvider.structural.isNotEmpty ||
            quantProvider.nonStructural.isNotEmpty)) {
      _structuralRows
        ..clear()
        ..addAll(quantProvider.structural.map(QuantificationRow.fromEntry));
      _nonStructuralRows
        ..clear()
        ..addAll(quantProvider.nonStructural.map(QuantificationRow.fromEntry));
    } else {
      await _prefillFromRatings();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _prefillFromRatings() async {
    final ratingsProvider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );
    final getProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );

    // If ratings are empty, try fetching from API for this floor/flat.
    if (ratingsProvider.structuralRatingMap.isEmpty &&
        ratingsProvider.nonStructuralRatingMap.isEmpty &&
        widget.floorId != null) {
      try {
        if (widget.flatId != null) {
          final data = await getProvider.getAllRatingsForFlat(
            structureId: widget.structureId,
            floorId: widget.floorId!,
            flatId: widget.flatId!,
            context: context,
          );
          ratingsProvider.populateStructuralRatingsFromFlat(
            data.data.structuralRating,
          );
          ratingsProvider.populateNonStructuralRatingsFromFlat(
            data.data.nonStructuralRating,
          );
        } else {
          final data = await getProvider.getAllRatingsForFloor(
            structureId: widget.structureId,
            floorId: widget.floorId!,
            flatId: '',
            context: context,
          );
          ratingsProvider.populateStructuralRatingsFromFloor(
            data.data.structuralRating,
          );
          final nonStructural = data.data.nonStructuralRating;
          if (nonStructural != null) {
            ratingsProvider.populateNonStructuralRatingsFromFloor(
              nonStructural,
            );
          }
        }
      } catch (_) {
        // If fetch fails, we still allow manual entry.
      }
    }

    _structuralRows
      ..clear()
      ..addAll(
        _buildRowsFromRatings(
          ratingsProvider.structuralRatingMap,
          isStructural: true,
        ),
      );

    _nonStructuralRows
      ..clear()
      ..addAll(
        _buildRowsFromRatings(
          ratingsProvider.nonStructuralRatingMap,
          isStructural: false,
        ),
      );
  }

  List<QuantificationRow> _buildRowsFromRatings(
    Map<String, List<RatingItem>> source, {
    required bool isStructural,
  }) {
    final rows = <QuantificationRow>[];

    source.forEach((type, items) {
      for (final item in items) {
        final hasData =
            (item.comment ?? '').trim().isNotEmpty ||
            item.lengthController.text.trim().isNotEmpty ||
            item.widthController.text.trim().isNotEmpty ||
            item.heightController.text.trim().isNotEmpty ||
            (item.repairMethodology ?? '').trim().isNotEmpty ||
            item.repairMethodologyController.text.trim().isNotEmpty;

        if (!hasData) continue;

        final category = _categoryForType(type, isStructural: isStructural);
        final locationText = (item.comment ?? '').trim().isNotEmpty
            ? item.comment!
            : (item.name ?? type);

        rows.add(
          QuantificationRow(
            id: _randomId(),
            category: category,
            locationOfDistress: locationText,
            nos: '',
            length: item.lengthController.text,
            breadth: item.widthController.text,
            height: item.heightController.text,
            repairMethodology: (item.repairMethodology ?? '').trim().isNotEmpty
                ? item.repairMethodology!
                : item.repairMethodologyController.text,
          ),
        );
      }
    });

    return rows;
  }

  String _categoryForType(String type, {required bool isStructural}) {
    final key = type.toLowerCase().replaceAll('_', ' ').trim();
    if (!isStructural) {
      return _titleCase(key);
    }

    switch (key) {
      case 'foundation':
        return 'FOOTINGS';
      case 'columns':
        return 'COLUMNS';
      case 'beams':
        return 'BEAMS';
      case 'slab':
        return 'SLAB';
      case 'roof truss':
        return 'ROOF TRUSS';
      case 'connections':
        return 'CONNECTIONS';
      case 'bracings':
        return 'BRACINGS';
      case 'purlins':
        return 'PURLINS';
      case 'channels':
        return 'CHANNELS';
      default:
        return _titleCase(key);
    }
  }

  String _titleCase(String input) {
    return input
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _randomId() =>
      'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  double _toDouble(String value) => double.tryParse(value) ?? 0;

  double? _computeQuantity(QuantificationRow row) {
    if ([
      row.nosController,
      row.lengthController,
      row.breadthController,
      row.heightController,
    ].every((controller) => controller.text.trim().isEmpty)) {
      return null;
    }
    final nosText = row.nosController.text.trim();
    final nos = nosText.isEmpty ? 1.0 : _toDouble(nosText);
    final length = _toDouble(row.lengthController.text);
    final breadth = _toDouble(row.breadthController.text);
    final height = _toDouble(row.heightController.text);

    final hasDim = length > 0 || breadth > 0 || height > 0;
    final dimMultiplier =
        (length > 0 ? length : 1) *
        (breadth > 0 ? breadth : 1) *
        (height > 0 ? height : 1);

    return hasDim ? (nos * dimMultiplier) : nos;
  }

  String _computeUnit(QuantificationRow row) {
    if (_computeQuantity(row) == null) return '';
    final length = _toDouble(row.lengthController.text);
    final breadth = _toDouble(row.breadthController.text);
    final height = _toDouble(row.heightController.text);
    if (height > 0) return 'CUM';
    if (breadth > 0) return 'SQM';
    if (length > 0) return 'RM';
    return "NO'S";
  }

  Future<void> _saveQuantifications() async {
    final quantProvider = Provider.of<QuantificationProvider>(
      context,
      listen: false,
    );

    final structuralEntries = _structuralRows.map((row) {
      final quantity = _computeQuantity(row);
      final unit = _computeUnit(row);
      return row.toEntry(quantity: quantity, unit: unit);
    }).toList();

    final nonStructuralEntries = _nonStructuralRows.map((row) {
      final quantity = _computeQuantity(row);
      final unit = _computeUnit(row);
      return row.toEntry(quantity: quantity, unit: unit);
    }).toList();

    if (widget.flatId != null) {
      await quantProvider.saveForFlat(
        structureId: widget.structureId,
        floorId: widget.floorId ?? '',
        flatId: widget.flatId!,
        context: context,
        structuralEntries: structuralEntries,
        nonStructuralEntries: nonStructuralEntries,
      );
    } else if (widget.floorId != null) {
      await quantProvider.saveForFloor(
        structureId: widget.structureId,
        floorId: widget.floorId!,
        context: context,
        structuralEntries: structuralEntries,
        nonStructuralEntries: nonStructuralEntries,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            labelStyle: w600_14Poppins(color: Colors.black87),
            unselectedLabelStyle: w400_14Poppins(color: Colors.black54),
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            tabs: const [
              Tab(text: 'Structural'),
              Tab(text: 'Non-Structural'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQuantificationSection(
                _structuralRows,
                title: 'Structural Observations',
              ),
              _buildQuantificationSection(
                _nonStructuralRows,
                title: 'Non-Structural Observations',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveQuantifications,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Save Quantifications', style: w500_16Poppins()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantificationSection(
    List<QuantificationRow> rows, {
    required String title,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: w600_16Poppins()),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => setState(
                  () => rows.add(QuantificationRow.empty(_randomId())),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Row'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuantificationTable(rows),
          const SizedBox(height: 16),
          _buildBoqSummary(rows),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuantificationTable(List<QuantificationRow> rows) {
    final headerStyle = w600_12Poppins();
    final cellPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FixedColumnWidth(260),
          2: FixedColumnWidth(70),
          3: FixedColumnWidth(70),
          4: FixedColumnWidth(70),
          5: FixedColumnWidth(70),
          6: FixedColumnWidth(90),
          7: FixedColumnWidth(200),
          8: FixedColumnWidth(60),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              _headerCell('Category', headerStyle, cellPadding),
              _headerCell('Location of Distress', headerStyle, cellPadding),
              _headerCell('Nos', headerStyle, cellPadding),
              _headerCell('L (m)', headerStyle, cellPadding),
              _headerCell('B (m)', headerStyle, cellPadding),
              _headerCell('H (m)', headerStyle, cellPadding),
              _headerCell('Qty', headerStyle, cellPadding),
              _headerCell('Repair Methodology', headerStyle, cellPadding),
              _headerCell('', headerStyle, cellPadding),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final quantity = _computeQuantity(row);
            final unit = _computeUnit(row);

            return TableRow(
              children: [
                _textCell(
                  row.categoryController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                _textCell(
                  row.locationController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                _numberCell(
                  row.nosController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                _numberCell(
                  row.lengthController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                _numberCell(
                  row.breadthController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                _numberCell(
                  row.heightController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: cellPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quantity?.toStringAsFixed(2) ?? '\u2014',
                        style: w500_12Poppins(),
                      ),
                      Text(
                        unit.isEmpty ? '\u2014' : unit,
                        style: w400_10Poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _textCell(
                  row.repairController,
                  cellPadding,
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: cellPadding,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () {
                      setState(() {
                        rows.removeAt(index).dispose();
                      });
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBoqSummary(List<QuantificationRow> rows) {
    final summary = _calculateSummary(rows);
    if (summary.isEmpty) {
      return Text(
        'BoQ Summary will appear here.',
        style: w400_12Poppins(color: Colors.grey.shade600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill of Quantities Summary', style: w600_16Poppins()),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('S.No', style: w600_12Poppins())),
              DataColumn(label: Text('Description', style: w600_12Poppins())),
              DataColumn(label: Text('Quantity', style: w600_12Poppins())),
              DataColumn(label: Text('Units', style: w600_12Poppins())),
            ],
            rows: summary.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('${idx + 1}', style: w400_12Poppins())),
                  DataCell(Text(row.description, style: w400_12Poppins())),
                  DataCell(
                    Text(
                      row.quantity.toStringAsFixed(2),
                      style: w400_12Poppins(),
                    ),
                  ),
                  DataCell(Text(row.unit, style: w400_12Poppins())),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<BoqSummaryRow> _calculateSummary(List<QuantificationRow> rows) {
    final Map<String, BoqSummaryRow> summary = {};

    for (final row in rows) {
      final method = row.repairController.text.trim();
      if (method.isEmpty) continue;

      final baseQty = _computeQuantity(row);
      if (baseQty == null) continue;
      final methodKey = method.toLowerCase();
      double qty = baseQty;
      String unit = _computeUnit(row);

      if (methodKey.contains('epoxy grouting')) {
        qty = baseQty * 8;
        unit = 'KGS';
      } else if (methodKey.contains('cement grouting')) {
        qty = baseQty * 8;
        unit = 'KGS';
      }

      if (summary.containsKey(methodKey)) {
        summary[methodKey] = summary[methodKey]!.copyWith(
          quantity: summary[methodKey]!.quantity + qty,
        );
      } else {
        summary[methodKey] = BoqSummaryRow(
          description: method,
          quantity: qty,
          unit: unit,
        );
      }
    }

    return summary.values.toList();
  }

  Widget _headerCell(String text, TextStyle style, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Text(text, style: style),
    );
  }

  Widget _textCell(
    TextEditingController controller,
    EdgeInsets padding, {
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: padding,
      child: CommonTextFormField(
        controller: controller,
        fillColor: Appcolors.textformFillColor,
        borderColor: Colors.grey.shade300,
        hintText: '\u2014',
        hintStyle: w400_12Poppins(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberCell(
    TextEditingController controller,
    EdgeInsets padding, {
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: padding,
      child: CommonTextFormField(
        controller: controller,
        fillColor: Appcolors.textformFillColor,
        borderColor: Colors.grey.shade300,
        hintText: '\u2014',
        hintStyle: w400_12Poppins(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: onChanged,
      ),
    );
  }
}

class QuantificationRow {
  final String id;
  final TextEditingController categoryController;
  final TextEditingController locationController;
  final TextEditingController nosController;
  final TextEditingController lengthController;
  final TextEditingController breadthController;
  final TextEditingController heightController;
  final TextEditingController repairController;

  QuantificationRow({
    required this.id,
    required String category,
    required String locationOfDistress,
    required String nos,
    required String length,
    required String breadth,
    required String height,
    required String repairMethodology,
  }) : categoryController = TextEditingController(text: category),
       locationController = TextEditingController(text: locationOfDistress),
       nosController = TextEditingController(text: nos),
       lengthController = TextEditingController(text: length),
       breadthController = TextEditingController(text: breadth),
       heightController = TextEditingController(text: height),
       repairController = TextEditingController(text: repairMethodology);

  factory QuantificationRow.empty(String id) => QuantificationRow(
    id: id,
    category: '',
    locationOfDistress: '',
    nos: '',
    length: '',
    breadth: '',
    height: '',
    repairMethodology: '',
  );

  factory QuantificationRow.fromEntry(QuantificationEntry entry) =>
      QuantificationRow(
        id: entry.entryId.isNotEmpty
            ? entry.entryId
            : 'q_${DateTime.now().millisecondsSinceEpoch}',
        category: entry.category,
        locationOfDistress: entry.locationOfDistress,
        nos: entry.nos?.toString() ?? '',
        length: entry.length?.toString() ?? '',
        breadth: entry.breadth?.toString() ?? '',
        height: entry.height?.toString() ?? '',
        repairMethodology: entry.repairMethodology,
      );

  QuantificationEntry toEntry({
    required double? quantity,
    required String unit,
  }) {
    double? parseMeasurement(String value) => double.tryParse(value.trim());
    return QuantificationEntry(
      entryId: id,
      category: categoryController.text.trim(),
      locationOfDistress: locationController.text.trim(),
      nos: parseMeasurement(nosController.text),
      length: parseMeasurement(lengthController.text),
      breadth: parseMeasurement(breadthController.text),
      height: parseMeasurement(heightController.text),
      quantity: quantity,
      unit: unit,
      repairMethodology: repairController.text.trim(),
    );
  }

  void dispose() {
    categoryController.dispose();
    locationController.dispose();
    nosController.dispose();
    lengthController.dispose();
    breadthController.dispose();
    heightController.dispose();
    repairController.dispose();
  }
}

class BoqSummaryRow {
  final String description;
  final double quantity;
  final String unit;

  BoqSummaryRow({
    required this.description,
    required this.quantity,
    required this.unit,
  });

  BoqSummaryRow copyWith({double? quantity, String? unit}) {
    return BoqSummaryRow(
      description: description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}
