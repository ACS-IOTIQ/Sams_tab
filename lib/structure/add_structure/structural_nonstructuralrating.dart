// import 'package:buttons_tabbar/buttons_tabbar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import 'package:sams_engineering_console/provider/addStructure_provider.dart';
// import 'package:sams_engineering_console/provider/addStructure_ratings_provider.dart';
// import 'package:sams_engineering_console/provider/getStructure_provider.dart';
// import 'package:sams_engineering_console/structure/add_structure/nonstructural_rating.dart';
// import 'package:sams_engineering_console/structure/add_structure/nonstructural_rating_revised.dart';
// import 'package:sams_engineering_console/structure/add_structure/structural_rating_revised.dart';
// import 'package:sams_engineering_console/structure/structure_list.dart';
// import 'package:sams_engineering_console/utils/appColors.dart';
// import 'package:sams_engineering_console/utils/app_fonts.dart';
// import 'package:sams_engineering_console/utils/custom_botton.dart';
// import 'package:sams_engineering_console/utils/images.dart';

// class StructuralNonstructuralrating extends StatefulWidget {
//   // Optional parameters for flat-based navigation
//   final List<String>? flatNumbers;
//   final Map<String, Map<String, String>>? flatInfoByNumber;
  
//   // Optional parameters for floor-based navigation
//   final List<String>? floorNumbers;
//   final Map<String, Map<String, String>>? floorInfoByNumber;
  
//   // Navigation type: 'flats_only', 'floors_only', or 'both'
//   final String? navigationType;
  
//   final String structureId;
  
//   // Structure type information for determining navigation
//   final String? structureType;
//   final String? commercialType;

//   const StructuralNonstructuralrating({
//     super.key, 
//     this.flatNumbers,
//     this.flatInfoByNumber,
//     this.floorNumbers,
//     this.floorInfoByNumber,
//     this.navigationType,
//     required this.structureId,
//     this.structureType,
//     this.commercialType,
//   });

//   /// Static utility method to determine navigation type based on structure type
//   /// Can be used by other files to determine what data to prepare
//   static String determineNavigationType({
//     required String? structureType, 
//     String? commercialType,
//     List<String>? availableFloorNumbers,
//     List<String>? availableFlatNumbers,
//   }) {
//     final lowerStructureType = structureType?.toLowerCase();
//     final lowerCommercialType = commercialType?.toLowerCase();

//     print("ðŸ—ï¸ [Static] Determining navigation type:");
//     print("  Structure Type: $lowerStructureType");
//     print("  Commercial Type: $lowerCommercialType");

//     // Residential structures show flats
//     if (lowerStructureType == 'residential') {
//       print("  â†’ Residential structure detected: Using flats_only");
//       return 'flats_only';
//     }
    
//     // Industrial structures show floors
//     if (lowerStructureType == 'industrial') {
//       print("  â†’ Industrial structure detected: Using floors_only");
//       return 'floors_only';
//     }
    
//     // Commercial structures depend on commercial type
//     if (lowerStructureType == 'commercial') {
//       if (lowerCommercialType == 'commercial') {
//         print("  â†’ Pure commercial structure detected: Using floors_only");
//         return 'floors_only';
//       } else if (lowerCommercialType == 'partly commercial with residential') {
//         print("  â†’ Mixed commercial structure detected: Using both");
//         return 'both';
//       } else {
//         // Default commercial to floors
//         print("  â†’ Commercial structure (unknown type): Using floors_only as default");
//         return 'floors_only';
//       }
//     }

//     // Fallback: infer from available data
//     print("  â†’ Unknown structure type, inferring from available data");
//     bool hasFloors = availableFloorNumbers != null && availableFloorNumbers.isNotEmpty;
//     bool hasFlats = availableFlatNumbers != null && availableFlatNumbers.isNotEmpty;
    
//     if (hasFloors && hasFlats) {
//       print("  â†’ Has both floors and flats: Using both");
//       return 'both';
//     } else if (hasFloors) {
//       print("  â†’ Has floors only: Using floors_only");
//       return 'floors_only';
//     } else {
//       print("  â†’ Default fallback: Using flats_only");
//       return 'flats_only';
//     }
//   }

//   @override
//   State<StructuralNonstructuralrating> createState() =>
//       _StructuralNonstructuralratingState();
// }

// class _StructuralNonstructuralratingState
//     extends State<StructuralNonstructuralrating> {
//   late GetstructureProvider getstructureProvider;
//   late List<FlatRatingData> flatRatings;
//   late List<FloorRatingData> floorRatings;

//   // For flat-based navigation
//   Map<String, List<String>> flatsByFloor = {};
//   Map<String, List<String>> selectedFlatsByFloor = {};

//   // For floor-based navigation
//   Map<String, List<String>> selectedFloors = {};

//   // Navigation mode
//   String currentNavigationType = 'flats_only'; // Default fallback

