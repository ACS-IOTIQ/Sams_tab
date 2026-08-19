
// import 'dart:io';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import 'package:sams_engineering_console/provider/addStructure_provider.dart';
// import 'package:sams_engineering_console/provider/getStructure_provider.dart';
// import 'package:sams_engineering_console/utils/appColors.dart';
// import 'package:sams_engineering_console/utils/app_fonts.dart';
// import 'package:sams_engineering_console/utils/common_textformfield.dart';
// // ignore: depend_on_referenced_packages
// import 'package:path/path.dart' as path;

// class NonstructuralRating extends StatefulWidget {
//   final String flatNumber;  // Back to required
//   final String? floorId;
//   final String? flatId;
//   final String? structureId;
//   final void Function(NonStructuralRatingData)? onChanged;

//   const NonstructuralRating({
//     super.key,
//     required this.flatNumber,  // Back to required
//     required this.onChanged,
//     this.flatId,
//     this.floorId,
//     this.structureId,
//   });

//   @override
//   State<NonstructuralRating> createState() => _NonstructuralRatingState();
// }

// class _NonstructuralRatingState extends State<NonstructuralRating> {
//   // Rating values
//   int? brickValue;
//   String? brickComment;
//   TextEditingController brickController = TextEditingController();
//   TextEditingController brickRatingController = TextEditingController();
//   dynamic brickFile;
//   String? brickName;

//   int? doorWindowValue;
//   String? doorWindowComment;
//   TextEditingController doorWindowController = TextEditingController();
//   TextEditingController doorWindowRatingController = TextEditingController();
//   dynamic doorWindowFile;
//   String? doorWindowName;

//   int? tilesvalue;
//   String? tilesComment;
//   TextEditingController tiledController = TextEditingController();
//   TextEditingController tilesRatingController = TextEditingController();
//   dynamic tilesFile;
//   String? tilesName;

//   int? electricalValue;
//   String? electricalComment;
//   TextEditingController electricalController = TextEditingController();
//   TextEditingController electricalRatingController = TextEditingController();
//   dynamic electricalFile;
//   String? electricalName;

//   int? fittingsValue;
//   String? fittingsComment;
//   TextEditingController fittingsController = TextEditingController();
//   TextEditingController fittingsRatingController = TextEditingController();
//   dynamic fittingsFile;
//   String? fittingsName;

//   int? railingsValue;
//   String? railingsComment;
//   TextEditingController railingsController = TextEditingController();
//   TextEditingController railingsRatingController = TextEditingController();
//   dynamic railingsFile;
//   String? railingsName;

//   int? waterTankValue;
//   String? waterTankComment;
//   TextEditingController waterTankController = TextEditingController();
//   TextEditingController waterTankRatingController = TextEditingController();
//   dynamic waterTankFile;
//   String? waterTankName;

//   int? plumbingValue;
//   String? plumbingComment;
//   TextEditingController plumbingController = TextEditingController();
//   TextEditingController plumbingRatingController = TextEditingController();
//   dynamic plumbingFile;
//   String? plumbingName;

//   int? sewageValue;
//   String? sewageComment;
//   TextEditingController sewageController = TextEditingController();
//   TextEditingController sewageRatingController = TextEditingController();
//   dynamic sewageFile;
//   String? sewageName;

//   int? transformerValue;
//   String? transformerComment;
//   TextEditingController transformerController = TextEditingController();
//   TextEditingController transformerRatingController = TextEditingController();
//   dynamic transformerFile;
//   String? transformerName;

//   int? liftValue;
//   String? liftComment;
//   TextEditingController liftController = TextEditingController();
//   TextEditingController liftRatingController = TextEditingController();
//   dynamic liftFile;
//   String? liftName;

//   late GetstructureProvider getstructureProvider;
//   bool isLoading = true;
//   bool controllersInitialized = false;

//   // Helper to determine if this is floor-only rating based on flatNumber prefix
//   bool get isFloorOnlyRating => widget.flatNumber.startsWith("Floor-");

//   @override
//   void initState() {
//     super.initState();
//     getstructureProvider = Provider.of<GetstructureProvider>(
//       context,
//       listen: false,
//     );
//     _loadExistingData();
//   }

//   // Helper method to safely convert rating to int
//   int? _safeConvertToInt(dynamic value) {
//     if (value == null) return null;

//     if (value is int) return value;
//     if (value is double) return value.round();
//     if (value is String) {
//       final parsed = double.tryParse(value);
//       return parsed?.round();
//     }

//     return null;
//   }

