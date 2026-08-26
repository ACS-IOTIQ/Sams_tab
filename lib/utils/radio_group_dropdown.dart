import 'package:flutter/material.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';
import 'package:sams_engineering_console/utils/wizard_scaffold.dart';

/// One choice in a [RadioGroupDropdown].
class RadioOption<T> {
  const RadioOption(this.value, this.label, {this.subtitle});

  final T value;
  final String label;
  final String? subtitle;
}

/// A picker that looks like a text field but opens a radio group in a bottom
/// sheet instead of an overlay menu.
///
/// `DropdownButtonFormField` anchors its menu to the field, which on a tablet
/// meant a cramped popup that jumped around and scrolled badly for long lists
/// (states, floor types). A sheet gives every option a full-width row and a
/// real hit target, and lists longer than [searchThreshold] get a filter box.
class RadioGroupDropdown<T> extends FormField<T> {
  RadioGroupDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.sheetTitle,
    super.enabled = true,
    this.showClear = false,
    this.searchThreshold = 12,
    this.useAlertDialog = false,
    super.validator,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> field) {
            final self = field.widget as RadioGroupDropdown<T>;
            final context = field.context;
            final current = field.value;
            final hasError = field.errorText != null;

            String? selectedLabel;
            for (final option in self.options) {
              if (option.value == current) {
                selectedLabel = option.label;
                break;
              }
            }

            Future<void> open() async {
              if (!self.enabled) return;
              FocusScope.of(context).unfocus();

              final sheet = _RadioSheet<T>(
                title: self.sheetTitle ?? self.hintText ?? 'Select an option',
                options: self.options,
                value: current,
                showClear: self.showClear,
                showSearch: self.options.length >= self.searchThreshold,
              );
              final result = self.useAlertDialog
                  ? await showDialog<_SheetResult<T>>(
                      context: context,
                      builder: (dialogContext) {
                        final size = MediaQuery.sizeOf(dialogContext);
                        return AlertDialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          content: SizedBox(
                            width: size.width > 568 ? 520 : size.width - 48,
                            height: self._dialogHeight(size),
                            child: sheet,
                          ),
                        );
                      },
                    )
                  : await showModalBottomSheet<_SheetResult<T>>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => sheet,
                    );

              if (result == null) return;
              field.didChange(result.value);
              self.onChanged(result.value);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: self.enabled ? open : null,
                    borderRadius: BorderRadius.circular(FormKit.radius),
                    child: Container(
                      padding: FormKit.fieldPadding,
                      decoration: BoxDecoration(
                        color: self.enabled
                            ? FormKit.fillColor
                            : FormKit.fillColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(FormKit.radius),
                        border: Border.all(
                          color: hasError
                              ? const Color(0xffDC2626)
                              : FormKit.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedLabel ?? self.hintText ?? 'Select',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: selectedLabel == null
                                  ? FormKit.hintStyle
                                  : FormKit.valueStyle,
                            ),
                          ),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: self.enabled
                                ? Appcolors.buttonColor
                                : FormKit.hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(
                      field.errorText!,
                      style: w500_12Poppins(color: const Color(0xffDC2626)),
                    ),
                  ),
              ],
            );
          },
        );

  final List<RadioOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final String? sheetTitle;
  final bool showClear;
  final int searchThreshold;
  final bool useAlertDialog;

  double _dialogHeight(Size size) {
    final desired =
        140.0 + (options.length * 52.0) +
        (options.length >= searchThreshold ? 56.0 : 0.0);
    final maximum = size.height * 0.72;
    return desired > maximum ? maximum : desired;
  }

  @override
  FormFieldState<T> createState() => _RadioGroupDropdownState<T>();
}

/// Keeps the field's value in step with the `value` the parent passes down —
/// the same job `DropdownButtonFormField` does, and the reason these pickers
/// stay correct when a screen repopulates its form from the API.
class _RadioGroupDropdownState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(RadioGroupDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final self = widget as RadioGroupDropdown<T>;
    if (self.value != oldWidget.value && self.value != value) {
      setValue(self.value);
    }
  }
}

class _SheetResult<T> {
  const _SheetResult(this.value);
  final T? value;
}

class _RadioSheet<T> extends StatefulWidget {
  const _RadioSheet({
    required this.title,
    required this.options,
    required this.value,
    required this.showClear,
    required this.showSearch,
  });

