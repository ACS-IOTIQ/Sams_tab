// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/models/floor_idby_flatby_strid_model.dart';
import 'package:sams_engineering_console/models/get_floor_bystrid_model.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/structure_view/view_form_widgets.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/module_header.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';



class GetGeometricdetails extends StatefulWidget {
  const GetGeometricdetails({super.key, required this.structureId});
  final String structureId;

  @override
  State<GetGeometricdetails> createState() => _GetGeometricdetailsState();
}

class _GetGeometricdetailsState extends State<GetGeometricdetails> {
  late GetstructureProvider getstructureProvider;
  bool isLoading = true;
  String? errorMessage;
  TextEditingController updateController = TextEditingController();

  // Store ratings data locally to avoid overwriting issues
  Map<String, dynamic> structuralRatings = {};
  Map<String, dynamic> nonStructuralRatings = {};

  @override
  void initState() {
    super.initState();
    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );
    _initializeData();
  }

  @override
  void dispose() {
    updateController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Step 1: Get geometric details for the selected structure only.
      await getstructureProvider.getGeometricDetailsByStructureId(
        structureId: widget.structureId,
        context: context,
      );

      // Step 2: Get floors
      await getstructureProvider.getFloorsByStructureId(
        structureId: widget.structureId,
        context: context,
      );

      // Step 3: Get flats and ratings for each floor sequentially
      final List<Floor> floors =
          getstructureProvider.getFloorsDetailsByStrId?.data?.floors ?? [];

      for (final floor in floors) {
        if (floor.floorId != null) {
          await _processFloorData(floor);
        }
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _processFloorData(Floor floor) async {
    try {
      // Get flats for this floor
      await getstructureProvider.getFlatsWithDetailsByFloorId(
        structureId: widget.structureId,
        floorId: floor.floorId!,
        context: context,
      );
    } catch (e) {
      print('Warning: Failed to process floor ${floor.floorId}: $e');
    }
  }

  Future<void> loadFlatsData(String floorId) async {
    print('🔄 Loading flats data for floor ID: $floorId');

    try {
      final existingFlatsData = getstructureProvider.getFlatsByFloorId(floorId);

      if (existingFlatsData == null) {
        print('📡 Fetching flats data from API...');
        await getstructureProvider.getFlatsWithDetailsByFloorId(
          structureId: widget.structureId,
          floorId: floorId,
          context: context,
        );
        print("floor id $floorId");
      }
    } catch (e) {
      print('❌ Error loading flats data: $e');
    }
  }

  Widget _buildGeometricDetailsSection(dynamic geometricData) {
    return ViewSectionCard(
      title: 'Geometric Details',
      subtitle: 'Overall structure dimensions and floor count.',
      child: ViewDetailGrid(
        items: [
          ViewDetailItemData(
            label: 'Number of Floors',
            value: _displayValue(geometricData.numberOfFloors),
            icon: Icons.layers_outlined,
          ),
          ViewDetailItemData(
            label: 'Structure Height',
            value: _displayValue(geometricData.structureHeight),
            icon: Icons.height_rounded,
          ),
          ViewDetailItemData(
            label: 'Structure Width',
            value: _displayValue(geometricData.structureWidth),
            icon: Icons.straighten_rounded,
          ),
          ViewDetailItemData(
            label: 'Structure Length',
            value: _displayValue(geometricData.structureLength),
            icon: Icons.swap_horiz_rounded,
          ),
          ViewDetailItemData(
            label: 'Total Area',
            value: _displayValue(geometricData.totalArea),
            icon: Icons.square_foot_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSection(
    Floor floor,
    GetstructureProvider getStructureProvider,
  ) {
    final flatsData = getStructureProvider.getFlatsByFloorId(
      floor.floorId ?? "",
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ViewSectionCard(
        title: 'Floor ${_displayValue(floor.floorNumber)}',
        subtitle: 'Floor specification and associated flat summaries.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFloorDetailsRow(floor),
            SizedBox(height: 14.h),
            flatsData?.data.flats == null || flatsData!.data.flats.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        "No flats available",
                        style: w400_15Poppins(color: const Color(0xff667085)),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 172.h,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: flatsData.data.flats.length,
                      itemBuilder: (context, flatIndex) {
                        final flatDetails = flatsData.data.flats[flatIndex];
                        return _buildFlatCard(flatDetails);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorDetailsRow(Floor floor) {
    return ViewDetailGrid(
      items: [
        ViewDetailItemData(
          label: 'Floor Number',
          value: _displayValue(floor.floorNumber),
          icon: Icons.tag_outlined,
        ),
        // `Floor` has no `floorType` field — this was the NoSuchMethodError.
        // Derived from the two fields that do exist on the model.
        ViewDetailItemData(
          label: 'Floor Type',
          value: floor.isParkingFloor == true
              ? _displayValue(floor.parkingFloorType)
              : 'Residential',
          icon: Icons.dashboard_outlined,
        ),
        ViewDetailItemData(
          label: 'Floor Label Name',
          value: _displayValue(floor.floorLabelName),
          icon: Icons.label_outline_rounded,
        ),
        ViewDetailItemData(
          label: 'Floor Height',
          value: _displayValue(floor.floorHeight),
          icon: Icons.height_rounded,
        ),
        ViewDetailItemData(
          label: 'Total Area (sq. m)',
          value: _displayValue(floor.totalAreaSqMts),
          icon: Icons.square_foot_rounded,
        ),
        ViewDetailItemData(
          label: 'Number of Flats',
          value: _displayValue(floor.numberOfFlats),
          icon: Icons.meeting_room_outlined,
        ),
      ],
    );
  }

  Widget _buildFlatCard(Flat flatDetails) {
    final flatId = flatDetails.flatId;
    // Debug print to check if ratings are available
    print('🏠 Building card for flat ${flatDetails.flatNumber} (ID: $flatId)');
    return Container(
      width: 248.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        border: Border.all(color: const Color(0xffE2E8F0)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Flat Number: ${_displayValue(flatDetails.flatNumber)}",
              style: w500_15Poppins(color: const Color(0xff101828)),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _flatInfoRow('Area', _displayValue(flatDetails.areaSqMts)),
                  _flatInfoRow(
                    'Flat Type',
                    _displayValue(flatDetails.flatType),
                  ),
                  _flatInfoRow(
                    'Occupancy Status',
                    _displayValue(flatDetails.occupancyStatus),
                  ),
                  _flatInfoRow(
                    'Direction Facing',
                    _displayValue(flatDetails.directionFacing),
                  ),
                  // `overallAverage` is nullable and absent from the current
                  // API response, so these render "N/A" rather than throwing.
                  // _flatInfoRow(
                  //   'Structural Rating',
                  //   _displayValue(flatDetails.structuralRating.overallAverage),
                  // ),
                  // _flatInfoRow(
                  //   'Non-Structural Rating',
                  //   _displayValue(
                  //     flatDetails.nonStructuralRating.overallAverage,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<GetstructureProvider>(
      builder: (context, commonProvider, child) {
        return ViewFormBottomBar(
          primaryLabel: 'Submit',
          onPrimaryTap: () {
            commonProvider.addRemarks(
              context,
              widget.structureId,
              updateController.text,
            );
          },
          secondaryLabel: 'Back',
          onSecondaryTap: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: const ModuleBackArrow(),
        leadingWidth: 42.w,
        titleSpacing: 2.w,
        title: const ModuleHeaderTitle(title: 'Geometric Details'),
      ),
      body: Consumer<GetstructureProvider>(
        builder: (context, getStructureProvider, child) {
          if (errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $errorMessage'),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final geometricData = getstructureProvider
              .getGeometricDetailsByStrId
              ?.data
              ?.geometricDetails;
          final List<Floor> floors =
              getStructureProvider.getFloorsDetailsByStrId?.data?.floors ?? [];

          // Check if essential data is available
          if (geometricData == null || floors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ViewFormPage(
            children: [
              _buildGeometricDetailsSection(geometricData),
              SizedBox(height: 12.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // Drive off the actual list, not the declared floor count.
                itemCount: floors.length,
                itemBuilder: (context, index) {
                  return _buildFloorSection(
                    floors[index],
                    getStructureProvider,
                  );
                },
              ),
              ViewSectionCard(
                title: 'Update Remarks',
                subtitle:
                    'Capture final review notes before submitting this view form.',
                child: CommonTextFormField(
                  controller: updateController,
                  maxLines: 4,
                  hintText: "Enter remarks",
                  hintStyle: w400_15Poppins(color: const Color(0xff98A2B3)),
                  borderColor: const Color(0xffD0D5DD),
                  fillColor: const Color(0xffF8FAFC),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

String _displayValue(dynamic value) {
  if (value == null) return 'N/A';
  final text = value.toString().trim();
  return text.isEmpty ? 'N/A' : text;
}

Widget _flatInfoRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: w500_12Poppins(color: const Color(0xff667085)),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: w600_13Poppins(color: const Color(0xff101828)),
          ),
        ),
      ],
    ),
  );
}