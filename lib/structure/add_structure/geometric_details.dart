import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/floor_details.dart';
import 'package:sams_engineering_console/structure/add_structure/structural_nonstructural_revised.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/floating_action_bar.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/images.dart';

class Geometricdetails extends StatefulWidget {
  const Geometricdetails({
    super.key,
    required this.structureId,
    required this.selectedCommercialType,
    required this.selectedStructureType,
    required this.selectedStructureSubType,
  });

  final String structureId;
  final String selectedStructureType;
  final String selectedStructureSubType;
  final String selectedCommercialType;

  @override
  State<Geometricdetails> createState() => _GeometricdetailsState();
}

class _GeometricdetailsState extends State<Geometricdetails> {
  TextEditingController floorController = TextEditingController();
  TextEditingController parkingFloorController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController lengthController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  // Floor controllers
  List<TextEditingController> parkingFloorNoControllers = [];
  List<TextEditingController> parkingFloorNameControllers = [];
  List<String?> parkingFloorTypes = [];
  List<TextEditingController> floorNoControllers = [];

  late AddstructureProvider addstructureProvider;
  late GetstructureProvider getstructureProvider;

  bool showDropdown = false;
  String? selectedFloor;
  List<String> floorDropdownItems = [];
  int currentStep = 1;
  final _floorCountKey = GlobalKey<FormState>();
  final _floorDetailsKey = GlobalKey<FormState>();
  final _structureDimensionsKey = GlobalKey<FormState>();
  int _floorCount = 0;
  bool _isDataLoaded = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> floorDetailsList = [];
  List<GlobalKey<FloordetailsWidgetState>> floorWidgetKeys = [];
  List<String> selectedFloors = [];

  @override
  void initState() {
    super.initState();

    floorController.text = "0";
    parkingFloorController.text = "0";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      getstructureProvider = Provider.of<GetstructureProvider>(
        context,
        listen: false,
      );

      // Load geometric details first
      await getstructureProvider.getGeometricDetailsByStructureId(
        structureId: widget.structureId,
        context: context,
      );

      // Load existing floors
      await getstructureProvider.getFloorsByStructureId(
        structureId: widget.structureId,
        context: context,
      );

      if (!mounted) return;
      _populateExistingData();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        _showErrorMessage('Failed to load existing data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    addstructureProvider = Provider.of<AddstructureProvider>(
      context,
      listen: false,
    );
  }

  void _initializeControllers(int regularCount, int parkingCount) {
    // ✅ FIX 4: Add mounted check before disposing controllers
    if (!mounted) return;

    // Clear existing controllers for regular floors
    for (var controller in floorNoControllers) {
      controller.dispose();
    }
    floorNoControllers.clear();

    // Clear existing controllers for parking floors
    for (var controller in parkingFloorNoControllers) {
      controller.dispose();
    }
    parkingFloorNoControllers.clear();

    for (var controller in parkingFloorNameControllers) {
      controller.dispose();
    }
    parkingFloorNameControllers.clear();
    parkingFloorTypes.clear();

    // Create new controllers for regular floors
    for (int i = 0; i < regularCount; i++) {
      floorNoControllers.add(TextEditingController());
    }

    // Create new controllers for parking floors
    for (int i = 0; i < parkingCount; i++) {
      parkingFloorNoControllers.add(TextEditingController());
      parkingFloorNameControllers.add(TextEditingController());
      parkingFloorTypes.add(null);
    }
  }

  void _onFloorCountChanged() {
    if (!mounted) return; // ✅ FIX 5: Add mounted check

    final totalFloors = int.tryParse(floorController.text) ?? 0;
    final parkingFloors = (selectedValue == "Yes")
        ? (int.tryParse(parkingFloorController.text) ?? 0)
        : 0;

    final regularFloors = totalFloors;

    if (totalFloors < 0 || regularFloors < 0) return;

    print(
      '🔢 Floor count changed - Total: $totalFloors, Parking: $parkingFloors, Regular: $regularFloors',
    );

    setState(() {
      _floorCount = regularFloors;
      _initializeControllers(regularFloors, parkingFloors);
      _syncFloorDetailsList(_floorCount);
      selectedFloors.clear();

      if (!_isDataLoaded) {
        floorDropdownItems.clear();
      }

      print('✅ _floorCount set to: $_floorCount');
      print('✅ floorNoControllers.length: ${floorNoControllers.length}');
    });
  }

  void _syncFloorDetailsList(int count) {
    if (!mounted) return; // ✅ FIX 6: Add mounted check

    print('🔧 Syncing floor details list to $count items');

    // Remove excess items
    while (floorDetailsList.length > count) {
      final removedItem = floorDetailsList.removeLast();
      final controller =
          removedItem["numberOfFlatsController"] as TextEditingController;
      controller.dispose();

      final flatControllers =
          removedItem["flatNumberControllers"] as List<TextEditingController>;
      for (var flatController in flatControllers) {
        flatController.dispose();
      }

      floorWidgetKeys.removeLast();
      print('➖ Removed floor details item ${floorDetailsList.length + 1}');
    }

    // Add new items
    while (floorDetailsList.length < count) {
      final key = GlobalKey<FloordetailsWidgetState>();
      floorWidgetKeys.add(key);

      floorDetailsList.add({
        "selected": null,
        "numberOfFlatsController": TextEditingController(),
        "flatNumberControllers": <TextEditingController>[],
        "widgetKey": key,
      });
      print('➕ Added floor details item ${floorDetailsList.length}');
    }

    print('✅ Floor details list synced: ${floorDetailsList.length} items');
  }

  List<String> getAvailableFloors() {
    final usedFloors = selectedFloors.toSet();
    return floorDropdownItems.where((f) => !usedFloors.contains(f)).toList();
  }

  List<String> value = ["Yes", "No"];

  String? selectedValue;

  void _showErrorMessage(String message) {
    CustomToast.showErrorToast(msg: message);
  }

  void showSuccessMessage(String message) {
    CustomToast.showSuccessToast(msg: "${Text(message)}");
  }

