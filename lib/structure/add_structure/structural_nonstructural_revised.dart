import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/nonstructural_rating_revised.dart';
import 'package:sams_engineering_console/structure/add_structure/structural_rating_revised.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/wizard_scaffold.dart';
import 'package:sams_engineering_console/utils/module_header.dart';

class PendingRatingSubmission {
  const PendingRatingSubmission({
    required this.key,
    required this.entityId,
    required this.isFloor,
    required this.structuralRatings,
    required this.nonStructuralRatings,
    required this.testingRequired,
  });

  final String key;
  final String entityId;
  final bool isFloor;
  final Map<String, List<RatingItem>> structuralRatings;
  final Map<String, List<RatingItem>> nonStructuralRatings;
  final bool testingRequired;
}

List<PendingRatingSubmission> collectPendingRatingSubmissions({
  required Map<String, Map<String, List<RatingItem>>> savedStructuralRatings,
  required Map<String, Map<String, List<RatingItem>>> savedNonStructuralRatings,
  required Map<String, bool> savedStructuralTestingRequired,
}) {
  final pendingKeys = <String>{
    ...savedStructuralRatings.keys,
    ...savedNonStructuralRatings.keys,
  };

  return pendingKeys
      .where((key) => key.startsWith('flat_') || key.startsWith('floor_'))
      .map((key) {
        final isFloor = key.startsWith('floor_');
        final entityId = key.substring(isFloor ? 6 : 5);

        return PendingRatingSubmission(
          key: key,
          entityId: entityId,
          isFloor: isFloor,
          structuralRatings: Map<String, List<RatingItem>>.from(
            savedStructuralRatings[key] ?? const <String, List<RatingItem>>{},
          ),
          nonStructuralRatings: Map<String, List<RatingItem>>.from(
            savedNonStructuralRatings[key] ??
                const <String, List<RatingItem>>{},
          ),
          testingRequired: savedStructuralTestingRequired[key] ?? false,
        );
      })
      .toList();
}

class StructuralNonstructuralrating extends StatefulWidget {
  // Optional parameters for flat-based navigation
  final List<String>? flatNumbers;
  final Map<String, Map<String, String>>? flatInfoByNumber;

  // Optional parameters for floor-based navigation
  final List<String>? floorNumbers;
  final Map<String, Map<String, String>>? floorInfoByNumber;

  // Navigation type: 'flats_only', 'floors_only', or 'both'
  final String? navigationType;

  final String structureId;

  // Structure type information for determining navigation
  final String? structureType;
  final String? commercialType;
  final String selectedStructureSubType;

  const StructuralNonstructuralrating({
    super.key,
    this.flatNumbers,
    this.flatInfoByNumber,
    this.floorNumbers,
    this.floorInfoByNumber,
    this.navigationType,
    required this.structureId,
    required this.selectedStructureSubType,
    this.structureType,
    this.commercialType,
  });

  /// Static utility method to determine navigation type based on structure type
  /// Can be used by other files to determine what data to prepare
  /// LOGIC: If both flats and floors exist → rate both, If only floors → rate floors only, If only flats → rate flats only
  static String determineNavigationType({
    required String? structureType,
    String? commercialType,
    List<String>? availableFloorNumbers,
    List<String>? availableFlatNumbers,
  }) {
    print("🗂️ [Static] Determining navigation type:");
    print("  Available Flats: ${availableFlatNumbers?.length ?? 0}");
    print("  Available Floors: ${availableFloorNumbers?.length ?? 0}");

    // PRIORITY 1: Check if both flats and floors exist
    // If there are both, allow rating both flats and floors
    bool hasFlats =
        availableFlatNumbers != null && availableFlatNumbers.isNotEmpty;
    bool hasFloors =
        availableFloorNumbers != null && availableFloorNumbers.isNotEmpty;

    if (hasFlats && hasFloors) {
      print(
        "  → Both flats and floors exist: Using 'both' (rate flats and floors)",
      );
      return 'both';
    }

    // PRIORITY 2: If only flats exist, use flat-based rating
    if (hasFlats) {
      print("  → Only flats exist: Using flats_only (flat-wise ratings)");
      return 'flats_only';
    }

    // PRIORITY 3: If only floors exist, use floor-based rating
    if (hasFloors) {
      print("  → Only floors exist: Using floors_only (floor-wise ratings)");
      return 'floors_only';
    }

    // FALLBACK: If neither flats nor floors exist, default to flats_only
    print("  → No flats or floors available: Defaulting to flats_only");
    return 'flats_only';
  }