//   @override
//   void initState() {
//     super.initState();

//     getstructureProvider = Provider.of<GetstructureProvider>(
//       context,
//       listen: false,
//     );

//     flatRatings = [];
//     floorRatings = [];

//     // Determine navigation mode from passed parameter or infer from data
//     if (widget.navigationType != null) {
//       currentNavigationType = widget.navigationType!;
//     } else {
//       // NEW: Determine based on structure type
//       currentNavigationType = _determineNavigationTypeFromStructure();
//     }

//     print("Navigation mode: $currentNavigationType");
//     print("Structure type: ${widget.structureType}");
//     print("Commercial type: ${widget.commercialType}");
    
//     switch (currentNavigationType) {
//       case 'flats_only':
//         print("Flat numbers passed to widget: ${widget.flatNumbers}");
//         _groupFlatsByFloor();
//         break;
//       case 'floors_only':
//         print("Floor numbers passed to widget: ${widget.floorNumbers}");
//         _initializeFloorNavigation();
//         break;
//       case 'both':
//         print("Both floors and flats passed to widget:");
//         print("  Floor numbers: ${widget.floorNumbers}");
//         print("  Flat numbers: ${widget.flatNumbers}");
//         _initializeFloorNavigation();
//         _groupFlatsByFloor();
//         break;
//     }
//   }

//   /// Determines navigation type based on structure type and commercial type
//   String _determineNavigationTypeFromStructure() {
//     final structureType = widget.structureType?.toLowerCase();
//     final commercialType = widget.commercialType?.toLowerCase();

//     print("ðŸ—ï¸ Determining navigation type:");
//     print("  Structure Type: $structureType");
//     print("  Commercial Type: $commercialType");

//     // Residential structures show flats
//     if (structureType == 'residential') {
//       print("  â†’ Residential structure detected: Using flats_only");
//       return 'flats_only';
//     }
    
//     // Industrial structures show floors
//     if (structureType == 'industrial') {
//       print("  â†’ Industrial structure detected: Using floors_only");
//       return 'floors_only';
//     }
    
//     // Commercial structures depend on commercial type
//     if (structureType == 'commercial') {
//       if (commercialType == 'commercial') {
//         print("  â†’ Pure commercial structure detected: Using floors_only");
//         return 'floors_only';
//       } else if (commercialType == 'partly commercial with residential') {
//         print("  â†’ Mixed commercial structure detected: Using both");
//         return 'both';
//       } else {
//         // Default commercial to floors
//         print("  â†’ Commercial structure (unknown type): Using floors_only as default");
//         return 'floors_only';
//       }
//     }

//     // Fallback: infer from available data
//     print("  â†’ Unknown structure type, inferring from available data");
//     bool hasFloors = widget.floorNumbers != null && widget.floorNumbers!.isNotEmpty;
//     bool hasFlats = widget.flatNumbers != null && widget.flatNumbers!.isNotEmpty;
    
//     if (hasFloors && hasFlats) {
//       print("  â†’ Has both floors and flats: Using both");
//       return 'both';
//     } else if (hasFloors) {
//       print("  â†’ Has floors only: Using floors_only");
//       return 'floors_only';
//     } else {
//       print("  â†’ Default fallback: Using flats_only");
//       return 'flats_only';
//     }
//   }

//   Set<String> loadingFlats = {};
//   Map<String, bool> flatDataInitialized = {};
//   Set<String> loadingFloors = {};
//   Map<String, bool> floorDataInitialized = {};

//   void _initializeFloorNavigation() {
//     if (widget.floorNumbers == null) return;
    
//     selectedFloors.clear();
//     for (String floorNumber in widget.floorNumbers!) {
//       selectedFloors[floorNumber] = [];
//       print('Floor initialized: $floorNumber');
//     }

//     print('Floor navigation initialized: ${selectedFloors.keys.length} floors');
//   }

//   void updateFlatRating({
//     required String flatNumber,
//     StructuralRatingData? structuralData,
//     NonStructuralRatingData? nonStructuralData,
//   }) {
//     final index = flatRatings.indexWhere((e) => e.flatNumber == flatNumber);
//     if (index == -1) return;

//     setState(() {
//       final old = flatRatings[index];
//       flatRatings[index] = FlatRatingData(
//         flatNumber: flatNumber,
//         structuralData: structuralData ?? old.structuralData,
//         nonStructuralData: nonStructuralData ?? old.nonStructuralData,
//         flatId: old.flatId,
//         floorId: old.floorId,
//       );

//       // Mark as initialized if we have data
//       if (structuralData != null || nonStructuralData != null) {
//         flatDataInitialized[flatNumber] = true;
//       }
//     });

//     print("Updated rating for flat $flatNumber");
//     print("Structural data present: ${structuralData != null}");
//     print("Non-structural data present: ${nonStructuralData != null}");
//   }

