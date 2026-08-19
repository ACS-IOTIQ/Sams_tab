import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';

class ModuleBackArrow extends StatelessWidget {
  const ModuleBackArrow({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () => Navigator.of(context).maybePop(),
      splashRadius: 20.r,
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18.sp,
        color: const Color(0xff111827),
      ),
    );
  }
}

class ModuleHeaderTitle extends StatelessWidget {
  const ModuleHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor = const Color(0xff111827),
    this.subtitleColor = const Color(0xff667085),
  });

  final String title;
  final String? subtitle;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: w700_20Poppins(color: titleColor),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: w400_12Poppins(color: subtitleColor),
          ),
        ],
      ],
    );
  }
}