//   Future<void> _loadExistingData() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       print('ðŸ“„ Loading data for structureId: ${widget.structureId}, floorId: ${widget.floorId}, flatNumber: ${widget.flatNumber}');
//       print('ðŸ¢ Is floor-only rating: $isFloorOnlyRating');

//       if (isFloorOnlyRating) {
//         // For floor-only ratings, load floor-level data
//         await _loadFloorLevelData();
//       } else {
//         // For flat-specific ratings, load flat-level data
//         await getstructureProvider.getFlatsWithDetailsByFloorId(
//           structureId: widget.structureId!,
//           floorId: widget.floorId!,
//           context: context,
//         );
//       }

//       print('âœ… Data loaded successfully');

//       if (mounted) {
//         // Use Future.microtask to ensure this runs after the current frame
//         Future.microtask(() {
//           if (mounted) {
//             _populateFieldsWithExistingData();
//           }
//         });
//       }
//     } catch (e) {
//       print('âŒ Error loading existing data: $e');
//       debugPrint('Error loading existing data: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadFloorLevelData() async {
//     // This method would load floor-level rating data
//     // You might need to implement a separate API call for floor data
//     // For now, we'll set loading to false and let the user fill fresh data
//     print('ðŸ¢ Loading floor-level data for floor: ${widget.floorId}');
    
//     // TODO: Implement floor-level data loading if API supports it
//     // await getstructureProvider.getFloorWithDetailsByFloorId(
//     //   structureId: widget.structureId!,
//     //   floorId: widget.floorId!,
//     //   context: context,
//     // );
//   }

//   void _populateFieldsWithExistingData() {
//     print('ðŸ” Populating fields with existing data...');
    
//     if (isFloorOnlyRating) {
//       // For floor-only ratings, data population might be different
//       // For now, just mark as initialized to allow fresh input
//       setState(() {
//         controllersInitialized = true;
//       });
      
//       // Notify parent immediately for floor ratings
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _notifyParent();
//           print('ðŸ“¢ Parent notified for floor-only rating');
//         }
//       });
      
//       return;
//     }

//     // Existing flat-based data population logic
//     final flatData = getstructureProvider.getFlatsByFloorId(widget.floorId!);
//     print('ðŸ“Š FlatData: ${flatData?.data?.flats?.length} flats found');

//     if (flatData?.data?.flats != null) {
//       final availableFlats = flatData!.data!.flats!
//           .map((f) => f.flatNumber)
//           .toList();
//       print('ðŸ  Available flats: $availableFlats');
//       print('ðŸ” Looking for flat: ${widget.flatNumber}');

//       final matchingFlats = flatData.data!.flats!.where(
//         (flat) => flat.flatNumber == widget.flatNumber,
//       );

//       print('âœ… Matching flats found: ${matchingFlats.length}');

//       final currentFlat = matchingFlats.isNotEmpty ? matchingFlats.first : null;

//       if (currentFlat != null) {
//         print('ðŸ  Current flat found: ${currentFlat.flatNumber}');
//         print('ðŸ“Š Has non-structural rating: ${currentFlat.nonStructuralRating != null}');

//         // FOR NON-STRUCTURAL RATING - populate data in setState
//         if (currentFlat.nonStructuralRating != null) {
//           final nonStructural = currentFlat.nonStructuralRating!;

//           setState(() {
//             // Populate Brick Plaster data
//             if (nonStructural.brickPlaster != null) {
//               final brickData = nonStructural.brickPlaster!;
//               print('ðŸ§± Processing brick data: rating=${brickData.rating}, comment=${brickData.conditionComment}');

//               // Use safe conversion for rating
//               final safeRating = _safeConvertToInt(brickData.rating);
//               if (safeRating != null) {
//                 brickValue = safeRating;
//                 brickComment = brickData.conditionComment ?? '';
//                 brickController.text = brickComment!;
//                 brickRatingController.text = brickValue.toString();
//                 brickFile = brickData.photos;
//                 print('ðŸ§± âœ… Populated brick - rating: $brickValue, comment: $brickComment');
//               } else {
//                 print('ðŸ§± âŒ Brick rating conversion failed: ${brickData.rating}');
//               }
//             } else {
//               print('ðŸ§± âŒ Brick object is null');
//             }

//             // Populate Doors & Windows data
//             if (nonStructural.doorsWindows != null) {
//               final doorData = nonStructural.doorsWindows!;
//               final safeRating = _safeConvertToInt(doorData.rating);
//               if (safeRating != null) {
//                 doorWindowValue = safeRating;
//                 doorWindowComment = doorData.conditionComment ?? '';
//                 doorWindowController.text = doorWindowComment!;
//                 doorWindowRatingController.text = doorWindowValue.toString();
//                 doorWindowFile = doorData.photos;
//                 print('ðŸšª âœ… Populated doors/windows - rating: $doorWindowValue, comment: $doorWindowComment');
//               }
//             }

