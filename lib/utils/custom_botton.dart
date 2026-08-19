import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.buttonText,
    this.onTap,
    this.buttonColor = Colors.red,
    this.textColor = Colors.black,
    this.height,
    this.width,
    this.buttonTextStyle,
    this.borderColor,
    this.isLoading = false,
    this.borderRadius,
    this.leadingWidget,
  });

  final String buttonText;
  final VoidCallback? onTap;
  final Color buttonColor;
  final Color textColor;
  final double? height;
  final double? width;
  final TextStyle? buttonTextStyle;
  final double? borderRadius;
  final bool isLoading;
  final Color? borderColor;
  final Widget? leadingWidget;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 5.h),
        height: height ?? 40.h,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? Colors.transparent),
          color: buttonColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 5.r),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget!,
                      SizedBox(width: 10.w),
                    ],
                    Text(
                      buttonText,
                      style:
                          buttonTextStyle ??
                          w400_16Poppins(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
