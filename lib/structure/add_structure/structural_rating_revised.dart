// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/images.dart';

class StructuralRating extends StatefulWidget {
  final String structureId;
  final String? flatId;
  final String? floorId;
  final String selectedStructureSubType;
  final bool initialTestingRequired;
  final ValueChanged<bool>? onTestingRequiredChanged;

  const StructuralRating({
    super.key,
    required this.structureId,
    this.flatId,
    this.floorId,
    required this.selectedStructureSubType,
    this.initialTestingRequired = false,
    this.onTestingRequiredChanged,
  });

  @override
  State<StructuralRating> createState() => _StructuralRatingState();
}

class _StructuralRatingState extends State<StructuralRating> {
  // ─── Global Foundation store ─────────────────────────────────────────────
  // Foundation belongs to the whole building, not a single floor.
  // We persist the filled-in values here so they auto-populate on every floor.
  static final Map<String, String> _sharedFoundation = {};
  static List<String> _sharedFoundationDistress = [];
  static String? _sharedFoundationStructureId;

  static const _fRating = 'rating';
  static const _fComment = 'comment';
  static const _fLength = 'length';
  static const _fBreadth = 'breadth';
  static const _fHeight = 'height';
  static const _fUnit = 'unit';
  static const _fRepair = 'repair';

  void _saveFoundationToShared(AddRatingsStructureProvider provider) {
    final items = provider.structuralRatingMap['Foundation'];
    if (items == null || items.isEmpty) return;
    final item = items.first;
    _sharedFoundation[_fRating] = item.ratingController.text;
    _sharedFoundation[_fComment] = item.commentController.text;
    _sharedFoundationDistress = List<String>.from(item.distressTypes);
    _sharedFoundation[_fLength] = item.lengthController.text;
    _sharedFoundation[_fBreadth] = item.widthController.text;
    _sharedFoundation[_fHeight] = item.heightController.text;
    _sharedFoundation[_fUnit] = item.distressUnit.apiValue;
    _sharedFoundation[_fRepair] = item.repairMethodologyController.text;
  }

  void _restoreFoundationFromShared(AddRatingsStructureProvider provider) {
    if (_sharedFoundation.isEmpty) return;
    // If Foundation isn't in the map yet, add a blank entry first.
    if (!provider.structuralRatingMap.containsKey('Foundation')) {
      provider.addStructuralStructureType('Foundation');
    }
    // Attach listeners and fill from shared store via the single shared helper.
    _foundationListenersAttached =
        false; // ensure fresh attach for this widget instance
    _attachFoundationListenersAndRestore(provider);
  }
  // ─────────────────────────────────────────────────────────────────────────

  List<String> get structureTypes {
    if (widget.selectedStructureSubType.toLowerCase() == 'steel') {
      return [
        'Foundation',
        'Columns',
        'Beams',
        'Roof_Truss',
        'Connections',
        'Bracings',
        'Purlins',
        'Channels',
      ];
    } else {
      // Default to RCC
      return ['Beams', 'Columns', 'Slab', 'Foundation'];
    }
  }

  bool isSubmitting = false;
  bool isLoading = true;
  String? errorMessage;
  bool testingRequired = false;

  /// Tracks distress types per component item: key = "$type|$index"
  final Map<String, List<String>> _distressTypePerItem = {};

  // Guard so Foundation dimension listeners are attached exactly once,
  // not re-attached on every build() call.
  bool _foundationListenersAttached = false;

  void _resetSharedFoundationForStructure() {
    if (_sharedFoundationStructureId == widget.structureId) return;
    _sharedFoundation..clear();
    _sharedFoundationDistress = [];
    _sharedFoundationStructureId = widget.structureId;
  }

  void _syncDistressSelectionsFromProvider(
    AddRatingsStructureProvider provider,
  ) {
    _distressTypePerItem.clear();

    provider.structuralRatingMap.forEach((type, items) {
      for (var index = 0; index < items.length; index++) {
        final distressTypes = List<String>.from(items[index].distressTypes);
        if (distressTypes.isNotEmpty) {
          _distressTypePerItem['$type|$index'] = distressTypes;
        }
      }
    });
  }