//             // Populate Flooring/Tiles data
//             if (nonStructural.flooringTiles != null) {
//               final tilesData = nonStructural.flooringTiles!;
//               final safeRating = _safeConvertToInt(tilesData.rating);
//               if (safeRating != null) {
//                 tilesvalue = safeRating;
//                 tilesComment = tilesData.conditionComment ?? '';
//                 tiledController.text = tilesComment!;
//                 tilesRatingController.text = tilesvalue.toString();
//                 tilesFile = tilesData.photos;
//                 print('ðŸŸ« âœ… Populated tiles - rating: $tilesvalue, comment: $tilesComment');
//               }
//             }

//             // Populate Electrical Wiring data
//             if (nonStructural.electricalWiring != null) {
//               final electricalData = nonStructural.electricalWiring!;
//               final safeRating = _safeConvertToInt(electricalData.rating);
//               if (safeRating != null) {
//                 electricalValue = safeRating;
//                 electricalComment = electricalData.conditionComment ?? '';
//                 electricalController.text = electricalComment!;
//                 electricalRatingController.text = electricalValue.toString();
//                 electricalFile = electricalData.photos;
//                 print('âš¡ âœ… Populated electrical - rating: $electricalValue, comment: $electricalComment');
//               }
//             }

//             // Populate Sanitary Fittings data
//             if (nonStructural.sanitaryFittings != null) {
//               final fittingsData = nonStructural.sanitaryFittings!;
//               final safeRating = _safeConvertToInt(fittingsData.rating);
//               if (safeRating != null) {
//                 fittingsValue = safeRating;
//                 fittingsComment = fittingsData.conditionComment ?? '';
//                 fittingsController.text = fittingsComment!;
//                 fittingsRatingController.text = fittingsValue.toString();
//                 fittingsFile = fittingsData.photos;
//                 print('ðŸš¿ âœ… Populated fittings - rating: $fittingsValue, comment: $fittingsComment');
//               }
//             }

//             // Populate Railings data
//             if (nonStructural.railings != null) {
//               final railingsData = nonStructural.railings!;
//               final safeRating = _safeConvertToInt(railingsData.rating);
//               if (safeRating != null) {
//                 railingsValue = safeRating;
//                 railingsComment = railingsData.conditionComment ?? '';
//                 railingsController.text = railingsComment!;
//                 railingsRatingController.text = railingsValue.toString();
//                 railingsFile = railingsData.photos;
//                 print('ðŸ›¡ï¸ âœ… Populated railings - rating: $railingsValue, comment: $railingsComment');
//               }
//             }

//             // Populate Water Tanks data
//             if (nonStructural.waterTanks != null) {
//               final waterData = nonStructural.waterTanks!;
//               final safeRating = _safeConvertToInt(waterData.rating);
//               if (safeRating != null) {
//                 waterTankValue = safeRating;
//                 waterTankComment = waterData.conditionComment ?? '';
//                 waterTankController.text = waterTankComment!;
//                 waterTankRatingController.text = waterTankValue.toString();
//                 waterTankFile = waterData.photos;
//                 print('ðŸ’§ âœ… Populated water tanks - rating: $waterTankValue, comment: $waterTankComment');
//               }
//             }

//             // Populate Plumbing data
//             if (nonStructural.plumbing != null) {
//               final plumbingData = nonStructural.plumbing!;
//               final safeRating = _safeConvertToInt(plumbingData.rating);
//               if (safeRating != null) {
//                 plumbingValue = safeRating;
//                 plumbingComment = plumbingData.conditionComment ?? '';
//                 plumbingController.text = plumbingComment!;
//                 plumbingRatingController.text = plumbingValue.toString();
//                 plumbingFile = plumbingData.photos;
//                 print('ðŸ”§ âœ… Populated plumbing - rating: $plumbingValue, comment: $plumbingComment');
//               }
//             }

//             // Populate Sewage System data
//             if (nonStructural.sewageSystem != null) {
//               final sewageData = nonStructural.sewageSystem!;
//               final safeRating = _safeConvertToInt(sewageData.rating);
//               if (safeRating != null) {
//                 sewageValue = safeRating;
//                 sewageComment = sewageData.conditionComment ?? '';
//                 sewageController.text = sewageComment!;
//                 sewageRatingController.text = sewageValue.toString();
//                 sewageFile = sewageData.photos;
//                 print('ðŸš° âœ… Populated sewage - rating: $sewageValue, comment: $sewageComment');
//               }
//             }

