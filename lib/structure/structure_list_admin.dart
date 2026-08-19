// ignore_for_file: avoid_print

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/images.dart';

class StructureListAdmin extends StatefulWidget {
  const StructureListAdmin({super.key});

  @override
  State<StructureListAdmin> createState() => _StructureListAdminState();
}

class _StructureListAdminState extends State<StructureListAdmin> {
  // Pagination variables
  int currentPage = 0;
  int itemsPerPage = 10;
  List<StructureData> structures = List.generate(
    50, // Generate 50 sample records
    (index) => StructureData(
      id: 'STR${(index + 1).toString().padLeft(3, '0')}',
      structureId: 'TTDTDYGHBBNBBJJKJ',
      assignedTo: 'Pawan',
      status: ['Active', 'Inactive', 'Pending'][index % 3],
    ),
  );

  // Get current page data
  List<StructureData> get currentPageData {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, structures.length);
    return structures.sublist(startIndex, endIndex);
  }

  // Get total pages
  int get totalPages => (structures.length / itemsPerPage).ceil();

  List<DataRow> _buildDataRows() {
    return currentPageData.asMap().entries.map((entry) {
      final index = entry.key;
      final structure = entry.value;
      final serialNumber = (currentPage * itemsPerPage) + index + 1;

      return DataRow(
        cells: [
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 30.w),
              child: Text('$serialNumber', style: w400_15Poppins()),
            ),
          ),
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 140.w),
              child: Text(
                structure.structureId,
                style: w400_15Poppins(),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 130.w),
              child: Text(structure.status, style: w400_15Poppins()),
            ),
          ),
          DataCell(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 130.w),
                child: Text(structure.assignedTo, style: w400_15Poppins()),
              ),
            ),
          ),
          DataCell(
            CustomButton(
              borderColor: Appcolors.buttonColor,
              buttonColor: Colors.white,
              buttonTextStyle: w500_14Poppins(color: Colors.black),
              buttonText: "View",
              onTap: () {
                // Handle edit action
                print('Edit clicked for ${structure.id}');
              },
              width: 29.w,
            ),
          ),
          DataCell(
            CustomButton(
              borderColor: Appcolors.buttonColor,
              buttonColor: Colors.white,
              buttonTextStyle: w500_14Poppins(color: Colors.black),
              buttonText: "Export",
              onTap: () {
                // Handle export action
                print('Export clicked for ${structure.id}');
              },
              width: 29.w,
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          height10,
          Text("All Structures", style: w500_17Poppins()),
          height10,
          Container(
            height: 300.h,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable2(
              headingRowDecoration: BoxDecoration(),
              columnSpacing: 4,
              horizontalMargin: 9,
              columns: [
                DataColumn2(
                  label: Text('S.No', style: w600_16Poppins()),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text('Structure ID', style: w600_16Poppins()),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text('Status', style: w600_16Poppins()),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text('Field Engineer', style: w600_16Poppins()),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text('View', style: w600_16Poppins()),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text('Download', style: w600_16Poppins()),
                  size: ColumnSize.S,
                ),
              ],
              rows: _buildDataRows(),
            ),
          ), // Pagination Controls
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Items info
                Text(
                  'Showing ${(currentPage * itemsPerPage) + 1}-${((currentPage + 1) * itemsPerPage).clamp(0, structures.length)} of ${structures.length}',
                  style: w400_14Poppins(color: Colors.grey[600]),
                ),

                // Pagination buttons
                Row(
                  children: [
                    // Previous button
                    GestureDetector(
                      onTap: currentPage > 0
                          ? () {
                              setState(() {
                                currentPage--;
                              });
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: currentPage > 0
                                ? Appcolors.buttonColor
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: currentPage > 0
                              ? Colors.white
                              : Colors.grey.shade100,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: currentPage > 0
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                            Text(
                              'Previous',
                              style: w400_14Poppins(
                                color: currentPage > 0
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Page indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade50,
                      ),
                      child: Text(
                        'Page ${currentPage + 1} of $totalPages',
                        style: w500_14Poppins(),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Next button
                    GestureDetector(
                      onTap: currentPage < totalPages - 1
                          ? () {
                              setState(() {
                                currentPage++;
                              });
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: currentPage < totalPages - 1
                                ? Appcolors.buttonColor
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: currentPage < totalPages - 1
                              ? Colors.white
                              : Colors.grey.shade100,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Next',
                              style: w400_14Poppins(
                                color: currentPage < totalPages - 1
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: currentPage < totalPages - 1
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data model for structure
class StructureData {
  final String id;
  final String structureId;
  final String assignedTo;
  final String status;

  StructureData({
    required this.id,
    required this.structureId,
    required this.assignedTo,
    required this.status,
  });
}


   



         