  /// Attach Foundation dimension-controller listeners once, then fill all
  /// fields from [_sharedFoundation] if it has data.  Safe to call
  /// multiple times — guards internally.
  void _attachFoundationListenersAndRestore(
    AddRatingsStructureProvider provider,
  ) {
    final items = provider.structuralRatingMap['Foundation'];
    if (items == null || items.isEmpty) return;
    final fi = items.first;

    if (!_foundationListenersAttached) {
      _foundationListenersAttached = true;
      fi.lengthController.addListener(
        () => _sharedFoundation[_fLength] = fi.lengthController.text,
      );
      fi.widthController.addListener(
        () => _sharedFoundation[_fBreadth] = fi.widthController.text,
      );
      fi.heightController.addListener(
        () => _sharedFoundation[_fHeight] = fi.heightController.text,
      );
      fi.ratingController.addListener(
        () => _sharedFoundation[_fRating] = fi.ratingController.text,
      );
      fi.commentController.addListener(
        () => _sharedFoundation[_fComment] = fi.commentController.text,
      );
      fi.repairMethodologyController.addListener(
        () => _sharedFoundation[_fRepair] = fi.repairMethodologyController.text,
      );
    }

    // Fill from shared store if it has data and the item is still blank.
    if (_sharedFoundation.isNotEmpty &&
        fi.ratingController.text.isEmpty &&
        fi.commentController.text.isEmpty) {
      fi.ratingController.text = _sharedFoundation[_fRating] ?? '';
      fi.commentController.text = _sharedFoundation[_fComment] ?? '';
      fi.lengthController.text = _sharedFoundation[_fLength] ?? '';
      fi.widthController.text = _sharedFoundation[_fBreadth] ?? '';
      fi.heightController.text = _sharedFoundation[_fHeight] ?? '';
      fi.distressUnit = DistressMeasurementUnitX.fromApiValue(
        _sharedFoundation[_fUnit],
      );
      fi.repairMethodologyController.text = _sharedFoundation[_fRepair] ?? '';
      final ratingVal = int.tryParse(_sharedFoundation[_fRating] ?? '');
      if (ratingVal != null) fi.rating = ratingVal;
      fi.comment = _sharedFoundation[_fComment];
      fi.repairMethodology = _sharedFoundation[_fRepair];
      if (_sharedFoundationDistress.isNotEmpty) {
        fi.distressTypes = List<String>.from(_sharedFoundationDistress);
        _distressTypePerItem['Foundation|0'] = List<String>.from(
          _sharedFoundationDistress,
        );
      }
      provider.notifyListeners();
    }
  }

  @override
  void initState() {
    super.initState();
    _resetSharedFoundationForStructure();
    testingRequired = widget.initialTestingRequired;
    _loadExistingRatings();
  }

