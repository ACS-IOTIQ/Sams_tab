import 'package:flutter/material.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/images.dart';

Future<dynamic> customShowDialog(
  BuildContext context,
  Widget dialogWidget, {
  double? height,
  Color? color,
  RouteSettings? routeSettings,
  bool enableDrag = false,
  bool isDismissible = true,

  Color? backGroundColor,
}) {
  return showModalBottomSheet(
    isDismissible: isDismissible,
    isScrollControlled: true,
    useSafeArea: true,
    routeSettings: routeSettings,
    enableDrag: enableDrag,
    barrierColor: Colors.black.withOpacity(0.16),
    backgroundColor: Colors.transparent,
    context: context,
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final screenWidth = mediaQuery.size.width;
      final isTablet = screenWidth >= 700;
      final targetHeight = height ?? mediaQuery.size.height * 0.45;
      final maxHeight = mediaQuery.size.height * (isTablet ? 0.78 : 0.72);
      final resolvedHeight = targetHeight > maxHeight
          ? maxHeight
          : targetHeight;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 12,
          0,
          isTablet ? 24 : 12,
          mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 48,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 460 : double.infinity,
              maxHeight: maxHeight,
            ),
            child: Material(
              color:
                  backGroundColor ?? Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height == null ? null : resolvedHeight,
                child: dialogWidget,
              ),
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    // commonProvider?.updateSelectedSound();
  });
}

Future<void> showAlertDialog(
  BuildContext context, {
  Widget? title,
  Widget? body,
  Color? backgrounColor,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.symmetric(horizontal: 7),
        title: title,
        content: body,
        backgroundColor: Colors.transparent,
      );
    },
  );
}

Widget showDialogCustomHeader(
  BuildContext context, {
  required String headerTitle,
  bool removeDivider = false,
  Color? headerColor,
  bool backNavigationRequired = true,
  VoidCallback? backButtonFuc,
}) {
  return Container(
    decoration: const BoxDecoration(
      // color: headerColor ?? webinarThemesProviders.colors.headerColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        topLeft: Radius.circular(20),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        height20,
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 5,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xff202223),
            ),
          ),
        ),
        height10,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headerTitle,
                style: w500_14Poppins(color: Theme.of(context).hoverColor),
              ),
              if (backNavigationRequired)
                GestureDetector(
                  onTap:
                      backButtonFuc ??
                      () {
                        Navigator.pop(context);
                      },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColorLight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        removeDivider
            ? const SizedBox.shrink()
            : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(),
              ),
      ],
    ),
  );
}
