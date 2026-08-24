import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';

/// Shared metrics for every form field in the add-structure wizard.
///
/// The wizard used to size fields with `MediaQuery.width * 0.35` and wrap them
/// in `SizedBox(height: 40.h)`. On a tablet that produced columns of unrelated
/// widths, labels that did not line up, and clipped validation messages. Fields
/// now take their width from [FormGrid] and their height from their own
/// content, so a row of fields always aligns.
class FormKit {
  const FormKit._();

  static const double radius = 10;
  static const double labelGap = 6;
  static const double rowGap = 16;
  static const double columnGap = 12;

  static const Color borderColor = Color(0xffCBD5E1);
  static const Color labelColor = Color(0xff334155);
  static const Color hintColor = Color(0xff94A3B8);

  static Color get fillColor => Appcolors.textformFillColor;

  static const EdgeInsets fieldPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 13);

  static TextStyle get labelStyle => w600_13Poppins(color: labelColor);
  static TextStyle get valueStyle => w500_14Poppins(color: const Color(0xff0F172A));
  static TextStyle get hintStyle => w400_14Poppins(color: hintColor);

  static OutlineInputBorder border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color ?? borderColor),
      );
}

/// A label sitting above its field, with the gap fixed app-wide so labels in
/// neighbouring columns share a baseline.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.trailing,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: label,
                  style: FormKit.labelStyle,
                  children: [
                    if (isRequired)
                      TextSpan(
                        text: ' *',
                        style: FormKit.labelStyle
                            .copyWith(color: const Color(0xffDC2626)),
                      ),
                  ],
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: FormKit.labelGap),
        child,
      ],
    );
  }
}

/// Lays [children] out in equal-width columns that wrap onto the next line when
/// they don't fit, so a row of fields keeps its alignment at any window width.
///
/// [columns] is the count wanted at a comfortable width; narrow screens fall
/// back to fewer columns automatically so a field is never squeezed below
/// [minItemWidth].
class FormGrid extends StatelessWidget {
  const FormGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.minItemWidth = 220,
    this.spacing = FormKit.columnGap,
    this.runSpacing = FormKit.rowGap,
  });

  final List<Widget> children;
  final int columns;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Drop columns until each one clears minItemWidth.
        var cols = columns.clamp(1, children.length);
        while (cols > 1 &&
            (maxWidth - spacing * (cols - 1)) / cols < minItemWidth) {
          cols--;
        }

        final itemWidth = cols == 1
            ? maxWidth
            : (maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// A text field carrying the wizard's shared decoration. Deliberately has no
/// fixed height — the field grows to fit its validation message instead of
/// clipping it.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final Function? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return CommonTextFormField(
      inputFormatters: inputFormatters,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      validator: validator,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      fillColor: FormKit.fillColor,
      borderColor: FormKit.borderColor,
      style: FormKit.valueStyle,
      hintStyle: FormKit.hintStyle,
      labelStyle: FormKit.labelStyle,
      padding: FormKit.fieldPadding,
      errorMaxLines: 2,
    );
  }
}

/// A number field with the stepper affordance the wizard already used, but with
/// hit targets big enough to tap and a floor of zero.
class FormStepperField extends StatelessWidget {
  const FormStepperField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.validator,
    this.minValue = 0,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? hintText;
  final Function? validator;
  final int minValue;

  void _step(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < minValue) return;
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      controller: controller,
      hintText: hintText,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
          _StepButton(icon: Icons.add_rounded, onTap: () => _step(1)),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FormKit.borderColor),
        ),
        child: Icon(icon, size: 16, color: Appcolors.buttonColor),
      ),
    );
  }
}

/// A titled white card — the wizard's standard section container.
class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.children,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Widget> children;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(title!, style: w600_16Poppins(color: FormKit.labelColor)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// The +/- affordance used inside quantification fields. Accepts decimals, and
/// keeps whole numbers whole.
class NumberStepperSuffix extends StatelessWidget {
  const NumberStepperSuffix({super.key, required this.controller});

  final TextEditingController controller;

  void _step(double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    controller.text =
        next % 1 == 0 ? next.toInt().toString() : next.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
        _StepButton(icon: Icons.add_rounded, onTap: () => _step(1)),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// A labelled attachment button with a count badge — replaces the bare icon
/// buttons that sat unlabelled at the end of a cramped rating row.
class AttachmentButton extends StatelessWidget {
  const AttachmentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.badgeColor = Colors.green,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FormKit.radius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(FormKit.radius),
            border: Border.all(color: FormKit.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: Appcolors.buttonColor),
              const SizedBox(width: 7),
              Text(label, style: w600_13Poppins(color: FormKit.labelColor)),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: w700_10Poppins(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
