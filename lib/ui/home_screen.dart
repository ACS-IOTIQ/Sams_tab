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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  String? userRole; // Store user role locally

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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserRoleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole');

    // Update the CommonProvider with the role if found
    if (userRole != null) {
      final commonProvider = Provider.of<CommonProvider>(
        context,
        listen: false,
      );
      commonProvider.setUserRole(userRole!);
    }
  }

  void _onTabSelected(int index) {
    if (selectedIndex == index) return;
    setState(() => selectedIndex = index);
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

  void logout(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color(0xffFBFAF5),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Consumer<CommonProvider>(
          builder: (context, commonProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                height10,
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 5.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xffEBEBEB),
                    ),
                  ),
                ),
                height10,

                Column(
                  children: [
                    SizedBox(
                      child: Text(
                        "Are you sure you want to logout?",
                        style: w400_16Poppins(),
                      ),
                    ),
                    height10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          width: 125.w,
                          height: 35.h,
                          borderRadius: 24,
                          buttonColor: Color(0xffE7E9E8),
                          buttonTextStyle: w500_16Poppins(color: Colors.black),
                          buttonText: "No",
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        width10,
                        CustomButton(
                          width: 125.w,
                          height: 35.h,
                          buttonColor: Appcolors.buttonColor,
                          borderRadius: 24,
                          buttonText: "Yes",
                          onTap: () {
                            Provider.of<CommonProvider>(
                              context,
                              listen: false,
                            ).logout();
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                height10,
              ],
            );
          },
        );
      },
    );
  }

  String getStructureMenuTitle() {
    if (userRole == null) return 'Structure';

    switch (userRole!.toLowerCase()) {
      case 'admin':
        return 'Admin Panel';
      case 'field engineer':
        return 'Structure';
      default:
        return 'Structure';
    }
  }

  Widget getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return _getStructureScreen();
      case 1:
        return ProfileScreen(
          userRole: userRole,
          onLogout: () => logout(context),
        );
      default:
        return Center(child: Text('Unknown tab'));
    }
  }

  Widget _getStructureScreen() {
    final role = userRole?.toLowerCase() ?? '';
    switch (role) {
      case 'admin':
        return StructureList(userRole: role);
      case 'field engineer':
        return StructureList(userRole: role);
      default:
        return StructureList(userRole: role); // Default until role loads
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final isStructureTab = selectedIndex == 0;
    final appBarTitle = isStructureTab ? 'Manage Structures' : 'Profile';
    final appBarSubtitle = isStructureTab
        ? 'Inspect, input and test structures.'
        : 'Manage your account and workspace access.';
    final displayName = commonProvider.userName?.trim().isNotEmpty == true
        ? commonProvider.userName!.trim()
        : userRole?.trim().isNotEmpty == true
        ? userRole!.trim()
        : 'User';
    final userInitials = _getUserInitials(displayName);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xffF7F8FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 14.w,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.h,
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(AppImages.applogo),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appBarTitle,
                      style: w700_20Poppins(color: const Color(0xff101828)),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      appBarSubtitle,
                      style: w400_12Poppins(color: const Color(0xff667085)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userRole: userRole,
                    onLogout: () => logout(context),
                  ),
                ),
              );
            },
            child: Container(
              width: 36.w,
              height: 36.h,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                userInitials,
                style: w600_12Poppins(color: const Color(0xff101828)),
              ),
            ),
          ),
          Container(
            width: 36.w,
            height: 36.h,
            margin: EdgeInsets.only(right: 14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xffE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => logout(context),
              splashRadius: 18.r,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.logout_rounded,
                size: 18.sp,
                color: Appcolors.buttonColor,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: _BottomNavigationShell.reservedSpace(context),
              ),
              child: getSelectedScreen(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNavigationShell(
              currentIndex: selectedIndex,
              onTap: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationShell extends StatelessWidget {
  const _BottomNavigationShell({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static double reservedSpace(BuildContext context) {
    final viewPadding = MediaQuery.of(context).padding.bottom;
    return 94.h + viewPadding;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 70.h,
          constraints: BoxConstraints(maxWidth: 520.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xF2FFFFFF),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: const Color(0xD9FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.apartment_outlined,
                  activeIcon: Icons.apartment_rounded,
                  label: 'Structures',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              // Expanded(
              //   child: _BottomNavItem(
              //     icon: Icons.person_outline_rounded,
              //     activeIcon: Icons.person_rounded,
              //     label: 'Profile',
              //     isSelected: currentIndex == 1,
              //     onTap: () => onTap(1),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? Appcolors.buttonColor
        : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 10.w : 0,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: foregroundColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                style: w500_12Poppins(color: foregroundColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.userRole, required this.onLogout});

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
        appBar: AppBar(
        backgroundColor: const Color(0xffF7F8FA),
        elevation: 0,
        // titleSpacing: 14.w,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.h,
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(AppImages.applogo),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile",
                      style: w700_20Poppins(color: const Color(0xff101828)),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Manage your account and workspace access.',
                      style: w400_12Poppins(color: const Color(0xff667085)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    
      ),
      body: Container(
        color: const Color(0xffF7F8FA),
        child: ListView(
          padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 6.h),
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(displayName, style: w600_16Poppins()),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      displayRole,
                      style: w500_13Poppins(color: Colors.blue.shade700),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Manage your testing workspace and sign out securely from this device.',
                    style: w400_13Poppins(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton.icon(
                      onPressed: widget.onLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text(
                        'Logout',
                        style: w500_14Poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension RoleExtension on String? {
  bool get isAdmin => this?.toLowerCase() == 'admin';
  bool get isUser => this?.toLowerCase() == 'user';
}
