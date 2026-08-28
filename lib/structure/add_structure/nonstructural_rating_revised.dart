// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';
import 'package:sams_engineering_console/utils/radio_group_dropdown.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class NonStructuralRating extends StatefulWidget {
  final String structureId;
  final String? flatId;
  final String? floorId;
  final String selectedStructureSubType;

  const NonStructuralRating({
    super.key,
    required this.structureId,
    this.flatId,
    this.floorId,
    required this.selectedStructureSubType,
  });

  @override
  State<NonStructuralRating> createState() => _NonStructuralRatingState();
}

class _NonStructuralRatingState extends State<NonStructuralRating> {
  List<String> get structureTypes {
    if (widget.selectedStructureSubType.toLowerCase() == 'steel') {
      return [
        'cladding_partition_panels',
        'roof_sheeting',
        'chequered_plate',
        'Doors & Windows',
        'Industrial_Flooring',
        'Electrical Wiring',
        'Sanitary Fittings',
        'Railings',
        'Water Tanks',
        'Plumbing',
        'Sewage System',
        'Transformer Panel / Board',
        'Lift System',
        "Walls",
        "Paintings",
      ];
    } else {
      return [
        'Brick Plaster',
        'Doors & Windows',
        'Flooring/Tiles',
        'Electrical Wiring',
        'Sanitary Fittings',
        'Railings',
        'Water Tanks',
        'Plumbing',
        'Sewage System',
        'Panel/Board Transformer',
        'Lift',
        "Walls",
        "Paintings",
      ];
    }
  }

  bool isSubmitting = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingRatings();
  }

  Future<void> _loadExistingRatings() async {
    if (!mounted) return;
    // Clear stale non-structural data without erasing the sibling tab's ratings.
    Provider.of<AddRatingsStructureProvider>(
      context,
      listen: false,
    ).clearNonStructuralRatings();
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
          print('🏠 Fetching flat non-structural ratings...');
          ratingsData = await getStructureProvider.getAllRatingsForFlat(
            structureId: widget.structureId,
            floorId: widget.floorId!,
            flatId: widget.flatId!,
            context: context,
          );
        } else if (widget.floorId != null) {
          print('🏢 Fetching floor non-structural ratings...');
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

      // Ignore an old response after the user selects another flat or floor.
      if (!mounted) return;

      if (ratingsData != null && ratingsData.data != null) {
        try {
          if (widget.flatId != null) {
            ratingsProvider.populateNonStructuralRatingsFromFlat(
              ratingsData.data.nonStructuralRating,
            );
          } else {
            ratingsProvider.populateNonStructuralRatingsFromFloor(
              ratingsData.data.nonStructuralRating,
            );
          }

          hasData = ratingsProvider.nonStructuralRatingMap.isNotEmpty;

          if (hasData) {
            errorMessage = null;
          } else {
            errorMessage =
                'No existing non-structural ratings found. You can create new ones.';
          }
        } catch (populateError) {
          errorMessage =
              'Could not load existing data properly. You can create new ratings.';
        }
      } else {
        errorMessage =
            'No existing non-structural ratings found. You can create new ones.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage =
              'No existing non-structural ratings found. You can create new ones.';
        });
      }
    } finally {
      if (mounted) {
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
            .where((type) => !provider.nonStructuralRatingMap.containsKey(type))
            .toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableOptions.isNotEmpty) ...[
                  LabeledField(
                    label: 'Add a non-structural element',
                    child: RadioGroupDropdown<String>(
                      options: radioOptionsFromStrings(availableOptions),
                      value: null,
                      hintText: 'Select item',
                      sheetTitle: 'Add a non-structural element',
                      onChanged: (value) {
                        if (value == null) return;
                        provider.addNonStructuralStructureType(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ...provider.nonStructuralRatingMap.entries.map((entry) {
                  final type = entry.key;
                  final items = entry.value;

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
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => provider
                                        .addItemToNonStructuralType(type),
                                    tooltip: 'Add another $type item',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      provider.removeNonStructuralStructureType(
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
                            // Distress types are removed for non-structural components

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

                const SizedBox(height: 20),
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
                            'Submit Non-Structural Ratings',
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

    final validationError = validateRatingsForSubmission(
      provider.nonStructuralRatingMap,
    );
    if (validationError != null) {
      CustomToast.showErrorToast(msg: validationError);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final addRatingsStructureProvider =
          Provider.of<AddRatingsStructureProvider>(context, listen: false);

      if (widget.flatId != null) {
        await addRatingsStructureProvider.submitAllNonStructuralData(
          widget.structureId,
          widget.flatId!,
          context,
          structureSubType: widget.selectedStructureSubType,
        );
      } else if (widget.floorId != null) {
        await addRatingsStructureProvider.submitAllNonStructuralDataForFloor(
          widget.structureId,
          widget.floorId!,
          context,
          structureSubType: widget.selectedStructureSubType,
        );
      }

      // Success toast is shown by the provider
    } catch (e) {
      // Error toast is already shown by the provider; only log here
      debugPrint("❌ [NON-STRUCTURAL] Submit failed: $e");
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
                  if (provider.nonStructuralRatingMap[type]!.length == 1) {
                    provider.removeNonStructuralStructureType(type);
                    CustomToast.showSuccessToast(msg: '$type removed');
                  } else {
                    provider.nonStructuralRatingMap[type]!.removeAt(index);
                    provider.notifyListeners();
                    CustomToast.showSuccessToast(msg: '$title removed');
                  }
                },
                tooltip: 'Delete $title',
              ),
            ],
          ),

          FormGrid(
            children: [
              LabeledField(
                label: 'Rating (1-5)',
                isRequired: true,
                child: FormTextField(
                  controller: item.ratingController,
                  keyboardType: TextInputType.number,
                  hintText: 'Rating',
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
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
                    provider.notifyListeners();
                  },
                ),
              ),
              LabeledField(
                label: 'Comment',
                child: FormTextField(
                  controller: item.commentController,
                  hintText: 'Enter comment',
                  onChanged: (value) {
                    item.comment = value;
                    provider.notifyListeners();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: FormKit.rowGap),

          Row(
            children: [
              AttachmentButton(
                icon: Icons.add_a_photo_outlined,
                label: 'Photos',
                count: item.files?.length ?? 0,
                badgeColor: Colors.green,
                onTap: () => _showImageSourceDialog(provider, type, index),
              ),
              const SizedBox(width: 10),
              AttachmentButton(
                icon: Icons.attach_file_rounded,
                label: 'Documents',
                count: item.docFiles?.length ?? 0,
                badgeColor: Colors.orange,
                onTap: () => _pickDocuments(provider, type, index),
              ),
            ],
          ),

          const SizedBox(height: FormKit.rowGap),

          FormGrid(
            columns: 3,
            minItemWidth: 170,
            children: [
              _buildDistressUnitDropdown(provider: provider, item: item),
              numberField(
                label: 'No.',
                controller: item.numberController,
                keyboardtype: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val, String? f) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter No.';
                  }
                  return null;
                },
              ),
              if (item.distressUnit != DistressMeasurementUnit.nos) ...[
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
                  validator: (val, String? f) => null,
                ),
                if (item.distressUnit != DistressMeasurementUnit.rm)
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
                    validator: (val, String? f) => null,
                  ),
              ],
              if (item.distressUnit == DistressMeasurementUnit.cum)
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
                  validator: (val, String? f) => null,
                ),
              LabeledField(
                label: "Repair methodology",
                child: FormTextField(
                  controller: item.repairMethodologyController,
                  hintText: "Enter repair",
                  onChanged: (value) {
                    item.repairMethodology = value;
                    provider.notifyListeners();
                  },
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
                        label: const Text('Add More'),
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
                        label: const Text('Add More'),
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
                      Expanded(
                        child: Text(
                          'Existing Photos (${item.photoUrls.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showImageSourceDialog(provider, type, index),
                        icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                        label: const Text('Add another'),
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

  // Distress types removed for non-structural components

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
    final item = provider.nonStructuralRatingMap[type]![index];
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
    final item = provider.nonStructuralRatingMap[type]![index];
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
    required RatingItem item,
  }) {
    return LabeledField(
      label: "Units",
      child: RadioGroupDropdown<DistressMeasurementUnit>(
        options: DistressMeasurementUnit.values
            .where((unit) => unit != DistressMeasurementUnit.nos)
            .map((unit) => RadioOption(unit, unit.label))
            .toList(),
        value: item.distressUnit,
        hintText: "Select unit",
        sheetTitle: "Measurement unit",
        useAlertDialog: true,
        onChanged: (value) {
          if (value == null) return;
          provider.updateDistressUnit(item, value);
        },
      ),
    );
  }

  Widget numberField({
    required String label,
    String? unitLabel,
    required TextEditingController controller,
    String? Function(String?, String)? validator,
    TextInputType? keyboardtype,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return LabeledField(
      label: unitLabel == null ? label : "$label ($unitLabel)",
      child: FormTextField(
        controller: controller,
        validator: validator,
        hintText: "Enter ${label.toLowerCase()}",
        keyboardType: keyboardtype,
        inputFormatters: inputFormatters,
        suffixIcon: NumberStepperSuffix(controller: controller),
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