//             // Populate Panel/Board Transformer data
//             if (nonStructural.panelBoard != null) {
//               final panelData = nonStructural.panelBoard!;
//               final safeRating = _safeConvertToInt(panelData.rating);
//               if (safeRating != null) {
//                 transformerValue = safeRating;
//                 transformerComment = panelData.conditionComment ?? '';
//                 transformerController.text = transformerComment!;
//                 transformerRatingController.text = transformerValue.toString();
//                 transformerFile = panelData.photos;
//                 print('ðŸ”Œ âœ… Populated transformer - rating: $transformerValue, comment: $transformerComment');
//               }
//             }

//             // Populate Lifts data
//             if (nonStructural.lifts != null) {
//               final liftsData = nonStructural.lifts!;
//               final safeRating = _safeConvertToInt(liftsData.rating);
//               if (safeRating != null) {
//                 liftValue = safeRating;
//                 liftComment = liftsData.conditionComment ?? '';
//                 liftController.text = liftComment!;
//                 liftRatingController.text = liftValue.toString();
//                 liftFile = liftsData.photos;
//                 print('ðŸ›— âœ… Populated lifts - rating: $liftValue, comment: $liftComment');
//               }
//             }

//             controllersInitialized = true;
//           });
//         } else {
//           print('âŒ No non-structural rating data available');
//           setState(() {
//             controllersInitialized = true;
//           });
//         }

//         // Notify parent after state is updated
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             _notifyParent();
//             print('ðŸ“¢ Parent notified after UI update');
//           }
//         });
//       } else {
//         print('âŒ No matching flat found for: ${widget.flatNumber}');
//         setState(() {
//           controllersInitialized = true;
//         });
//       }
//     } else {
//       print('âŒ No flat data available');
//       setState(() {
//         controllersInitialized = true;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     brickController.dispose();
//     brickRatingController.dispose();
//     doorWindowController.dispose();
//     doorWindowRatingController.dispose();
//     tiledController.dispose();
//     tilesRatingController.dispose();
//     electricalController.dispose();
//     electricalRatingController.dispose();
//     fittingsController.dispose();
//     fittingsRatingController.dispose();
//     railingsController.dispose();
//     railingsRatingController.dispose();
//     waterTankController.dispose();
//     waterTankRatingController.dispose();
//     plumbingController.dispose();
//     plumbingRatingController.dispose();
//     sewageController.dispose();
//     sewageRatingController.dispose();
//     transformerController.dispose();
//     transformerRatingController.dispose();
//     liftController.dispose();
//     liftRatingController.dispose();
//     super.dispose();
//   }

//   int? _validateAndConvertRating(String value) {
//     if (value.isEmpty) return null;
//     final intValue = int.tryParse(value);
//     if (intValue != null && intValue >= 1 && intValue <= 5) {
//       return intValue;
//     }
//     return null;
//   }

//   void _notifyParent() {
//     if (widget.onChanged != null) {
//       widget.onChanged!(
//         NonStructuralRatingData(
//           // Brick
//           brickValue: brickValue,
//           brickComment: brickComment,
//           brickFile: brickFile,
//           brickName: brickName,
//           brickController: brickController,
//           brickRatingController: brickRatingController,

//           // Door Window
//           doorWindowValue: doorWindowValue,
//           doorWindowComment: doorWindowComment,
//           doorWindowFile: doorWindowFile,
//           doorWindowName: doorWindowName,
//           doorWindowController: doorWindowController,
//           doorWindowRatingController: doorWindowRatingController,

//           // Tiles
//           tilesvalue: tilesvalue,
//           tilesComment: tilesComment,
//           tilesFile: tilesFile,
//           tilesName: tilesName,
//           tiledController: tiledController,
//           tilesRatingController: tilesRatingController,

//           // Electrical
//           electricalValue: electricalValue,
//           electricalComment: electricalComment,
//           electricalFile: electricalFile,
//           electricalName: electricalName,
//           electricalController: electricalController,
//           electricalRatingController: electricalRatingController,

//           // Fittings
//           fittingsValue: fittingsValue,
//           fittingsComment: fittingsComment,
//           fittingsFile: fittingsFile,
//           fittingsName: fittingsName,
//           fittingsController: fittingsController,
//           fittingsRatingController: fittingsRatingController,

