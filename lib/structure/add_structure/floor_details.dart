// ignore_for_file: unnecessary_null_comparison, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sams_engineering_console/models/floor_idby_flatby_strid_model.dart';
import 'package:sams_engineering_console/models/get_floor_bystrid_model.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';
import 'package:sams_engineering_console/utils/radio_group_dropdown.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class FloordetailsWidget extends StatefulWidget {
  final String? initialSelectedFloor;
  final List<String> floorDropdownItems;
  final Function(String)? onFloorChanged;
  final Function(Map<String, dynamic>)? onFloorDataChanged;
  final List<TextEditingController>? flatNumberControllers;
  final TextEditingController? numberOfFlatsController;
  final String structureId;
  final bool isEditMode;
  final String structureType;
  final String commercialType;
  final List<String>? selectedFloorsFromOtherWidgets;

  const FloordetailsWidget({
    super.key,
    this.initialSelectedFloor,
    required this.floorDropdownItems,
    this.flatNumberControllers,
    this.numberOfFlatsController,
    this.onFloorChanged,
    this.onFloorDataChanged,
    required this.structureId,
    this.isEditMode = false,
    required this.structureType,
    required this.commercialType,
    this.selectedFloorsFromOtherWidgets,
  });

  @override
  State<FloordetailsWidget> createState() => FloordetailsWidgetState();
}
// ignore_for_file: invalid_use_of_protected_member

class FloordetailsWidgetState extends State<FloordetailsWidget> {
  List<TextEditingController> flatNumberControllers = [];
  TextEditingController numberOfFlatsController = TextEditingController();
  TextEditingController flatLabelNameController = TextEditingController();
  TextEditingController floorAreaController = TextEditingController();
  TextEditingController floorHeightController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<TextEditingController> flatAreaControllers = [];
  List<TextEditingController> flatOccupancyControllers = [];
  List<TextEditingController> flatTypeControllers = [];
  List<TextEditingController> flatDirectionControllers = [];
  String? parkingFloorTypes;

  // Dropdown selected value lists
  List<String?> flatTypeDropdownValues = [];
  List<String?> flatDirectionDropdownValues = [];
  List<String?> flatOccupancyDropdownValues = [];

  // Dropdown options
  static const List<String> _parkingFloorTypeOptions = [
    "stilt",
    "cellar",
    "sub cellar",
  ];

  static const List<String> flatTypeOptions = [
    '1bhk', '2bhk', '3bhk', '4bhk', '5bhk',
    'studio', 'duplex', 'penthouse', 'shop', 'office'
  ];
  static const List<String> directionOptions = [
    'north', 'south', 'east', 'west',
    'northeast', 'northwest', 'southeast', 'southwest',
  ];
  static const List<String> occupancyOptions = [
    'occupied', 'vacant', 'under_renovation', 'locked',
  ];

  List<String?> flatIds = [];
  List<bool> flatSavingStates = [];

  String? selectedFloor;
  String? selectedFloorType;
  String? currentFloorId;
  bool _isDataLoaded = false;
  bool _isLoadingFloorData = false;
  bool _isLoadingFlatData = false;
  bool _hasTriedToLoadData = false;
  bool _isSaving = false;

  late GetstructureProvider getstructureProvider;
  static String get baseUrl => CommonProvider.baseUrl;

  @override
  void initState() {
    super.initState();
    debugPrint('🗂️ FloordetailsWidget initState');

    _initializeControllers();
    _setupListeners();

    selectedFloor = widget.initialSelectedFloor;

    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );

