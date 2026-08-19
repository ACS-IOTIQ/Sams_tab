import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/module_header.dart';

class ViewFormScaffold extends StatelessWidget {
  const ViewFormScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
  });

  final String title;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: Navigator.of(context).canPop() ? 42.w : 0,
        leading: Navigator.of(context).canPop()
            ? const ModuleBackArrow()
            : null,
        titleSpacing: Navigator.of(context).canPop() ? 2.w : 16.w,
        title: ModuleHeaderTitle(title: title),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

class ViewFormPage extends StatelessWidget {
  const ViewFormPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class ViewSectionCard extends StatelessWidget {
  const ViewSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE5E7EB)),
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
          Text(title, style: w600_18Poppins(color: const Color(0xff111827))),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle!,
              style: w400_13Poppins(color: const Color(0xff6B7280)),
            ),
          ],
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

class ViewInfoBanner extends StatelessWidget {
  const ViewInfoBanner({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xffEEF4FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffD6E4FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: Appcolors.buttonColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: w500_12Poppins(color: const Color(0xff475467)),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: w600_16Poppins(color: const Color(0xff101828)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ViewDetailGrid extends StatelessWidget {
  const ViewDetailGrid({super.key, required this.items, this.columns = 2});

  final List<ViewDetailItemData> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final gridColumns = isCompact ? 1 : columns;
        final childAspectRatio = isCompact ? 4.4 : 2.6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ViewDetailItem(item: item);
          },
        );
      },
    );
  }
}

class ViewDetailItemData {
  const ViewDetailItemData({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline_rounded,
  });

  final String label;
  final String value;
  final IconData icon;
}

class ViewDetailItem extends StatelessWidget {
  const ViewDetailItem({super.key, required this.item});

  final ViewDetailItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(item.icon, size: 18.sp, color: Appcolors.buttonColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: w500_12Poppins(color: const Color(0xff667085)),
                ),
                SizedBox(height: 5.h),
                Text(
                  item.value,
                  style: w600_14Poppins(color: const Color(0xff101828)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ViewChipRow extends StatelessWidget {
  const ViewChipRow({super.key, required this.items});

  final List<ViewChipData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: items
          .map(
            (item) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                '${item.label}: ${item.value}',
                style: w500_13Poppins(color: item.textColor),
              ),
            ),
          )
          .toList(),
    );
  }
}

class ViewChipData {
  const ViewChipData({
    required this.label,
    required this.value,
    this.backgroundColor = const Color(0xffEEF2FF),
    this.textColor = const Color(0xff344054),
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;
}

class ViewFormBottomBar extends StatelessWidget {
  const ViewFormBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xffF5F7FB),
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: secondaryLabel,
                borderRadius: 14.r,
                buttonColor: Colors.white,
                buttonTextStyle: w700_15Poppins(color: Appcolors.buttonColor),
                height: 44.h,
                borderColor: const Color(0xffD0D5DD),
                onTap: onSecondaryTap,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomButton(
                buttonText: primaryLabel,
                borderRadius: 14.r,
                buttonColor: Appcolors.buttonColor,
                buttonTextStyle: w700_15Poppins(color: Colors.white),
                height: 44.h,
                onTap: onPrimaryTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