//           // Railings
//           railingsValue: railingsValue,
//           railingsComment: railingsComment,
//           railingsFile: railingsFile,
//           railingsName: railingsName,
//           railingsController: railingsController,
//           railingsRatingController: railingsRatingController,

//           // Water Tank
//           waterTankValue: waterTankValue,
//           waterTankComment: waterTankComment,
//           waterTankFile: waterTankFile,
//           waterTankName: waterTankName,
//           waterTankController: waterTankController,
//           waterTankRatingController: waterTankRatingController,

//           // Plumbing
//           plumbingValue: plumbingValue,
//           plumbingComment: plumbingComment,
//           plumbingFile: plumbingFile,
//           plumbingName: plumbingName,
//           plumbingController: plumbingController,
//           plumbingRatingController: plumbingRatingController,

//           // Sewage
//           sewageValue: sewageValue,
//           sewageComment: sewageComment,
//           sewageFile: sewageFile,
//           sewageName: sewageName,
//           sewageController: sewageController,
//           sewageRatingController: sewageRatingController,

//           // Transformer
//           transformerValue: transformerValue,
//           transformerComment: transformerComment,
//           transformerFile: transformerFile,
//           transformerName: transformerName,
//           transformerController: transformerController,
//           transformerRatingController: transformerRatingController,

//           // Lift
//           liftValue: liftValue,
//           liftComment: liftComment,
//           liftFile: liftFile,
//           liftName: liftName,
//           liftController: liftController,
//           liftRatingController: liftRatingController,
//         ),
//       );
//     }
//   }

//   Future<void> _pickFile(String type) async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
//       );

//       if (result != null && result.files.single.path != null) {
//         setState(() {
//           final file = File(result.files.single.path!);
//           final fileName = result.files.single.name;

//           switch (type) {
//             case 'brick':
//               brickFile = file;
//               brickName = fileName;
//               break;
//             case 'doorWindow':
//               doorWindowFile = file;
//               doorWindowName = fileName;
//               break;
//             case 'tiles':
//               tilesFile = file;
//               tilesName = fileName;
//               break;
//             case 'electrical':
//               electricalFile = file;
//               electricalName = fileName;
//               break;
//             case 'fittings':
//               fittingsFile = file;
//               fittingsName = fileName;
//               break;
//             case 'railings':
//               railingsFile = file;
//               railingsName = fileName;
//               break;
//             case 'waterTank':
//               waterTankFile = file;
//               waterTankName = fileName;
//               break;
//             case 'plumbing':
//               plumbingFile = file;
//               plumbingName = fileName;
//               break;
//             case 'sewage':
//               sewageFile = file;
//               sewageName = fileName;
//               break;
//             case 'transformer':
//               transformerFile = file;
//               transformerName = fileName;
//               break;
//             case 'lift':
//               liftFile = file;
//               liftName = fileName;
//               break;
//           }
//         });
//         _notifyParent();
//       }
//     } catch (e) {
//       debugPrint('Error picking file: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
//       }
//     }
//   }

//   Widget _buildFilePreview(dynamic file, String? name, String? extension) {
//     // Handle existing photos from API (List<String>)
//     if (file is List<String> && file.isNotEmpty) {
//       // Debug: Print the URL to see what we're trying to load
//       print('ðŸ–¼ï¸ Trying to load image URL: ${file.first}');

//       // For single image
//       if (file.length == 1) {
//         String imageUrl = file.first;

//         // Check if URL is valid and properly formatted
//         if (!imageUrl.startsWith('http://') &&
//             !imageUrl.startsWith('https://')) {
//           // If it's a relative path, you might need to prepend your base URL
//           // imageUrl = 'https://your-api-base-url.com/' + imageUrl;
//           print('âš ï¸ Invalid URL format: $imageUrl');

//           // Show fallback UI for invalid URLs
//           return Container(
//             height: 150.h,
//             width: 400.w,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.orange),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.photo, size: 40, color: Colors.orange),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Image available',
//                   textAlign: TextAlign.center,
//                   style: w400_14Poppins(color: Colors.orange),
//                 ),
//                 Text(
//                   'Invalid URL format',
//                   textAlign: TextAlign.center,
//                   style: w400_12Poppins(color: Colors.grey),
//                 ),
//                 Text(
//                   'Tap to replace',
//                   textAlign: TextAlign.center,
//                   style: w400_10Poppins(color: Colors.grey),
//                 ),
//               ],
//             ),
//           );
//         }

