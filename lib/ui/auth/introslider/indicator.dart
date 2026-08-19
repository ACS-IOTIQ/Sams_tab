import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/ui/auth/introslider/custom_slide.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';

class Indicator extends StatelessWidget {
  final PageController controller;

  const Indicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final currentPage = (controller.page ?? controller.initialPage).round();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(customSlideLst.length, (index) {
            return GestureDetector(
              onTap: () {
                controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: currentPage == index ? 22.w : 5.w,
                height: 5.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: currentPage == index
                      ? Appcolors.buttonColor
                      : const Color(0xffDFDFDF),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
