import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/get_all_structures_model.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/add_structure.dart';
import 'package:sams_engineering_console/structure/structure_view/get_location_details.dart';
import 'package:sams_engineering_console/testing_module/testing_screen.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/images.dart';

class StructureList extends StatefulWidget {
  const StructureList({super.key, required this.userRole});

  final String userRole;

  @override
  State<StructureList> createState() => _StructureListState();
}

class _StructureListState extends State<StructureList> {
  late AddstructureProvider addstructureProvider;
  late GetstructureProvider getstructureProvider;
  bool isLoading = false;

  bool get _showTestingColumn => widget.userRole.trim().toUpperCase() != "FE";
  String get _normalizedRole => widget.userRole.trim().toUpperCase();

  @override
  void initState() {
    super.initState();
    addstructureProvider = Provider.of<AddstructureProvider>(
      context,
      listen: false,
    );
    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );
    _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await getstructureProvider.getStructures(context, page: page);
    } catch (e) {
      if (mounted) {
        CustomToast.showErrorToast(msg: "Error loading data: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Datum> _applyRoleFilter(List<Datum> structureList) {
    if (_normalizedRole == "VE" || _normalizedRole == "TE") {
      return structureList
          .where((s) => s.status.toLowerCase() == "submitted")
          .toList();
    }
    return structureList;
  }

  void _openTestingScreen(Datum structure) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => TestingScreen(
          structureId: structure.structureId,
          structureIdentityNumber: structure.structuralIdentityNumber,
          initialStatus: structure.status,
        ),
      ),
    );
  }

  Future<void> _showDownloadOptions(Datum structure) async {
    final provider = Provider.of<GetstructureProvider>(context, listen: false);
    final downloadKey = structure.structuralIdentityNumber.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.12),
      builder: (dialogContext) {
        return _ReportDownloadDialog(
          isDownloading: provider.isReportDownloading(downloadKey),
          onFormatSelected: (format) {
            Navigator.of(dialogContext).pop();
            provider.downloadStructureReportByStrId(
              context,
              downloadKey,
              format: format,
              displayName:
                  'Structure_Report_${structure.structuralIdentityNumber}',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GetstructureProvider>(
      builder: (context, provider, child) {
        final filteredList = _applyRoleFilter(provider.structureList);
        final pagination = provider.structureData?.pagination;
        final currentPage = pagination?.currentPage ?? 1;
        final totalPages = pagination?.totalPages ?? 1;
        final hasNextPage = pagination?.hasNextPage ?? false;
        final hasPrevPage = pagination?.hasPrevPage ?? false;

        if (isLoading && provider.structureData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => _fetchPage(1),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 18.h),
            children: [
              _StructureHeader(
                userRole: _normalizedRole,
                onOpenActions: _normalizedRole == "FE"
                    ? () => _showStructureActionsMenu(filteredList)
                    : null,
              ),
              SizedBox(height: 12.h),
              if (filteredList.isEmpty)
                SizedBox(
                  height: 420.h,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AppImages.emptyStructureList),
                        height20,
                        Text("No records available", style: w600_18Poppins()),
                        height10,
                        SizedBox(
                          width: 330.w,
                          child: Text(
                            "Nothing to display. Create your first file to get started!",
                            style: w400_15Poppins(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...filteredList.map(
                  (structure) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _StructureCard(
                      structure: structure,
                      downloadState: provider.reportDownloadStateFor(
                        structure.structuralIdentityNumber.trim(),
                      ),
                      showEditButton: _normalizedRole == "FE",
                      showTestingButton: _showTestingColumn,
                      onOpenDetails: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GetLocationdetails(
                              structureId: structure.structureId,
                            ),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddStructureScreen(
                              structureId: structure.structureId,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _showDeleteConfirmation(structure),
                      onStartTesting: () => _openTestingScreen(structure),
                      onDownload: () => _showDownloadOptions(structure),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                _PaginationBar(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  hasNextPage: hasNextPage,
                  hasPrevPage: hasPrevPage,
                  isLoading: isLoading,
                  onPrevious: () => _fetchPage(currentPage - 1),
                  onNext: () => _fetchPage(currentPage + 1),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStructureActionsMenu(List<Datum> structures) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Structure actions',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.14),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Positioned(
                  top: 12.h,
                  right: 14.w,
                  child: GestureDetector(
                    onTap: () {},
                    child: _StructureActionMenu(
                      onAddStructure: () {
                        Navigator.of(dialogContext).pop();
                        addstructureProvider.initializeStructure(context);
                      },
                      onEditStructure: () {
                        Navigator.of(dialogContext).pop();
                        _showEditStructureSelector(structures);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showEditStructureSelector(List<Datum> structures) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _EditStructureSelectorDialog(
          structures: structures,
          isLoading: isLoading && structures.isEmpty,
          onSelected: (structure) {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddStructureScreen(structureId: structure.structureId),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(Datum structure) async {
    if (!mounted) return;

    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 26.h),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xffD0D5DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: const Color(0xffFEE4E2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xffD92D20),
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Delete structure?',
                  style: w600_20Poppins(color: const Color(0xff101828)),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Are you sure you want to delete the structure ${structure.structuralIdentityNumber}?',
                  textAlign: TextAlign.center,
                  style: w400_14Poppins(color: const Color(0xff475467)),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff344054),
                          side: const BorderSide(color: Color(0xffD0D5DD)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text('Cancel', style: w600_14Poppins()),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD92D20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                        ),
                        child: Text('Delete', style: w600_14Poppins(color: Colors.white)),
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

    if (shouldDelete != true) return;

    final bool deleted = await addstructureProvider.deleteStructure(
      structure.structureId,
      context,
    );

    if (deleted && mounted) {
      await getstructureProvider.getStructures(context, page: 1);
    }
  }
}

class _StructureHeader extends StatelessWidget {
  const _StructureHeader({required this.userRole, required this.onOpenActions});

  final String userRole;
  final VoidCallback? onOpenActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        if (onOpenActions != null)
          _HeaderPlusButton(onTap: onOpenActions!)
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: Text(
              userRole,
              style: w500_12Poppins(color: Appcolors.buttonColor),
            ),
          ),
      ],
    );
  }
}

class _HeaderPlusButton extends StatelessWidget {
  const _HeaderPlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          width: 42.w,
          height: 42.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                Appcolors.buttonColor,
                Appcolors.buttonColor.withOpacity(0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Appcolors.buttonColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '+',
              style: _expoStyle(
                w700_20Poppins(color: Colors.white),
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StructureCard extends StatelessWidget {
  const _StructureCard({
    required this.structure,
    required this.downloadState,
    required this.showEditButton,
    required this.showTestingButton,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onStartTesting,
    required this.onDownload,
  });

  final Datum structure;
  final ReportDownloadState downloadState;
  final bool showEditButton;
  final bool showTestingButton;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStartTesting;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final metadata = <_MetadataItem>[
      _MetadataItem(
        icon: Icons.apartment_rounded,
        label: _floorsLabel(structure),
      ),
      _MetadataItem(
        icon: Icons.calendar_today_rounded,
        label: _dateLabel(structure),
      ),
      _MetadataItem(
        icon: Icons.place_outlined,
        label: _locationLabel(structure),
      ),
    ].where((item) => item.label.isNotEmpty).toList();

    final subtitle = _subtitle(structure);
    final supportingLine = _supportingLine(structure);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xffECEFF3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff101828).withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StructureThumbnail(
                  typeLabel: _structureTypeShortLabel(structure),
                  imageUrl: structure.location.structureImage,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  structure.structuralIdentityNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: w600_16Poppins(
                                    color: const Color(0xff182230),
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  SizedBox(height: 3.h),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: w400_12Poppins(
                                      color: const Color(0xff475467),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusChip(status: structure.status),
                              if (showEditButton) ...[
                                _CardActionIcon(
                                  icon: Icons.edit_outlined,
                                  tooltip: 'Edit structure',
                                  onTap: onEdit,
                                ),
                                SizedBox(width: 8.w),
                                _CardActionIcon(
                                  icon: Icons.delete_outline_rounded,
                                  tooltip: 'Delete structure',
                                  onTap: onDelete,
                                  color: const Color(0xffD92D20),
                                  backgroundColor: const Color(0xffFEF3F2),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (supportingLine.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          supportingLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: w400_12Poppins(color: const Color(0xff98A2B3)),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        SizedBox(height: 9.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: metadata
                              .map(
                                (item) => _MetadataPill(
                                  icon: item.icon,
                                  label: item.label,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34.h,
                              child: OutlinedButton.icon(
                                onPressed: downloadState.isDownloading
                                    ? null
                                    : onDownload,
                                icon: downloadState.isDownloading
                                    ? SizedBox(
                                        width: 14.w,
                                        height: 14.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: downloadState.progress,
                                          color: Appcolors.buttonColor,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  downloadState.isDownloading
                                      ? _downloadLabel(downloadState)
                                      : 'Download',
                                  style: w500_12Poppins(
                                    color: downloadState.isDownloading
                                        ? const Color(0xff98A2B3)
                                        : const Color(0xff344054),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: downloadState.isDownloading
                                        ? const Color(0xffD0D5DD)
                                        : const Color(0xffD0D5DD),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          if (showTestingButton)
                            SizedBox(
                              height: 34.h,
                              child: ElevatedButton(
                                onPressed: onStartTesting,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Appcolors.buttonColor,
                                  foregroundColor: Colors.white,
                                  elevation: 1.5,
                                  shadowColor: Appcolors.buttonColor
                                      .withOpacity(0.22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 7.h,
                                  ),
                                  minimumSize: Size(0, 34.h),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Start Testing',
                                  style: w500_12Poppins(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (downloadState.isDownloading) ...[
                        SizedBox(height: 10.h),
                        LinearProgressIndicator(
                          value: downloadState.progress,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: const Color(0xffE4E7EC),
                          color: Appcolors.buttonColor,
                        ),
                      ],
                      if (!downloadState.isDownloading &&
                          (downloadState.errorMessage ?? '').isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          downloadState.errorMessage!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: w400_12Poppins(color: const Color(0xffB42318)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _locationLabel(Datum structure) {
    final parts = <String>[
      if (structure.location.cityName.trim().isNotEmpty)
        structure.location.cityName.trim(),
      if (structure.location.stateCode.trim().isNotEmpty)
        structure.location.stateCode.trim(),
    ];
    return parts.join(', ');
  }

  static String _subtitle(Datum structure) {
    final clientName = (structure.clientName ?? '').trim();
    if (clientName.isNotEmpty) return clientName;

    final type = structure.typeOfStructure.trim();
    if (type.isNotEmpty) {
      return type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ');
    }

    return '';
  }

  static String _prettyStatus(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Pending';
    return trimmed
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _supportingLine(Datum structure) {
    final parts = <String>[
      if (_locationLabel(structure).isNotEmpty) _locationLabel(structure),
      if (_dateLabel(structure).isNotEmpty) 'Updated ${_dateLabel(structure)}',
    ];
    return parts.join('  •  ');
  }

  static String _structureTypeShortLabel(Datum structure) {
    final raw = structure.typeOfStructure.trim();
    if (raw.isEmpty) return 'S';
    return raw.substring(0, 1).toUpperCase();
  }

  static String _floorsLabel(Datum structure) {
    final floors = structure.dimensions.floors;
    if (floors == null || floors <= 0) return '';
    return '$floors Floors';
  }

  static String _dateLabel(Datum structure) {
    return _formatDate(structure.timestamps.lastUpdatedDate);
  }

  static String _downloadLabel(ReportDownloadState state) {
    final progress = state.progress;
    final format = state.format?.label ?? 'Report';
    if (progress == null || progress <= 0) {
      return 'Downloading $format';
    }
    return 'Downloading ${(progress * 100).round()}%';
  }

  static String _formatDate(DateTime date) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }
}

class _ReportDownloadDialog extends StatelessWidget {
  const _ReportDownloadDialog({
    required this.isDownloading,
    required this.onFormatSelected,
  });

  final bool isDownloading;
  final ValueChanged<ReportDownloadFormat> onFormatSelected;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= 700;
    final maxWidth = isTablet ? 420.0 : mediaQuery.size.width * 0.84;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(16.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: mediaQuery.size.height * 0.52,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: EdgeInsets.all(isTablet ? 18.w : 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xffEAECF0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff101828).withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download report',
                    style: w600_16Poppins(color: const Color(0xff101828)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Choose a format for this report.',
                    style: w400_12Poppins(color: const Color(0xff667085)),
                  ),
                  SizedBox(height: 12.h),
                  _DownloadFormatTile(
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: const Color(0xffD92D20),
                    title: 'Download as PDF',
                    subtitle: 'Portable document format',
                    isDisabled: isDownloading,
                    onTap: () => onFormatSelected(ReportDownloadFormat.pdf),
                  ),
                  SizedBox(height: 8.h),
                  _DownloadFormatTile(
                    icon: Icons.description_rounded,
                    iconColor: const Color(0xff155EEF),
                    title: 'Download as Word',
                    subtitle: 'Editable Word document',
                    isDisabled: isDownloading,
                    onTap: () => onFormatSelected(ReportDownloadFormat.word),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StructureActionMenu extends StatelessWidget {
  const _StructureActionMenu({
    required this.onAddStructure,
    required this.onEditStructure,
  });

  final VoidCallback onAddStructure;
  final VoidCallback onEditStructure;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 212.w,
          constraints: BoxConstraints(maxHeight: 180.h),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white.withOpacity(0.68),
            border: Border.all(color: Colors.white.withOpacity(0.46)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff101828).withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionMenuItem(
                  icon: Icons.add_rounded,
                  title: 'Add Structure',
                  onTap: onAddStructure,
                ),
                SizedBox(height: 4.h),
                _ActionMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Structure',
                  onTap: onEditStructure,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: EdgeInsets.fromLTRB(6.w, 9.h, 8.w, 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Appcolors.buttonColor.withOpacity(0.12),
                  border: Border.all(
                    color: Appcolors.buttonColor.withOpacity(0.14),
                  ),
                ),
                child: Icon(icon, color: Appcolors.buttonColor, size: 18),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _expoStyle(
                    w600_14Poppins(color: const Color(0xff182230)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditStructureSelectorDialog extends StatefulWidget {
  const _EditStructureSelectorDialog({
    required this.structures,
    required this.isLoading,
    required this.onSelected,
  });

  final List<Datum> structures;
  final bool isLoading;
  final ValueChanged<Datum> onSelected;

  @override
  State<_EditStructureSelectorDialog> createState() =>
      _EditStructureSelectorDialogState();
}

class _EditStructureSelectorDialogState
    extends State<_EditStructureSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStructures = widget.structures.where((structure) {
      final needle = _query.trim().toLowerCase();
      if (needle.isEmpty) return true;

      final haystack = [
        structure.structuralIdentityNumber,
        structure.clientName ?? '',
        structure.location.cityName,
        structure.location.stateCode,
        structure.location.address,
      ].join(' ').toLowerCase();

      return haystack.contains(needle);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(maxWidth: 560.w, maxHeight: 560.h),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              color: Colors.white.withOpacity(0.82),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff101828).withOpacity(0.18),
                  blurRadius: 34,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit structure',
                            style: _expoStyle(
                              w600_18Poppins(color: const Color(0xff101828)),
                              letterSpacing: -0.35,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Search and choose a structure to open the existing edit form.',
                            style: _expoStyle(
                              w400_12Poppins(color: const Color(0xff667085)),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search by structure number, client, city...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.72),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.r),
                      borderSide: BorderSide(color: const Color(0xffD0D5DD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.r),
                      borderSide: BorderSide(color: Appcolors.buttonColor),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.r),
                      color: Colors.white.withOpacity(0.42),
                      border: Border.all(color: Colors.white.withOpacity(0.48)),
                    ),
                    child: widget.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredStructures.isEmpty
                        ? _SelectorEmptyState(query: _query)
                        : Scrollbar(
                            thumbVisibility: true,
                            child: ListView.separated(
                              padding: EdgeInsets.all(10.w),
                              itemCount: filteredStructures.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 8.h),
                              itemBuilder: (context, index) {
                                final structure = filteredStructures[index];
                                return _StructureSelectionTile(
                                  structure: structure,
                                  onTap: () => widget.onSelected(structure),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StructureSelectionTile extends StatelessWidget {
  const _StructureSelectionTile({required this.structure, required this.onTap});

  final Datum structure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if ((structure.clientName ?? '').trim().isNotEmpty)
        structure.clientName!.trim(),
      if (structure.location.cityName.trim().isNotEmpty)
        structure.location.cityName.trim(),
      if (structure.location.stateCode.trim().isNotEmpty)
        structure.location.stateCode.trim(),
    ].join('  •  ');

    final address = structure.location.address.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withOpacity(0.74),
            border: Border.all(color: const Color(0xffEAECF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Appcolors.buttonColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  color: Appcolors.buttonColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      structure.structuralIdentityNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _expoStyle(
                        w600_14Poppins(color: const Color(0xff101828)),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _expoStyle(
                          w400_11Poppins(color: const Color(0xff475467)),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                    if (address.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _expoStyle(
                          w400_11Poppins(color: const Color(0xff98A2B3)),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: const Color(0xff667085),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorEmptyState extends StatelessWidget {
  const _SelectorEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearching = query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.folder_open_rounded,
              size: 34,
              color: const Color(0xff98A2B3),
            ),
            SizedBox(height: 10.h),
            Text(
              isSearching
                  ? 'No matching structures'
                  : 'No structures available',
              style: _expoStyle(w600_14Poppins(color: const Color(0xff344054))),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              isSearching
                  ? 'Try a different structure number, client name, or location.'
                  : 'Once structures are assigned, they will appear here for quick editing.',
              style: _expoStyle(
                w400_12Poppins(color: const Color(0xff667085)),
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadFormatTile extends StatelessWidget {
  const _DownloadFormatTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDisabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          height: 66.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xffF8F9FC)
                : const Color(0xffFCFCFD),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xffE4E7EC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff101828).withOpacity(0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: w600_13Poppins(color: const Color(0xff101828)),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: w400_11Poppins(color: const Color(0xff98A2B3)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13.sp,
                color: const Color(0xff98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _expoStyle(TextStyle baseStyle, {double? letterSpacing}) {
  return GoogleFonts.spaceGrotesk(
    textStyle: baseStyle,
    letterSpacing: letterSpacing ?? -0.2,
    height: baseStyle.height ?? 1.15,
  );
}

class _MetadataItem {
  const _MetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _CardActionIcon extends StatelessWidget {
  const _CardActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = const Color(0xff344054),
    this.backgroundColor = const Color(0xffF8FAFC),
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xffE4E7EC)),
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
        ),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xffF4F6FA);
    const textColor = Color(0xff475467);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xffE8ECF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          SizedBox(width: 5.w),
          Text(label, style: w500_12Poppins(color: textColor)),
        ],
      ),
    );
  }
}

class _StructureThumbnail extends StatelessWidget {
  const _StructureThumbnail({required this.typeLabel, this.imageUrl});

  final String typeLabel;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: 82.w,
        height: 106.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffEAF2FF), Color(0xffD6E5FF)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (normalizedImageUrl.isNotEmpty)
              Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
              )
            else
              const _ThumbnailPlaceholder(),
            Positioned(
              top: 10.h,
              right: 10.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: w600_12Poppins(color: Appcolors.buttonColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffEAF2FF), Color(0xffD6E5FF)],
        ),
      ),
      child: Center(
        child: Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.domain_rounded,
            size: 24.sp,
            color: Appcolors.buttonColor,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _statusChipBackgroundColor(status);
    final foregroundColor = _statusChipForegroundColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _StructureCard._prettyStatus(status),
        style: w600_11Poppins(color: foregroundColor),
      ),
    );
  }
}

Color _statusChipBackgroundColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return const Color(0xffFFF1D7);
    case 'under_testing':
    case 'in_testing':
      return const Color(0xffDFF2FF);
    case 'tested':
    case 'validated':
    case 'approved':
    case 'completed':
      return const Color(0xffDFF7E8);
    case 'rejected':
      return const Color(0xffFFE0E0);
    default:
      return const Color(0xffEEF2F6);
  }
}

Color _statusChipForegroundColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return const Color(0xffC97A00);
    case 'under_testing':
    case 'in_testing':
      return const Color(0xff0C6FB8);
    case 'tested':
    case 'validated':
    case 'approved':
    case 'completed':
      return const Color(0xff1E8E5A);
    case 'rejected':
      return const Color(0xffC74A4A);
    default:
      return const Color(0xff475467);
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            label: 'Previous',
            enabled: hasPrevPage && !isLoading,
            onTap: onPrevious,
          ),
          SizedBox(width: 12.w),
          Text('Page $currentPage of $totalPages', style: w500_14Poppins()),
          SizedBox(width: 12.w),
          _PaginationButton(
            label: 'Next',
            enabled: hasNextPage && !isLoading,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: enabled ? Appcolors.buttonColor : Colors.grey.shade200,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        minimumSize: Size(0, 34.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: w500_14Poppins(color: Colors.white)),
    );
  }
}
