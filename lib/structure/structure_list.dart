import 'package:flutter/material.dart';
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

// ─── Design tokens ─────────────────────────────────────────────────────────
// NOTE: this screen intentionally uses raw doubles (no `.w`/`.h`/`.sp`) so
// that on tablets flutter_screenutil doesn't scale chrome elements up to 2×
// their intended size. On phones the numbers already match ScreenUtil's
// unscaled values, so nothing changes there.
class _T {
  static const bg = Color(0xffF4F5F7);
  static const surface = Color(0xffFFFFFF);
  static const ink = Color(0xff1E293B);
  static const ink2 = Color(0xff475569);
  static const muted = Color(0xff94A3B8);
  static const muted2 = Color(0xffCBD5E1);
  static const line = Color(0xffE5E7EB);
  static const line2 = Color(0xffF1F5F9);
  static const primaryTint = Color(0xffE0E7EF);
  static const primaryTint2 = Color(0xffDBE4F0);

  static const successBg = Color(0xffDCFCE7);
  static const successFg = Color(0xff15803D);
  static const amberBg = Color(0xffFEF3C7);
  static const amberFg = Color(0xff92400E);
  static const slateBg = Color(0xffE2E8F0);
  static const slateFg = Color(0xff475569);
  static const infoBg = Color(0xffDBEAFE);
  static const infoFg = Color(0xff1D4ED8);
  static const dangerBg = Color(0xffFEE2E2);
  static const dangerFg = Color(0xffDC2626);

  // Modal sheets/dialogs still read better capped at a phone-ish width.
  static const double maxDialogWidth = 460;
}

/// Horizontal page gutter, shared by the app bar and the list content so the
/// two line up at every screen size. The page itself always fills the window —
/// capping it left large empty margins on tablets.
double contentGutter(double screenWidth) {
  if (screenWidth >= 1100) return 32;
  if (screenWidth >= 700) return 24;
  return 14;
}

/// Cards are laid out in columns rather than stretched edge to edge, so a wide
/// tablet fills its width without each card becoming one long thin strip.
int contentColumns(double screenWidth) {
  // Thresholds chosen so each column lands near the ~380-460dp the card was
  // designed for: a 10" tablet gets 2 columns in portrait, 3 in landscape.
  if (screenWidth >= 1200) return 3;
  if (screenWidth >= 720) return 2;
  return 1;
}

// ─── Filter enum ───────────────────────────────────────────────────────────
enum _FilterKey {
  all,
  submitted,
  completed,
  underTesting,
  draft,
  residential,
  commercial,
}

class _FilterDef {
  const _FilterDef(this.key, this.label);
  final _FilterKey key;
  final String label;
}

