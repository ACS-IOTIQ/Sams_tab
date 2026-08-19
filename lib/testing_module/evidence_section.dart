
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/images.dart';

/// Reusable Remarks & Evidence card.
/// Drop this into any test screen to get working PDF + Image attachment.
class EvidenceSection extends StatefulWidget {
  const EvidenceSection({super.key});

  @override
  State<EvidenceSection> createState() => _EvidenceSectionState();
}

class _EvidenceSectionState extends State<EvidenceSection> {
  final List<PlatformFile> _pdfs = [];
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // ── PDF picker ─────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pdfs.addAll(result.files));
    }
  }

  void _removePdf(int index) => setState(() => _pdfs.removeAt(index));

  // ── Image picker ───────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) setState(() => _images.addAll(picked));
    } else {
      final picked =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked != null) setState(() => _images.add(picked));
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Select Image Source", style: w600_18Poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text("Gallery", style: w400_15Poppins()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text("Camera", style: w400_15Poppins()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Remarks & Evidence", style: w600_18Poppins()),
            height10,

            // ── Action buttons ───────────────────────────────────────
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text("Add PDF", style: w500_16Poppins()),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text("Add Image", style: w500_16Poppins()),
                ),
              ],
            ),

            // ── PDF list ─────────────────────────────────────────────
            if (_pdfs.isNotEmpty) ...[
              height10,
              Text("PDFs (${_pdfs.length})", style: w500_18Poppins()),
              height5,
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pdfs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final pdf = _pdfs[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pdf.name,
                                style: w500_16Poppins(),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatBytes(pdf.size),
                                style: w400_14Poppins(),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removePdf(i),
                          tooltip: "Remove",
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // ── Image grid ───────────────────────────────────────────
            if (_images.isNotEmpty) ...[
              height10,
              Text("Images (${_images.length})", style: w500_18Poppins()),
              height5,
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _images.length,
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      // Thumbnail — tap to view full screen
                      GestureDetector(
                        onTap: () => _showFullImage(context, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_images[i].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Full-screen image viewer ───────────────────────────────────────────

  void _showFullImage(BuildContext context, int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewer(
          images: _images,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}

// ── Full-screen swipeable image viewer ────────────────────────────────────

class _FullImageViewer extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;

  const _FullImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          "Image ${_currentIndex + 1} of ${widget.images.length}",
          style: w400_17Poppins(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(widget.images[i].path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}