//   void updateFloorRating({
//     required String floorNumber,
//     StructuralRatingData? structuralData,
//     NonStructuralRatingData? nonStructuralData,
//   }) {
//     final index = floorRatings.indexWhere((e) => e.floorNumber == floorNumber);
//     if (index == -1) return;

//     setState(() {
//       final old = floorRatings[index];
//       floorRatings[index] = FloorRatingData(
//         floorNumber: floorNumber,
//         floorId: old.floorId,
//         structuralData: structuralData ?? old.structuralData,
//         nonStructuralData: nonStructuralData ?? old.nonStructuralData,
//       );

//       // Mark as initialized if we have data
//       if (structuralData != null || nonStructuralData != null) {
//         floorDataInitialized[floorNumber] = true;
//       }
//     });

//     print("Updated rating for floor $floorNumber");
//     print("Structural data present: ${structuralData != null}");
//     print("Non-structural data present: ${nonStructuralData != null}");
//   }

//   void _groupFlatsByFloor() {
//     if (widget.flatNumbers == null || widget.flatInfoByNumber == null) return;

//     flatsByFloor.clear();
//     selectedFlatsByFloor.clear();

//     for (String flatNumber in widget.flatNumbers!) {
//       if (widget.flatInfoByNumber!.containsKey(flatNumber)) {
//         final flatInfo = widget.flatInfoByNumber![flatNumber]!;

//         // Use floor number directly from flatInfo if available
//         String floorNumber;
//         if (flatInfo.containsKey('floorNumber') &&
//             flatInfo['floorNumber']!.isNotEmpty) {
//           floorNumber = flatInfo['floorNumber']!;
//         } else {
//           // Fallback to extracting from floorId
//           final floorId = flatInfo['floorId']!;
//           floorNumber = _getFloorNumberFromId(floorId);
//         }

//         // Debug print to see what floor numbers we're getting
//         print('Flat $flatNumber -> Floor Number: $floorNumber');

//         if (!flatsByFloor.containsKey(floorNumber)) {
//           flatsByFloor[floorNumber] = [];
//           selectedFlatsByFloor[floorNumber] = [];
//         }

//         flatsByFloor[floorNumber]!.add(flatNumber);
//       }
//     }

//     // Debug print final grouping
//     print('Final floor grouping:');
//     flatsByFloor.forEach((floor, flats) {
//       print('  Floor $floor: ${flats.length} flats -> ${flats.join(', ')}');
//     });

//     // Sort floors (assuming they are numeric)
//     var sortedFloors = flatsByFloor.keys.toList()
//       ..sort((a, b) {
//         // Try to parse as numbers first
//         final aNum = int.tryParse(a);
//         final bNum = int.tryParse(b);

//         if (aNum != null && bNum != null) {
//           return aNum.compareTo(bNum);
//         }

//         // Fall back to string comparison
//         return a.compareTo(b);
//       });

//     // Rebuild the map with sorted keys
//     Map<String, List<String>> sortedFlatsByFloor = {};
//     Map<String, List<String>> sortedSelectedFlatsByFloor = {};

//     for (String floor in sortedFloors) {
//       sortedFlatsByFloor[floor] = flatsByFloor[floor]!;
//       sortedSelectedFlatsByFloor[floor] = selectedFlatsByFloor[floor]!;
//     }

//     flatsByFloor = sortedFlatsByFloor;
//     selectedFlatsByFloor = sortedSelectedFlatsByFloor;
//   }

//   String _getFloorNumberFromId(String floorId) {
//     // Extract floor number from floorId
//     print('Extracting floor number from floorId: $floorId');

//     // Method 1: If floorId contains underscore, get the part after it
//     if (floorId.contains('_')) {
//       final parts = floorId.split('_');
//       final extracted = parts.last;
//       print('  Method 1 (underscore): $extracted');
//       return extracted;
//     }

//     // Method 2: If floorId contains "floor" text, extract the number
//     if (floorId.toLowerCase().contains('floor')) {
//       RegExp regex = RegExp(r'\d+');
//       var match = regex.firstMatch(floorId);
//       final extracted = match?.group(0) ?? floorId;
//       print('  Method 2 (regex): $extracted');
//       return extracted;
//     }

//     // Method 3: If it's already a number or simple string, return as is
//     print('  Method 3 (direct): $floorId');
//     return floorId;
//   }

//   void updateSelectedFlat(
//     String floorNumber,
//     String flatNumber,
//     bool isSelected,
//   ) {
//     setState(() {
//       if (isSelected) {
//         if (!selectedFlatsByFloor[floorNumber]!.contains(flatNumber)) {
//           selectedFlatsByFloor[floorNumber]!.add(flatNumber);
//           loadingFlats.add(flatNumber); // Mark as loading

//           // Add to flatRatings
//           if (widget.flatInfoByNumber!.containsKey(flatNumber)) {
//             final info = widget.flatInfoByNumber![flatNumber]!;

