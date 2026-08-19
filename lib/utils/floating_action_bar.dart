import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FloatingActionBar extends StatelessWidget {
  const FloatingActionBar({
    super.key,
    required this.children,
    this.bottomMargin,
  });

  final List<Widget> children;
  final double? bottomMargin;

  static double contentBottomPadding(BuildContext context) {
    final viewPadding = MediaQuery.of(context).padding.bottom;
    return 132.h + viewPadding;
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final shouldScroll = shortestSide < 700;

    final actionLayout = shouldScroll
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _withSpacing(children),
            ),
          )
        : Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 10.h,
            children: children,
          );

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomMargin ?? 12.h),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: BoxConstraints(maxWidth: 900.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(0.58)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff101828).withOpacity(0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: actionLayout,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        result.add(SizedBox(width: 12.w));
      }
      result.add(items[i]);
    }
    return result;
  }
}
