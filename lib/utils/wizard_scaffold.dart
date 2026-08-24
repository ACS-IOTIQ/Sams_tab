import 'package:flutter/material.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';

/// The chrome shared by every step of the add-structure wizard.
///
/// Navigation reads top-left to bottom-right: going back is the app bar's back
/// arrow, going forward is a single primary button pinned to the bottom-right.
/// This replaces the floating Back/Next pill pair, which sat centred over the
/// content and hid the last field behind it.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onNext,
    this.subtitle,
    this.nextLabel = 'Next',
    this.onBack,
    this.appBarActions = const [],
    this.secondaryAction,
    this.isBusy = false,
    this.backgroundColor = const Color(0xffF4F5F7),
    this.contentPadding = const EdgeInsets.fromLTRB(14, 14, 14, 20),
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;

  /// `null` renders the Next button disabled.
  final VoidCallback? onNext;
  final String nextLabel;

  /// Defaults to popping the route.
  final VoidCallback? onBack;

  final List<Widget> appBarActions;

  /// Optional button placed to the left of Next (e.g. "Save draft").
  final Widget? secondaryAction;

  final bool isBusy;
  final Color backgroundColor;
  final EdgeInsets contentPadding;

  /// Set false when [body] manages its own scrolling.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: contentPadding, child: body);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        leading: _BackArrow(onTap: onBack ?? () => Navigator.of(context).pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: w600_16Poppins(color: const Color(0xff0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              Text(
                subtitle!,
                style: w500_12Poppins(color: FormKit.hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          ...appBarActions,
          const SizedBox(width: 8),
        ],
      ),
      body: scrollable
          ? SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            )
          : content,
      bottomNavigationBar: WizardActionBar(
        nextLabel: nextLabel,
        onNext: onNext,
        isBusy: isBusy,
        secondaryAction: secondaryAction,
      ),
    );
  }
}

class _BackArrow extends StatelessWidget {
  const _BackArrow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded,
                size: 18, color: Color(0xff334155)),
          ),
        ),
      ),
    );
  }
}

/// The bottom bar holding the wizard's forward action, right-aligned.
class WizardActionBar extends StatelessWidget {
  const WizardActionBar({
    super.key,
    required this.onNext,
    this.nextLabel = 'Next',
    this.isBusy = false,
    this.secondaryAction,
  });

  final VoidCallback? onNext;
  final String nextLabel;
  final bool isBusy;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (secondaryAction != null) ...[
              secondaryAction!,
              const SizedBox(width: 12),
            ],
            WizardNextButton(
              label: nextLabel,
              onTap: onNext,
              isBusy: isBusy,
            ),
          ],
        ),
      ),
    );
  }
}

class WizardNextButton extends StatelessWidget {
  const WizardNextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isBusy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: enabled ? Appcolors.buttonColor : const Color(0xffE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy) ...[
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: w600_14Poppins(
                  color: enabled ? Colors.white : const Color(0xff94A3B8),
                ),
              ),
              if (!isBusy) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: enabled ? Colors.white : const Color(0xff94A3B8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Skip" affordance the wizard shows once a step already has saved data.
class WizardSkipButton extends StatelessWidget {
  const WizardSkipButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? Appcolors.buttonColor : const Color(0xffE2E8F0),
              ),
            ),
            child: Text(
              'Skip',
              style: w600_13Poppins(
                color: enabled ? Appcolors.buttonColor : const Color(0xff94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