const List<_FilterDef> _filterOrder = [
  _FilterDef(_FilterKey.all, 'All'),
  _FilterDef(_FilterKey.submitted, 'Submitted'),
  _FilterDef(_FilterKey.completed, 'Completed'),
  _FilterDef(_FilterKey.underTesting, 'Under testing'),
  _FilterDef(_FilterKey.draft, 'Draft'),
  _FilterDef(_FilterKey.residential, 'Residential'),
  _FilterDef(_FilterKey.commercial, 'Commercial'),
];

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

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _FilterKey _activeFilter = _FilterKey.all;

  bool get _showTestingColumn => widget.userRole.trim().toUpperCase() != "FE";
  String get _normalizedRole => widget.userRole.trim().toUpperCase();
  bool get _isFE => _normalizedRole == "FE";

  @override
  void initState() {
    super.initState();
    addstructureProvider =
        Provider.of<AddstructureProvider>(context, listen: false);
    getstructureProvider =
        Provider.of<GetstructureProvider>(context, listen: false);
    _fetchPage(1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // ── Filters ────────────────────────────────────────────────────────────
  List<Datum> _applyRoleFilter(List<Datum> structureList) {
    if (_normalizedRole == "VE" || _normalizedRole == "TE") {
      return structureList
          .where((s) => s.status.toLowerCase() == "submitted")
          .toList();
    }
    return structureList;
  }

  bool _matchesFilter(Datum s, _FilterKey f) {
    final status = s.status.trim().toLowerCase();
    final type = s.typeOfStructure.trim().toLowerCase();
    switch (f) {
      case _FilterKey.all:
        return true;
      case _FilterKey.submitted:
        return status == 'submitted';
      case _FilterKey.completed:
        return {'tested', 'validated', 'approved', 'completed'}.contains(status);
      case _FilterKey.underTesting:
        return status == 'under_testing' || status == 'in_testing';
      case _FilterKey.draft:
        return status.isEmpty || status == 'draft' || status == 'pending';
      case _FilterKey.residential:
        return type.contains('residential');
      case _FilterKey.commercial:
        return type.contains('commercial');
    }
  }

  bool _matchesSearch(Datum s, String needle) {
    if (needle.isEmpty) return true;
    final n = needle.toLowerCase();
    return [
      s.structuralIdentityNumber,
      s.clientName ?? '',
      s.typeOfStructure,
      s.location.cityName,
      s.location.stateCode,
      s.location.address,
    ].any((v) => v.toLowerCase().contains(n));
  }

  List<Datum> _applyViewFilters(List<Datum> roleFiltered) {
    final q = _query.trim();
    return roleFiltered
        .where((s) => _matchesFilter(s, _activeFilter) && _matchesSearch(s, q))
        .toList();
  }

  Map<_FilterKey, int> _computeCounts(List<Datum> roleFiltered) {
    final Map<_FilterKey, int> out = {};
    for (final def in _filterOrder) {
      out[def.key] =
          roleFiltered.where((s) => _matchesFilter(s, def.key)).length;
    }
    return out;
  }

  DateTime? _lastUpdated(List<Datum> list) {
    if (list.isEmpty) return null;
    return list
        .map((s) => s.timestamps.lastUpdatedDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ── Card actions ───────────────────────────────────────────────────────
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

  Future<void> _showDeleteConfirmation(Datum structure) async {
    if (!mounted) return;

    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _T.maxDialogWidth),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding:
                  const EdgeInsets.fromLTRB(20, 18, 20, 40),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffD0D5DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _T.dangerBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _T.dangerFg,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Delete structure?',
                        style: w600_18Poppins(color: _T.ink)),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to delete ${structure.structuralIdentityNumber}?',
                      textAlign: TextAlign.center,
                      style: w400_13Poppins(color: _T.ink2),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(bottomSheetContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _T.ink,
                              side: const BorderSide(color: Color(0xffD0D5DD)),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Cancel',
                                style: w600_14Poppins(color: _T.ink)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(bottomSheetContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _T.dangerFg,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text('Delete',
                                style: w600_14Poppins(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<GetstructureProvider>(
      builder: (context, provider, child) {
        final roleFiltered = _applyRoleFilter(provider.structureList);
        final counts = _computeCounts(roleFiltered);
        final filteredList = _applyViewFilters(roleFiltered);
        final pagination = provider.structureData?.pagination;
        final currentPage = pagination?.currentPage ?? 1;
        final totalPages = pagination?.totalPages ?? 1;
        final hasNextPage = pagination?.hasNextPage ?? false;
        final hasPrevPage = pagination?.hasPrevPage ?? false;
        final lastUpdated = _lastUpdated(roleFiltered);

        if (isLoading && provider.structureData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final screenW = MediaQuery.of(context).size.width;
        final horizPad = contentGutter(screenW);
        final columns = contentColumns(screenW);

        return RefreshIndicator(
          onRefresh: () => _fetchPage(1),
          color: Appcolors.buttonColor,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizPad, 4, horizPad, 24),
            children: [
              _PageHeader(
                totalCount: roleFiltered.length,
                lastUpdated: lastUpdated,
                showPrimaryAction: _isFE,
                onPrimaryAction: () =>
                    addstructureProvider.initializeStructure(context),
              ),
              const SizedBox(height: 16),
              _SearchRow(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                hasQuery: _query.isNotEmpty,
              ),
              const SizedBox(height: 12),
              if (roleFiltered.isNotEmpty) ...[
                _FilterChipsRow(
                  active: _activeFilter,
                  counts: counts,
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
                const SizedBox(height: 14),
              ],
              if (roleFiltered.isEmpty)
                _buildInitialEmptyState()
              else if (filteredList.isEmpty)
                _buildNoResultsState()
              else ...[
                _CardGrid(
                  columns: columns,
                  spacing: 10,
                  children: [
                    for (final structure in filteredList)
                      _StructureCard(
                        structure: structure,
                        downloadState: provider.reportDownloadStateFor(
                          structure.structuralIdentityNumber.trim(),
                        ),
                        showEditActions: _isFE,
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
                  ],
                ),
                const SizedBox(height: 16),
                _PaginationBar(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  hasNextPage: hasNextPage,
                  hasPrevPage: hasPrevPage,
                  isLoading: isLoading,
                  onPrevious: () => _fetchPage(currentPage - 1),
                  onNext: () => _fetchPage(currentPage + 1),
                ),
                const SizedBox(height: 8),
                _Footnote(count: filteredList.length),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialEmptyState() {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.emptyStructureList),
            const SizedBox(height: 20),
            Text("No records available", style: w600_18Poppins(color: _T.ink)),
            const SizedBox(height: 10),
            SizedBox(
              width: 330,
              child: Text(
                "Nothing to display. Create your first structure to get started!",
                style: w400_13Poppins(color: _T.ink2),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.line),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _T.line2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                color: _T.muted, size: 22),
          ),
          const SizedBox(height: 12),
          Text('No matching structures',
              style: w600_14Poppins(color: _T.ink)),
          const SizedBox(height: 4),
          Text(
            'Try a different code, city, or filter.',
            textAlign: TextAlign.center,
            style: w400_12Poppins(color: _T.ink2),
          ),
        ],
      ),
    );
  }
}

// ─── Page header ───────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalCount,
    required this.lastUpdated,
    required this.showPrimaryAction,
    required this.onPrimaryAction,
  });

  final int totalCount;
  final DateTime? lastUpdated;
  final bool showPrimaryAction;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final countStr = totalCount.toString().padLeft(2, '0');
    final subtitleParts = <String>[
      '$countStr ${totalCount == 1 ? "structure" : "structures"}',
      if (lastUpdated != null) 'updated ${_formatDate(lastUpdated!)}',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Structures',
                style: w700_24Poppins(color: _T.ink)
                    .copyWith(letterSpacing: -0.6, height: 1.05),
              ),
              const SizedBox(height: 4),
              Text(
                subtitleParts.join(' · '),
                style: w500_12Poppins(color: _T.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (showPrimaryAction) ...[
          const SizedBox(width: 10),
          _PrimaryActionButton(onTap: onPrimaryAction),
        ],
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Appcolors.buttonColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Appcolors.buttonColor.withOpacity(0.24),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('New structure',
                  style: w600_13Poppins(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search + sort row ─────────────────────────────────────────────────────
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 42,
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 16, color: _T.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: w500_13Poppins(color: _T.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Search by code, location, or type',
                      hintStyle: w500_13Poppins(color: _T.muted),
                    ),
                  ),
                ),
                if (hasQuery)
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 15, color: _T.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareIconButton(
          icon: Icons.sort_rounded,
          tooltip: 'Sort',
          onTap: () {
            // Sort not wired yet.
          },
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.line),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: _T.ink2),
          ),
        ),
      ),
    );
  }
}

// ─── Filter chips ──────────────────────────────────────────────────────────
class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.active,
    required this.counts,
    required this.onChanged,
  });

  final _FilterKey active;
  final Map<_FilterKey, int> counts;
  final ValueChanged<_FilterKey> onChanged;

  @override
  Widget build(BuildContext context) {
    final visible = _filterOrder
        .where((d) => d.key == _FilterKey.all || (counts[d.key] ?? 0) > 0)
        .toList();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final def = visible[i];
          final isActive = def.key == active;
          final count = counts[def.key] ?? 0;
          final showCount = def.key != _FilterKey.residential &&
              def.key != _FilterKey.commercial;
          return _FilterChip(
            label: def.label,
            count: showCount ? count : null,
            active: isActive,
            onTap: () => onChanged(def.key),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Appcolors.buttonColor : _T.surface,
            border: Border.all(
                color: active ? Appcolors.buttonColor : _T.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: w600_12Poppins(
                  color: active ? Colors.white : _T.ink2,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  count!.toString().padLeft(2, '0'),
                  style: w700_10Poppins(
                    color: active
                        ? Colors.white.withOpacity(0.72)
                        : _T.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Responsive card grid ──────────────────────────────────────────────────
/// Lays [children] out in `columns` equal-width columns. Cards in the same row
/// are stretched to a common height so the row reads as one band; with a single
/// column this degrades to a plain vertical list.
class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (int start = 0; start < children.length; start += columns) {
      final slice = children.sublist(
        start,
        (start + columns).clamp(0, children.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(
                  child: i < slice.length ? slice[i] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }
}

// ─── Structure card ────────────────────────────────────────────────────────
class _StructureCard extends StatelessWidget {
  const _StructureCard({
    required this.structure,
    required this.downloadState,
    required this.showEditActions,
    required this.showTestingButton,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onStartTesting,
    required this.onDownload,
  });

  final Datum structure;
  final ReportDownloadState downloadState;
  final bool showEditActions;
  final bool showTestingButton;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStartTesting;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final code = structure.structuralIdentityNumber;
    final prefix = code.length > 4 ? code.substring(0, 4) : code;
    final rest = code.length > 4 ? code.substring(4) : '';
    final typeShort = _shortType(structure);
    final typeLabel = _typeLabel(structure);
    final location = _locationLabel(structure);
    final floors = structure.dimensions.floors;
    final dateStr = _formatDate(structure.timestamps.lastUpdatedDate);
    final agoStr = _timeAgo(structure.timestamps.lastUpdatedDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.line),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP: icon + code/meta + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardIconTile(typeShort: typeShort),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CodeText(prefix: prefix, rest: rest),
                        const SizedBox(height: 4),
                        _MetaLine(typeLabel: typeLabel, location: location),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: structure.status),
                ],
              ),
              const SizedBox(height: 12),
              const _DashedDivider(),
              const SizedBox(height: 10),

              // BOTTOM: facts + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (floors != null && floors > 0)
                          _Fact(
                            icon: Icons.apartment_rounded,
                            label:
                                '$floors ${floors == 1 ? "floor" : "floors"}',
                            emphasize: true,
                          ),
                        _Fact(
                          icon: Icons.calendar_today_rounded,
                          label: dateStr,
                          emphasize: true,
                        ),
                        _Fact(
                          icon: Icons.access_time_rounded,
                          label: agoStr,
                          emphasize: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CardActions(
                    isDownloading: downloadState.isDownloading,
                    onDownload: onDownload,
                    showEditActions: showEditActions,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    showTestingButton: showTestingButton,
                    onStartTesting: onStartTesting,
                  ),
                ],
              ),

              // Download progress
              if (downloadState.isDownloading) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: downloadState.progress,
                          minHeight: 4,
                          backgroundColor: _T.line2,
                          color: Appcolors.buttonColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _downloadLabel(downloadState),
                      style: w500_12Poppins(color: _T.ink2),
                    ),
                  ],
                ),
              ],

              // Download error
              if (!downloadState.isDownloading &&
                  (downloadState.errorMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _T.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: _T.dangerFg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          downloadState.errorMessage!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: w500_12Poppins(color: _T.dangerFg),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _locationLabel(Datum s) {
    final parts = <String>[
      if (s.location.cityName.trim().isNotEmpty) s.location.cityName.trim(),
      if (s.location.stateCode.trim().isNotEmpty) s.location.stateCode.trim(),
    ];
    return parts.join(', ');
  }

  static String _typeLabel(Datum s) {
    final raw = s.typeOfStructure.trim();
    if (raw.isEmpty) return 'Structure';
    return raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
  }

  static String _shortType(Datum s) {
    final raw = s.typeOfStructure.trim();
    if (raw.isEmpty) return 'S';
    return raw.substring(0, 1).toUpperCase();
  }

  static String _downloadLabel(ReportDownloadState state) {
    final progress = state.progress;
    if (progress == null || progress <= 0) {
      return 'Downloading…';
    }
    return '${(progress * 100).round()}%';
  }
}

class _CardIconTile extends StatelessWidget {
  const _CardIconTile({required this.typeShort});
  final String typeShort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _T.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.apartment_rounded,
                color: Appcolors.buttonColor, size: 20),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _T.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _T.primaryTint2, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                typeShort,
                style: w700_10Poppins(color: Appcolors.buttonColor)
                    .copyWith(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeText extends StatelessWidget {
  const _CodeText({required this.prefix, required this.rest});
  final String prefix;
  final String rest;

  @override
  Widget build(BuildContext context) {
    // Poppins with weight contrast — reads as an identifier without needing
    // a mono font, matches the rest of the app's typography.
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: w500_15Poppins(color: _T.muted)
                .copyWith(letterSpacing: -0.2, height: 1.2),
          ),
          if (rest.isNotEmpty)
            TextSpan(
              text: rest,
              style: w700_15Poppins(color: _T.ink)
                  .copyWith(letterSpacing: -0.2, height: 1.2),
            ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.typeLabel, required this.location});
  final String typeLabel;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          typeLabel.toUpperCase(),
          style: w700_10Poppins(color: _T.muted)
              .copyWith(letterSpacing: 0.4),
        ),
        if (location.isNotEmpty) ...[
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: _T.muted2,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            location,
            style: w500_12Poppins(color: _T.ink2),
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: palette.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _prettyStatus(status),
            style: w600_11Poppins(color: palette.fg),
          ),
        ],
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