  Widget _getStepWidget() {
    switch (currentStep) {
      case 1:
        return buildExpansionTileStep();
      case 2:
        return buildFloorDetailsStep();

      default:
        return SizedBox.shrink();
    }
  }

  Widget buildExpansionTileStep() {
    return Form(
      key: _floorCountKey,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                // Row(
                //   children: [
                //       Text(
                //     "Parking :",
                //     style: w500_16Poppins(),
                //   ),
                //   width5,
                //     Wrap(
                //           spacing: 12,
                //           runSpacing: 8,
                //           children: value.map((type) {
                //             return Row(
                //               mainAxisSize: MainAxisSize.min,
                //               children: [
                //                 Radio<String>(
                //                   value: type,
                //                   groupValue: selectedValue,
                //                   onChanged: (value) {
                //                     setState(() {
                //                       selectedValue = value;
                //                       // Recalculate floor count when parking changes
                //                       _onFloorCountChanged();
                //                     });
                //                   },
                //                 ),
                //                 Text(type, style: w400_14Poppins()),
                //               ],
                //             );
                //           }).toList(),
                //         ),
                //   ],
                // ),
                height10,
                // Show parking floor count when parking is "Yes"
                if (selectedValue == "Yes") ...[
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      backgroundColor: Colors.transparent,
                      childrenPadding: EdgeInsets.all(0),
                      title: Text(
                        "Number Of Parking Floors",
                        style: w500_16Poppins(),
                      ),
                      subtitle: CommonTextFormField(
                        controller: parkingFloorController,
                        fillColor: Appcolors.textformFillColor,
                        borderColor: Colors.grey.shade400,
                        validator: (val, String? f) {
                          return FormValidations.requiredFieldValidation(
                            val,
                            "Please enter no. of parking floors",
                          );
                        },
                        hintText: "Enter Number Of Parking Floors",
                        hintStyle: w400_17Poppins(),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          // Trigger floor count changed when user types
                          _onFloorCountChanged();
                        },
                        suffixIcon: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              child: Icon(Icons.arrow_drop_up),
                              onTap: () {
                                setState(() {
                                  final val =
                                      int.tryParse(
                                        parkingFloorController.text,
                                      ) ??
                                      0;
                                  parkingFloorController.text = (val + 1)
                                      .toString();
                                  _onFloorCountChanged();
                                });
                              },
                            ),
                            GestureDetector(
                              child: Icon(Icons.arrow_drop_down),
                              onTap: () {
                                setState(() {
                                  final val =
                                      int.tryParse(
                                        parkingFloorController.text,
                                      ) ??
                                      0;
                                  if (val > 0) {
                                    parkingFloorController.text = (val - 1)
                                        .toString();
                                    _onFloorCountChanged();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      trailing: Icon(Icons.arrow_drop_down),
                      children: [
                        Column(
                          children: [
                            // Parking floors detailed input
                            if (parkingFloorNoControllers.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  height: 242.h,
                                  child: ListView.builder(
                                    itemCount: parkingFloorNoControllers.length,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width:
                                            100.w, // Slightly increased width
                                        margin: EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Floor Number
                                              commonTextField(
                                                label: "Floor Number",
                                                controller:
                                                    parkingFloorNoControllers[index],
                                                validator: (val, String? f) {
                                                  return FormValidations.requiredFieldValidation(
                                                    val,
                                                    "Please enter floor number",
                                                  );
                                                },
                                              ),
                                              commonTextField(
                                                label: "Floor Area",
                                                controller:
                                                    parkingFloorNoControllers[index],
                                                validator: (val, String? f) {
                                                  return FormValidations.requiredFieldValidation(
                                                    val,
                                                    "Please enter floor area",
                                                  );
                                                },
                                              ),
                                              commonTextField(
                                                label: "Floor Name",
                                                controller:
                                                    parkingFloorNameControllers[index],
                                                validator: (val, String? f) {
                                                  return FormValidations.requiredFieldValidation(
                                                    val,
                                                    "Please enter floor name",
                                                  );
                                                },
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Floor Type",
                                                    style: w400_16Poppins(),
                                                  ),
                                                  height5,
                                                  SizedBox(
                                                    height: 45.h,
                                                    width: double.infinity,
                                                    child: DropdownButtonFormField<String>(
                                                      hint: Text(
                                                        "Select floor type",
                                                        style: w400_16Poppins(),
                                                      ),
                                                      value:
                                                          parkingFloorTypes[index],
                                                      isExpanded: true,
                                                      decoration: InputDecoration(
                                                        filled: true,
                                                        fillColor:
                                                            Colors.grey[100],
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade400,
                                                                  ),
                                                            ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade400,
                                                                  ),
                                                            ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                      items:
                                                          [
                                                            "stilt",
                                                            "cellar",
                                                            "sub cellar",
                                                            "sub cellar 1",
                                                            "sub cellar 2",
                                                            "sub cellar 3",
                                                            "sub cellar 4",
                                                            "sub cellar 5",
                                                          ].map((type) {
                                                            return DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: type,
                                                              child: Text(
                                                                type,
                                                                style:
                                                                    w400_16Poppins(),
                                                              ),
                                                            );
                                                          }).toList(),
                                                      dropdownColor: Appcolors
                                                          .textformFillColor,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          parkingFloorTypes[index] =
                                                              value;
                                                        });
                                                      },
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please select floor type';
                                                        }
                                                        return null;
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
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  height10,
                ],
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    backgroundColor: Colors.transparent,
                    childrenPadding: EdgeInsets.all(0),
                    title: Text(
                      "Number Of Floors ${selectedValue == "Yes" ? "(Excluding Parking)" : ""}",
                      style: w500_16Poppins(),
                    ),
                    subtitle: CommonTextFormField(
                      controller: floorController,
                      fillColor: Appcolors.textformFillColor,
                      borderColor: Colors.grey.shade400,
                      validator: (val, String? f) {
                        return FormValidations.requiredFieldValidation(
                          val,
                          "Please enter no. of floors",
                        );
                      },
                      hintText: "Enter Number Of Floors",
                      hintStyle: w400_17Poppins(),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        // Trigger floor count changed when user types
                        _onFloorCountChanged();
                      },
                      suffixIcon: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Icon(Icons.arrow_drop_up),
                            onTap: () {
                              setState(() {
                                final val =
                                    int.tryParse(floorController.text) ?? 0;
                                floorController.text = (val + 1).toString();
                                _onFloorCountChanged();
                              });
                            },
                          ),
                          GestureDetector(
                            child: Icon(Icons.arrow_drop_down),
                            onTap: () {
                              setState(() {
                                final val =
                                    int.tryParse(floorController.text) ?? 0;
                                if (val > 0) {
                                  floorController.text = (val - 1).toString();
                                  _onFloorCountChanged();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_drop_down),
                    children: [
                      Column(
                        children: [
                          GridView.builder(
                            itemCount: _floorCount,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.6,
                                ),
                            itemBuilder: (context, index) {
                              print(
                                '🏗️ Building floor item $index of $_floorCount',
                              );
                              return commonTextField(
                                label: "Floor No.",
                                controller: floorNoControllers[index],
                                validator: (val, String? f) {
                                  return FormValidations.requiredFieldValidation(
                                    val,
                                    "Please enter floor no.",
                                  );
                                },
                              );
                            },
                          ),
                          height5,
                          CustomButton(
                            height: 30.h,
                            width: 100.w,
                            buttonTextStyle: w500_15Poppins(),
                            buttonColor: Colors.transparent,
                            borderColor: Colors.grey.shade400,
                            onTap: () {
                              if (_floorCountKey.currentState?.validate() ??
                                  false) {
                                // ✅ Generate floor dropdown items from all controllers (parking + regular)
                                List<String> parkingFloorsEntered =
                                    parkingFloorNoControllers
                                        .map(
                                          (controller) =>
                                              controller.text.trim(),
                                        )
                                        .where((text) => text.isNotEmpty)
                                        .toList();

                                List<String> regularFloorsEntered =
                                    floorNoControllers
                                        .map(
                                          (controller) =>
                                              controller.text.trim(),
                                        )
                                        .where((text) => text.isNotEmpty)
                                        .toList();

                                // Combine parking and regular floors
                                List<String> allFloorsEntered = [
                                  ...parkingFloorsEntered,
                                  ...regularFloorsEntered,
                                ];

                                if (allFloorsEntered.isNotEmpty) {
                                  setState(() {
                                    // ✅ Only update if not already populated from existing data
                                    if (!_isDataLoaded) {
                                      floorDropdownItems = allFloorsEntered;
                                    }
                                    currentStep = 2;
                                  });
                                  print(
                                    '📋 Moving to step 2 with floors: $floorDropdownItems',
                                  );
                                } else {
                                  _showErrorMessage(
                                    'Please enter at least one floor number',
                                  );
                                }
                              }
                            },
                            buttonText: "Next",
                          ),
                        ],
                      ),
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

  Widget buildFloorDetailsStep() {
    print(
      '🏗️ Building floor details step with ${floorDetailsList.length} floors',
    );

    return Form(
      key: _floorDetailsKey,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Build exactly the number of floor widgets as specified
                ...List.generate(floorDetailsList.length, (index) {
                  final item = floorDetailsList[index];
                  final key =
                      item["widgetKey"] as GlobalKey<FloordetailsWidgetState>;

                  print(
                    '🔨 Building floor widget $index with key: ${key.toString()}',
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FloordetailsWidget(
                      structureId: widget.structureId,
                      key: key,
                      initialSelectedFloor: item["selected"],
                      floorDropdownItems: floorDropdownItems,
                      flatNumberControllers: item["flatNumberControllers"],
                      numberOfFlatsController: item["numberOfFlatsController"],
                      isEditMode: _isDataLoaded,
                      structureType: widget.selectedStructureType,
                      commercialType: widget.selectedCommercialType,
                      // FIXED: Pass list of already selected floors to filter dropdown
                      selectedFloorsFromOtherWidgets: selectedFloors
                          .where((floor) => floor != item["selected"])
                          .toList(),
                      onFloorChanged: (selected) {
                        setState(() {
                          // Remove previous selection
                          if (item["selected"] != null) {
                            selectedFloors.remove(item["selected"]);
                          }
                          // Add new selection
                          item["selected"] = selected;
                          selectedFloors.add(selected);
                        });
                        print(
                          '🔄 Floor $index selection changed to: $selected',
                        );
                      },
                      onFloorDataChanged: (Map<String, dynamic> floorData) {
                        // FIXED: Add mounted check to prevent setState on disposed widget
                        if (mounted) {
                          setState(() {
                            item["floorData"] = floorData;
                            final flats =
                                floorData['flats'] as List<dynamic>? ?? [];
                            item["flatNumbers"] = flats
                                .map(
                                  (flat) =>
                                      flat['flatNumber']?.toString() ?? '',
                                )
                                .where((flatNum) => flatNum.isNotEmpty)
                                .toList();
                          });
                        }
                      },
                    ),
                  );
                }),

                // Only show "Add Floor" button if there are available floors and we're not at max
                if (getAvailableFloors().isNotEmpty &&
                    floorDetailsList.length < floorDropdownItems.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        if (floorDetailsList.length <
                            floorDropdownItems.length) {
                          setState(() {
                            final key = GlobalKey<FloordetailsWidgetState>();
                            floorWidgetKeys.add(key);
                            floorDetailsList.add({
                              "selected": null,
                              "numberOfFlatsController":
                                  TextEditingController(),
                              "flatNumberControllers":
                                  <TextEditingController>[],
                              "widgetKey": key,
                            });
                          });
                          print(' Added new floor details widget');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appcolors.textformFillColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.grey[600]),
                      ),
                    ),
                  ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            currentStep = 1;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text("Back", style: w400_20Poppins()),
                      ),
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

  void _populateExistingData() {
    final geometricData =
        getstructureProvider.getGeometricDetailsByStrId?.data?.geometricDetails;
    final floors =
        getstructureProvider.getFloorsDetailsByStrId?.data?.floors ?? [];

    print('📊 Populating existing data...');
    print('📊 Geometric data: $geometricData');
    print('🏢 Floors count: ${floors.length}');

    if (geometricData != null) {
      setState(() {
        floorController.text = geometricData.numberOfFloors?.toString() ?? '';
        widthController.text = geometricData.structureWidth?.toString() ?? '';
        heightController.text = geometricData.structureHeight?.toString() ?? '';
        lengthController.text = geometricData.structureLength?.toString() ?? '';
      });
      print('✅ Geometric data populated');
    }

    if (floors.isNotEmpty) {
      setState(() {
        // FIXED: Use unique floor numbers only and filter out duplicates
        Map<String, dynamic> uniqueFloors = {};
        List<String> existingFloorNumbers = [];

        // Process floors and keep only unique floor numbers
        for (var floor in floors) {
          String floorNumber = floor.floorNumber?.toString() ?? '';
          if (floorNumber.isNotEmpty &&
              !uniqueFloors.containsKey(floorNumber)) {
            uniqueFloors[floorNumber] = floor;
            existingFloorNumbers.add(floorNumber);
          }
        }

        print(
          '🏢 Unique floors found: ${existingFloorNumbers.length} out of ${floors.length} total',
        );
        print('📋 Unique floor numbers: $existingFloorNumbers');

        // Use the count of unique floors
        _floorCount = existingFloorNumbers.length;

        // Initialize controllers based on unique floors only
        _initializeControllers(_floorCount, 0);

        // Populate controllers with unique floor numbers
        for (
          int i = 0;
          i < existingFloorNumbers.length && i < floorNoControllers.length;
          i++
        ) {
          floorNoControllers[i].text = existingFloorNumbers[i];
        }

        // Create dropdown items from unique floor numbers only
        floorDropdownItems = existingFloorNumbers;
        print('📋 Floor dropdown items: $floorDropdownItems');

        // Initialize floor details list to match unique floor count
        _syncFloorDetailsList(existingFloorNumbers.length);

        // Set initial selected floors for each floor detail widget
        selectedFloors.clear();
        for (
          int i = 0;
          i < existingFloorNumbers.length && i < floorDetailsList.length;
          i++
        ) {
          floorDetailsList[i]["selected"] = existingFloorNumbers[i];
          selectedFloors.add(existingFloorNumbers[i]);
        }

        _isDataLoaded = true;
      });

      // Force rebuild after state change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Empty setState to force rebuild
          });
          print('🔄 Forced rebuild after populating existing data');
        }
      });

      print('✅ All floors data populated successfully');
    } else {
      // FIXED: For new structure, don't set any default values - leave empty
      print('🆕 No existing floors, keeping fields empty for new structure');
      setState(() {
        _floorCount = 0;
        // Don't set any default values - let user enter everything
        _initializeControllers(0, 0);
        _syncFloorDetailsList(0);
      });
    }

    // Add listener only after data is populated
    floorController.addListener(_onFloorCountChanged);
  }

  Future<bool> _saveFloorDetails() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> allFloorsData = [];

      // ✅ 1. Validate all floor widgets
      for (var floorMap in floorDetailsList) {
        final key = floorMap['widgetKey'] as GlobalKey<FloordetailsWidgetState>;
        final widgetState = key.currentState;

        if (widgetState != null && widgetState.validate()) {
          final floorData = widgetState.getData();

          // ✅ 2. Add debugging to see what data we're getting
          print('📊 Floor data before processing: $floorData');

          allFloorsData.add(floorData);
        } else {
          return false;
        }
      }

      // ✅ 3. Process and validate data before sending
      List<Map<String, dynamic>> processedFloors = [];

      for (var floorData in allFloorsData) {
        // Convert string values to appropriate types
        final isParkingFloor = floorData['is_parking_floor'] ?? false;

        Map<String, dynamic> processedFloor = {
          "floor_number": floorData['selectedFloor'],
          "floor_height": _parseDouble(floorData['floorHeight']),
          "total_area_sq_mts": _parseDouble(floorData['floorArea']),
          "floor_label_name": floorData['floorLabelName'],
          "number_of_flats": _parseInt(floorData['numberOfFlats']),
          "floor_notes": "",
          "is_parking_floor": isParkingFloor,
        };

        // Add parking_floor_type only if it's a parking floor
        if (isParkingFloor && floorData['parking_floor_type'] != null) {
          processedFloor["parking_floor_type"] =
              floorData['parking_floor_type'];
        }

        // ✅ 4. Validate processed data
        if (_validateFloorData(processedFloor)) {
          processedFloors.add(processedFloor);
          print('✅ Processed floor: $processedFloor');
        } else {}
      }

      // ✅ 5. Save floors with better error handling
      final floorResponse = await addstructureProvider.addGeometricDataFloors(
        context: context,
        rawFloors: processedFloors,
        isUpdate: _isDataLoaded,
        structureId: widget.structureId,
      );

      print('📊 Floor response: $floorResponse');

      if (floorResponse == null) {
        _showErrorMessage('Failed to save floors - no response from server');
        return false;
      }

      if (floorResponse['success'] != true) {
        final errorMsg = floorResponse['message'] ?? 'Unknown error';
        _showErrorMessage('Failed to save floors: $errorMsg');
        return false;
      }

      // ✅ 6. Save flats for each floor
      final floors = floorResponse['data']['floors'] as List<dynamic>;
      bool allFlatsSuccess = true;

      for (int i = 0; i < floors.length && i < allFloorsData.length; i++) {
        final floorInfo = floors[i];
        final floorId = floorInfo['floor_id'] as String;
        final originalFloorData = allFloorsData[i];

        // Process flats data
        final flatsData = originalFloorData['flats'] as List<dynamic>;
        List<Map<String, dynamic>> processedFlats = [];

        for (var flat in flatsData) {
          final processedFlat = {
            "flat_number": flat['flatNumber'],
            "flat_type": flat['flatType'],
            "area_sq_mts": _parseDouble(flat['area_sq_mts'].toString()),
            "direction_facing": flat['flatDirection'],
            "occupancy_status": flat['occupancyStatus'],
            "flat_notes": "",
          };

          if (_validateFlatData(processedFlat)) {
            processedFlats.add(processedFlat);
          }
        }

        if (processedFlats.isNotEmpty) {
          final flatsResponse = await addstructureProvider
              .addGeometricFlatsByFloors(
                context: context,
                floorId: floorId,
                rawFlats: processedFlats,
                isUpdate: _isDataLoaded,
                structureId: widget.structureId,
              );

          if (flatsResponse == null || flatsResponse['success'] != true) {
            allFlatsSuccess = false;
            final errorMsg = flatsResponse?['message'] ?? 'Unknown error';
            _showErrorMessage(
              'Failed to save flats for floor ${floorInfo['floor_number']}: $errorMsg',
            );
            break;
          }
        }
      }

      if (allFlatsSuccess) {
        // FIXED: Reload floors data immediately after successful save
        // This ensures the provider has fresh data before UI rebuilds
        print('✅ Save successful, reloading floors data...');
        try {
          await getstructureProvider.getFloorsByStructureId(
            structureId: widget.structureId,
            context: context,
          );
          print('✅ Floors data reloaded successfully');
        } catch (e) {
          print('⚠️ Error reloading floors data: $e');
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Error saving floor details: $e');
      _showErrorMessage('Failed to save floor details: $e');
      return false;
    } finally {
      // FIXED: setState happens after reload is complete
      setState(() => _isLoading = false);
    }
  }

  // ✅ Helper method to safely parse double values
  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  // ✅ Helper method to safely parse int values
  int _parseInt(String? value) {
    if (value == null || value.trim().isEmpty)
      return 0; // Return 0 for empty strings
    return int.tryParse(value.trim()) ?? 0;
  }

  // Helper method to validate floor data (if not already present)
  bool _validateFloorData(Map<String, dynamic> floorData) {
    if (floorData['floor_number'] == null ||
        floorData['floor_number'].toString().isEmpty) {
      print('❌ Floor number is missing');
      return false;
    }

    if (floorData['floor_height'] == null || floorData['floor_height'] <= 0) {
      print('❌ Floor height is missing or invalid');
      return false;
    }
    if (floorData['total_area_sq_mts'] == null ||
        floorData['total_area_sq_mts'] <= 0) {
      print('❌ Floor area is missing or invalid');
      return false;
    }
    if (floorData['floor_label_name'] == null ||
        floorData['floor_label_name'].toString().isEmpty) {
      print('❌ Floor label name is missing');
      return false;
    }
    if (floorData['number_of_flats'] < 0) {
      print('❌ Number of flats is invalid (must be >= 0)');
      return false;
    }
    return true;
  }

  // ✅ Validate flat data before sending to API
  bool _validateFlatData(Map<String, dynamic> flatData) {
    if (flatData['flat_number'] == null ||
        flatData['flat_number'].toString().isEmpty) {
      print('❌ Flat number is missing');
      return false;
    }

    if (flatData['flat_type'] == null ||
        flatData['flat_type'].toString().isEmpty) {
      print('❌ Flat type is missing');
      return false;
    }

    if (flatData['area_sq_mts'] == null) {
      print('❌ Flat area is missing');
      return false;
    }

    if (flatData['direction_facing'] == null ||
        flatData['direction_facing'].toString().isEmpty) {
      print('❌ Flat direction is missing');
      return false;
    }

    if (flatData['occupancy_status'] == null ||
        flatData['occupancy_status'].toString().isEmpty) {
      print('❌ Flat occupancy status is missing');
      return false;
    }

    return true;
  }

  Widget numberField({
    required String label,
    required TextEditingController controller,
    String? Function(String?, String)? validator,
    TextInputType? keyboardtype,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label:", style: w500_15Poppins()),
        height5,
        SizedBox(
          height: 30.h,
          width: MediaQuery.of(context).size.width * 0.35,
          child: CommonTextFormField(
            controller: controller,
            fillColor: Appcolors.textformFillColor,
            borderColor: Colors.grey.shade400,
            validator: validator,
            hintText: "Enter $label",
            hintStyle: w400_14Poppins(),
            keyboardType: keyboardtype,
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Icon(Icons.arrow_drop_up),
                  onTap: () {
                    final val = int.tryParse(controller.text) ?? 0;
                    controller.text = (val + 1).toString();
                  },
                ),
                GestureDetector(
                  child: Icon(Icons.arrow_drop_down),
                  onTap: () {
                    final val = int.tryParse(controller.text) ?? 0;
                    controller.text = (val - 1).toString();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fix 3: Update the commonTextField widget to handle null values properly
  Widget commonTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?, String)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: w600_16Poppins()),
        height5,
        SizedBox(
          height: 40.h,
          width: MediaQuery.of(context).size.width * 0.24,
          child: CommonTextFormField(
            fillColor: Appcolors.textformFillColor,
            borderColor: Colors.grey.shade400,
            controller: controller,
            hintText: "Enter $label",
            keyboardType: keyboardType,
            validator: validator,
            hintStyle: w400_17Poppins(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AddstructureProvider, GetstructureProvider>(
      builder: (context, addStructureProvider, getStructureProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          extendBody: true,
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...', style: w400_16Poppins()),
                    ],
                  ),
                )
              : Form(
                  key: _structureDimensionsKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: FloatingActionBar.contentBottomPadding(context),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Geometric Details",
                                    style: w700_20Poppins(),
                                  ),
                                  if (_isDataLoaded) ...[
                                    CustomButton(
                                      buttonText: "Skip",
                                      borderRadius: 10.r,
                                      buttonColor: currentStep == 2
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      buttonTextStyle: w700_15Poppins(
                                        color: currentStep == 2
                                            ? Appcolors.buttonColor
                                            : Colors.grey.shade500,
                                      ),
                                      width: 60.w,
                                      height: 30.h,
                                      borderColor: currentStep == 2
                                          ? Appcolors.buttonColor
                                          : Colors.grey.shade400,
                                      onTap: currentStep == 2
                                          ? () async {
                                              // Navigate directly using existing data
                                              final addStructureProvider =
                                                  Provider.of<
                                                    AddstructureProvider
                                                  >(context, listen: false);
                                              onSubmit(addStructureProvider);
                                            }
                                          : null,
                                    ),
                                    width10,
                                  ],
                                ],
                              ),
                              height10,
                              _getStepWidget(),
                              height10,
                              Row(
                                children: [
                                  numberField(
                                    label: "Structure Width (M)",
                                    controller: widthController,
                                    validator: (val, String? f) {
                                      return FormValidations.requiredFieldValidation(
                                        val,
                                        "Please enter structure width",
                                      );
                                    },
                                  ),
                                  width10,
                                  numberField(
                                    label: "Structure Length (M)",
                                    controller: lengthController,
                                    validator: (val, String? f) {
                                      return FormValidations.requiredFieldValidation(
                                        val,
                                        "Please enter structure length",
                                      );
                                    },
                                  ),
                                ],
                              ),
                              height10,
                              Row(
                                children: [
                                  numberField(
                                    label: "Total Height (M)",
                                    controller: heightController,
                                    validator: (val, String? f) {
                                      return FormValidations.requiredFieldValidation(
                                        val,
                                        "Please enter total height",
                                      );
                                    },
                                  ),
                                  width10,
                                ],
                              ),
                              height10,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: FloatingActionBar(
            children: [
              CustomButton(
                buttonText: "Back",
                borderRadius: 10.r,
                buttonColor: Colors.transparent,
                buttonTextStyle: w700_15Poppins(color: Appcolors.buttonColor),
                width: 140.w,
                height: 40.h,
                borderColor: Appcolors.buttonColor,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              CustomButton(
                buttonText: "Next",
                borderRadius: 10.r,
                buttonColor: currentStep == 2
                    ? Appcolors.buttonColor
                    : Colors.grey.shade300,
                buttonTextStyle: w700_15Poppins(
                  color: currentStep == 2 ? Colors.white : Colors.grey.shade500,
                ),
                width: 170.w,
                height: 40.h,
                borderColor: currentStep == 2
                    ? Appcolors.buttonColor
                    : Colors.grey.shade400,
                onTap: currentStep == 2
                    ? () async {
                        if (_structureDimensionsKey.currentState?.validate() ??
                            false) {
                          final getStructureProvider =
                              Provider.of<GetstructureProvider>(
                                context,
                                listen: false,
                              );

                          final addStructureProvider =
                              Provider.of<AddstructureProvider>(
                                context,
                                listen: false,
                              );

                          final isUpdate =
                              getStructureProvider
                                  .getGeometricDetailsByStrId
                                  ?.data !=
                              null;

                          await addStructureProvider.submitGeometricData(
                            context,
                            floorController.text,
                            widthController.text,
                            lengthController.text,
                            heightController.text,
                            isUpdate,
                            widget.structureId,
                          );

                          onSubmit(
                            addStructureProvider,
                          ); // your navigation or next step
                        }
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  // UPDATED NAVIGATION LOGIC
  void onSubmit(AddstructureProvider addstructureProvider) async {
    List<FlatRatingData> allFlatRatings = [];
    List<String> allFlatNumbers = [];
    Map<String, Map<String, String>> allFlatInfoByNumber = {};
    List<String> allFloorNumbers = [];
    Map<String, Map<String, String>> allFloorInfoByNumber = {};

    try {
      print(
        '🗗️ Starting onSubmit with ${floorDetailsList.length} floor details',
      );
      print('🏗️ Structure type: ${widget.selectedStructureType}');
      print('🏢 Commercial type: ${widget.selectedCommercialType}');

      // Get existing floors and their flats
      final existingFloors =
          getstructureProvider.getFloorsDetailsByStrId?.data?.floors ?? [];
      Map<String, String> existingFloorIds = {};

      // Build map of existing floor numbers to floor IDs
      for (var floor in existingFloors) {
        final floorNumber = floor.floorNumber?.toString() ?? '';
        final floorId = floor.floorId ?? '';
        if (floorNumber.isNotEmpty && floorId.isNotEmpty) {
          existingFloorIds[floorNumber] = floorId;
          print('📋 Found existing floor: "$floorNumber" (ID: $floorId)');
        }
      }

      for (
        int floorIndex = 0;
        floorIndex < floorDetailsList.length;
        floorIndex++
      ) {
        final floorMap = floorDetailsList[floorIndex];
        final key = floorMap['widgetKey'] as GlobalKey<FloordetailsWidgetState>;
        final widgetState = key.currentState;
        final data = widgetState?.getData();

        if (data == null) {
          print('⚠️ No data from floor widget $floorIndex');
          continue;
        }

        final floorNumber = data['selectedFloor']?.toString() ?? '';
        if (floorNumber.isEmpty) {
          print('⚠️ Floor number is empty for floor $floorIndex');
          continue;
        }

        final isParkingFloor = data['is_parking_floor'] ?? false;
        final numberOfFlats = int.tryParse(data['numberOfFlats'] ?? '0') ?? 0;

        print('🏢 Processing floor: "$floorNumber"');
        print('  Is parking floor: $isParkingFloor');
        print('  Number of flats: $numberOfFlats');

        // Check if floor exists
        String floorId = existingFloorIds[floorNumber] ?? '';
        bool isFloorUpdate = floorId.isNotEmpty;

        if (!isFloorUpdate) {
          // CREATE new floor
          Map<String, dynamic> floorPayload = {
            "floor_number": floorNumber,
            "floor_height": data['floorHeight'],
            "total_area_sq_mts": data['floorArea'],
            "floor_label_name": data['floorLabelName'],
            "number_of_flats": numberOfFlats,
            "floor_notes": "",
            "is_parking_floor": isParkingFloor,
          };

          // Add parking_floor_type only if it's a parking floor
          if (isParkingFloor && data['parking_floor_type'] != null) {
            floorPayload["parking_floor_type"] = data['parking_floor_type'];
          }

          print('🆕 Creating new floor...');
          final floorResponse = await addstructureProvider
              .addGeometricDataFloors(
                context: context,
                rawFloors: [floorPayload],
                isUpdate: false,
                structureId: widget.structureId,
              );

          if (floorResponse == null || floorResponse['success'] != true) {
            print("⚠️ Failed to add floor: $floorNumber");
            continue;
          }

          final floors = floorResponse['data']['floors'] as List<dynamic>;
          if (floors.isEmpty) {
            print("⚠️ No floors returned in response");
            continue;
          }

          floorId = floors[0]['floor_id'] as String;
          print('✅ Floor created successfully: "$floorNumber" (ID: $floorId)');
        } else {
          print('🔄 Using existing floor ID: $floorId');
        }

        // ✅ CRITICAL: Always collect floor data regardless of whether it has flats
        print('📝 Adding floor to collections: $floorNumber');
        allFloorNumbers.add(floorNumber);
        allFloorInfoByNumber[floorNumber] = {
          'floorId': floorId,
          'floorNumber': floorNumber,
          'floorType': data['selectedFloorType']?.toString() ?? '',
          'floorArea': data['floorArea']?.toString() ?? '',
          'floorHeight': data['floorHeight']?.toString() ?? '',
          'floorLabelName': data['floorLabelName']?.toString() ?? '',
          'numberOfFlats': numberOfFlats.toString(),
          'isParkingFloor': isParkingFloor.toString(),
        };
        print('✅ Floor "$floorNumber" added to collections');
        print('   Total floors collected so far: ${allFloorNumbers.length}');

        // Process flats if they exist
        final flatsFromData = data['flats'] as List? ?? [];
        print(
          '🏠 Floor "$floorNumber" has ${flatsFromData.length} flats in data',
        );

        if (flatsFromData.isNotEmpty) {
          // Prepare flats payload
          List<Map<String, dynamic>> flatsPayload = [];

          for (var flat in flatsFromData) {
            final flatNumber = flat['flatNumber']?.toString().trim() ?? '';
            if (flatNumber.isEmpty) continue;

            final flatData = {
              "flat_number": flatNumber,
              "flat_type": flat['flatType']?.toString().trim() ?? '',
              "area_sq_mts": flat['area_sq_mts'],
              "direction_facing":
                  flat['flatDirection']?.toString().trim() ?? '',
              "occupancy_status":
                  flat['occupancyStatus']?.toString().trim() ?? '',
              "flat_notes": "",
            };

            flatsPayload.add(flatData);
          }

          if (flatsPayload.isNotEmpty) {
            print(
              '📤 Processing ${flatsPayload.length} flats for floor $floorNumber...',
            );

            final flatsResponse = await addstructureProvider
                .addGeometricFlatsByFloors(
                  context: context,
                  floorId: floorId,
                  rawFlats: flatsPayload,
                  isUpdate: true,
                  structureId: widget.structureId,
                );

            if (flatsResponse != null && flatsResponse['success'] == true) {
              final flatsJson =
                  flatsResponse['data']['flats'] as List<dynamic>? ?? [];
              _processFlatsForNavigation(
                flatsJson,
                floorId,
                floorNumber,
                allFlatNumbers,
                allFlatInfoByNumber,
                allFlatRatings,
              );
              print(
                '✅ Processed ${flatsJson.length} flats for floor $floorNumber',
              );
              print(
                '   Total flats collected so far: ${allFlatNumbers.length}',
              );
            } else {
              print('⚠️ Failed to process flats for floor $floorNumber');
              _showErrorMessage('Failed to save flats for floor $floorNumber');
            }
          }
        } else {
          print(
            'ℹ️ Floor "$floorNumber" has no flats (OK for parking/commercial floors)',
          );
        }

        print(''); // Empty line for readability
      }

      // Determine navigation type based on collected data
      String navigationType = _getNavigationType(
        allFloorNumbers,
        allFlatNumbers,
      );
      print('📋 Navigation strategy determined: $navigationType');
      print('📊 Data collected:');
      print('  - Floors: ${allFloorNumbers.length}');
      print('  - Flats: ${allFlatNumbers.length}');

      // Navigation logic based on structure type
      switch (navigationType) {
        case 'flats_only':
          // Navigate with flat data only
          if (allFlatNumbers.isEmpty) {
            _showErrorMessage(
              'No flats data available for navigation. Please add floors and flats first.',
            );
            return;
          }

          print('📋 Final Navigation Data Summary (FLATS ONLY):');
          print('  Total flats collected: ${allFlatNumbers.length}');
          print('  Flat numbers: $allFlatNumbers');

          print(
            '🚀 Navigating to StructuralNonstructuralrating with FLATS ONLY...',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StructuralNonstructuralrating(
                structureId: widget.structureId,
                flatNumbers: allFlatNumbers,
                flatInfoByNumber: allFlatInfoByNumber,
                navigationType: 'flats_only',
                selectedStructureSubType: widget.selectedStructureSubType,
              ),
            ),
          );
          break;

        case 'floors_only':
          // Navigate with floor data only
          if (allFloorNumbers.isEmpty) {
            return;
          }

          print('📋 Final Navigation Data Summary (FLOORS ONLY):');
          print('  Total floors collected: ${allFloorNumbers.length}');
          print('  Floor numbers: $allFloorNumbers');

          print(
            '🚀 Navigating to StructuralNonstructuralrating with FLOORS ONLY...',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StructuralNonstructuralrating(
                structureId: widget.structureId,
                floorNumbers: allFloorNumbers,
                floorInfoByNumber: allFloorInfoByNumber,
                navigationType: 'floors_only',
                selectedStructureSubType: widget.selectedStructureSubType,
              ),
            ),
          );
          break;

        case 'both':
          // Navigate with both floor and flat data
          if (allFloorNumbers.isEmpty && allFlatNumbers.isEmpty) {
            _showErrorMessage(
              'No floors or flats data available for navigation. Please add floors and flats first.',
            );
            return;
          }

          print('📋 Final Navigation Data Summary (BOTH FLOORS AND FLATS):');
          print('  Total floors collected: ${allFloorNumbers.length}');
          print('  Floor numbers: $allFloorNumbers');
          print('  Total flats collected: ${allFlatNumbers.length}');
          print('  Flat numbers: $allFlatNumbers');

          print('🚀 Navigating to StructuralNonstructuralrating with BOTH...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StructuralNonstructuralrating(
                structureId: widget.structureId,
                flatNumbers: allFlatNumbers,
                flatInfoByNumber: allFlatInfoByNumber,
                floorNumbers: allFloorNumbers,
                floorInfoByNumber: allFloorInfoByNumber,
                structureType: widget
                    .selectedStructureType, // e.g., 'residential', 'commercial', 'industrial'
                commercialType: widget.selectedCommercialType,
                selectedStructureSubType: widget.selectedStructureSubType,
              ),
            ),
          );
          break;

        default:
          _showErrorMessage('Invalid navigation type determined.');
          break;
      }
    } catch (e, stackTrace) {
      print('⌚ Error in onSubmit: $e');
      print('📋 Stack trace: $stackTrace');
      _showErrorMessage('Failed to process floor and flat data: $e');
    }
  }

  String _getNavigationType(
    List<String> collectedFloors,
    List<String> collectedFlats,
  ) {
    final structureType = widget.selectedStructureType.toLowerCase();
    final commercialType = widget.selectedCommercialType.toLowerCase();

    print('🔍 Evaluating navigation type:');
    print('  Structure type: $structureType');
    print('  Commercial type: $commercialType');
    print('  Collected floors: ${collectedFloors.length}');
    print('  Collected flats: ${collectedFlats.length}');

    // MODIFICATION: Always use floors_only for ratings
    // Flats are ignored - only floor-level ratings will be performed
    if (collectedFloors.isNotEmpty) {
      print('  ✅ Floors available -> Use FLOORS ONLY (flats ignored)');
      return 'floors_only';
    }

    // Fallback if no floors are collected
    print('  ⚠️ No floors collected -> Defaulting to FLOORS ONLY');
    return 'floors_only';
  }

  void _processFlatsForNavigation(
    List<dynamic> flatsJson,
    String floorId,
    String floorNumber,
    List<String> allFlatNumbers,
    Map<String, Map<String, String>> allFlatInfoByNumber,
    List<FlatRatingData> allFlatRatings,
  ) {
    print('🏠 Processing ${flatsJson.length} flats for navigation...');

    for (var flatJson in flatsJson) {
      print('🔍 Processing flat JSON: $flatJson');

      // Handle different response structures
      Map<String, dynamic> flatData;

      // Check if this is a PUT response (has updated_flat) or POST response (direct flat data)
      if (flatJson.containsKey('updated_flat')) {
        // PUT response structure
        flatData = flatJson['updated_flat'] as Map<String, dynamic>;
        print('📝 Using updated_flat structure');
      } else {
        // POST response structure or direct flat data
        flatData = flatJson as Map<String, dynamic>;
        print('📝 Using direct flat structure');
      }

      // Safe null-aware casting
      final flatNumber = flatData['flat_number']?.toString() ?? '';
      final flatId =
          flatData['flat_id']?.toString() ??
          flatData['id']?.toString() ??
          flatJson['flat_id']?.toString() ?? // Fallback to parent level
          '';

      // Skip if essential data is missing
      if (flatNumber.isEmpty) {
        print('⚠️ Skipping flat with empty flat_number');
        continue;
      }

      if (flatId.isEmpty) {
        print('⚠️ Skipping flat $flatNumber - missing flat_id');
        continue;
      }

      print('✅ Adding flat: $flatNumber (ID: $flatId)');

      allFlatNumbers.add(flatNumber);

      // Use the original flatJson data to get complete information, fallback to flatData
      allFlatInfoByNumber[flatNumber] = {
        'flatId': flatId,
        'floorId': floorId,
        'floorNumber': floorNumber,
        'flatType':
            flatData['flat_type']?.toString() ??
            flatJson['flat_type']?.toString() ??
            'Unknown',
        'direction':
            flatData['direction_facing']?.toString() ??
            flatJson['direction_facing']?.toString() ??
            'Unknown',
        'occupancy':
            flatData['occupancy_status']?.toString() ??
            flatJson['occupancy_status']?.toString() ??
            'Unknown',
        'area':
            flatData['area_sq_mts']?.toString() ??
            flatJson['area_sq_mts']?.toString() ??
            '0',
      };

      allFlatRatings.add(
        FlatRatingData(
          flatId: flatId,
          flatNumber: flatNumber,
          floorId: floorId,
        ),
      );
    }

    print('📊 Navigation data processed: ${allFlatNumbers.length} flats total');
  }

  @override
  void dispose() {
    floorController.dispose();
    parkingFloorController.dispose();
    widthController.dispose();
    lengthController.dispose();
    heightController.dispose();

    for (var controller in floorNoControllers) {
      controller.dispose();
    }
    floorNoControllers.clear();
    for (var controller in parkingFloorNoControllers) {
      controller.dispose();
    }
    parkingFloorNoControllers.clear();

    for (var controller in parkingFloorNameControllers) {
      controller.dispose();
    }
    parkingFloorNameControllers.clear();

    for (var floorDetails in floorDetailsList) {
      final numberOfFlatsController =
          floorDetails["numberOfFlatsController"] as TextEditingController?;
      numberOfFlatsController?.dispose();

      final flatNumberControllers =
          floorDetails["flatNumberControllers"] as List<TextEditingController>?;
      if (flatNumberControllers != null) {
        for (var controller in flatNumberControllers) {
          controller.dispose();
        }
      }
    }
    floorDetailsList.clear();
    floorWidgetKeys.clear();

    super.dispose();
  }
}