    if (selectedFloor != null && !_hasTriedToLoadData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFloorData(selectedFloor!);
      });
    }
  }

  @override
  void didUpdateWidget(FloordetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialSelectedFloor != oldWidget.initialSelectedFloor &&
        widget.initialSelectedFloor != null &&
        widget.initialSelectedFloor != selectedFloor) {
      debugPrint(
        '🔄 Floor selection changed from parent: ${widget.initialSelectedFloor}',
      );
      selectedFloor = widget.initialSelectedFloor;
      _hasTriedToLoadData = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFloorData(selectedFloor!);
        }
      });
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing FloordetailsWidget');

    try {
      numberOfFlatsController.removeListener(_onFlatCountChanged);
      flatLabelNameController.removeListener(_notifyDataChanged);
      floorAreaController.removeListener(_notifyDataChanged);
      floorHeightController.removeListener(_notifyDataChanged);
    } catch (e) {
      print('⚠️ Error removing main listeners: $e');
    }

    _disposeControllers();

    if (widget.numberOfFlatsController == null) {
      try {
        numberOfFlatsController.dispose();
      } catch (e) {
        print('⚠️ Error disposing numberOfFlatsController: $e');
      }
    }

    try {
      flatLabelNameController.dispose();
      floorAreaController.dispose();
      floorHeightController.dispose();
    } catch (e) {
      print('⚠️ Error disposing main controllers: $e');
    }

    print('✅ FloordetailsWidget disposed');
    super.dispose();
  }

  // ─── NEW: dropdown helper for flat fields ───────────────────────────────────
  Widget _buildFlatDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return LabeledField(
      label: label,
      isRequired: true,
      child: RadioGroupDropdown<String>(
        options: radioOptionsFromStrings(options, labelBuilder: prettifyOptionLabel),
        value: options.contains(value) ? value : null,
        hintText: "Select ${label.toLowerCase()}",
        sheetTitle: label,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  void _syncControllers(int count) {
    debugPrint('🔄 Syncing controllers for $count flats');

    try {
      void syncControllerList(
        List<TextEditingController> controllers,
        String controllerType,
      ) {
        while (controllers.length > count) {
          final controller = controllers.removeLast();
          controller.removeListener(_notifyDataChanged);
          controller.dispose();
        }
        while (controllers.length < count) {
          final controller = TextEditingController();
          controller.addListener(_notifyDataChanged);
          controllers.add(controller);
        }
      }

      syncControllerList(flatNumberControllers, 'flatNumber');
      syncControllerList(flatAreaControllers, 'flatArea');
      syncControllerList(flatDirectionControllers, 'flatDirection');
      syncControllerList(flatOccupancyControllers, 'flatOccupancy');
      syncControllerList(flatTypeControllers, 'flatType');

      // Sync dropdown value lists
      while (flatTypeDropdownValues.length > count) flatTypeDropdownValues.removeLast();
      while (flatTypeDropdownValues.length < count) flatTypeDropdownValues.add(null);

      while (flatDirectionDropdownValues.length > count) flatDirectionDropdownValues.removeLast();
      while (flatDirectionDropdownValues.length < count) flatDirectionDropdownValues.add(null);

      while (flatOccupancyDropdownValues.length > count) flatOccupancyDropdownValues.removeLast();
      while (flatOccupancyDropdownValues.length < count) flatOccupancyDropdownValues.add(null);

      while (flatIds.length > count) flatIds.removeLast();
      while (flatIds.length < count) flatIds.add(null);

      while (flatSavingStates.length > count) flatSavingStates.removeLast();
      while (flatSavingStates.length < count) flatSavingStates.add(false);

      print('✅ All controllers synced successfully for $count flats');
    } catch (e) {
      print('❌ Error syncing controllers: $e');
      CustomToast.showErrorToast(msg: "Error syncing controllers: $e");
    }
  }

  void _onFlatCountChanged() {
    if (!mounted) return;
    // Industrial structures never have flats
    if (widget.structureType.toLowerCase() == 'industrial') return;

    final countText = numberOfFlatsController.text.trim();
    final count = int.tryParse(countText) ?? 0;

    if (count < 0) return;

    _clearExistingFlatData();

    if (mounted) {
      setState(() {
        _syncControllers(count);
      });
    }

    _notifyDataChanged();
  }

  void _clearExistingFlatData() {
    for (var c in flatAreaControllers) c.clear();
    for (var c in flatOccupancyControllers) c.clear();
    for (var c in flatTypeControllers) c.clear();
    for (var c in flatDirectionControllers) c.clear();

    for (int i = 0; i < flatIds.length; i++) flatIds[i] = null;
    for (int i = 0; i < flatTypeDropdownValues.length; i++) flatTypeDropdownValues[i] = null;
    for (int i = 0; i < flatDirectionDropdownValues.length; i++) flatDirectionDropdownValues[i] = null;
    for (int i = 0; i < flatOccupancyDropdownValues.length; i++) flatOccupancyDropdownValues[i] = null;
  }

  void _populateFlatsData(List<Flat> flats) {
    print('📥 Populating flats data: ${flats.length} flats');

    if (!mounted) return;

    _removeDataChangeListeners();

    try {
      setState(() {
        final flatCount = flats.length;

        if (numberOfFlatsController.text != flatCount.toString()) {
          numberOfFlatsController.text = flatCount.toString();
        }

        _syncControllers(flatCount);

        flatIds.clear();
        flatSavingStates.clear();
        flatTypeDropdownValues.clear();
        flatDirectionDropdownValues.clear();
        flatOccupancyDropdownValues.clear();

        for (int i = 0; i < flats.length; i++) {
          final flat = flats[i];

          if (i < flatNumberControllers.length) {
            flatNumberControllers[i].text = flat.flatNumber;
          }

          if (i < flatAreaControllers.length) {
            final areaValue = flat.areaSqMts;
            flatAreaControllers[i].text =
                areaValue != null && areaValue > 0 ? areaValue.toString() : '';
          }

          // Occupancy — populate both controller (legacy) and dropdown value
          final occupancy = flat.occupancyStatus;
          if (i < flatOccupancyControllers.length) {
            flatOccupancyControllers[i].text = occupancy;
          }
          flatOccupancyDropdownValues.add(
            occupancyOptions.contains(occupancy) ? occupancy : null,
          );

          // Flat type — populate both controller (legacy) and dropdown value
          final flatType = flat.flatType;
          if (i < flatTypeControllers.length) {
            flatTypeControllers[i].text = flatType;
          }
          flatTypeDropdownValues.add(
            flatTypeOptions.contains(flatType) ? flatType : null,
          );

          // Direction — populate both controller (legacy) and dropdown value
          final direction = flat.directionFacing;
          if (i < flatDirectionControllers.length) {
            flatDirectionControllers[i].text = direction;
          }
          flatDirectionDropdownValues.add(
            directionOptions.contains(direction) ? direction : null,
          );

          flatIds.add(flat.flatId);
          flatSavingStates.add(false);

          print('✅ Populated flat ${i + 1}: ${flat.flatNumber} (ID: ${flat.flatId})');
        }

        _isDataLoaded = true;
      });
    } finally {
      _addDataChangeListeners();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        _notifyDataChanged();
      }
    });

    print('✅ All flats data populated successfully');
  }

  Map<String, dynamic> getData() {
    try {
      if (selectedFloor == null || selectedFloor!.isEmpty) {
        throw Exception('Floor number is not selected');
      }

      final floorArea = floorAreaController.text.trim();
      final floorHeight = floorHeightController.text.trim();
      final numberOfFlats = numberOfFlatsController.text.trim();
      final floorLabelName = flatLabelNameController.text.trim();
      final isParkingFloor = selectedValue?.toLowerCase() == 'yes';

      if (isParkingFloor &&
          (parkingFloorTypes == null || parkingFloorTypes!.isEmpty)) {
        throw Exception('Parking floor type is required for parking floors');
      }

      if (floorArea.isEmpty) throw Exception('Floor area is required');
      if (floorHeight.isEmpty) throw Exception('Floor height is required');
      if (floorLabelName.isEmpty) throw Exception('Floor label name is required');

      List<Map<String, dynamic>> flatsData = [];

      for (int index = 0; index < flatNumberControllers.length; index++) {
        if (index >= flatNumberControllers.length ||
            index >= flatAreaControllers.length ||
            index >= flatOccupancyDropdownValues.length ||
            index >= flatTypeDropdownValues.length ||
            index >= flatDirectionDropdownValues.length) {
          continue;
        }

        final flatNumber = flatNumberControllers[index].text.trim();
        final flatArea = flatAreaControllers[index].text.trim();
        final occupancyStatus = flatOccupancyDropdownValues[index] ?? '';
        final flatType = flatTypeDropdownValues[index] ?? '';
        final flatDirection = flatDirectionDropdownValues[index] ?? '';

        if (flatNumber.isEmpty && flatType.isEmpty && flatArea.isEmpty) continue;

        if (flatNumber.isNotEmpty) {
          if (flatType.isEmpty) throw Exception('Flat type is required for flat ${index + 1}');
          if (flatArea.isEmpty) throw Exception('Flat area is required for flat ${index + 1}');

          final areaSqMts = double.tryParse(flatArea);
          if (areaSqMts == null || areaSqMts <= 0) {
            throw Exception('Valid flat area is required for flat ${index + 1}');
          }

          if (flatDirection.isEmpty) throw Exception('Direction facing is required for flat ${index + 1}');
          if (occupancyStatus.isEmpty) throw Exception('Occupancy status is required for flat ${index + 1}');

          flatsData.add({
            'flatNumber': flatNumber,
            'area_sq_mts': areaSqMts,
            'occupancyStatus': occupancyStatus,
            'flatType': flatType,
            'flatDirection': flatDirection,
          });
        }
      }

      return {
        'selectedFloor': selectedFloor,
        'is_parking_floor': isParkingFloor,
        'parking_floor_type': isParkingFloor ? parkingFloorTypes : null,
        'floorArea': floorArea,
        'floorHeight': floorHeight,
        'numberOfFlats': numberOfFlats,
        'floorLabelName': floorLabelName,
        'flats': flatsData,
      };
    } catch (e) {
      print('❌ Error in FloordetailsWidget getData: $e');
      return {
        'selectedFloor': selectedFloor,
        'is_parking_floor': selectedValue?.toLowerCase() == 'yes',
        'parking_floor_type': parkingFloorTypes,
        'floorArea': floorAreaController.text.trim(),
        'floorHeight': floorHeightController.text.trim(),
        'numberOfFlats': numberOfFlatsController.text.trim(),
        'floorLabelName': flatLabelNameController.text.trim(),
        'flats': [],
        'error': e.toString(),
      };
    }
  }

  bool validate() {
    try {
      if (!formKey.currentState!.validate()) return false;

      if (selectedFloor == null || selectedFloor!.isEmpty) {
        CustomToast.showWarningToast(msg: "Please select a floor number");
        return false;
      }

      final expectedLength = flatNumberControllers.length;
      if (flatTypeDropdownValues.length != expectedLength ||
          flatAreaControllers.length != expectedLength ||
          flatDirectionDropdownValues.length != expectedLength ||
          flatOccupancyDropdownValues.length != expectedLength) {
        CustomToast.showErrorToast(msg: "Internal error: Controller mismatch");
        return false;
      }

      for (int i = 0; i < flatNumberControllers.length; i++) {
        final flatNumber = flatNumberControllers[i].text.trim();
        final flatType = flatTypeDropdownValues[i] ?? '';
        final flatArea = flatAreaControllers[i].text.trim();
        final flatDirection = flatDirectionDropdownValues[i] ?? '';
        final occupancyStatus = flatOccupancyDropdownValues[i] ?? '';

        if (flatNumber.isEmpty && flatType.isEmpty && flatArea.isEmpty) continue;

        if (flatNumber.isEmpty) {
          CustomToast.showWarningToast(msg: "Flat number is required for flat ${i + 1}");
          return false;
        }
        if (flatType.isEmpty) {
          CustomToast.showWarningToast(msg: "Flat type is required for flat ${i + 1}");
          return false;
        }
        if (flatArea.isEmpty) {
          CustomToast.showWarningToast(msg: "Area is required for flat ${i + 1}");
          return false;
        }
        final area = double.tryParse(flatArea);
        if (area == null || area <= 0) {
          CustomToast.showWarningToast(msg: "Please enter valid area for flat ${i + 1}");
          return false;
        }
        if (flatDirection.isEmpty) {
          CustomToast.showWarningToast(msg: "Direction is required for flat ${i + 1}");
          return false;
        }
        if (occupancyStatus.isEmpty) {
          CustomToast.showWarningToast(msg: "Occupancy status is required for flat ${i + 1}");
          return false;
        }
      }

      return true;
    } catch (e) {
      CustomToast.showErrorToast(msg: "Validation error: $e");
      return false;
    }
  }

  void debugControllerValues() {
    print('🛠 DEBUG: Controller Values Analysis');
    print('🛠 selectedFloor: $selectedFloor');
    print('🛠 currentFloorId: $currentFloorId');
    print('🛠 _isDataLoaded: $_isDataLoaded');
    for (int i = 0; i < flatNumberControllers.length; i++) {
      print('🛠 Flat $i: number=${flatNumberControllers[i].text}, '
          'type=${flatTypeDropdownValues[i]}, area=${flatAreaControllers[i].text}, '
          'direction=${flatDirectionDropdownValues[i]}, occupancy=${flatOccupancyDropdownValues[i]}');
    }
  }

  void _initializeControllers() {
    _disposeControllers();

    if (widget.flatNumberControllers != null &&
        widget.flatNumberControllers!.isNotEmpty) {
      flatNumberControllers = List.from(widget.flatNumberControllers!);
    } else {
      flatNumberControllers = [];
    }

    if (widget.numberOfFlatsController != null) {
      numberOfFlatsController = widget.numberOfFlatsController!;
    } else {
      numberOfFlatsController = TextEditingController();
    }

    flatAreaControllers = [];
    flatOccupancyControllers = [];
    flatTypeControllers = [];
    flatDirectionControllers = [];
    flatTypeDropdownValues = [];
    flatDirectionDropdownValues = [];
    flatOccupancyDropdownValues = [];
    flatIds = [];
    flatSavingStates = [];
  }

  void _disposeControllers() {
    for (var c in flatAreaControllers) {
      c.removeListener(_notifyDataChanged);
      c.dispose();
    }
    for (var c in flatOccupancyControllers) {
      c.removeListener(_notifyDataChanged);
      c.dispose();
    }
    for (var c in flatTypeControllers) {
      c.removeListener(_notifyDataChanged);
      c.dispose();
    }
    for (var c in flatDirectionControllers) {
      c.removeListener(_notifyDataChanged);
      c.dispose();
    }

    flatAreaControllers.clear();
    flatOccupancyControllers.clear();
    flatTypeControllers.clear();
    flatDirectionControllers.clear();
  }

  void _setupListeners() {
    numberOfFlatsController.addListener(_onFlatCountChanged);
    flatLabelNameController.addListener(_notifyDataChanged);
    floorAreaController.addListener(_notifyDataChanged);
    floorHeightController.addListener(_notifyDataChanged);
  }

  void _removeDataChangeListeners() {
    try {
      numberOfFlatsController.removeListener(_onFlatCountChanged);
      flatLabelNameController.removeListener(_notifyDataChanged);
      floorAreaController.removeListener(_notifyDataChanged);
      floorHeightController.removeListener(_notifyDataChanged);
    } catch (e) {
      print('⚠️ Error removing listeners: $e');
    }
  }

  void _addDataChangeListeners() {
    try {
      if (!numberOfFlatsController.hasListeners) {
        numberOfFlatsController.addListener(_onFlatCountChanged);
      }
      if (!flatLabelNameController.hasListeners) {
        flatLabelNameController.addListener(_notifyDataChanged);
      }
      if (!floorAreaController.hasListeners) {
        floorAreaController.addListener(_notifyDataChanged);
      }
      if (!floorHeightController.hasListeners) {
        floorHeightController.addListener(_notifyDataChanged);
      }
    } catch (e) {
      print('⚠️ Error adding listeners: $e');
    }
  }

  Future<void> _loadFloorData(String floorNumber) async {
    if (_isLoadingFloorData) return;

    _hasTriedToLoadData = true;

    if (!mounted) return;

    setState(() {
      _isLoadingFloorData = true;
    });

    try {
      await getstructureProvider.getFloorsByStructureId(
        structureId: widget.structureId,
        context: context,
        forceRefresh: true,
      );

      if (!mounted) return;

      final floors =
          getstructureProvider.getFloorsDetailsByStrId?.data?.floors ?? [];

      final selectedFloorData = floors.cast<Floor?>().firstWhere(
            (floor) => floor?.floorNumber.toString() == floorNumber,
            orElse: () => null,
          );

      if (selectedFloorData == null) {
        if (currentFloorId != null && _isDataLoaded) {
          print('ℹ️ Keeping existing data');
        } else {
          _clearFloorData();
        }
        return;
      }

      currentFloorId = selectedFloorData.floorId;
      _populateFloorData(selectedFloorData);

      if (selectedFloorData.floorId != null &&
          selectedFloorData.floorId!.isNotEmpty) {
        await _loadFlatsData(selectedFloorData.floorId!);
      } else {
        _clearFlatsData();
      }
    } catch (e) {
      print('❌ Error loading floor data: $e');
      if (mounted) {
        CustomToast.showErrorToast(msg: "Error loading floor data");
      }
      _clearFloorData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFloorData = false;
        });
      }
    }
  }

  void _clearFloorData() {
    setState(() {
      floorAreaController.clear();
      floorHeightController.clear();
      flatLabelNameController.clear();
      numberOfFlatsController.clear();
      currentFloorId = null;
      _clearFlatsData();
      _isDataLoaded = true;
    });
  }

  void _populateFloorData(Floor floorData) {
    if (!mounted) return;

    _removeDataChangeListeners();

    try {
      setState(() {
        floorAreaController.text = floorData.totalAreaSqMts?.toString() ?? '';
        floorHeightController.text = floorData.floorHeight?.toString() ?? '';
        flatLabelNameController.text = floorData.floorLabelName ?? '';
        numberOfFlatsController.text =
            floorData.numberOfFlats?.toString() ?? '';

        // Industrial structures have no parking or flats
        if (widget.structureType.toLowerCase() != 'industrial') {
          try {
            final json = floorData.toJson();
            final parkingRaw = json['is_parking_floor'] ?? json['isParkingFloor'];
            if (parkingRaw != null) {
              selectedValue = (parkingRaw == true) ? "Yes" : "No";
            }

            final typeRaw =
                json['parking_floor_type'] ?? json['parkingFloorType'];
            if (typeRaw != null && typeRaw.toString().isNotEmpty) {
              parkingFloorTypes = typeRaw.toString();
            }
          } catch (e) {
            print('⚠️ Could not load parking fields from floor data: $e');
          }
        } else {
          // Always clear parking/flats state for industrial
          selectedValue = null;
          parkingFloorTypes = null;
          numberOfFlatsController.text = '';
        }
      });
    } finally {
      _addDataChangeListeners();

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notifyDataChanged();
        });
      }
    }
  }

  Future<void> _loadFlatsData(String floorId) async {
    // Industrial structures have no flats — skip entirely
    if (widget.structureType.toLowerCase() == 'industrial') {
      _clearFlatsData();
      return;
    }
    if (_isLoadingFlatData) return;

    setState(() {
      _isLoadingFlatData = true;
    });

    try {
      // A remounted floor must display edits saved on the previous visit.
      await getstructureProvider.getFlatsWithDetailsByFloorId(
        structureId: widget.structureId,
        floorId: floorId,
        context: context,
      );

      if (!mounted) return;

      final flatsData = getstructureProvider.getFlatsByFloorId(floorId);

      if (flatsData?.data.flats != null && flatsData!.data.flats.isNotEmpty) {
        _populateFlatsData(flatsData.data.flats);
      } else {
        _clearFlatsData();
      }
    } catch (e) {
      print('❌ Error loading flats data: $e');
      if (mounted) {
        CustomToast.showErrorToast(msg: "Error loading flats data: $e");
      }
      _clearFlatsData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFlatData = false;
        });
      }
    }
  }

  void _clearFlatsData() {
    setState(() {
      _safelyDisposeAndClearControllers(flatNumberControllers);
      _safelyDisposeAndClearControllers(flatAreaControllers);
      _safelyDisposeAndClearControllers(flatOccupancyControllers);
      _safelyDisposeAndClearControllers(flatTypeControllers);
      _safelyDisposeAndClearControllers(flatDirectionControllers);

      flatIds.clear();
      flatSavingStates.clear();
      flatTypeDropdownValues.clear();
      flatDirectionDropdownValues.clear();
      flatOccupancyDropdownValues.clear();

      _isDataLoaded = true;
    });
  }

  void _safelyDisposeAndClearControllers(
    List<TextEditingController> controllers,
  ) {
    for (var controller in controllers) {
      try {
        controller.removeListener(_notifyDataChanged);
        controller.clear();
      } catch (e) {
        print('⚠️ Error clearing controller: $e');
      }
    }
  }

  void _notifyDataChanged() {
    if (!mounted) return;
    if (widget.onFloorDataChanged != null) {
      widget.onFloorDataChanged!(getData());
    }
  }

  Future<http.Response> putFlatDetails({
    required String structureId,
    required String floorId,
    required String flatId,
    required String flatNumber,
    required String flatType,
    required double areaSqMts,
    required String directionFacing,
    required String occupancyStatus,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId',
    );
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final Map<String, dynamic> requestBody = {
      "flat_number": flatNumber,
      "flat_type": flatType,
      "area_sq_mts": areaSqMts,
      "direction_facing": directionFacing,
      "occupancy_status": occupancyStatus,
      "flat_notes": "Well-ventilated with balcony",
    };

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );
      return response;
    } catch (e) {
      print('Error occurred while updating flat: $e');
      rethrow;
    }
  }

  Future<void> _saveFlatDetails(int flatIndex) async {
    if (flatIndex >= flatIds.length ||
        currentFloorId == null ||
        flatIds[flatIndex] == null) {
      CustomToast.showErrorToast(msg: "Cannot save flat: missing floor or flat ID");
      return;
    }

    if (flatIndex >= flatNumberControllers.length ||
        flatIndex >= flatAreaControllers.length ||
        flatIndex >= flatTypeDropdownValues.length ||
        flatIndex >= flatDirectionDropdownValues.length ||
        flatIndex >= flatOccupancyDropdownValues.length) {
      CustomToast.showErrorToast(msg: "Error: Controller index out of bounds");
      return;
    }

    if (flatNumberControllers[flatIndex].text.trim().isEmpty) {
      CustomToast.showErrorToast(msg: "Flat number is required");
      return;
    }

    final flatType = flatTypeDropdownValues[flatIndex] ?? '';
    if (flatType.isEmpty) {
      CustomToast.showErrorToast(msg: "Flat type is required");
      return;
    }

    final area = double.tryParse(flatAreaControllers[flatIndex].text.trim());
    if (area == null || area <= 0) {
      CustomToast.showErrorToast(msg: "Valid flat area is required");
      return;
    }

    final direction = flatDirectionDropdownValues[flatIndex] ?? '';
    if (direction.isEmpty) {
      CustomToast.showErrorToast(msg: "Direction facing is required");
      return;
    }

    final occupancy = flatOccupancyDropdownValues[flatIndex] ?? '';
    if (occupancy.isEmpty) {
      CustomToast.showErrorToast(msg: "Occupancy status is required");
      return;
    }

    setState(() {
      flatSavingStates[flatIndex] = true;
    });

    try {
      final response = await putFlatDetails(
        structureId: widget.structureId,
        floorId: currentFloorId!,
        flatId: flatIds[flatIndex]!,
        flatNumber: flatNumberControllers[flatIndex].text.trim(),
        flatType: flatType,
        areaSqMts: area,
        directionFacing: direction,
        occupancyStatus: occupancy,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        CustomToast.showSuccessToast(msg: "Flat saved successfully");
        Provider.of<GetstructureProvider>(context, listen: false)
            .getStructures(context);
      } else {
        throw Exception('Failed to save flat details: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving flat details: $e');
      CustomToast.showErrorToast(msg: "Error saving flat $e");
    } finally {
      if (mounted && flatIndex < flatSavingStates.length) {
        setState(() {
          flatSavingStates[flatIndex] = false;
        });
      }
    }
  }

  Future<http.Response> putFloorDetails({
    required String structureId,
    required String floorId,
    required int floorNumber,
    required double floorHeight,
    required double totalAreaSqMts,
    required String floorLabelName,
    required int numberOfFlats,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId',
    );
    final token = Provider.of<CommonProvider>(listen: false, context).accessToken;
    final Map<String, dynamic> requestBody = {
      "floor_number": floorNumber,
      "floor_height": floorHeight,
      "total_area_sq_mts": totalAreaSqMts,
      "floor_label_name": floorLabelName,
      "number_of_flats": numberOfFlats,
      "floor_notes": "Well-ventilated with balcony",
    };

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );
      return response;
    } catch (e) {
      print('Error occurred while updating floor: $e');
      rethrow;
    }
  }

  Future<void> _saveFloorDetails() async {
    if (!formKey.currentState!.validate()) return;

    if (currentFloorId == null || selectedFloor == null) {
      CustomToast.showErrorToast(msg: "No floor selected to save");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final floorNumber = int.tryParse(selectedFloor!) ?? 0;
      final floorHeight =
          double.tryParse(floorHeightController.text.trim()) ?? 0.0;
      final totalArea = double.tryParse(floorAreaController.text.trim()) ?? 0.0;
      final numberOfFlats =
          int.tryParse(numberOfFlatsController.text.trim()) ?? 0;
      final floorLabelName = flatLabelNameController.text.trim();

      if (floorHeight <= 0) throw Exception('Valid floor height is required');
      if (totalArea <= 0) throw Exception('Valid floor area is required');
      if (floorLabelName.isEmpty) throw Exception('Floor label name is required');
      if (numberOfFlats <= 0) throw Exception('Valid number of flats is required');

      final response = await putFloorDetails(
        structureId: widget.structureId,
        floorId: currentFloorId!,
        floorNumber: floorNumber,
        floorHeight: floorHeight,
        totalAreaSqMts: totalArea,
        floorLabelName: floorLabelName,
        numberOfFlats: numberOfFlats,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        CustomToast.showSuccessToast(msg: "Floor details saved successfully!");
        Provider.of<GetstructureProvider>(context, listen: false)
            .getStructures(context);
      } else {
        throw Exception('Failed to save floor details: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving floor details: $e');
      CustomToast.showErrorToast(msg: "Error saving floor details");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> validateAndGetData() {
    try {
      Map<String, String> validationErrors = {};

      if (selectedFloor == null || selectedFloor!.isEmpty) {
        validationErrors['selectedFloor'] = 'Floor number is not selected';
      }

      final floorArea = floorAreaController.text.trim();
      final floorHeight = floorHeightController.text.trim();
      final numberOfFlats = numberOfFlatsController.text.trim();
      final floorLabelName = flatLabelNameController.text.trim();

      if (floorArea.isEmpty) validationErrors['floorArea'] = 'Floor area is required';
      if (floorHeight.isEmpty) validationErrors['floorHeight'] = 'Floor height is required';
      if (floorLabelName.isEmpty) validationErrors['floorLabelName'] = 'Floor label name is required';

      List<Map<String, dynamic>> validFlatsData = [];
      List<String> flatValidationErrors = [];

      for (int index = 0; index < flatNumberControllers.length; index++) {
        final flatNumber = flatNumberControllers[index].text.trim();
        final flatArea = index < flatAreaControllers.length
            ? flatAreaControllers[index].text.trim()
            : '';
        final occupancyStatus = index < flatOccupancyDropdownValues.length
            ? (flatOccupancyDropdownValues[index] ?? '')
            : '';
        final flatType = index < flatTypeDropdownValues.length
            ? (flatTypeDropdownValues[index] ?? '')
            : '';
        final flatDirection = index < flatDirectionDropdownValues.length
            ? (flatDirectionDropdownValues[index] ?? '')
            : '';

        Map<String, String> flatErrors = {};
        if (flatNumber.isEmpty) flatErrors['flatNumber'] = 'Flat number is required';
        if (flatType.isEmpty) flatErrors['flatType'] = 'Flat type is required';
        if (flatArea.isEmpty) flatErrors['flatArea'] = 'Flat area is required';
        if (flatDirection.isEmpty) flatErrors['flatDirection'] = 'Direction facing is required';
        if (occupancyStatus.isEmpty) flatErrors['occupancyStatus'] = 'Occupancy status is required';

        if (flatErrors.isNotEmpty) {
          flatValidationErrors.add('Flat ${index + 1}: ${flatErrors.values.join(', ')}');
        } else {
          validFlatsData.add({
            'flatNumber': flatNumber,
            'area_sq_mts': double.parse(flatArea),
            'occupancyStatus': occupancyStatus,
            'flatType': flatType,
            'flatDirection': flatDirection,
          });
        }
      }

      List<String> allErrors = [
        ...validationErrors.values,
        ...flatValidationErrors,
      ];

      return {
        'isValid': allErrors.isEmpty,
        'errors': allErrors,
        'selectedFloor': selectedFloor,
        'floorArea': floorArea,
        'floorHeight': floorHeight,
        'numberOfFlats': numberOfFlats,
        'floorLabelName': floorLabelName,
        'flats': validFlatsData,
      };
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Validation error: $e'],
        'selectedFloor': selectedFloor,
        'floorArea': '',
        'floorHeight': '',
        'numberOfFlats': '',
        'floorLabelName': '',
        'flats': [],
      };
    }
  }

  bool validateWithDetailedFeedback() {
    final validationResult = validateAndGetData();
    final bool isValid = validationResult['isValid'] ?? false;
    final List<String> errors = List<String>.from(validationResult['errors'] ?? []);

    if (!isValid && errors.isNotEmpty) {
      CustomToast.showWarningToast(msg: errors.first);
    }
    return isValid;
  }

  Map<String, dynamic> getDataSafely() {
    final validationResult = validateAndGetData();
    if (validationResult['isValid'] == true) {
      return {
        'selectedFloor': validationResult['selectedFloor'],
        'floorArea': validationResult['floorArea'],
        'floorHeight': validationResult['floorHeight'],
        'numberOfFlats': validationResult['numberOfFlats'],
        'floorLabelName': validationResult['floorLabelName'],
        'flats': validationResult['flats'],
      };
    }
    return validationResult;
  }

  void ensureControllerSynchronization() {
    final numberOfFlats = int.tryParse(numberOfFlatsController.text) ?? 0;
    if (numberOfFlats <= 0) return;
    _syncControllers(numberOfFlats);
  }

  List<String> value = ["Yes", "No"];
  String? selectedValue;

  Future<void> _retryFloorLoad() async {
    if (selectedFloor == null || selectedFloor!.isEmpty) return;
    await _loadFloorData(selectedFloor!);
  }

  Widget _buildFloorRequestStatus(GetstructureProvider provider) {
    final isFetchingFloors = provider.isLoadingFloors && _isLoadingFloorData;
    final hasFloorError =
        _hasTriedToLoadData &&
        !_isLoadingFloorData &&
        (provider.floorsError?.isNotEmpty ?? false);

    if (!isFetchingFloors && !hasFloorError && !_isLoadingFlatData) {
      return const SizedBox.shrink();
    }

    final statusText = isFetchingFloors
        ? 'Fetching floor details...'
        : _isLoadingFlatData
            ? 'Fetching flat details...'
            : provider.floorsError ?? 'Unable to load floor details';

    final statusColor = hasFloorError ? Colors.red.shade50 : Colors.blue.shade50;
    final borderColor =
        hasFloorError ? Colors.red.shade200 : Colors.blue.shade100;
    final iconColor = hasFloorError ? Colors.red.shade400 : Colors.blue.shade400;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (isFetchingFloors || _isLoadingFlatData)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.error_outline_rounded, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: w400_14Poppins().copyWith(
                color: hasFloorError ? Colors.red.shade700 : Colors.blueGrey.shade700,
              ),
            ),
          ),
          if (hasFloorError && selectedFloor != null && selectedFloor!.isNotEmpty)
            TextButton(
              onPressed: _retryFloorLoad,
              child: Text('Retry', style: w500_14Poppins()),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableFloors = widget.floorDropdownItems
        .where((floor) =>
            floor == selectedFloor ||
            !(widget.selectedFloorsFromOtherWidgets?.contains(floor) ?? false))
        .toList();

    final isIndustrial = widget.structureType.toLowerCase() == 'industrial';
    final isParkingFloor = selectedValue == "Yes";
    final showFlats = !isIndustrial && !isParkingFloor;

    return Consumer<GetstructureProvider>(
      builder: (context, provider, child) {
        return Form(
          key: formKey,
          child: FormCard(
            title: "Floor ${selectedFloor ?? '—'}",
            trailing: isIndustrial ? null : _buildParkingToggle(),
            children: [
              _buildFloorRequestStatus(provider),
              FormGrid(
                children: [
                  LabeledField(
                    label: "Floor number",
                    isRequired: true,
                    child: RadioGroupDropdown<String>(
                      options: radioOptionsFromStrings(availableFloors),
                      value: availableFloors.contains(selectedFloor)
                          ? selectedFloor
                          : null,
                      hintText: "Select floor number",
                      sheetTitle: "Select floor number",
                      enabled:
                          !(_isLoadingFloorData || provider.isLoadingFloors),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please select a floor'
                          : null,
                      onChanged: (val) async {
                        if (val == null || val == selectedFloor) return;
                        setState(() {
                          selectedFloor = val;
                          _hasTriedToLoadData = false;
                          currentFloorId = null;
                        });
                        widget.onFloorChanged?.call(val);
                        await _loadFloorData(val);
                        _notifyDataChanged();
                      },
                    ),
                  ),
                  if (isParkingFloor)
                    LabeledField(
                      label: "Parking floor type",
                      isRequired: true,
                      child: RadioGroupDropdown<String>(
                        options: radioOptionsFromStrings(
                          _parkingFloorTypeOptions,
                          labelBuilder: prettifyOptionLabel,
                        ),
                        value: parkingFloorTypes,
                        hintText: "Select floor type",
                        sheetTitle: "Parking floor type",
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please select floor type'
                            : null,
                        onChanged: (v) {
                          setState(() => parkingFloorTypes = v);
                          _notifyDataChanged();
                        },
                      ),
                    ),
                  LabeledField(
                    label: "Floor area (Sq.mts)",
                    isRequired: true,
                    child: FormTextField(
                      controller: floorAreaController,
                      keyboardType: TextInputType.number,
                      hintText: "Enter floor area",
                      validator: (val, hintText) {
                        if (val == null || val.isEmpty) {
                          return "Please enter floor area";
                        }
                        if (double.tryParse(val) == null ||
                            double.parse(val) <= 0) {
                          return "Please enter valid floor area";
                        }
                        return null;
                      },
                    ),
                  ),
                  LabeledField(
                    label: "Floor height (M)",
                    isRequired: true,
                    child: FormTextField(
                      controller: floorHeightController,
                      keyboardType: TextInputType.number,
                      hintText: "Enter floor height",
                      validator: (val, hintText) {
                        if (val == null || val.isEmpty) {
                          return "Please enter floor height";
                        }
                        if (double.tryParse(val) == null ||
                            double.parse(val) <= 0) {
                          return "Please enter valid floor height";
                        }
                        return null;
                      },
                    ),
                  ),
                  LabeledField(
                    label: "Floor label name",
                    isRequired: true,
                    child: FormTextField(
                      controller: flatLabelNameController,
                      hintText: "Enter floor label name",
                      validator: (val, hintText) =>
                          (val == null || val.isEmpty)
                              ? "Please enter floor label"
                              : null,
                    ),
                  ),
                  if (showFlats)
                    LabeledField(
                      label: "Number of flats",
                      isRequired: true,
                      child: FormTextField(
                        controller: numberOfFlatsController,
                        keyboardType: TextInputType.number,
                        hintText: "Enter number of flats",
                        validator: (val, hintText) =>
                            (val == null || val.isEmpty)
                                ? "Please enter no. of flats"
                                : null,
                      ),
                    ),
                ],
              ),
              if (showFlats) ...[
                const SizedBox(height: 18),
                _buildFlatsSection(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildParkingToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Parking floor", style: w600_13Poppins(color: FormKit.labelColor)),
        const SizedBox(width: 6),
        for (final option in value)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: ChoiceChip(
              label: Text(
                option,
                style: w600_12Poppins(
                  color: selectedValue == option
                      ? Colors.white
                      : FormKit.labelColor,
                ),
              ),
              selected: selectedValue == option,
              onSelected: (_) => setState(() => selectedValue = option),
              selectedColor: Appcolors.buttonColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selectedValue == option
                    ? Appcolors.buttonColor
                    : FormKit.borderColor,
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  /// The flats on this floor. Previously a horizontally-scrolling strip of
  /// 110dp cards, which clipped every field inside it; now a wrapping grid so
  /// each flat gets a readable card at any width.
  Widget _buildFlatsSection() {
    if (flatNumberControllers.isEmpty) {
      if (!_isDataLoaded) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: Text(
          "No flats yet — enter the number of flats above.",
          textAlign: TextAlign.center,
          style: w400_14Poppins(color: FormKit.hintColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FLATS · ${flatNumberControllers.length}",
          style: w700_10Poppins(color: FormKit.hintColor)
              .copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        FormGrid(
          minItemWidth: 250,
          children: [
            for (int index = 0; index < flatNumberControllers.length; index++)
              _buildFlatCard(index),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatCard(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "FLAT ${index + 1}",
            style: w700_10Poppins(color: FormKit.hintColor)
                .copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          LabeledField(
            label: "Flat number",
            isRequired: true,
            child: FormTextField(
              controller: flatNumberControllers[index],
              hintText: "Enter flat number",
              validator: (val, _) =>
                  (val == null || val.isEmpty) ? "Required" : null,
            ),
          ),
          const SizedBox(height: FormKit.rowGap),
          _buildFlatDropdown(
            label: "Flat type",
            value: index < flatTypeDropdownValues.length
                ? flatTypeDropdownValues[index]
                : null,
            options: flatTypeOptions,
            onChanged: (v) {
              setState(() {
                if (index < flatTypeDropdownValues.length) {
                  flatTypeDropdownValues[index] = v;
                }
                if (index < flatTypeControllers.length) {
                  flatTypeControllers[index].text = v ?? '';
                }
              });
              _notifyDataChanged();
            },
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: FormKit.rowGap),
          LabeledField(
            label: "Area (Sq.mts)",
            isRequired: true,
            child: FormTextField(
              controller: flatAreaControllers[index],
              keyboardType: TextInputType.number,
              hintText: "Enter area",
              validator: (val, _) {
                if (val == null || val.isEmpty) return "Required";
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return "Invalid";
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: FormKit.rowGap),
          _buildFlatDropdown(
            label: "Direction facing",
            value: index < flatDirectionDropdownValues.length
                ? flatDirectionDropdownValues[index]
                : null,
            options: directionOptions,
            onChanged: (v) {
              setState(() {
                if (index < flatDirectionDropdownValues.length) {
                  flatDirectionDropdownValues[index] = v;
                }
                if (index < flatDirectionControllers.length) {
                  flatDirectionControllers[index].text = v ?? '';
                }
              });
              _notifyDataChanged();
            },
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: FormKit.rowGap),
          _buildFlatDropdown(
            label: "Occupancy",
            value: index < flatOccupancyDropdownValues.length
                ? flatOccupancyDropdownValues[index]
                : null,
            options: occupancyOptions,
            onChanged: (v) {
              setState(() {
                if (index < flatOccupancyDropdownValues.length) {
                  flatOccupancyDropdownValues[index] = v;
                }
                if (index < flatOccupancyControllers.length) {
                  flatOccupancyControllers[index].text = v ?? '';
                }
              });
              _notifyDataChanged();
            },
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),
        ],
      ),
    );
  }
}