_StatusPalette _statusPalette(String status) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return const _StatusPalette(_T.amberBg, _T.amberFg);
    case 'under_testing':
    case 'in_testing':
      return const _StatusPalette(_T.infoBg, _T.infoFg);
    case 'tested':
    case 'validated':
    case 'approved':
    case 'completed':
      return const _StatusPalette(_T.successBg, _T.successFg);
    case 'rejected':
      return const _StatusPalette(_T.dangerBg, _T.dangerFg);
    default:
      return const _StatusPalette(_T.slateBg, _T.slateFg);
  }
}

String _prettyStatus(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Draft';
  return trimmed
      .split('_')
      .map((p) =>
          p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}

/// Painted rather than built from a `LayoutBuilder`, because the cards sit
/// inside an `IntrinsicHeight` row on tablets and `LayoutBuilder` cannot report
/// intrinsic dimensions.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  static const double _dash = 4;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _T.line
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += _dash + _gap) {
      final end = (x + _dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, 0.5), Offset(end, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.emphasize,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _T.muted),
        const SizedBox(width: 5),
        Text(
          label,
          style: emphasize
              ? w600_12Poppins(color: _T.ink2)
              : w500_12Poppins(color: _T.muted),
        ),
      ],
    );
  }
}

// ─── Card actions ──────────────────────────────────────────────────────────
class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.isDownloading,
    required this.onDownload,
    required this.showEditActions,
    required this.onEdit,
    required this.onDelete,
    required this.showTestingButton,
    required this.onStartTesting,
  });

  final bool isDownloading;
  final VoidCallback onDownload;
  final bool showEditActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showTestingButton;
  final VoidCallback onStartTesting;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: isDownloading ? null : Icons.download_rounded,
          tooltip: 'Download',
          onTap: isDownloading ? null : onDownload,
          child: isDownloading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Appcolors.buttonColor,
                  ),
                )
              : null,
        ),
        if (showEditActions) ...[
          _IconAction(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onTap: onEdit,
          ),
          _IconAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete',
            onTap: onDelete,
            danger: true,
          ),
        ],
        if (showTestingButton) ...[
          const SizedBox(width: 6),
          _TestButton(onTap: onStartTesting),
        ],
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
    this.child,
  });

  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final baseColor = danger ? _T.dangerFg : _T.muted;
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
            alignment: Alignment.center,
            child: child ?? Icon(icon, size: 15, color: baseColor),
          ),
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Appcolors.buttonColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.science_outlined,
                  size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text('Test', style: w600_12Poppins(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pagination bar ────────────────────────────────────────────────────────
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
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageNavButton(
            icon: Icons.arrow_back_rounded,
            label: 'Previous',
            enabled: hasPrevPage && !isLoading,
            onTap: onPrevious,
          ),
          Text('Page $currentPage of $totalPages',
              style: w600_12Poppins(color: _T.ink2)),
          _PageNavButton(
            icon: Icons.arrow_forward_rounded,
            label: 'Next',
            enabled: hasNextPage && !isLoading,
            onTap: onNext,
            trailing: true,
          ),
        ],
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? _T.ink : _T.muted2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!trailing) Icon(icon, size: 14, color: fg),
              if (!trailing) const SizedBox(width: 6),
              Text(label, style: w600_12Poppins(color: fg)),
              if (trailing) const SizedBox(width: 6),
              if (trailing) Icon(icon, size: 14, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'END OF LIST · ${count.toString().padLeft(2, '0')} ${count == 1 ? "STRUCTURE" : "STRUCTURES"}',
        style: w700_10Poppins(color: _T.muted).copyWith(letterSpacing: 1.4),
      ),
    );
  }
}

// ─── Download-format dialog ────────────────────────────────────────────────
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
    final maxWidth =
        mediaQuery.size.width >= 700 ? 400.0 : mediaQuery.size.width * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: mediaQuery.size.height * 0.55,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.line),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download report', style: w600_16Poppins(color: _T.ink)),
                const SizedBox(height: 4),
                Text('Choose a format for this report.',
                    style: w400_12Poppins(color: _T.muted)),
                const SizedBox(height: 14),
                _DownloadFormatTile(
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: _T.dangerFg,
                  title: 'Download as PDF',
                  subtitle: 'Portable document format',
                  isDisabled: isDownloading,
                  onTap: () => onFormatSelected(ReportDownloadFormat.pdf),
                ),
                const SizedBox(height: 8),
                _DownloadFormatTile(
                  icon: Icons.description_rounded,
                  iconColor: _T.infoFg,
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDisabled ? _T.line2 : _T.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: w600_13Poppins(color: _T.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: w400_11Poppins(color: _T.muted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: _T.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date/time helpers ─────────────────────────────────────────────────────
String _formatDate(DateTime date) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final m = monthNames[date.month - 1];
  final d = date.day.toString().padLeft(2, '0');
  return '$m $d, ${date.year}';
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}