//             flatRatings.add(
//               FlatRatingData(
//                 flatNumber: flatNumber,
//                 flatId: info['flatId']!,
//                 floorId: info['floorId']!,
//               ),
//             );
//           }

//           // Remove from loading after a delay (data should be loaded by then)
//           Future.delayed(Duration(seconds: 2), () {
//             if (mounted) {
//               setState(() {
//                 loadingFlats.remove(flatNumber);
//               });
//             }
//           });
//         }
//       } else {
//         selectedFlatsByFloor[floorNumber]!.remove(flatNumber);
//         flatRatings.removeWhere((f) => f.flatNumber == flatNumber);
//         loadingFlats.remove(flatNumber);
//         flatDataInitialized.remove(flatNumber);
//       }
//     });

//     print("Selected flats by floor: $selectedFlatsByFloor");
//     print("FlatRatings: ${flatRatings.map((e) => e.flatNumber).toList()}");
//   }

//   void updateSelectedFloor(String floorNumber, bool isSelected) {
//     setState(() {
//       if (isSelected) {
//         selectedFloors[floorNumber] = [];
//         loadingFloors.add(floorNumber); // Mark as loading

//         // Add to floorRatings
//         if (widget.floorInfoByNumber != null && widget.floorInfoByNumber!.containsKey(floorNumber)) {
//           final info = widget.floorInfoByNumber![floorNumber]!;

//           floorRatings.add(
//             FloorRatingData(
//               floorNumber: floorNumber,
//               floorId: info['floorId'] ?? floorNumber, // Use floorNumber as fallback
//             ),
//           );
//         } else {
//           // If no floor info available, create basic rating data
//           floorRatings.add(
//             FloorRatingData(
//               floorNumber: floorNumber,
//               floorId: floorNumber, // Use floorNumber as floorId
//             ),
//           );
//         }

//         // Remove from loading after a delay (data should be loaded by then)
//         Future.delayed(Duration(seconds: 2), () {
//           if (mounted) {
//             setState(() {
//               loadingFloors.remove(floorNumber);
//             });
//           }
//         });

//         print('Selected floor: $floorNumber');
//       } else {
//         selectedFloors.remove(floorNumber);
//         floorRatings.removeWhere((f) => f.floorNumber == floorNumber);
//         loadingFloors.remove(floorNumber);
//         floorDataInitialized.remove(floorNumber);
//         print('Deselected floor: $floorNumber');
//       }
//     });

//     print("Selected floors: ${selectedFloors.keys.toList()}");
//     print("FloorRatings: ${floorRatings.map((e) => e.floorNumber).toList()}");
//   }

//   Widget _buildFloorSection(String floorNumber, List<String> flats) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Floor header
//           Row(
//             children: [
//               Icon(Icons.apartment, color: Appcolors.buttonColor, size: 24),
//               SizedBox(width: 8),
//               Text(
//                 "Floor $floorNumber",
//                 style: w500_18Poppins(color: Appcolors.buttonColor),
//               ),
//               Spacer(),
//               Text(
//                 "${selectedFlatsByFloor[floorNumber]?.length ?? 0}/${flats.length} selected",
//                 style: w400_14Poppins(color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),

//           // Flats selection
//           Text("Select flats for rating:", style: w500_15Poppins()),
//           SizedBox(height: 8),

