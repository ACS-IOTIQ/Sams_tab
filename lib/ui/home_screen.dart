import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/structure/structure_list.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design tokens shared with StructureList — keep these in sync.
class _T {
  static const bg = Color(0xffF4F5F7);
  static const surface = Color(0xffFFFFFF);
  static const ink = Color(0xff1E293B);
  static const ink2 = Color(0xff475569);
  static const muted = Color(0xff94A3B8);
  static const line = Color(0xffE5E7EB);
  static const primaryTint = Color(0xffE0E7EF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final commonProvider = Provider.of<CommonProvider>(context, listen: false);
    userRole = commonProvider.userRole;

    if (userRole == null) {
      await _loadUserRoleFromPrefs();
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadUserRoleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole');

    if (userRole != null && mounted) {
      Provider.of<CommonProvider>(context, listen: false).setUserRole(userRole!);
    }
  }

  String _getUserInitials(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'U';

    final segments = normalized
        .split(RegExp(r'[\s_]+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (segments.isEmpty) return 'U';
    if (segments.length == 1) {
      return segments.first
          .substring(0, normalized.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (segments.first[0] + segments[1][0]).toUpperCase();
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userRole: userRole,
          onLogout: () => logout(context),
        ),
      ),
    );
  }

  void logout(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Consumer<CommonProvider>(
          builder: (context, commonProvider, child) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xffFBFAF5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 32.h),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5.h,
                      width: 50.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xffEBEBEB),
                      ),
                    ),
                    height10,
                    Container(
                      width: 52.w,
                      height: 52.w,
                      decoration: BoxDecoration(
                        color: _T.primaryTint,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Appcolors.buttonColor,
                        size: 26.sp,
                      ),
                    ),
                    height10,
                    Text(
                      'Sign out?',
                      style: w600_18Poppins(color: _T.ink),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'You will need to log in again to continue working.',
                      textAlign: TextAlign.center,
                      style: w400_13Poppins(color: _T.ink2),
                    ),
                    height15,
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            height: 44.h,
                            borderRadius: 14,
                            buttonColor: const Color(0xffE7E9E8),
                            buttonTextStyle: w500_14Poppins(color: _T.ink),
                            buttonText: 'Cancel',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        width10,
                        Expanded(
                          child: CustomButton(
                            height: 44.h,
                            buttonColor: Appcolors.buttonColor,
                            borderRadius: 14,
                            buttonText: 'Sign out',
                            buttonTextStyle: w500_14Poppins(color: Colors.white),
                            onTap: () {
                              Provider.of<CommonProvider>(
                                context,
                                listen: false,
                              ).logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final displayName = commonProvider.userName?.trim().isNotEmpty == true
        ? commonProvider.userName!.trim()
        : userRole?.trim().isNotEmpty == true
        ? userRole!.trim()
        : 'User';
    final userInitials = _getUserInitials(displayName);

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(userInitials),
      body: StructureList(userRole: userRole ?? ''),
    );
  }

  PreferredSizeWidget _buildAppBar(String userInitials) {
    // Raw doubles (no `.w`/`.h`/`.sp`): flutter_screenutil is pinned to a
    // 360dp design width, so on a tablet it scales app-bar chrome to ~2x its
    // intended size. On phones these numbers already match the unscaled values.
    return AppBar(
      backgroundColor: _T.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: contentGutter(MediaQuery.of(context).size.width),
      toolbarHeight: 62,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.line),
            ),
            child: Image.asset(AppImages.applogo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAMS', style: w700_14Poppins(color: _T.ink)),
                const SizedBox(height: 1),
                Text(
                  'Field inspection',
                  style: w500_12Poppins(color: _T.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _AppBarAvatarButton(
          initials: userInitials,
          onTap: _openProfile,
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Sign out',
          onTap: () => logout(context),
        ),
        SizedBox(width: contentGutter(MediaQuery.of(context).size.width)),
      ],
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _T.line),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: _T.ink2),
          ),
        ),
      ),
    );
  }
}

class _AppBarAvatarButton extends StatelessWidget {
  const _AppBarAvatarButton({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _T.primaryTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: w700_10Poppins(color: Appcolors.buttonColor),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userRole, required this.onLogout});

  final String? userRole;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final displayName = commonProvider.userName?.trim().isNotEmpty == true
        ? commonProvider.userName!.trim()
        : 'User';
    final displayRole = (widget.userRole ?? commonProvider.userRole ?? 'Unknown')
        .toUpperCase();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 4.w,
        toolbarHeight: 60.h,
        iconTheme: const IconThemeData(color: _T.ink),
        title: Text(
          'Profile',
          style: w700_18Poppins(color: _T.ink),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
        children: [
          // Identity card
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: _T.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54.w,
                      height: 54.h,
                      decoration: const BoxDecoration(
                        color: _T.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_rounded,
                        color: Appcolors.buttonColor,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: w600_16Poppins(color: _T.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _T.primaryTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              displayRole,
                              style: w600_11Poppins(color: Appcolors.buttonColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  'Manage your workspace access and sign out securely from this device.',
                  style: w400_13Poppins(color: _T.ink2),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton.icon(
                    onPressed: widget.onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolors.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'Sign out',
                      style: w500_14Poppins(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension RoleExtension on String? {
  bool get isAdmin => this?.toLowerCase() == 'admin';
  bool get isUser => this?.toLowerCase() == 'user';
}