  final String title;
  final List<RadioOption<T>> options;
  final T? value;
  final bool showClear;
  final bool showSearch;

  @override
  State<_RadioSheet<T>> createState() => _RadioSheetState<T>();
}

class _RadioSheetState<T> extends State<_RadioSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RadioOption<T>> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            o.label.toLowerCase().contains(q) ||
            (o.subtitle ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final visible = _visible;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: media.size.height * 0.72,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: w600_16Poppins(color: const Color(0xff0F172A)),
                      ),
                    ),
                    if (widget.showClear && widget.value != null)
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop(_SheetResult<T>(null)),
                        child: Text(
                          'Clear',
                          style: w600_13Poppins(color: Appcolors.buttonColor),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: FormKit.hintColor,
                    ),
                  ],
                ),
              ),
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    style: FormKit.valueStyle,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FormKit.fillColor,
                      hintText: 'Search',
                      hintStyle: FormKit.hintStyle,
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: FormKit.hintColor),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: FormKit.border(),
                      enabledBorder: FormKit.border(),
                      focusedBorder: FormKit.border(Appcolors.buttonColor),
                    ),
                  ),
                ),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No matches',
                          style: w500_14Poppins(color: FormKit.hintColor),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Color(0xffF1F5F9),
                        ),
                        itemBuilder: (context, i) {
                          final option = visible[i];
                          final isSelected = option.value == widget.value;
                          return RadioListTile<T>(
                            value: option.value,
                            groupValue: widget.value,
                            onChanged: (v) => Navigator.of(context)
                                .pop(_SheetResult<T>(v)),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: Appcolors.buttonColor,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(
                              option.label,
                              style: isSelected
                                  ? w600_14Poppins(color: Appcolors.buttonColor)
                                  : FormKit.valueStyle,
                            ),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(
                                    option.subtitle!,
                                    style: w400_12Poppins(
                                        color: FormKit.hintColor),
                                  ),
                          );
                        },
                      ),
              ),
              SizedBox(height: media.padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience for the common `List<String>` case.
List<RadioOption<String>> radioOptionsFromStrings(
  List<String> values, {
  String Function(String)? labelBuilder,
}) {
  return values
      .map((v) => RadioOption<String>(v, labelBuilder?.call(v) ?? v))
      .toList();
}

/// Turns `only_commercial` into `Only commercial` for display.
String prettifyOptionLabel(String raw) {
  final cleaned = raw.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return raw;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

// ─── Multi-select variant ──────────────────────────────────────────────────

/// The multi-select sibling of [RadioGroupDropdown]: same trigger, but the
/// sheet holds checkboxes and an Apply action, since a multi-select can't
/// close on the first tap.
///
/// [exclusiveValues] names options that stand alone — picking one clears the
/// rest, and picking anything else clears it. That is how a "None" option
/// behaves without every caller re-implementing the rule.
class CheckboxGroupDropdown<T> extends StatelessWidget {
  const CheckboxGroupDropdown({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.hintText,
    this.sheetTitle,
    this.exclusiveValues = const [],
    this.enabled = true,
    this.searchThreshold = 12,
    this.errorText,
    this.useAlertDialog = false,
  });

  final List<RadioOption<T>> options;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String? hintText;
  final String? sheetTitle;
  final List<T> exclusiveValues;
  final bool enabled;
  final int searchThreshold;
  final String? errorText;
  final bool useAlertDialog;

  double _dialogHeight(Size size) {
    // A fixed 72% height left a large blank area under short distress lists.
    final desired =
        150.0 + (options.length * 52.0) +
        (options.length >= searchThreshold ? 56.0 : 0.0);
    final maximum = size.height * 0.72;
    return desired > maximum ? maximum : desired;
  }

  String? get _summary {
    if (values.isEmpty) return null;
    final labels = <String>[];
    for (final value in values) {
      for (final option in options) {
        if (option.value == value) {
          labels.add(option.label);
          break;
        }
      }
    }
    return labels.isEmpty ? null : labels.join(', ');
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    FocusScope.of(context).unfocus();

    final sheet = _CheckboxSheet<T>(
      title: sheetTitle ?? hintText ?? 'Select options',
      options: options,
      values: values,
      exclusiveValues: exclusiveValues,
      showSearch: options.length >= searchThreshold,
      asDialog: useAlertDialog,
    );
    final result = useAlertDialog
        ? await showDialog<List<T>>(
            context: context,
            builder: (dialogContext) {
              final size = MediaQuery.sizeOf(dialogContext);
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: SizedBox(
                  width: size.width > 568 ? 520 : size.width - 48,
                  height: _dialogHeight(size),
                  child: sheet,
                ),
              );
            },
          )
        : await showModalBottomSheet<List<T>>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => sheet,
          );

    if (result == null) return;
    onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _open(context) : null,
            borderRadius: BorderRadius.circular(FormKit.radius),
            child: Container(
              padding: FormKit.fieldPadding,
              decoration: BoxDecoration(
                color: enabled
                    ? FormKit.fillColor
                    : FormKit.fillColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(FormKit.radius),
                border: Border.all(
                  color:
                      hasError ? const Color(0xffDC2626) : FormKit.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary ?? hintText ?? 'Select',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: summary == null
                          ? FormKit.hintStyle
                          : FormKit.valueStyle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (values.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Appcolors.buttonColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        values.length.toString(),
                        style: w700_10Poppins(color: Colors.white),
                      ),
                    ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: enabled ? Appcolors.buttonColor : FormKit.hintColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              errorText!,
              style: w500_12Poppins(color: const Color(0xffDC2626)),
            ),
          ),
      ],
    );
  }
}