//         return Container(
//           height: 150.h,
//           width: 400.w,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.green),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: _buildNetworkImage(imageUrl),
//           ),
//         );
//       }
//       // For multiple images - show grid
//       else {
//         return Container(
//           height: 150.h,
//           width: 400.w,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.green),
//           ),
//           child: file.length <= 4
//               ? _buildImageGrid(file)
//               : _buildImageCarousel(file),
//         );
//       }
//     }

//     // Handle new file uploads (File)
//     if (file is File) {
//       String ext = extension ?? path.extension(name ?? '').toLowerCase();
//       if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
//         return Container(
//           height: 150.h,
//           width: 400.w,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: Image.file(file, fit: BoxFit.cover),
//           ),
//         );
//       } else {
//         IconData icon = Icons.description;
//         if (ext == '.pdf') icon = Icons.picture_as_pdf;
//         if (ext == '.doc' || ext == '.docx') icon = Icons.article;

//         return Container(
//           height: 150.h,
//           width: 400.w,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 40, color: Colors.blue),
//               const SizedBox(height: 8),
//               Text(
//                 name ?? '',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ],
//           ),
//         );
//       }
//     }

//     return const SizedBox.shrink();
//   }

//   // Helper method to format/validate image URL
//   String _formatImageUrl(String url) {
//     // Print original URL for debugging
//     print('ðŸ” Original URL: $url');

//     // If URL is already complete, return as is
//     if (url.startsWith('http://') || url.startsWith('https://')) {
//       return url;
//     }

//     // If it's a relative path, prepend your API base URL
//     // Replace 'YOUR_API_BASE_URL' with your actual API base URL
//     const String baseUrl = 'YOUR_API_BASE_URL'; // Update this!
//     String formattedUrl = baseUrl.endsWith('/')
//         ? baseUrl + url
//         : baseUrl + '/' + url;

//     print('ðŸ”§ Formatted URL: $formattedUrl');
//     return formattedUrl;
//   }

//   // Alternative method using CachedNetworkImage (if you add the dependency)
//   Widget _buildNetworkImage(String imageUrl) {
//     String formattedUrl = _formatImageUrl(imageUrl);

//     return Image.network(
//       formattedUrl,
//       fit: BoxFit.cover,
//       headers: {
//         'User-Agent': 'Flutter App',
//         // Add any required headers for your API
//         // 'Authorization': 'Bearer your-token-here',
//       },
//       loadingBuilder: (context, child, loadingProgress) {
//         if (loadingProgress == null) return child;
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 value: loadingProgress.expectedTotalBytes != null
//                     ? loadingProgress.cumulativeBytesLoaded /
//                           loadingProgress.expectedTotalBytes!
//                     : null,
//               ),
//               SizedBox(height: 8),
//               Text('Loading...', style: w400_12Poppins(color: Colors.grey)),
//             ],
//           ),
//         );
//       },
//       errorBuilder: (context, error, stackTrace) {
//         print('âŒ Network Image Error: $error');
//         print('ðŸ” Failed URL: $formattedUrl');
//         print('ðŸ“š Stack trace: $stackTrace');

//         return Container(
//           color: Colors.grey[200],
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.broken_image, size: 40, color: Colors.red),
//               SizedBox(height: 8),
//               Text(
//                 'Image failed to load',
//                 style: w400_12Poppins(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'URL: ${formattedUrl.length > 30 ? formattedUrl.substring(0, 30) + "..." : formattedUrl}',
//                 style: w400_10Poppins(color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Tap to replace',
//                 style: w400_10Poppins(color: Colors.blue),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildImageGrid(List<String> imageUrls) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(10),
//       child: GridView.builder(
//         physics: NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: imageUrls.length == 2 ? 2 : 2,
//           crossAxisSpacing: 2,
//           mainAxisSpacing: 2,
//         ),
//         itemCount: imageUrls.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () => _showImageDialog(imageUrls[index]),
//             child: _buildNetworkImage(imageUrls[index]),
//           );
//         },
//       ),
//     );
//   }

//   // Helper method for displaying carousel of images (5+ images)
//   Widget _buildImageCarousel(List<String> imageUrls) {
//     return Stack(
//       children: [
//         PageView.builder(
//           itemCount: imageUrls.length,
//           itemBuilder: (context, index) {
//             return GestureDetector(
//               onTap: () => _showImageDialog(imageUrls[index]),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.network(
//                   imageUrls[index],
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       color: Colors.grey[300],
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.error_outline, color: Colors.red),
//                           Text('Failed to load', style: w400_10Poppins()),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             );
//           },
//         ),
//         // Image counter overlay
//         Positioned(
//           top: 8,
//           right: 8,
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.black54,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               '${imageUrls.length} photos',
//               style: w400_12Poppins(color: Colors.white),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Helper method to show full-screen image dialog
//   void _showImageDialog(String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Stack(
//             children: [
//               Center(
//                 child: InteractiveViewer(
//                   child: Image.network(
//                     imageUrl,
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey[300],
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.error_outline,
//                               size: 60,
//                               color: Colors.red,
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'Failed to load image',
//                               style: w400_16Poppins(color: Colors.red),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: 40,
//                 right: 20,
//                 child: GestureDetector(
//                   onTap: () => Navigator.of(context).pop(),
//                   child: Container(
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(Icons.close, color: Colors.white, size: 24),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget buildRatingSection({
//     required String title,
//     required String type,
//     required int? ratingValue,
//     required ValueChanged<int?> onRatingChanged,
//     required dynamic pickedFile,
//     required String? pickedFileName,
//     required String? comment,
//     required ValueChanged<String> onCommentChanged,
//     required TextEditingController controller,
//     required TextEditingController ratingController,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: w500_15Poppins()),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               // Rating input
//               SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.28,
//                 height: 30.h,
//                 child: CommonTextFormField(
//                   controller: ratingController,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(1),
//                   ],
//                   fillColor: Appcolors.textformFillColor,
//                   borderColor: Colors.grey.shade400,
//                   hintText: "Rating (1-5)",
//                   hintStyle: w400_15Poppins(),
//                   validator: (value, hintText) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a rating';
//                     }
//                     final intValue = int.tryParse(value);
//                     if (intValue == null || intValue < 1 || intValue > 5) {
//                       return 'Rating must be between 1 and 5';
//                     }
//                     return null;
//                   },
//                   onChanged: (value) {
//                     final validatedValue = _validateAndConvertRating(value);
//                     onRatingChanged(validatedValue);
//                     _notifyParent();
//                   },
//                 ),
//               ),
//               const SizedBox(width: 10),
//               // Comment input
//               SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.28,
//                 child: CommonTextFormField(
//                   controller: controller,
//                   fillColor: Appcolors.textformFillColor,
//                   borderColor: Colors.grey.shade400,
//                   hintText: "Enter comment",
//                   hintStyle: w400_17Poppins(),
//                   onChanged: (value) {
//                     onCommentChanged(value);
//                     _notifyParent();
//                   },
//                 ),
//               ),
//               // Camera icon (if rating is 1-3)
//               if (ratingValue != null && ratingValue <= 3)
//                 IconButton(
//                   onPressed: () => _pickFile(type),
//                   icon: const Icon(Icons.file_upload_outlined, size: 30),
//                 ),
//             ],
//           ),
//           // File preview
//           if (ratingValue != null && ratingValue <= 3)
//             Padding(
//               padding: const EdgeInsets.only(top: 12),
//               child: GestureDetector(
//                 onTap: () => _pickFile(type),
//                 child: _buildFilePreview(
//                   pickedFile,
//                   pickedFileName,
//                   path.extension(pickedFileName ?? ''),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   String get _ratingTitle {
//     if (isFloorOnlyRating) {
//       // Extract floor number from "Floor-X" format
//       String floorNumber = widget.flatNumber.replaceFirst("Floor-", "");
//       return "Non-Structural Ratings for Floor: $floorNumber";
//     } else {
//       return "Non-Structural Ratings for Flat: ${widget.flatNumber}";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<GetstructureProvider>(
//       builder: (context, provider, child) {
//         // Show loading indicator while fetching data
//         if (isLoading) {
//           return Center(child: CircularProgressIndicator());
//         }

//         return SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Text(
//                   _ratingTitle,
//                   style: w500_15Poppins(),
//                 ),
//                 const SizedBox(height: 10),

//                 buildRatingSection(
//                   title: "Brick Plaster",
//                   type: "brick",
//                   ratingValue: brickValue,
//                   onRatingChanged: (val) => setState(() => brickValue = val),
//                   pickedFile: brickFile,
//                   pickedFileName: brickName,
//                   comment: brickComment,
//                   onCommentChanged: (val) => setState(() => brickComment = val),
//                   controller: brickController,
//                   ratingController: brickRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Doors & Windows",
//                   type: "doorWindow",
//                   ratingValue: doorWindowValue,
//                   onRatingChanged: (val) =>
//                       setState(() => doorWindowValue = val),
//                   pickedFile: doorWindowFile,
//                   pickedFileName: doorWindowName,
//                   comment: doorWindowComment,
//                   onCommentChanged: (val) =>
//                       setState(() => doorWindowComment = val),
//                   controller: doorWindowController,
//                   ratingController: doorWindowRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Flooring/Tiles",
//                   type: "tiles",
//                   ratingValue: tilesvalue,
//                   onRatingChanged: (val) => setState(() => tilesvalue = val),
//                   pickedFile: tilesFile,
//                   pickedFileName: tilesName,
//                   comment: tilesComment,
//                   onCommentChanged: (val) => setState(() => tilesComment = val),
//                   controller: tiledController,
//                   ratingController: tilesRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Electrical Wiring",
//                   type: "electrical",
//                   ratingValue: electricalValue,
//                   onRatingChanged: (val) =>
//                       setState(() => electricalValue = val),
//                   pickedFile: electricalFile,
//                   pickedFileName: electricalName,
//                   comment: electricalComment,
//                   onCommentChanged: (val) =>
//                       setState(() => electricalComment = val),
//                   controller: electricalController,
//                   ratingController: electricalRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Sanitary Fittings",
//                   type: "fittings",
//                   ratingValue: fittingsValue,
//                   onRatingChanged: (val) => setState(() => fittingsValue = val),
//                   pickedFile: fittingsFile,
//                   pickedFileName: fittingsName,
//                   comment: fittingsComment,
//                   onCommentChanged: (val) =>
//                       setState(() => fittingsComment = val),
//                   controller: fittingsController,
//                   ratingController: fittingsRatingController,
//                 ),

//                 if (!isFloorOnlyRating) ...[
//                   // These sections are only shown for flat ratings, not floor-only ratings
//                   buildRatingSection(
//                     title: "Railings",
//                     type: "railings",
//                     ratingValue: railingsValue,
//                     onRatingChanged: (val) => setState(() => railingsValue = val),
//                     pickedFile: railingsFile,
//                     pickedFileName: railingsName,
//                     comment: railingsComment,
//                     onCommentChanged: (val) =>
//                         setState(() => railingsComment = val),
//                     controller: railingsController,
//                     ratingController: railingsRatingController,
//                   ),

//                   buildRatingSection(
//                     title: "Water Tanks",
//                     type: "waterTank",
//                     ratingValue: waterTankValue,
//                     onRatingChanged: (val) =>
//                         setState(() => waterTankValue = val),
//                     pickedFile: waterTankFile,
//                     pickedFileName: waterTankName,
//                     comment: waterTankComment,
//                     onCommentChanged: (val) =>
//                         setState(() => waterTankComment = val),
//                     controller: waterTankController,
//                     ratingController: waterTankRatingController,
//                   ),

//                   buildRatingSection(
//                     title: "Plumbing",
//                     type: "plumbing",
//                     ratingValue: plumbingValue,
//                     onRatingChanged: (val) => setState(() => plumbingValue = val),
//                     pickedFile: plumbingFile,
//                     pickedFileName: plumbingName,
//                     comment: plumbingComment,
//                     onCommentChanged: (val) =>
//                         setState(() => plumbingComment = val),
//                     controller: plumbingController,
//                     ratingController: plumbingRatingController,
//                   ),

//                   buildRatingSection(
//                     title: "Sewage System",
//                     type: "sewage",
//                     ratingValue: sewageValue,
//                     onRatingChanged: (val) => setState(() => sewageValue = val),
//                     pickedFile: sewageFile,
//                     pickedFileName: sewageName,
//                     comment: sewageComment,
//                     onCommentChanged: (val) =>
//                         setState(() => sewageComment = val),
//                     controller: sewageController,
//                     ratingController: sewageRatingController,
//                   ),

//                   buildRatingSection(
//                     title: "Panel/Board Transformer",
//                     type: "transformer",
//                     ratingValue: transformerValue,
//                     onRatingChanged: (val) =>
//                         setState(() => transformerValue = val),
//                     pickedFile: transformerFile,
//                     pickedFileName: transformerName,
//                     comment: transformerComment,
//                     onCommentChanged: (val) =>
//                         setState(() => transformerComment = val),
//                     controller: transformerController,
//                     ratingController: transformerRatingController,
//                   ),

//                   buildRatingSection(
//                     title: "Lift",
//                     type: "lift",
//                     ratingValue: liftValue,
//                     onRatingChanged: (val) => setState(() => liftValue = val),
//                     pickedFile: liftFile,
//                     pickedFileName: liftName,
//                     comment: liftComment,
//                     onCommentChanged: (val) => setState(() => liftComment = val),
//                     controller: liftController,
//                     ratingController: liftRatingController,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }