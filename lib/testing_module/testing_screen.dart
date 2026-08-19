import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/provider/testing_provider.dart';
import 'package:sams_engineering_console/testing_module/testing_format_registry.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:sams_engineering_console/utils/module_header.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({
    super.key,
    required this.structureId,
    required this.structureIdentityNumber,
    required this.initialStatus,
    this.assignedFormats = const <TestingFormat>[],
  });

  final String structureId;
  final String structureIdentityNumber;
  final String initialStatus;
  final List<TestingFormat> assignedFormats;

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  late final List<TabletTestingFormatDescriptor> _formats;
  String? _selectedFormatId;

  @override
  void initState() {
    super.initState();
    _setFormats(widget.assignedFormats);
    if (widget.assignedFormats.isEmpty &&
        widget.structureId.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAssignedFormats();
      });
    }
  }

  Future<void> _loadAssignedFormats() async {
    final provider = context.read<TestingProvider>();
    await provider.fetchWorkflow(
      context,
      widget.structureId,
      showLoader: false,
    );
    if (!mounted) return;

    final assignedFormats =
        provider.testingAssignment?.testingFormats ?? const <TestingFormat>[];
    if (assignedFormats.isNotEmpty) {
      setState(() {
        _setFormats(assignedFormats);
      });
    }
  }

  void _setFormats(List<TestingFormat> assignedFormats) {
    _formats = TestingFormatRegistry.resolveFormats(assignedFormats);
    if (_formats.isEmpty) {
      _selectedFormatId = null;
      return;
    }

    final previousSelection = _selectedFormatId;
    final hasPreviousSelection =
        previousSelection != null &&
        _formats.any((format) => format.id == previousSelection);
    _selectedFormatId = hasPreviousSelection
        ? previousSelection
        : _formats.first.id;
  }

  TabletTestingFormatDescriptor? get _selectedFormat {
    if (_formats.isEmpty) return null;
    return _formats.firstWhere(
      (format) => format.id == _selectedFormatId,
      orElse: () => _formats.first,
    );
  }

  Widget _getSelectedScreen() {
    if (_formats.isEmpty) {
      return const _NoFormatsAssignedState();
    }

    final activeFormat = _selectedFormat ?? _formats.first;
    return activeFormat.builder(widget.structureId);
  }

  void _selectFormat(String formatId) {
    setState(() {
      _selectedFormatId = formatId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedFormat = _selectedFormat;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: const ModuleBackArrow(),
        titleSpacing: 2,
        title: const ModuleHeaderTitle(
          title: 'Testing Details',
          subtitle: 'Inspect, input and test structures.',
        ),
      ),
      body: Column(
        children: [
          _TestingHeader(
            structureIdentityNumber: widget.structureIdentityNumber,
            selectedFormatLabel: selectedFormat?.name ?? 'No format selected',
            selector: _GlassFormatSelector(
              formats: _formats,
              selectedFormatId: _selectedFormatId,
              onSelected: _selectFormat,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _getSelectedScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestingHeader extends StatelessWidget {
  const _TestingHeader({
    required this.structureIdentityNumber,
    required this.selectedFormatLabel,
    required this.selector,
  });

  final String structureIdentityNumber;
  final String selectedFormatLabel;
  final Widget selector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Testing Formats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a format and enter the test details for $structureIdentityNumber',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                if (isCompact) ...[
                  _SelectedFormatSummary(
                    selectedFormatLabel: selectedFormatLabel,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: selector),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _SelectedFormatSummary(
                          selectedFormatLabel: selectedFormatLabel,
                        ),
                      ),
                      const SizedBox(width: 16),
                      selector,
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectedFormatSummary extends StatelessWidget {
  const _SelectedFormatSummary({required this.selectedFormatLabel});

  final String selectedFormatLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          selectedFormatLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _GlassFormatSelector extends StatelessWidget {
  const _GlassFormatSelector({
    required this.formats,
    required this.selectedFormatId,
    required this.onSelected,
  });

  final List<TabletTestingFormatDescriptor> formats;
  final String? selectedFormatId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (formats.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedFormat = formats.firstWhere(
      (format) => format.id == selectedFormatId,
      orElse: () => formats.first,
    );

    return PopupMenuButton<String>(
      tooltip: 'Select test format',
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 10),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _GlassFormatDropdownContent(
            formats: formats,
            selectedFormatId: selectedFormatId,
            onSelected: onSelected,
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight =
              constraints.maxWidth > 0 && constraints.maxWidth < 260;

          return Container(
            width: isTight ? double.infinity : null,
            constraints: BoxConstraints(
              minWidth: isTight ? 0 : 210,
              maxWidth: isTight ? constraints.maxWidth : 280,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.80),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xff2563EB),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _readableFormatLabel(selectedFormat.name),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassFormatDropdownContent extends StatelessWidget {
  const _GlassFormatDropdownContent({
    required this.formats,
    required this.selectedFormatId,
    required this.onSelected,
  });

  final List<TabletTestingFormatDescriptor> formats;
  final String? selectedFormatId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 260,
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: formats.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.white.withOpacity(0.45)),
            itemBuilder: (context, index) {
              final format = formats[index];
              final isSelected = format.id == selectedFormatId;

              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(format.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xffDDEBFF).withOpacity(0.70)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _readableFormatLabel(format.name),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: const Color(0xff1F2937),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Color(0xff2563EB),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoFormatsAssignedState extends StatelessWidget {
  const _NoFormatsAssignedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: Text('No testing formats available')),
    );
  }
}

String _readableFormatLabel(String rawLabel) {
  if (rawLabel.trim().isEmpty) return rawLabel;
  final normalized = rawLabel.replaceAll('_', ' ').trim();
  return normalized
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1)}';
      })
      .join(' ');
}
