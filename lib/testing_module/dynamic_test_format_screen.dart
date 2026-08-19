import 'package:flutter/material.dart';
import 'package:sams_engineering_console/models/testing_workflow_model.dart';
import 'package:sams_engineering_console/testing_module/evidence_section.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/module_header.dart';

class DynamicTestFormatScreen extends StatefulWidget {
  const DynamicTestFormatScreen({super.key, required this.format});

  final TestingFormat format;

  @override
  State<DynamicTestFormatScreen> createState() =>
      _DynamicTestFormatScreenState();
}

class _DynamicTestFormatScreenState extends State<DynamicTestFormatScreen> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, String> _selectedOptions = <String, String>{};

  @override
  void initState() {
    super.initState();
    for (final field in widget.format.fields) {
      if (_usesTextController(field.type)) {
        _controllers[field.key] = TextEditingController();
      } else if (field.options.isNotEmpty) {
        _selectedOptions[field.key] = field.options.first;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.format.fields;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: const ModuleBackArrow(),
        titleSpacing: 2,
        title: ModuleHeaderTitle(
          title: widget.format.name,
          subtitle: 'Inspect, input and test structures.',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Custom Test Format', style: w600_18Poppins()),
                    const SizedBox(height: 8),
                    Text(
                      fields.isEmpty
                          ? 'This format has been assigned, but no dynamic field schema was returned by the API yet.'
                          : 'Fill the assigned custom test fields below. This screen is schema-driven so new formats can be added without changing the tablet layout.',
                      style: w400_14Poppins(color: Colors.grey.shade700),
                    ),
                    if (widget.format.layout.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Layout: ${widget.format.layout}',
                        style: w400_14Poppins(color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (fields.isEmpty)
              _EmptyDynamicState(formatName: widget.format.name)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: fields
                        .map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildField(field),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const EvidenceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TestingDynamicField field) {
    final label = field.required ? '${field.label} *' : field.label;
    final type = field.type.toLowerCase();

    if (type == 'select' && field.options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _selectedOptions[field.key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: field.options
            .map(
              (option) =>
                  DropdownMenuItem<String>(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: field.readOnly
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _selectedOptions[field.key] = value;
                });
              },
      );
    }

    return TextFormField(
      controller: _controllers[field.key],
      readOnly: field.readOnly,
      keyboardType: _keyboardTypeFor(type),
      maxLines: type == 'textarea' ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  bool _usesTextController(String type) {
    return type.toLowerCase() != 'select';
  }

  TextInputType? _keyboardTypeFor(String type) {
    switch (type) {
      case 'number':
        return const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        );
      case 'date':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }
}

class _EmptyDynamicState extends StatelessWidget {
  const _EmptyDynamicState({required this.formatName});

  final String formatName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatName, style: w600_18Poppins()),
            const SizedBox(height: 8),
            Text(
              'Ask the backend/admin format configuration to return `fields` for this custom format so the tablet can render it dynamically.',
              style: w400_14Poppins(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