//           // Flat checkboxes in a grid
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: flats.map((flatNumber) {
//               bool isSelected =
//                   selectedFlatsByFloor[floorNumber]?.contains(flatNumber) ??
//                   false;

//               return InkWell(
//                 onTap: () =>
//                     updateSelectedFlat(floorNumber, flatNumber, !isSelected),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? Appcolors.buttonColor.withOpacity(0.1)
//                         : Colors.grey.shade100,
//                     border: Border.all(
//                       color: isSelected
//                           ? Appcolors.buttonColor
//                           : Colors.grey.shade300,
//                       width: isSelected ? 2 : 1,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         isSelected
//                             ? Icons.check_box
//                             : Icons.check_box_outline_blank,
//                         color: isSelected
//                             ? Appcolors.buttonColor
//                             : Colors.grey.shade500,
//                         size: 20,
//                       ),
//                       SizedBox(width: 6),
//                       Text(
//                         "Flat $flatNumber ",
//                         style: w400_14Poppins(
//                           color: isSelected
//                               ? Appcolors.buttonColor
//                               : Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),

//           // Rating sections for selected flats
//           if (selectedFlatsByFloor[floorNumber]?.isNotEmpty == true) ...[
//             height10,

//             ...selectedFlatsByFloor[floorNumber]!.map((flatNumber) {
//               final flatInfo = widget.flatInfoByNumber![flatNumber]!;

//               final isLoadingData = loadingFlats.contains(flatNumber);
//               final isDataInitialized =
//                   flatDataInitialized[flatNumber] ?? false;

//               return Container(
//                 margin: EdgeInsets.only(bottom: 16),
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade400),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.home, color: Colors.blue.shade700, size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           "Flat $flatNumber Rating",
//                           style: w500_16Poppins(color: Colors.blue.shade700),
//                         ),
//                         Spacer(),
//                         // Show data status indicator
//                         if (flatDataInitialized[flatNumber] == true)
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green.shade100,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               'Data Loaded',
//                               style: w400_10Poppins(
//                                 color: Colors.green.shade700,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     height10,

//                     DefaultTabController(
//                       length: 2,
//                       child: Column(
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade300,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ButtonsTabBar(
//                               unselectedBackgroundColor: Colors.grey.shade300,
//                               unselectedBorderColor: Colors.transparent,
//                               backgroundColor: Colors.white,
//                               height: 30.h,
//                               borderWidth: 2,
//                               borderColor: Colors.transparent,
//                               labelStyle: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               unselectedLabelStyle: TextStyle(
//                                 color: Colors.black54,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               tabs: <Widget>[
//                                 Tab(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 8.0,
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Text(
//                                           "Structural",
//                                           style: w400_14Poppins(),
//                                         ),
//                                         if (isLoadingData)
//                                           Padding(
//                                             padding: EdgeInsets.only(left: 4),
//                                             child: SizedBox(
//                                               width: 10,
//                                               height: 10,
//                                               child: CircularProgressIndicator(
//                                                 strokeWidth: 1,
//                                               ),
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Tab(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 8.0,
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Text(
//                                           "Non-Structural",
//                                           style: w400_14Poppins(),
//                                         ),
//                                         if (isLoadingData)
//                                           Padding(
//                                             padding: EdgeInsets.only(left: 4),
//                                             child: SizedBox(
//                                               width: 10,
//                                               height: 10,
//                                               child: CircularProgressIndicator(
//                                                 strokeWidth: 1,
//                                               ),
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           // Data initialization status
//                           if (!isDataInitialized && !isLoadingData)
//                             Container(
//                               padding: EdgeInsets.all(8),
//                               margin: EdgeInsets.only(top: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.shade50,
//                                 borderRadius: BorderRadius.circular(6),
//                                 border: Border.all(color: Colors.blue.shade200),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.info_outline,
//                                     size: 16,
//                                     color: Colors.blue.shade600,
//                                   ),
//                                   SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       'Data is being loaded for this flat...',
//                                       style: w400_12Poppins(
//                                         color: Colors.blue.shade600,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),

//                          SizedBox(
//   height: 300.h,
//   child: TabBarView(
//     children: [
//       ChangeNotifierProvider(
//         create: (_) => AddRatingsStructureProvider(),
//         child: StructuralRating(
//           structureId: widget.structureId,
//           floorId: flatInfo['floorId'] ?? floorNumber,  // ✅ floorId from your existing floorInfo
//         ),
//       ),
//       ChangeNotifierProvider(
//         create: (_) => AddRatingsStructureProvider(),
//         child: NonStructuralRating(
//           structureId: widget.structureId,
//           floorId: flatInfo['floorId'] ?? floorNumber,  // ✅ floorId from your existing floorInfo
//         ),
//       ),


//                                 // StructuralRating(
//                                 //   flatNumber: flatNumber,
//                                 //   flatId: flatInfo['flatId'],
//                                 //   floorId: flatInfo['floorId'],
//                                 //   structureId: widget.structureId,
//                                 //   onChanged: (structuralData) {
//                                 //     updateFlatRating(
//                                 //       flatNumber: flatNumber,
//                                 //       structuralData: structuralData,
//                                 //     );
//                                 //   },
//                                 // ),
//                                 // NonstructuralRating(
//                                 //   flatNumber: flatNumber,
//                                 //   flatId: flatInfo['flatId'],
//                                 //   floorId: flatInfo['floorId'],
//                                 //   structureId: widget.structureId,
//                                 //   onChanged: (nonstructuralData) {
//                                 //     updateFlatRating(
//                                 //       flatNumber: flatNumber,
//                                 //       nonStructuralData: nonstructuralData,
//                                 //     );
//                                 //   },
//                                 // ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildFloorOnlySection(String floorNumber) {
//     bool isSelected = selectedFloors.containsKey(floorNumber);
//     final floorInfo = widget.floorInfoByNumber?[floorNumber];
//     final isLoadingData = loadingFloors.contains(floorNumber);
//     final isDataInitialized = floorDataInitialized[floorNumber] ?? false;

//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Floor header with selection
//           Row(
//             children: [
//               InkWell(
//                 onTap: () => updateSelectedFloor(floorNumber, !isSelected),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? Appcolors.buttonColor.withOpacity(0.1)
//                         : Colors.grey.shade100,
//                     border: Border.all(
//                       color: isSelected
//                           ? Appcolors.buttonColor
//                           : Colors.grey.shade300,
//                       width: isSelected ? 2 : 1,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         isSelected
//                             ? Icons.check_box
//                             : Icons.check_box_outline_blank,
//                         color: isSelected
//                             ? Appcolors.buttonColor
//                             : Colors.grey.shade500,
//                         size: 20,
//                       ),
//                       SizedBox(width: 8),
//                       Icon(Icons.apartment, color: Appcolors.buttonColor, size: 24),
//                       SizedBox(width: 8),
//                       Text(
//                         "Floor $floorNumber",
//                         style: w500_18Poppins(color: isSelected 
//                             ? Appcolors.buttonColor 
//                             : Colors.black87),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Spacer(),
//               if (floorInfo != null)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       "Type: ${floorInfo['floorType'] ?? 'N/A'}",
//                       style: w400_12Poppins(color: Colors.grey.shade600),
//                     ),
//                     Text(
//                       "Area: ${floorInfo['floorArea'] ?? 'N/A'} sq.mts",
//                       style: w400_12Poppins(color: Colors.grey.shade600),
//                     ),
//                   ],
//                 ),
//             ],
//           ),

//           // Rating section for selected floor
//           if (isSelected) ...[
//             height10,
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade400),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.apartment, color: Colors.blue.shade700, size: 20),
//                       SizedBox(width: 8),
//                       Text(
//                         "Floor $floorNumber Rating",
//                         style: w500_16Poppins(color: Colors.blue.shade700),
//                       ),
//                       Spacer(),
//                       // Show data status indicator
//                       if (floorDataInitialized[floorNumber] == true)
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(
//                             'Data Loaded',
//                             style: w400_10Poppins(
//                               color: Colors.green.shade700,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   height10,

//                   DefaultTabController(
//                     length: 2,
//                     child: Column(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: ButtonsTabBar(
//                             unselectedBackgroundColor: Colors.grey.shade300,
//                             unselectedBorderColor: Colors.transparent,
//                             backgroundColor: Colors.white,
//                             height: 30.h,
//                             borderWidth: 2,
//                             borderColor: Colors.transparent,
//                             labelStyle: TextStyle(
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             unselectedLabelStyle: TextStyle(
//                               color: Colors.black54,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             tabs: <Widget>[
//                               Tab(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8.0,
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(
//                                         "Structural",
//                                         style: w400_14Poppins(),
//                                       ),
//                                       if (isLoadingData)
//                                         Padding(
//                                           padding: EdgeInsets.only(left: 4),
//                                           child: SizedBox(
//                                             width: 10,
//                                             height: 10,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 1,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Tab(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8.0,
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(
//                                         "Non-Structural",
//                                         style: w400_14Poppins(),
//                                       ),
//                                       if (isLoadingData)
//                                         Padding(
//                                           padding: EdgeInsets.only(left: 4),
//                                           child: SizedBox(
//                                             width: 10,
//                                             height: 10,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 1,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Data initialization status
//                         if (!isDataInitialized && !isLoadingData)
//                           Container(
//                             padding: EdgeInsets.all(8),
//                             margin: EdgeInsets.only(top: 8),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(color: Colors.blue.shade200),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.info_outline,
//                                   size: 16,
//                                   color: Colors.blue.shade600,
//                                 ),
//                                 SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Data is being loaded for this floor...',
//                                     style: w400_12Poppins(
//                                       color: Colors.blue.shade600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                     SizedBox(
//   height: 300.h,
//   child: TabBarView(
//     children: [
//       ChangeNotifierProvider(
//         create: (_) => AddRatingsStructureProvider(),
//         child: StructuralRating(
//           structureId: widget.structureId,
//           flatId: floorInfo!['flatId']!,  // ✅ flatId from your existing flatInfo
//         ),
//       ),
//       ChangeNotifierProvider(
//         create: (_) => AddRatingsStructureProvider(),
//         child: NonStructuralRating(
//           structureId: widget.structureId,
//           flatId: floorInfo['flatId']!,  // ✅ flatId from your existing flatInfo
//         ),
//       ),
  
//                               // StructuralRating(
//                               //   flatNumber: "Floor-$floorNumber", // Use floor identifier for floor rating
//                               //   flatId: floorInfo?['floorId'] ?? floorNumber,     // Use floorId as flatId for floor rating
//                               //   floorId: floorInfo?['floorId'] ?? floorNumber,
//                               //   structureId: widget.structureId,
//                               //   onChanged: (structuralData) {
//                               //     updateFloorRating(
//                               //       floorNumber: floorNumber,
//                               //       structuralData: structuralData,
//                               //     );
//                               //   },
//                               // ),
//                               // Floor non-structural rating using the same NonstructuralRating widget
//                               // NonstructuralRating(
//                               //   flatNumber: "Floor-$floorNumber", // Use floor identifier for floor rating
//                               //   flatId: floorInfo?['floorId'] ?? floorNumber,     // Use floorId as flatId for floor rating
//                               //   floorId: floorInfo?['floorId'] ?? floorNumber,
//                               //   structureId: widget.structureId,
//                               //   onChanged: (nonstructuralData) {
//                               //     updateFloorRating(
//                               //       floorNumber: floorNumber,
//                               //       nonStructuralData: nonstructuralData,
//                               //     );
//                               //   },
//                               // ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   String _getNavigationModeDescription() {
//     final structureType = widget.structureType?.toLowerCase();
//     final commercialType = widget.commercialType?.toLowerCase();

//     switch (currentNavigationType) {
//       case 'flats_only':
//         if (structureType == 'residential') {
//           return "Residential structure: Rate individual flats for residential buildings";
//         }
//         return "Flat-based rating mode: Rate individual flats";
//       case 'floors_only':
//         if (structureType == 'industrial') {
//           return "Industrial structure: Rate entire floors for industrial facilities";
//         } else if (structureType == 'commercial' && commercialType == 'commercial') {
//           return "Commercial structure: Rate entire floors for commercial buildings";
//         }
//         return "Floor-based rating mode: Rate entire floors";
//       case 'both':
//         if (structureType == 'commercial' && commercialType == 'partly commercial with residential') {
//           return "Mixed-use structure: Rate both commercial floors and residential flats";
//         }
//         return "Mixed rating mode: Rate both floors and flats";
//       default:
//         return "Unknown rating mode";
//     }
//   }

//   Color _getNavigationModeColor() {
//     switch (currentNavigationType) {
//       case 'flats_only':
//         return Colors.blue.shade600;
//       case 'floors_only':
//         return Colors.orange.shade600;
//       case 'both':
//         return Colors.purple.shade600;
//       default:
//         return Colors.grey.shade600;
//     }
//   }

//   IconData _getNavigationModeIcon() {
//     switch (currentNavigationType) {
//       case 'flats_only':
//         return Icons.home;
//       case 'floors_only':
//         return Icons.apartment;
//       case 'both':
//         return Icons.business;
//       default:
//         return Icons.help;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AddstructureProvider>(
//       builder: (context, addStructureProvider, child) {
//         return Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             backgroundColor: Colors.white,
//             elevation: 0,
//             title: Text(
//               currentNavigationType == 'floors_only' 
//                 ? "Floor Rating" 
//                 : currentNavigationType == 'both'
//                   ? "Floor & Flat Rating"
//                   : "Flat Rating", 
//               style: w600_18Poppins()
//             ),
//             leading: IconButton(
//               icon: Icon(Icons.arrow_back, color: Colors.black),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           body: SingleChildScrollView(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Display navigation mode info
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   margin: EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: _getNavigationModeColor().withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: _getNavigationModeColor().withOpacity(0.3),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         _getNavigationModeIcon(),
//                         color: _getNavigationModeColor(),
//                       ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           _getNavigationModeDescription(),
//                           style: w400_12Poppins(
//                             color: _getNavigationModeColor().withOpacity(0.9),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Render appropriate sections based on navigation mode
//                 if (currentNavigationType == 'flats_only') ...[
//                   // Flat-based navigation only
//                   ...flatsByFloor.entries.map((entry) {
//                     return _buildFloorSection(entry.key, entry.value);
//                   }).toList(),
//                 ] else if (currentNavigationType == 'floors_only') ...[
//                   // Floor-based navigation only
//                   ...widget.floorNumbers!.map((floorNumber) {
//                     return _buildFloorOnlySection(floorNumber);
//                   }).toList(),
//                 ] else if (currentNavigationType == 'both') ...[
//                   // Both floors and flats
//                   Text(
//                     "Floor-Level Ratings:",
//                     style: w600_18Poppins(color: Colors.purple.shade700),
//                   ),
//                   height10,
//                   if (widget.floorNumbers != null) ...[
//                     ...widget.floorNumbers!.map((floorNumber) {
//                       return _buildFloorOnlySection(floorNumber);
//                     }).toList(),
//                   ],
//                   height20,
//                   Text(
//                     "Flat-Level Ratings:",
//                     style: w600_18Poppins(color: Colors.blue.shade700),
//                   ),
//                   height10,
//                   ...flatsByFloor.entries.map((entry) {
//                     return _buildFloorSection(entry.key, entry.value);
//                   }).toList(),
//                 ],
//               ],
//             ),
//           ),
//           bottomNavigationBar: Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.shade300,
//                   blurRadius: 4,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: "Back",
//                     borderRadius: 10.r,
//                     buttonColor: Colors.transparent,
//                     buttonTextStyle: w700_15Poppins(
//                       color: Appcolors.buttonColor,
//                     ),
//                     height: 35.h,
//                     borderColor: Appcolors.buttonColor,
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: "Save & Continue",
//                     borderRadius: 10.r,
//                     buttonColor: Appcolors.buttonColor,
//                     buttonTextStyle: w700_15Poppins(color: Colors.white),
//                     height: 35.h,
//                     onTap: () async {
//                       // if (currentNavigationType == 'floors_only') {
//                       //   // // Handle floor-based saving
//                       //   // if (floorRatings.isEmpty) {
//                       //   //   ScaffoldMessenger.of(context).showSnackBar(
//                       //   //     SnackBar(
//                       //   //       content: Text(
//                       //   //         "Please select at least one floor for rating",
//                       //   //       ),
//                       //   //       backgroundColor: Colors.orange,
//                       //   //     ),
//                       //   //   );
//                       //   //   return;
//                       //   // }

//                       //   try {
//                       //     for (var rating in floorRatings) {
//                       //       if (rating.structuralData != null &&
//                       //           rating.nonStructuralData != null) {
//                       //         await addStructureProvider.postFloorRating(
//                       //           context: context,
//                       //           floorId: rating.floorId,
//                       //           floorData: rating,
//                       //           structureId: widget.structureId,
//                       //         );
//                       //       }
//                       //     }

//                       //     await addStructureProvider.submitStructure(
//                       //       context,
//                       //       widget.structureId,
//                       //     );


//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => StructureList(),
//                             ),
//                           );
//                       //   } catch (e) {
//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text("Error saving floor ratings: $e"),
//                       //         backgroundColor: Colors.red,
//                       //       ),
//                       //     );
//                       //   }
//                       // } else if (currentNavigationType == 'flats_only') {
//                       //   // Handle flat-based saving only
//                       //   if (flatRatings.isEmpty) {
//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text(
//                       //           "Please select at least one flat for rating",
//                       //         ),
//                       //         backgroundColor: Colors.orange,
//                       //       ),
//                       //     );
//                       //     return;
//                       //   }

//                       //   try {
//                       //     for (var rating in flatRatings) {
//                       //       if (rating.structuralData != null &&
//                       //           rating.nonStructuralData != null) {
//                       //         await addStructureProvider.postFlatRating(
//                       //           context: context,
//                       //           floorId: rating.floorId,
//                       //           flatId: rating.flatId,
//                       //           flatData: rating,
//                       //           structureId: widget.structureId,
//                       //         );
//                       //       }
//                       //     }

//                       //     await addStructureProvider.submitStructure(
//                       //       context,
//                       //       widget.structureId,
//                       //     );

//                       //     Navigator.push(
//                       //       context,
//                       //       MaterialPageRoute(
//                       //         builder: (context) => StructureList(),
//                       //       ),
//                       //     );
//                       //   } catch (e) {
//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text("Error saving ratings: $e"),
//                       //         backgroundColor: Colors.red,
//                       //       ),
//                       //     );
//                       //   }
//                       // } else if (currentNavigationType == 'both') {
//                       //   // Handle both floor and flat saving
//                       //   bool hasFloorRatings = floorRatings.isNotEmpty;
//                       //   bool hasFlatRatings = flatRatings.isNotEmpty;

//                       //   if (!hasFloorRatings && !hasFlatRatings) {
//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text(
//                       //           "Please select at least one floor or flat for rating",
//                       //         ),
//                       //         backgroundColor: Colors.orange,
//                       //       ),
//                       //     );
//                       //     return;
//                       //   }

//                       //   try {
//                       //     // Save floor ratings
//                       //     if (hasFloorRatings) {
//                       //       for (var rating in floorRatings) {
//                       //         if (rating.structuralData != null &&
//                       //             rating.nonStructuralData != null) {
//                       //           await addStructureProvider.postFloorRating(
//                       //             context: context,
//                       //             floorId: rating.floorId,
//                       //             floorData: rating,
//                       //             structureId: widget.structureId,
//                       //           );
//                       //         }
//                       //       }
//                       //     }

//                       //     // Save flat ratings
//                       //     if (hasFlatRatings) {
//                       //       for (var rating in flatRatings) {
//                       //         if (rating.structuralData != null &&
//                       //             rating.nonStructuralData != null) {
//                       //           await addStructureProvider.postFlatRating(
//                       //             context: context,
//                       //             floorId: rating.floorId,
//                       //             flatId: rating.flatId,
//                       //             flatData: rating,
//                       //             structureId: widget.structureId,
//                       //           );
//                       //         }
//                       //       }
//                       //     }

//                       //     await addStructureProvider.submitStructure(
//                       //       context,
//                       //       widget.structureId,
//                       //     );

//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text("Mixed ratings saved successfully!"),
//                       //         backgroundColor: Colors.green,
//                       //       ),
//                       //     );

//                       //     Navigator.push(
//                       //       context,
//                       //       MaterialPageRoute(
//                       //         builder: (context) => StructureList(),
//                       //       ),
//                       //     );
//                       //   } catch (e) {
//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         content: Text("Error saving ratings: $e"),
//                       //         backgroundColor: Colors.red,
//                       //       ),
//                       //     );
//                       //   }
//                       // }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }