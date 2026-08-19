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
// import 'package:path/path.dart' as path;

// class StructuralRating extends StatefulWidget {
//   final String flatNumber;
//   final String? floorId;
//   final String? flatId;
//   final String? structureId;
//   final void Function(StructuralRatingData)? onChanged;

//   const StructuralRating({
//     super.key,
//     required this.flatNumber,
//     required this.onChanged,
//     this.flatId,
//     this.floorId,
//     this.structureId,
//   });

//   @override
//   State<StructuralRating> createState() => _StructuralRatingState();
// }

// class _StructuralRatingState extends State<StructuralRating> {
//   // Rating values
//   int? beamsRating;
//   String? beamsComment;
//   dynamic beamsFile;
//   String? beamsFileName;

//   int? columnsRating;
//   String? columnComment;
//   dynamic columnFile;
//   String? columnFileName;

//   int? slabRating;
//   String? slabComment;
//   dynamic slabFile;
//   String? slabFileName;

//   int? foundationRating;
//   String? foundationComment;
//   dynamic foundationFile;
//   String? foundationFileName;

//   // Controllers
//   final TextEditingController beamsController = TextEditingController();
//   final TextEditingController beamsRatingController = TextEditingController();
//   final TextEditingController columnsController = TextEditingController();
//   final TextEditingController columnsRatingController = TextEditingController();
//   final TextEditingController slabController = TextEditingController();
//   final TextEditingController slabRatingController = TextEditingController();
//   final TextEditingController foundationController = TextEditingController();
//   final TextEditingController foundationRatingController =
//       TextEditingController();

//   late GetstructureProvider getstructureProvider;
//   bool isLoading = true;
//   bool hasLoadedData = false;
//   bool controllersInitialized = false;
//   bool _dataInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     getstructureProvider = Provider.of<GetstructureProvider>(
//       context,
//       listen: false,
//     );

//     // Initialize with a slight delay to ensure widget is fully mounted
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadExistingData();
//     });
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
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       print(
//         'Ã°Å¸"â€ž Loading data for structureId: ${widget.structureId}, floorId: ${widget.floorId}, flatNumber: ${widget.flatNumber}',
//       );

//       await getstructureProvider.getFlatsWithDetailsByFloorId(
//         structureId: widget.structureId!,
//         floorId: widget.floorId!,
//         context: context,
//       );

//       print('Ã¢Å“â€¦ Data loaded successfully');

//       // Wait for the provider to update and then populate fields
//       if (mounted) {
//         await Future.delayed(
//           Duration(milliseconds: 100),
//         ); // Small delay for provider to update
//         _populateFieldsWithExistingData();
//       }
//     } catch (e) {
//       print('âŒ Error loading existing data: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading existing data: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   void _populateFieldsWithExistingData() {
//     if (!mounted || _dataInitialized) return;

//     print('Ã°Å¸" Populating fields with existing data...');
//     final flatData = getstructureProvider.getFlatsByFloorId(widget.floorId!);

//     if (flatData?.data?.flats == null) {
//       print('âŒ No flat data available');
//       return;
//     }

//     final currentFlat = flatData!.data!.flats!.firstWhere(
//       (flat) => flat.flatNumber == widget.flatNumber,
//       orElse: () => throw StateError('Flat not found'),
//     );

//     if (currentFlat.structuralRating == null) {
//       print('â„¹ï¸ No existing structural rating data');
//       setState(() {
//         _dataInitialized = true;
//       });
//       return;
//     }

//     final structural = currentFlat.structuralRating!;
//     bool hasData = false;

//     setState(() {
//       // Populate Beams with safe conversion
//       if (structural.beams?.rating != null) {
//         final safeRating = _safeConvertToInt(structural.beams!.rating);
//         if (safeRating != null) {
//           beamsRating = safeRating;
//           beamsComment = structural.beams!.conditionComment ?? '';
//           beamsController.text = beamsComment!;
//           beamsRatingController.text = beamsRating.toString();
//           beamsFile = structural.beams!.photos;
//           hasData = true;
//           print('âœ… Populated beams data - rating: $beamsRating');
//         } else {
//           print(
//             'âŒ Beams rating conversion failed: ${structural.beams!.rating}',
//           );
//         }
//       }

//       // Populate Columns with safe conversion
//       if (structural.columns?.rating != null) {
//         final safeRating = _safeConvertToInt(structural.columns!.rating);
//         if (safeRating != null) {
//           columnsRating = safeRating;
//           columnComment = structural.columns!.conditionComment ?? '';
//           columnsController.text = columnComment!;
//           columnsRatingController.text = columnsRating.toString();
//           columnFile = structural.columns!.photos;
//           hasData = true;
//           print('âœ… Populated columns data - rating: $columnsRating');
//         } else {
//           print(
//             'âŒ Columns rating conversion failed: ${structural.columns!.rating}',
//           );
//         }
//       }

//       // Populate Slab with safe conversion
//       if (structural.slab?.rating != null) {
//         final safeRating = _safeConvertToInt(structural.slab!.rating);
//         if (safeRating != null) {
//           slabRating = safeRating;
//           slabComment = structural.slab!.conditionComment ?? '';
//           slabController.text = slabComment!;
//           slabRatingController.text = slabRating.toString();
//           slabFile = structural.slab!.photos;
//           hasData = true;
//           print('âœ… Populated slab data - rating: $slabRating');
//         } else {
//           print('âŒ Slab rating conversion failed: ${structural.slab!.rating}');
//         }
//       }

//       // Populate Foundation with safe conversion
//       if (structural.foundation?.rating != null) {
//         final safeRating = _safeConvertToInt(structural.foundation!.rating);
//         if (safeRating != null) {
//           foundationRating = safeRating;
//           foundationComment = structural.foundation!.conditionComment ?? '';
//           foundationController.text = foundationComment!;
//           foundationRatingController.text = foundationRating.toString();
//           foundationFile = structural.foundation!.photos;
//           hasData = true;
//           print('âœ… Populated foundation data - rating: $foundationRating');
//         } else {
//           print(
//             'âŒ Foundation rating conversion failed: ${structural.foundation!.rating}',
//           );
//         }
//       }

//       _dataInitialized = true;
//       controllersInitialized = true;
//     });

//     // Notify parent after state update is complete
//     if (hasData) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _notifyParent();
//         print('Ã°Å¸"Â¢ Parent notified with existing data');
//       });
//     }
//   }

//   @override
//   void dispose() {
//     beamsController.dispose();
//     beamsRatingController.dispose();
//     columnsController.dispose();
//     columnsRatingController.dispose();
//     slabController.dispose();
//     slabRatingController.dispose();
//     foundationController.dispose();
//     foundationRatingController.dispose();
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

//   bool hasExistingPhotos(dynamic fileData) {
//     if (fileData is List<String>) {
//       return fileData.isNotEmpty;
//     }
//     if (fileData is File) {
//       return true;
//     }
//     return false;
//   }

//   void _notifyParent() {
//     if (widget.onChanged != null) {
//       widget.onChanged!(
//         StructuralRatingData(
//           // Beams
//           beamsRating: beamsRating,
//           beamsComment: beamsComment,
//           beamsFile: beamsFile,
//           beamsFileName: beamsFileName,
//           beamsController: beamsController,
//           beamsRatingController: beamsRatingController,

//           // Columns
//           columnsRating: columnsRating,
//           columnsComment: columnComment,
//           columnsFile: columnFile,
//           columnsFileName: columnFileName,
//           columnsController: columnsController,
//           columnsRatingController: columnsRatingController,

//           // Slab
//           slabRating: slabRating,
//           slabComment: slabComment,
//           slabFile: slabFile,
//           slabFileName: slabFileName,
//           slabController: slabController,
//           slabRatingController: slabRatingController,

//           // Foundation
//           foundationRating: foundationRating,
//           foundationComment: foundationComment,
//           foundationFile: foundationFile,
//           foundationFileName: foundationFileName,
//           foundationController: foundationController,
//           foundationRatingController: foundationRatingController,
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
//             case 'beams':
//               beamsFile = file;
//               beamsFileName = fileName;
//               break;
//             case 'columns':
//               columnFile = file;
//               columnFileName = fileName;
//               break;
//             case 'slab':
//               slabFile = file;
//               slabFileName = fileName;
//               break;
//             case 'foundation':
//               foundationFile = file;
//               foundationFileName = fileName;
//               break;
//           }
//         });
//         _notifyParent();
//       }
//     } catch (e) {
//       debugPrint('Error picking file: $e');
//       // Show error to user
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
//         print('ðŸ“ Failed URL: $formattedUrl');
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
//     required TextEditingController commentController,
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
//           const SizedBox(height: 5),
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
//               const SizedBox(width: 5),
//               // Comment input
//               SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.28,
//                 height: 30.h,
//                 child: CommonTextFormField(
//                   controller: commentController,
//                   fillColor: Appcolors.textformFillColor,
//                   borderColor: Colors.grey.shade400,
//                   hintText: "Enter comment",
//                   hintStyle: w400_15Poppins(),
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

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<GetstructureProvider>(
//       builder: (context, getStructureProvider, child) {
//         // Show loading indicator while fetching data
//         if (isLoading && !_dataInitialized) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Loading existing ratings...', style: w400_14Poppins()),
//               ],
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Ratings for Flat: ${widget.flatNumber}",
//                   style: w500_18Poppins(),
//                 ),

//                 // Show data status for debugging
//                 if (!_dataInitialized)
//                   Container(
//                     padding: EdgeInsets.all(8),
//                     margin: EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.orange),
//                     ),
//                     child: Text(
//                       'Initializing data...',
//                       style: w400_12Poppins(color: Colors.orange.shade800),
//                     ),
//                   ),

//                 const SizedBox(height: 10),

//                 buildRatingSection(
//                   title: "Beams Rating",
//                   type: "beams",
//                   ratingValue: beamsRating,
//                   onRatingChanged: (val) => setState(() => beamsRating = val),
//                   pickedFile: beamsFile,
//                   pickedFileName: beamsFileName,
//                   comment: beamsComment,
//                   onCommentChanged: (val) => setState(() => beamsComment = val),
//                   commentController: beamsController,
//                   ratingController: beamsRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Columns Rating",
//                   type: "columns",
//                   ratingValue: columnsRating,
//                   onRatingChanged: (val) => setState(() => columnsRating = val),
//                   pickedFile: columnFile,
//                   pickedFileName: columnFileName,
//                   comment: columnComment,
//                   onCommentChanged: (val) =>
//                       setState(() => columnComment = val),
//                   commentController: columnsController,
//                   ratingController: columnsRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Slab Rating",
//                   type: "slab",
//                   ratingValue: slabRating,
//                   onRatingChanged: (val) => setState(() => slabRating = val),
//                   pickedFile: slabFile,
//                   pickedFileName: slabFileName,
//                   comment: slabComment,
//                   onCommentChanged: (val) => setState(() => slabComment = val),
//                   commentController: slabController,
//                   ratingController: slabRatingController,
//                 ),

//                 buildRatingSection(
//                   title: "Foundation Rating",
//                   type: "foundation",
//                   ratingValue: foundationRating,
//                   onRatingChanged: (val) =>
//                       setState(() => foundationRating = val),
//                   pickedFile: foundationFile,
//                   pickedFileName: foundationFileName,
//                   comment: foundationComment,
//                   onCommentChanged: (val) =>
//                       setState(() => foundationComment = val),
//                   commentController: foundationController,
//                   ratingController: foundationRatingController,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