  @override
  void dispose() {
    // Persist Foundation data so the next floor finds it auto-populated.
    final provider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );
    _saveFoundationToShared(provider);
    super.dispose();
  }

  Future<void> _loadExistingRatings() async {
    if (!mounted) return;
    // ✅ Always clear stale data from previous floor before loading
    Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    ).clearForNewFloor();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final ratingsProvider = Provider.of<AddRatingsStructureProvider>(
        context,
        listen: false,
      );
      final getStructureProvider = Provider.of<GetstructureProvider>(
        context,
        listen: false,
      );

      dynamic ratingsData;
      bool hasData = false;

      try {
        if (widget.flatId != null) {
          print('🏠 Fetching flat structural ratings...');
          ratingsData = await getStructureProvider.getAllRatingsForFlat(
            structureId: widget.structureId,
            floorId: widget.floorId!,
            flatId: widget.flatId!,
            context: context,
          );
        } else if (widget.floorId != null) {
          print('🏢 Fetching floor structural ratings...');
          ratingsData = await getStructureProvider.getAllRatingsForFloor(
            structureId: widget.structureId,
            floorId: widget.floorId!,
            flatId: '',
            context: context,
          );
        }
      } catch (apiError) {
        print('❌ API Error: $apiError');
        rethrow;
      }

      if (ratingsData != null && ratingsData.data != null) {
        try {
          if (widget.flatId != null) {
            ratingsProvider.populateStructuralRatingsFromFlat(
              ratingsData.data.structuralRating,
            );
          } else {
            ratingsProvider.populateStructuralRatingsFromFloor(
              ratingsData.data.structuralRating,
            );
            testingRequired = ratingsData.data.testingRequired;
            widget.onTestingRequiredChanged?.call(testingRequired);
          }

          _syncDistressSelectionsFromProvider(ratingsProvider);

          hasData = ratingsProvider.structuralRatingMap.isNotEmpty;

          if (hasData) {
            errorMessage = null;
          } else {
            errorMessage =
                'No existing structural ratings found. You can create new ones.';
          }
        } catch (populateError) {
          errorMessage =
              'Could not load existing data properly. You can create new ratings.';
        }
      } else {
        errorMessage =
            'No existing structural ratings found. You can create new ones.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage =
              'No existing structural ratings found. You can create new ones.';
        });
      }
    } finally {
      if (mounted) {
        // ✅ Auto-populate Foundation from shared store if not already loaded from API.
        final ratingsProvider = Provider.of<AddRatingsStructureProvider>(
          context,
          listen: false,
        );
        _restoreFoundationFromShared(ratingsProvider);

        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddRatingsStructureProvider>(
      builder: (context, provider, child) {
        if (isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading existing ratings...'),
              ],
            ),
          );
        }

        final availableOptions = structureTypes
            .where((type) => !provider.structuralRatingMap.containsKey(type))
            .toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableOptions.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: Text(
                              'Select Item',
                              style: w400_15Poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                            items: availableOptions
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: w400_15Poppins(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            value: null,
                            onChanged: (value) {
                              if (value != null) {
                                provider.addStructuralStructureType(value);
                                // When Foundation is selected, attach listeners and
                                // immediately fill from the shared store so the user
                                // sees the same values they entered on earlier floors.
                                if (value == 'Foundation') {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      _foundationListenersAttached =
                                          false; // reset so new item gets listeners
                                      _attachFoundationListenersAndRestore(
                                        provider,
                                      );
                                    }
                                  });
                                }
                              }
                            },
                            buttonStyleData: ButtonStyleData(
                              height: 30.h,
                              width: MediaQuery.of(context).size.width * 0.35,
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                                color: Appcolors.textformFillColor,
                              ),
                              elevation: 0,
                            ),
                            iconStyleData: const IconStyleData(
                              icon: Icon(Icons.arrow_drop_down),
                              iconSize: 24,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Appcolors.textformFillColor,
                              ),
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(40),
                                thickness: WidgetStateProperty.all(6),
                                thumbVisibility: WidgetStateProperty.all(true),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                              padding: EdgeInsets.only(left: 14, right: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                ...provider.structuralRatingMap.entries.map((entry) {
                  final type = entry.key;
                  final items = entry.value;

                  // Attach Foundation listeners once and restore shared data
                  // (guard inside the method prevents duplicate attachment).
                  if (type == 'Foundation' && items.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted)
                        _attachFoundationListenersAndRestore(provider);
                    });
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(type, style: w600_16Poppins()),
                              Row(
                                children: [
                                  // Foundation is a building-wide singleton — never allow adding more items.
                                  if (type != 'Foundation')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () => provider
                                          .addItemToStructuralType(type),
                                      tooltip: 'Add another $type item',
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      provider.removeStructuralStructureType(
                                        type,
                                      );
                                    },
                                    tooltip: 'Remove $type',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),

                          ...items.asMap().entries.map((itemEntry) {
                            final index = itemEntry.key;
                            final item = itemEntry.value;

                            // ── Seed the local dropdown map from API data ──
                            // The dropdown reads _distressTypePerItem, not item.distressType
                            // directly. Without this, API-loaded values never appear in the UI.
                            final mapKey = '$type|$index';
                            if (!_distressTypePerItem.containsKey(mapKey) &&
                                item.distressTypes.isNotEmpty) {
                              // Schedule after current build frame to avoid setState-during-build
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _distressTypePerItem[mapKey] =
                                        List<String>.from(item.distressTypes);
                                  });
                                }
                              });
                            }

                            return _buildRatingSection(
                              context: context,
                              provider: provider,
                              title:
                                  widget.floorId != null &&
                                      widget.flatId == null
                                  ? (item.name ?? "$type Item ${index + 1}")
                                  : type,
                              type: type,
                              index: index,
                              item: item,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Testing Required (Structural Only)',
                    style: w500_15Poppins(),
                  ),
                  value: testingRequired,
                  onChanged: (val) {
                    setState(() => testingRequired = val);
                    widget.onTestingRequiredChanged?.call(val);
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitRatings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Structural Ratings',
                            style: w500_16Poppins(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRatings() async {
    final provider = Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    );

    bool hasErrors = false;
    for (var entry in provider.structuralRatingMap.entries) {
      for (var item in entry.value) {
        if (item.rating == null || item.rating! < 1 || item.rating! > 5) {
          hasErrors = true;
          break;
        }
      }
      if (hasErrors) break;
    }

    if (hasErrors) {
      CustomToast.showErrorToast(
        msg: "Please enter valid ratings (1-5) for all items",
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final addRatingsStructureProvider =
          Provider.of<AddRatingsStructureProvider>(context, listen: false);

      if (widget.flatId != null) {
        await addRatingsStructureProvider.submitAllStructuralData(
          widget.structureId,
          widget.flatId!,
          context,
          structureSubType: widget.selectedStructureSubType,
          testingRequired: testingRequired,
        );
      } else if (widget.floorId != null) {
        await addRatingsStructureProvider.submitAllStructuralDataForFloor(
          widget.structureId,
          widget.floorId!,
          context,
          structureSubType: widget.selectedStructureSubType,
          testingRequired: testingRequired,
        );
      }

      // Success toast is shown by the provider
    } catch (e) {
      // Error toast is already shown by the provider; only log here
      debugPrint("❌ [STRUCTURAL] Submit failed: $e");
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Widget _buildRatingSection({
    required BuildContext context,
    required AddRatingsStructureProvider provider,
    required String title,
    required String type,
    required int index,
    required RatingItem item,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: w500_15Poppins()),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  if (provider.structuralRatingMap[type]!.length == 1) {
                    provider.removeStructuralStructureType(type);
                    CustomToast.showSuccessToast(msg: '$type removed');
                  } else {
                    provider.structuralRatingMap[type]!.removeAt(index);
                    provider.notifyListeners();
                    CustomToast.showSuccessToast(msg: '$title removed');
                  }
                },
                tooltip: 'Delete $title',
              ),
            ],
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.13,
                    height: 32.h,
                    child: CommonTextFormField(
                      controller: item.ratingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      fillColor: Appcolors.textformFillColor,
                      borderColor: Colors.grey.shade400,
                      hintText: "Rating",
                      hintStyle: w400_15Poppins(),
                      validator: (value, hintText) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a rating';
                        }
                        final intValue = int.tryParse(value);
                        if (intValue == null || intValue < 1 || intValue > 5) {
                          return 'Rating must be between 1 and 5';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final validatedValue = _validateAndConvertRating(value);
                        item.rating = validatedValue;
                        if (type == 'Foundation') {
                          _sharedFoundation[_fRating] = value;
                        }
                        provider.notifyListeners();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.21,
                    height: 32.h,
                    child: CommonTextFormField(
                      controller: item.commentController,
                      fillColor: Appcolors.textformFillColor,
                      borderColor: Colors.grey.shade400,
                      hintText: "Enter comment",
                      hintStyle: w400_15Poppins(),
                      onChanged: (value) {
                        item.comment = value;
                        if (type == 'Foundation') {
                          _sharedFoundation[_fComment] = value;
                        }
                        provider.notifyListeners();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 32.h,
                      child: _buildDistressTypesMultiSelect(
                        provider,
                        type,
                        index,
                        item,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_a_photo, size: 28),
                              onPressed: () =>
                                  _showImageSourceDialog(provider, type, index),
                              tooltip: 'Upload images',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            if (item.files != null && item.files!.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${item.files!.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file, size: 28),
                              onPressed: () =>
                                  _pickDocuments(provider, type, index),
                              tooltip: 'Upload PDF/Excel',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.orange.shade50,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            if (item.docFiles != null &&
                                item.docFiles!.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${item.docFiles!.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDistressUnitDropdown(
                provider: provider,
                type: type,
                item: item,
              ),
              if (item.distressUnit != DistressMeasurementUnit.nos) ...[
                width5,
                numberField(
                  label: "Length",
                  unitLabel: 'm',
                  controller: item.lengthController,
                  keyboardtype: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (val, String? f) {
                    return FormValidations.requiredFieldValidation(
                      val,
                      "Please enter length",
                    );
                  },
                ),
                if (item.distressUnit != DistressMeasurementUnit.rm) ...[
                  width5,
                  numberField(
                    label: "Breadth",
                    unitLabel: 'm',
                    controller: item.widthController,
                    keyboardtype: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (val, String? f) {
                      return FormValidations.requiredFieldValidation(
                        val,
                        "Please enter breadth",
                      );
                    },
                  ),
                ],
              ],
              if (item.distressUnit == DistressMeasurementUnit.cum) ...[
                width5,
                numberField(
                  label: "Height",
                  unitLabel: 'm',
                  controller: item.heightController,
                  keyboardtype: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (val, String? f) {
                    return FormValidations.requiredFieldValidation(
                      val,
                      "Please enter height",
                    );
                  },
                ),
              ],
              width5,
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Repair Methodology",
                      style: w400_12Poppins(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    height5,
                    SizedBox(
                      width: double.infinity,
                      child: CommonTextFormField(
                        controller: item.repairMethodologyController,
                        fillColor: Appcolors.textformFillColor,
                        borderColor: Colors.grey.shade400,
                        hintText: "Enter repair",
                        hintStyle: w400_15Poppins(),
                        onChanged: (value) {
                          item.repairMethodology = value;
                          if (type == 'Foundation') {
                            _sharedFoundation[_fRepair] = value;
                          }
                          provider.notifyListeners();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selected images — only shown when files exist
          if (item.files != null && item.files!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Images (${item.files!.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          'Add More',
                          style: w400_15Poppins(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _showImageSourceDialog(provider, type, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.files!.asMap().entries.map((e) {
                      final fi = e.key;
                      final file = e.value;
                      final ext = path
                          .extension(file.path)
                          .toLowerCase()
                          .replaceAll('.', '');
                      final isImg = [
                        'jpg',
                        'jpeg',
                        'png',
                        'gif',
                        'webp',
                      ].contains(ext);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: isImg
                                ? () => _showExpandedImage(localFile: file)
                                : null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isImg
                                  ? Image.file(
                                      file,
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _filePlaceholder(ext),
                                    )
                                  : _filePlaceholder(ext),
                            ),
                          ),
                          if (isImg)
                            Positioned(
                              bottom: 3,
                              right: 3,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => item.files!.removeAt(fi));
                                provider.notifyListeners();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Selected documents (PDF/Excel)
          if (item.docFiles != null && item.docFiles!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Files (${item.docFiles!.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          'Add More',
                          style: w400_15Poppins(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _pickDocuments(provider, type, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.docFiles!.asMap().entries.map((e) {
                      final fi = e.key;
                      final file = e.value;
                      final ext = path
                          .extension(file.path)
                          .toLowerCase()
                          .replaceAll('.', '');
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _filePlaceholder(ext),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => item.docFiles!.removeAt(fi));
                                provider.notifyListeners();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Server photos — ALL photos from API, tap to expand
          if (item.photoUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_download,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Photos From Server (${item.photoUrls.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.photoUrls
                        .map(
                          (url) => GestureDetector(
                            onTap: () => _showExpandedImage(networkUrl: url),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, c, p) => p == null
                                        ? c
                                        : Container(
                                            height: 90,
                                            width: 90,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 90,
                                      width: 90,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 3,
                                  right: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // Server documents — from API
          if (item.docUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_download,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Files From Server (${item.docUrls.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.docUrls.map((url) {
                      final ext = path
                          .extension(url)
                          .toLowerCase()
                          .replaceAll('.', '');
                      return _filePlaceholder(ext);
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ✅ NEW: Get file size helper
  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }

  List<String> _getDistressOptions(String componentType) {
    final isSteel = widget.selectedStructureSubType.toLowerCase() == 'steel';
    if (!isSteel) {
      return const ['physical', 'chemical', 'mechanical', 'none'];
    }

    final isPrimarySteel =
        componentType == 'Foundation' ||
        componentType == 'Columns' ||
        componentType == 'Beams';
    if (isPrimarySteel) {
      return const [
        'physical',
        'chemical',
        'mechanical',
        'corrosion',
        'section_loss',
        'warping',
        'none',
      ];
    }

    return const ['corrosion', 'section_loss', 'warping', 'none'];
  }

  String _distressLabel(String value) {
    switch (value) {
      case 'section_loss':
        return 'Section Loss';
      default:
        return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
    }
  }

  Future<void> _showDistressMultiSelectDialog({
    required AddRatingsStructureProvider provider,
    required String type,
    required int index,
    required RatingItem item,
  }) async {
    final options = _getDistressOptions(type);
    final mapKey = '$type|$index';
    final current = <String>{
      ...(_distressTypePerItem[mapKey] ?? item.distressTypes),
    };

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select distress types', style: w500_15Poppins()),
          content: SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                return ListView(
                  shrinkWrap: true,
                  children: options.map((opt) {
                    final checked = current.contains(opt);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(_distressLabel(opt), style: w400_14Poppins()),
                      onChanged: (val) {
                        setLocalState(() {
                          if (opt == 'none') {
                            current
                              ..clear()
                              ..add('none');
                          } else {
                            current.remove('none');
                            if (val == true) {
                              current.add(opt);
                            } else {
                              current.remove(opt);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, current),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        final selected = result.toList();
        _distressTypePerItem[mapKey] = selected;
        item.distressTypes = selected;
        if (type == 'Foundation') {
          _sharedFoundationDistress = List<String>.from(selected);
        }
      });
      provider.notifyListeners();
    }
  }

  Widget _buildDistressTypesMultiSelect(
    AddRatingsStructureProvider provider,
    String type,
    int index,
    RatingItem item,
  ) {
    final mapKey = '$type|$index';
    final selected = _distressTypePerItem[mapKey] ?? item.distressTypes;
    final label = selected.isEmpty
        ? 'Select distress types'
        : selected.map(_distressLabel).join(', ');

    return InkWell(
      onTap: () => _showDistressMultiSelectDialog(
        provider: provider,
        type: type,
        index: index,
        item: item,
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Appcolors.textformFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
        ),
        child: Text(
          label,
          style: w400_14Poppins(),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Image source choice dialog ──────────────────────────────────────────
  void _showImageSourceDialog(
    AddRatingsStructureProvider provider,
    String type,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Images', style: w500_15Poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.photo_library, color: Colors.blue.shade700),
              ),
              title: Text('Choose from Gallery', style: w400_14Poppins()),
              subtitle: Text('Select multiple images', style: w400_12Poppins()),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery(provider, type, index);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.camera_alt, color: Colors.green.shade700),
              ),
              title: Text('Take a Photo', style: w400_14Poppins()),
              subtitle: Text('Use device camera', style: w400_12Poppins()),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera(provider, type, index);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery(
    AddRatingsStructureProvider provider,
    String type,
    int index,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
      if (files.isNotEmpty) _addImages(provider, type, index, files);
    }
  }

  Future<void> _pickFromCamera(
    AddRatingsStructureProvider provider,
    String type,
    int index,
  ) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) _addImages(provider, type, index, [File(picked.path)]);
  }

  Future<void> _pickDocuments(
    AddRatingsStructureProvider provider,
    String type,
    int index,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['pdf', 'xls', 'xlsx'],
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
      if (files.isNotEmpty) _addDocuments(provider, type, index, files);
    }
  }

  void _addImages(
    AddRatingsStructureProvider provider,
    String type,
    int index,
    List<File> files,
  ) {
    final item = provider.structuralRatingMap[type]![index];
    item.files ??= [];
    item.files!.addAll(files);
    setState(() {});
    provider.notifyListeners();
    CustomToast.showSuccessToast(msg: '✅ ${files.length} image(s) added!');
  }

  void _addDocuments(
    AddRatingsStructureProvider provider,
    String type,
    int index,
    List<File> files,
  ) {
    final item = provider.structuralRatingMap[type]![index];
    item.docFiles ??= [];
    item.docFiles!.addAll(files);
    setState(() {});
    provider.notifyListeners();
    CustomToast.showSuccessToast(msg: '✅ ${files.length} file(s) added!');
  }

  void _showExpandedImage({File? localFile, String? networkUrl}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const SizedBox.expand(),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: localFile != null
                    ? Image.file(localFile, fit: BoxFit.contain)
                    : Image.network(
                        networkUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, c, p) => p == null
                            ? c
                            : const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filePlaceholder(String ext) {
    final c = _getFileColor('.$ext');
    return Container(
      height: 90,
      width: 90,
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon('.$ext'), color: c, size: 32),
          const SizedBox(height: 4),
          Text(
            ext.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: c,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else if (['xls', 'xlsx'].contains(extension)) {
      return 'spreadsheet';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'document';
    }
    return 'unknown';
  }

  IconData _getFileIcon(String fileExtension) {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image;
    } else if (ext == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (['xls', 'xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileExtension) {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Colors.green;
    } else if (ext == 'pdf') {
      return Colors.red;
    } else if (['xls', 'xlsx'].contains(ext)) {
      return Colors.teal;
    } else if (['doc', 'docx'].contains(ext)) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  Widget _buildFilePreview({
    required String filePath,
    required bool isExisting,
    String? fileName,
  }) {
    final fileType = _getFileType(filePath);
    final displayName = fileName ?? path.basename(filePath);

    if (fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isExisting
            ? Image.network(
                filePath,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.broken_image, size: 40),
                  );
                },
              )
            : Image.file(
                File(filePath),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
      );
    } else {
      final fileColor = _getFileColor(path.extension(filePath));
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fileColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fileColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(path.extension(filePath)),
              color: fileColor,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDistressUnitDropdown({
    required AddRatingsStructureProvider provider,
    required String type,
    required RatingItem item,
  }) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Units:",
            style: w400_12Poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          height5,
          SizedBox(
            height: 28.h,
            width: double.infinity,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<DistressMeasurementUnit>(
                isExpanded: true,
                value: item.distressUnit,
                items: DistressMeasurementUnit.values
                    .map(
                      (unit) => DropdownMenuItem<DistressMeasurementUnit>(
                        value: unit,
                        child: Text(unit.label, style: w400_12Poppins()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  provider.updateDistressUnit(item, value);
                  if (type == 'Foundation') {
                    _sharedFoundation[_fUnit] = value.apiValue;
                  }
                },
                buttonStyleData: ButtonStyleData(
                  height: 28.h,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                    color: Appcolors.textformFillColor,
                  ),
                ),
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 20,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(height: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// NOTE: returns an [Expanded], so it must only be used as a direct child
  /// of a [Row]. The width is no longer hard-coded off MediaQuery - the row
  /// divides whatever space is actually available, which is what stops the
  /// right-edge overflow.
  Widget numberField({
    required String label,
    String? unitLabel,
    required TextEditingController controller,
    String? Function(String?, String)? validator,
    TextInputType? keyboardtype,
    List<TextInputFormatter>? inputFormatters,
    int flex = 3,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unitLabel == null ? "$label:" : "$label ($unitLabel):",
            style: w400_12Poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          height5,
          SizedBox(
            height: 28.h,
            width: double.infinity,
            child: CommonTextFormField(
              controller: controller,
              fillColor: Appcolors.textformFillColor,
              borderColor: Colors.grey.shade400,
              validator: validator,
              hintText: "Enter $label",
              hintStyle: w400_14Poppins(),
              keyboardType: keyboardtype,
              inputFormatters: inputFormatters,
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: const Icon(Icons.arrow_drop_up),
                    onTap: () {
                      final val = double.tryParse(controller.text) ?? 0;
                      final next = val + 1;
                      controller.text = next % 1 == 0
                          ? next.toInt().toString()
                          : next.toString();
                    },
                  ),
                  GestureDetector(
                    child: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      final val = double.tryParse(controller.text) ?? 0;
                      final next = val - 1;
                      controller.text = next % 1 == 0
                          ? next.toInt().toString()
                          : next.toString();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _validateAndConvertRating(String value) {
    if (value.isEmpty) return null;
    final intValue = int.tryParse(value);
    if (intValue != null && intValue >= 1 && intValue <= 5) {
      return intValue;
    }
    return null;
  }
}