  @override
  State<StructuralNonstructuralrating> createState() =>
      _StructuralNonstructuralratingState();
}

class _StructuralNonstructuralratingState
    extends State<StructuralNonstructuralrating>
    with TickerProviderStateMixin {
  /// Guards the submit button while a submission is in flight.
  bool _isSubmitting = false;

  late final TabController _tabController;
  late GetstructureProvider getstructureProvider;

  // For flat-based navigation
  Map<String, List<String>> flatsByFloor = {};
  Map<String, List<String>> selectedFlatsByFloor = {};

  // For floor-based navigation
  Map<String, List<String>> selectedFloors = {};

  // Navigation mode
  String currentNavigationType = 'flats_only'; // Default fallback

  // For 'both' mode: track whether rating flats or floors
  String ratingMode = 'flats'; // 'flats' or 'floors'

  // Track current selection
  String? currentFloorNumber;
  String? currentFlatNumber;
  String? currentFloorId;
  String? currentFlatId;

  // ==========================================
  // UPDATED: Store ratings separately for structural and non-structural
  // ==========================================
  // Key format: "flat_{flatId}" or "floor_{floorId}"
  Map<String, Map<String, List<RatingItem>>> savedStructuralRatings = {};
  Map<String, Map<String, List<RatingItem>>> savedNonStructuralRatings = {};
  Map<String, bool> savedStructuralTestingRequired = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );

    // Determine navigation mode from passed parameter or infer from data
    if (widget.navigationType != null) {
      currentNavigationType = widget.navigationType!;
    } else {
      currentNavigationType = _determineNavigationTypeFromStructure();
    }

    print("Navigation mode: $currentNavigationType");

    // Initialize based on navigation type
    if (currentNavigationType == 'flats_only') {
      print("Flat numbers passed to widget: ${widget.flatNumbers}");
      _groupFlatsByFloor();
    } else if (currentNavigationType == 'floors_only') {
      print("Floor numbers passed to widget: ${widget.floorNumbers}");
      _initializeFloorNavigation();
    } else if (currentNavigationType == 'both') {
      print("Both flats and floors available for rating");
      print("Flat numbers: ${widget.flatNumbers}");
      print("Floor numbers: ${widget.floorNumbers}");
      _groupFlatsByFloor();
      _initializeFloorNavigation();
    }
  }

  /// Determines navigation type based on available flats and floors
  /// LOGIC: If both flats and floors exist → rate both, If only floors → rate floors only, If only flats → rate flats only
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _determineNavigationTypeFromStructure() {
    print("🗂️ Determining navigation type:");
    print("  Available Flats: ${widget.flatNumbers?.length ?? 0}");
    print("  Available Floors: ${widget.floorNumbers?.length ?? 0}");

    // PRIORITY 1: Check if both flats and floors exist
    // If there are both, allow rating both flats and floors
    bool hasFlats =
        widget.flatNumbers != null && widget.flatNumbers!.isNotEmpty;
    bool hasFloors =
        widget.floorNumbers != null && widget.floorNumbers!.isNotEmpty;

    if (hasFlats && hasFloors) {
      print(
        "  → Both flats and floors exist: Using 'both' (rate flats and floors)",
      );
      return 'both';
    }

    // PRIORITY 2: If only flats exist, use flat-based rating
    if (hasFlats) {
      print("  → Only flats exist: Using flats_only (flat-wise ratings)");
      return 'flats_only';
    }

    // PRIORITY 3: If only floors exist, use floor-based rating
    if (hasFloors) {
      print("  → Only floors exist: Using floors_only (floor-wise ratings)");
      return 'floors_only';
    }

    // FALLBACK: If neither flats nor floors exist, default to flats_only
    print("  → No flats or floors available: Defaulting to flats_only");
    return 'flats_only';
  }

  void _groupFlatsByFloor() {
    flatsByFloor.clear();
    selectedFlatsByFloor.clear();

    if (widget.flatNumbers != null && widget.flatInfoByNumber != null) {
      for (String flatNumber in widget.flatNumbers!) {
        final flatInfo = widget.flatInfoByNumber![flatNumber];
        if (flatInfo != null && flatInfo['floorNumber'] != null) {
          final floorNum = flatInfo['floorNumber']!;
          if (!flatsByFloor.containsKey(floorNum)) {
            flatsByFloor[floorNum] = [];
            selectedFlatsByFloor[floorNum] = [];
          }
          flatsByFloor[floorNum]!.add(flatNumber);
        }
      }
    }

    setState(() {});
  }

  void _initializeFloorNavigation() {
    selectedFloors.clear();
    if (widget.floorNumbers != null) {
      for (String floorNumber in widget.floorNumbers!) {
        selectedFloors[floorNumber] = [];
      }
    }
    setState(() {});
  }

  /// Get list of floors that DON'T have any flats
  /// These are the only floors that should be available for floor-level rating
  List<String> _getFloorsWithoutFlats() {
    if (widget.floorNumbers == null) return [];

    List<String> floorsWithoutFlats = [];

    for (String floorNumber in widget.floorNumbers!) {
      // Check if this floor has any flats
      bool hasFlats =
          flatsByFloor.containsKey(floorNumber) &&
          flatsByFloor[floorNumber]!.isNotEmpty;

      if (!hasFlats) {
        floorsWithoutFlats.add(floorNumber);
      }
    }

    print(
      "🏢 Floors without flats (available for floor rating): $floorsWithoutFlats",
    );
    return floorsWithoutFlats;
  }

  // ==========================================
  // UPDATED: Save and load both structural and non-structural data
  // ==========================================
  void _selectFlat(String floorNum, String flatNum) {
    final provider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );

    // Save current ratings before switching (if something is currently selected)
    _persistCurrentSelection(provider);

    setState(() {
      final flatInfo = widget.flatInfoByNumber![flatNum];
      if (flatInfo != null) {
        currentFloorNumber = floorNum;
        currentFlatNumber = flatNum;
        currentFloorId = flatInfo['floorId'];
        currentFlatId = flatInfo['flatId'];

        // Load saved ratings for the newly selected flat (if any)
        String newKey = 'flat_$currentFlatId';

        // Clear both maps
        provider.structuralRatingMap.clear();
        provider.nonStructuralRatingMap.clear();

        // Load structural ratings if saved
        if (savedStructuralRatings.containsKey(newKey)) {
          provider.structuralRatingMap.addAll(
            Map<String, List<RatingItem>>.from(savedStructuralRatings[newKey]!),
          );
          print(
            "📂 Loaded saved structural ratings for flat $flatNum: ${provider.structuralRatingMap.keys}",
          );
        }

        // Load non-structural ratings if saved
        if (savedNonStructuralRatings.containsKey(newKey)) {
          provider.nonStructuralRatingMap.addAll(
            Map<String, List<RatingItem>>.from(
              savedNonStructuralRatings[newKey]!,
            ),
          );
          print(
            "📂 Loaded saved non-structural ratings for flat $flatNum: ${provider.nonStructuralRatingMap.keys}",
          );
        }

        if (!savedStructuralRatings.containsKey(newKey) &&
            !savedNonStructuralRatings.containsKey(newKey)) {
          print("📝 No saved ratings for flat $flatNum, starting fresh");
        }

        provider.notifyListeners();
      }
    });
  }

  void _selectFloor(String floorNumber) {
    final provider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );

    // Save current ratings before switching (if something is currently selected)
    _persistCurrentSelection(provider);

    setState(() {
      final floorInfo = widget.floorInfoByNumber![floorNumber];
      if (floorInfo != null) {
        currentFloorNumber = floorNumber;
        currentFlatNumber = null;
        currentFloorId = floorInfo['floorId'];
        currentFlatId = null;

        // Load saved ratings for the newly selected floor (if any)
        String newKey = 'floor_$currentFloorId';

        // Clear both maps
        provider.structuralRatingMap.clear();
        provider.nonStructuralRatingMap.clear();

        // Load structural ratings if saved
        if (savedStructuralRatings.containsKey(newKey)) {
          provider.structuralRatingMap.addAll(
            Map<String, List<RatingItem>>.from(savedStructuralRatings[newKey]!),
          );
          print(
            "📂 Loaded saved structural ratings for floor $floorNumber: ${provider.structuralRatingMap.keys}",
          );
        }

        // Load non-structural ratings if saved
        if (savedNonStructuralRatings.containsKey(newKey)) {
          provider.nonStructuralRatingMap.addAll(
            Map<String, List<RatingItem>>.from(
              savedNonStructuralRatings[newKey]!,
            ),
          );
          print(
            "📂 Loaded saved non-structural ratings for floor $floorNumber: ${provider.nonStructuralRatingMap.keys}",
          );
        }

        if (!savedStructuralRatings.containsKey(newKey) &&
            !savedNonStructuralRatings.containsKey(newKey)) {
          print("📝 No saved ratings for floor $floorNumber, starting fresh");
        }

        provider.notifyListeners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 42.w,
        leading: const ModuleBackArrow(),
        titleSpacing: 2.w,
        title: ModuleHeaderTitle(
          title: 'Structure Rating',
          subtitle: currentNavigationType == 'both'
              ? ratingMode == 'flats'
                    ? 'Rating individual flats'
                    : 'Rating entire floors'
              : currentNavigationType == 'flats_only'
              ? 'Rating individual flats'
              : 'Rating entire floors',
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Consumer<AddstructureProvider>(
        builder: (context, addStructureProvider, child) {
          return WizardActionBar(
            nextLabel: "Submit Inspection",
            isBusy: _isSubmitting,
            onNext: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    try {
                      final submitted = await _submitPendingRatings();
                      if (!submitted) return;
                      await addStructureProvider.submitStructure(
                        context,
                        widget.structureId,
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (currentNavigationType == 'flats_only') {
      return _buildFlatBasedUI();
    } else if (currentNavigationType == 'floors_only') {
      return _buildFloorBasedUI();
    } else if (currentNavigationType == 'both') {
      return _buildBothModesUI();
    } else {
      return _buildFlatBasedUI(); // Fallback
    }
  }

  Widget _buildFlatBasedUI() {
    if (flatsByFloor.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No flats available',
              style: w500_16Poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: flatsByFloor.keys.length,
      itemBuilder: (context, index) {
        final floorNum = flatsByFloor.keys.elementAt(index);
        final flats = flatsByFloor[floorNum]!;

        // Count rated flats - check if either structural OR non-structural ratings exist
        int ratedCount = flats.where((flatNum) {
          final flatInfo = widget.flatInfoByNumber?[flatNum];
          final flatId = flatInfo?['flatId'];
          if (flatId == null) return false;
          String key = 'flat_$flatId';
          return savedStructuralRatings.containsKey(key) ||
              savedNonStructuralRatings.containsKey(key);
        }).length;

        return _buildFloorSection(floorNum, flats, ratedCount);
      },
    );
  }

  Widget _buildFloorSection(
    String floorNumber,
    List<String> flats,
    int ratedCount,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor header
          Row(
            children: [
              Icon(Icons.apartment, color: Appcolors.buttonColor, size: 24),
              SizedBox(width: 8),
              Text(
                "Floor $floorNumber",
                style: w500_18Poppins(color: Appcolors.buttonColor),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ratedCount == flats.length && ratedCount > 0
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ratedCount == flats.length && ratedCount > 0
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  "$ratedCount/${flats.length} rated",
                  style: w400_12Poppins(
                    color: ratedCount == flats.length && ratedCount > 0
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1),
          SizedBox(height: 12),

          // Flats selection grid
          Text("Select a flat to rate:", style: w500_14Poppins()),
          SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: flats.map((flatNum) {
              final flatInfo = widget.flatInfoByNumber![flatNum];
              final flatId = flatInfo?['flatId'];
              // Check if either structural OR non-structural ratings exist
              bool hasRatings = false;
              if (flatId != null) {
                String key = 'flat_$flatId';
                hasRatings =
                    savedStructuralRatings.containsKey(key) ||
                    savedNonStructuralRatings.containsKey(key);
              }
              final isSelected =
                  currentFlatNumber == flatNum &&
                  currentFloorNumber == floorNumber;

              return InkWell(
                onTap: () => _selectFlat(floorNumber, flatNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Appcolors.buttonColor.withOpacity(0.1)
                        : hasRatings
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected
                          ? Appcolors.buttonColor
                          : hasRatings
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRatings ? Icons.check_circle : Icons.home,
                        color: isSelected
                            ? Appcolors.buttonColor
                            : hasRatings
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Flat $flatNum",
                        style: w400_14Poppins(
                          color: isSelected
                              ? Appcolors.buttonColor
                              : hasRatings
                              ? Colors.green.shade700
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Show rating section for selected flat
          if (currentFloorNumber == floorNumber &&
              currentFlatNumber != null) ...[
            SizedBox(height: 16),
            Divider(height: 1),
            SizedBox(height: 16),
            Builder(
              builder: (context) {
                // Check if ratings are saved for this flat
                bool hasSavedRatings = false;
                if (currentFlatId != null) {
                  String key = 'flat_$currentFlatId';
                  hasSavedRatings =
                      savedStructuralRatings.containsKey(key) ||
                      savedNonStructuralRatings.containsKey(key);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rate_review,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Rating Flat $currentFlatNumber",
                        style: w500_14Poppins(color: Colors.blue.shade700),
                      ),
                      Spacer(),
                      if (hasSavedRatings)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Saved',
                            style: w400_10Poppins(color: Colors.green.shade700),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            SizedBox(height: 500.h, child: _buildRatingTabs()),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorBasedUI() {
    // Get the appropriate floor list based on navigation type
    List<String> availableFloors = currentNavigationType == 'both'
        ? _getFloorsWithoutFlats() // Only floors without flats in 'both' mode
        : (widget.floorNumbers ?? []); // All floors in 'floors_only' mode

    if (availableFloors.isEmpty) {
      String message = currentNavigationType == 'both'
          ? 'All floors have flats. Please rate individual flats instead.'
          : 'No floors available';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              message,
              style: w500_16Poppins(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (currentNavigationType == 'both') ...[
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    ratingMode = 'flats';
                  });
                },
                icon: Icon(Icons.arrow_forward),
                label: Text('Go to Flat Rating'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: availableFloors.length,
      itemBuilder: (context, index) {
        final floorNum = availableFloors[index];
        final floorInfo = widget.floorInfoByNumber?[floorNum];
        final floorId = floorInfo?['floorId'];
        // Check if either structural OR non-structural ratings exist
        bool hasRatings = false;
        if (floorId != null) {
          String key = 'floor_$floorId';
          hasRatings =
              savedStructuralRatings.containsKey(key) ||
              savedNonStructuralRatings.containsKey(key);
        }
        final isSelected = currentFloorNumber == floorNum;

        return _buildFloorCard(floorNum, hasRatings, isSelected);
      },
    );
  }

  Widget _buildFloorCard(String floorNumber, bool hasRatings, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? Appcolors.buttonColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor header - clickable
          InkWell(
            onTap: () => _selectFloor(floorNumber),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Appcolors.buttonColor.withOpacity(0.1)
                    : hasRatings
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.layers,
                    color: isSelected
                        ? Appcolors.buttonColor
                        : hasRatings
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Floor $floorNumber",
                          style: w500_18Poppins(
                            color: isSelected
                                ? Appcolors.buttonColor
                                : hasRatings
                                ? Colors.green.shade700
                                : Colors.black87,
                          ),
                        ),
                        if (currentNavigationType == 'both')
                          Text(
                            "No flats on this floor",
                            style: w400_12Poppins(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  if (hasRatings)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Rated',
                            style: w400_12Poppins(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    )
                  else if (!isSelected)
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          // Show rating section for selected floor
          if (isSelected && currentFloorId != null) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rate_review,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Rating Floor $floorNumber",
                          style: w500_14Poppins(color: Colors.blue.shade700),
                        ),
                        Spacer(),
                        if (hasRatings)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Saved',
                              style: w400_10Poppins(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(height: 450.h, child: _buildRatingTabs()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBothModesUI() {
    return Column(
      children: [
        // Mode selector (Flats or Floors)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: Appcolors.buttonColor, size: 20),
                  SizedBox(width: 8),
                  Text('Rating Mode:', style: w600_16Poppins()),
                ],
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        'flats',
                        'Individual Flats',
                        Icons.home,
                        'Rate each flat separately',
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: _buildModeButton(
                        'floors',
                        'Entire Floors',
                        Icons.layers,
                        'Rate whole floors',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Show appropriate UI based on selected mode
        Expanded(
          child: ratingMode == 'flats'
              ? _buildFlatBasedUI()
              : _buildFloorBasedUI(),
        ),
      ],
    );
  }

  Widget _buildModeButton(
    String mode,
    String label,
    IconData icon,
    String description,
  ) {
    final isSelected = ratingMode == mode;

    return InkWell(
      onTap: () {
        if (ratingMode == mode) return; // Already selected

        final provider = Provider.of<AddRatingsStructureProvider>(
          context,
          listen: false,
        );

        // Save current ratings before switching modes (save BOTH maps)
        if (currentFlatId != null) {
          String currentKey = 'flat_$currentFlatId';
          savedStructuralRatings[currentKey] =
              Map<String, List<RatingItem>>.from(provider.structuralRatingMap);
          savedNonStructuralRatings[currentKey] =
              Map<String, List<RatingItem>>.from(
                provider.nonStructuralRatingMap,
              );
          print("💾 Saved ratings before mode switch: $currentKey");
        } else if (currentFloorId != null) {
          String currentKey = 'floor_$currentFloorId';
          savedStructuralRatings[currentKey] =
              Map<String, List<RatingItem>>.from(provider.structuralRatingMap);
          savedNonStructuralRatings[currentKey] =
              Map<String, List<RatingItem>>.from(
                provider.nonStructuralRatingMap,
              );
          print("💾 Saved ratings before mode switch: $currentKey");
        }

        setState(() {
          ratingMode = mode;
          // Clear current selection when switching modes
          currentFloorNumber = null;
          currentFlatNumber = null;
          currentFloorId = null;
          currentFlatId = null;

          // Clear BOTH provider rating maps (user will select new flat/floor)
          provider.structuralRatingMap.clear();
          provider.nonStructuralRatingMap.clear();
          provider.notifyListeners();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Appcolors.buttonColor : Colors.grey.shade600,
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: isSelected
                  ? w600_13Poppins(color: Appcolors.buttonColor)
                  : w400_13Poppins(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingTabs() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(4),
          child: ButtonsTabBar(
            controller: _tabController,
            unselectedBackgroundColor: Colors.transparent,
            unselectedBorderColor: Colors.transparent,
            backgroundColor: Colors.white,
            height: 40,
            borderWidth: 0,
            borderColor: Colors.transparent,
            radius: 10,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            labelStyle: w600_14Poppins(color: Colors.black87),
            unselectedLabelStyle: w400_14Poppins(color: Colors.black54),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.foundation, size: 16),
                    SizedBox(width: 6),
                    Text("Structural"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_repair_service, size: 16),
                    SizedBox(width: 6),
                    Text("Non-Structural"),
                  ],
                ),
              ),
              // Tab(
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.table_chart, size: 16),
              //       SizedBox(width: 6),
              //       Text("Quantification"),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // Physics locked so accidental swipe doesn't switch tabs while
            // scrolling within a tab's content.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ValueKey forces remount only when flat/floor actually changes,
              // not on every parent rebuild or tab switch.
              StructuralRating(
                key: ValueKey('structural_${currentFloorId}_$currentFlatId'),
                structureId: widget.structureId,
                flatId: currentFlatId,
                floorId: currentFloorId,
                selectedStructureSubType: widget.selectedStructureSubType,
                initialTestingRequired:
                    savedStructuralTestingRequired[_currentSelectionKey] ??
                    false,
                onTestingRequiredChanged: (value) {
                  final selectionKey = _currentSelectionKey;
                  if (selectionKey == null) return;
                  savedStructuralTestingRequired[selectionKey] = value;
                },
              ),
              NonStructuralRating(
                key: ValueKey('nonstructural_${currentFloorId}_$currentFlatId'),
                structureId: widget.structureId,
                flatId: currentFlatId,
                floorId: currentFloorId,
                selectedStructureSubType: widget.selectedStructureSubType,
              ),
              // QuantificationScreen(
              //   key: ValueKey('quantification_${currentFloorId}_$currentFlatId'),
              //   structureId: widget.structureId,
              //   flatId: currentFlatId,
              //   floorId: currentFloorId,
              // ),
            ],
          ),
        ),
      ],
    );
  }

  String? get _currentSelectionKey {
    if (currentFlatId != null) return 'flat_$currentFlatId';
    if (currentFloorId != null) return 'floor_$currentFloorId';
    return null;
  }

  Map<String, List<RatingItem>> _cloneRatings(
    Map<String, List<RatingItem>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, List<RatingItem>.from(value)),
    );
  }

  void _replaceProviderRatings(
    AddRatingsStructureProvider provider, {
    required Map<String, List<RatingItem>> structuralRatings,
    required Map<String, List<RatingItem>> nonStructuralRatings,
  }) {
    provider.structuralRatingMap
      ..clear()
      ..addAll(_cloneRatings(structuralRatings));
    provider.nonStructuralRatingMap
      ..clear()
      ..addAll(_cloneRatings(nonStructuralRatings));
    provider.notifyListeners();
  }

  void _persistCurrentSelection(AddRatingsStructureProvider provider) {
    final currentKey = _currentSelectionKey;
    if (currentKey == null) return;

    final structuralCopy = _cloneRatings(provider.structuralRatingMap);
    final nonStructuralCopy = _cloneRatings(provider.nonStructuralRatingMap);

    if (structuralCopy.isEmpty) {
      savedStructuralRatings.remove(currentKey);
      savedStructuralTestingRequired.remove(currentKey);
    } else {
      savedStructuralRatings[currentKey] = structuralCopy;
      savedStructuralTestingRequired[currentKey] ??= false;
    }

    if (nonStructuralCopy.isEmpty) {
      savedNonStructuralRatings.remove(currentKey);
    } else {
      savedNonStructuralRatings[currentKey] = nonStructuralCopy;
    }
  }

  Future<bool> _submitPendingRatings() async {
    final provider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );

    _persistCurrentSelection(provider);

    final originalStructuralRatings = _cloneRatings(
      provider.structuralRatingMap,
    );
    final originalNonStructuralRatings = _cloneRatings(
      provider.nonStructuralRatingMap,
    );
    final pendingSubmissions = collectPendingRatingSubmissions(
      savedStructuralRatings: savedStructuralRatings,
      savedNonStructuralRatings: savedNonStructuralRatings,
      savedStructuralTestingRequired: savedStructuralTestingRequired,
    );

    for (final submission in pendingSubmissions) {
      final structuralError = validateRatingsForSubmission(
        submission.structuralRatings,
      );
      final nonStructuralError = validateRatingsForSubmission(
        submission.nonStructuralRatings,
      );
      final validationError = structuralError ?? nonStructuralError;
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError)),
        );
        return false;
      }
    }

    try {
      for (final submission in pendingSubmissions) {
        if (submission.structuralRatings.isNotEmpty) {
          _replaceProviderRatings(
            provider,
            structuralRatings: submission.structuralRatings,
            nonStructuralRatings: const <String, List<RatingItem>>{},
          );

          if (submission.isFloor) {
            await provider.submitAllStructuralDataForFloor(
              widget.structureId,
              submission.entityId,
              context,
              structureSubType: widget.selectedStructureSubType,
              testingRequired: submission.testingRequired,
            );
          } else {
            await provider.submitAllStructuralData(
              widget.structureId,
              submission.entityId,
              context,
              structureSubType: widget.selectedStructureSubType,
              testingRequired: submission.testingRequired,
            );
          }
        }

        if (submission.nonStructuralRatings.isNotEmpty) {
          _replaceProviderRatings(
            provider,
            structuralRatings: const <String, List<RatingItem>>{},
            nonStructuralRatings: submission.nonStructuralRatings,
          );

          if (submission.isFloor) {
            await provider.submitAllNonStructuralDataForFloor(
              widget.structureId,
              submission.entityId,
              context,
              structureSubType: widget.selectedStructureSubType,
            );
          } else {
            await provider.submitAllNonStructuralData(
              widget.structureId,
              submission.entityId,
              context,
              structureSubType: widget.selectedStructureSubType,
            );
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _replaceProviderRatings(
        provider,
        structuralRatings: originalStructuralRatings,
        nonStructuralRatings: originalNonStructuralRatings,
      );
    }
  }
}