class _CheckboxSheet<T> extends StatefulWidget {
  const _CheckboxSheet({
    required this.title,
    required this.options,
    required this.values,
    required this.exclusiveValues,
    required this.showSearch,
    this.asDialog = false,
  });

  final String title;
  final List<RadioOption<T>> options;
  final List<T> values;
  final List<T> exclusiveValues;
  final bool showSearch;
  final bool asDialog;

  @override
  State<_CheckboxSheet<T>> createState() => _CheckboxSheetState<T>();
}

class _CheckboxSheetState<T> extends State<_CheckboxSheet<T>> {
  late final Set<T> _selected = {...widget.values};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RadioOption<T>> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(T value, bool isOn) {
    setState(() {
      if (widget.exclusiveValues.contains(value)) {
        _selected.clear();
        if (isOn) _selected.add(value);
        return;
      }
      _selected.removeWhere(widget.exclusiveValues.contains);
      if (isOn) {
        _selected.add(value);
      } else {
        _selected.remove(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final visible = _visible;

    final content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: media.size.height * 0.45,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: widget.asDialog
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.asDialog) ...[
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffD0D5DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: w600_16Poppins(color: const Color(0xff0F172A)),
                      ),
                    ),
                    if (_selected.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(_selected.clear),
                        child: Text(
                          'Clear',
                          style: w600_13Poppins(color: Appcolors.buttonColor),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: FormKit.hintColor,
                    ),
                  ],
                ),
              ),
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: TextField(   
                    controller: _searchController,
                    style: FormKit.valueStyle,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FormKit.fillColor,
                      hintText: 'Search',
                      hintStyle: FormKit.hintStyle,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: FormKit.hintColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: FormKit.border(),
                      enabledBorder: FormKit.border(),
                      focusedBorder: FormKit.border(Appcolors.buttonColor),
                    ),
                  ),
                ),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No matches',
                          style: w500_14Poppins(color: FormKit.hintColor),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Color(0xffF1F5F9),
                        ),
                        itemBuilder: (context, i) {
                          final option = visible[i];
                          final isSelected = _selected.contains(option.value);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) => _toggle(option.value, v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: Appcolors.buttonColor,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(
                              option.label,
                              style: isSelected
                                  ? w600_14Poppins(color: Appcolors.buttonColor)
                                  : FormKit.valueStyle,
                            ),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(
                                    option.subtitle!,
                                    style: w400_12Poppins(
                                      color: FormKit.hintColor,
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1, color: Color(0xffF1F5F9)),
              Padding(   
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  media.padding.bottom + 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected.isEmpty
                            ? 'Nothing selected'
                            : '${_selected.length} selected',
                        style: w500_13Poppins(color: FormKit.hintColor),
                      ),
                    ),
                    WizardNextButton(
                      label: 'Apply',
                      onTap: () => Navigator.of(context).pop(_selected.toList()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

    return widget.asDialog
        ? content
        : Align(alignment: Alignment.bottomCenter, child: content);
  }
}
