// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';

class CommonTextFormField extends StatelessWidget {
  const CommonTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.labelStyle,
    this.suffixIcon,
    this.fillColor,
    this.prefixIcon,
    this.obscureText = false,
    this.errorMaxLines = 1,
    this.onChanged,
    this.inputAction,
    this.labelText,
    this.hintStyle,
    this.enableBorder = false,
    this.maxLength,
    this.style,
    this.borderColor = Colors.white,
    this.padding,
    this.maxLines = 1,
    this.onTap,
    this.inputFormatters,
    this.allowSpace = true,
    this.numberOfchars,
    this.autovalidateMode,
    this.errorTextHeight = 1,
    this.enableErrorBoarder = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool readOnly;
  final Function? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final Widget? prefixIcon;
  final int errorMaxLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextStyle? style;
  final bool? enableBorder;
  final TextInputAction? inputAction;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final Color? borderColor;
  final Function()? onTap;
  final bool allowSpace;
  final int? numberOfchars;
  final AutovalidateMode? autovalidateMode;
  final double errorTextHeight;
  final List<TextInputFormatter>? inputFormatters;

  final bool enableErrorBoarder;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onTapOutside: (event) {
        if (WidgetsBinding
                .instance
                .platformDispatcher
                .views
                .first
                .viewInsets
                .bottom >
            0.0) {
          FocusScope.of(context).unfocus();
        }
      },
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      controller: controller,
      readOnly: readOnly,
      validator: (value) {
        if (validator != null) {
          return validator!(value, hintText);
        }
        return null;
      },
      obscureText: obscureText,
      obscuringCharacter: "*",
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      textInputAction: inputAction ?? TextInputAction.next,
      style:
          style ??
          w500_16Poppins(color: Theme.of(context).hintColor.withOpacity(0.8)),
      inputFormatters: allowSpace
          ? inputFormatters
          : [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z 0-9@._-]+')),
              LengthLimitingTextInputFormatter(numberOfchars),
            ],
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: prefixIcon,
        hintText: hintText,

        labelText: labelText,
        labelStyle:
            labelStyle ??
            w500_14Poppins(color: Theme.of(context).hintColor.withOpacity(0.8)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0.r),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        contentPadding:
            padding ?? EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        hintStyle: hintStyle ?? w400_13Poppins(color: Colors.black),
        errorMaxLines: errorMaxLines,
        errorStyle: w500_12Poppins(
          color: Colors.red,
          errorTextHeight: errorTextHeight,
        ),

        /// Disable Border
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0.r),
          borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
        ),

        /// Focused Border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0.r),
          borderSide: BorderSide(
            color: borderColor ?? Theme.of(context).primaryColorDark,
          ),
        ),

        /// Enable Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0.r),
          borderSide: BorderSide(color: borderColor ?? Colors.transparent),
        ),

        /// Error Border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0.r),
          borderSide: BorderSide(
            color: enableErrorBoarder
                ? Colors.red
                : Theme.of(context).primaryColorDark,
          ),
        ),

        /// Focused Error Border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0.r),
          borderSide: BorderSide(
            color: borderColor ?? Theme.of(context).primaryColorDark,
          ),
        ),
      ),
    );
  }
}
