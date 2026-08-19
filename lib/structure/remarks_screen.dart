import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/images.dart';

class RemarksScreen extends StatefulWidget {
  const RemarksScreen({
    super.key, 
    required this.strId,
    required this.userRole, // Add userRole parameter
  });

  final String strId;
  final String userRole; // User's role (FE or VE)

  @override
  State<RemarksScreen> createState() => _RemarksScreenState();
}

class _RemarksScreenState extends State<RemarksScreen> {
  TextEditingController updateController = TextEditingController();
  late GetstructureProvider getstructureProvider;

  // Store the remark ID based on user role
  String? remarkId;

  @override
  void initState() {
    super.initState();
    getstructureProvider =
        Provider.of<GetstructureProvider>(context, listen: false);

    loadRemarks();
  }

  Future<void> loadRemarks() async {
    await getstructureProvider.getRemarksByStructureId(
      context: context,
      structureId: widget.strId,
    );

    final remarks = getstructureProvider.getRemarksByStrId;

    if (remarks != null) {
      // Check user role and load appropriate remarks
      if (widget.userRole.trim().toUpperCase() == "FE") {
        // Load FE remarks
        if (remarks.data.feRemarks.isNotEmpty &&
            remarks.data.feRemarks[0].text.isNotEmpty) {
          updateController.text = remarks.data.feRemarks[0].text;
          remarkId = remarks.data.feRemarks[0].id.trim();
        } else {
          remarkId = null;
        }
      } else if (widget.userRole.trim().toUpperCase() == "VE") {
        // Load VE remarks
        if (remarks.data.veRemarks.isNotEmpty &&
            remarks.data.veRemarks[0].text.isNotEmpty) {
          updateController.text = remarks.data.veRemarks[0].text;
          remarkId = remarks.data.veRemarks[0].id.trim();
        } else {
          remarkId = null;
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Consumer<GetstructureProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      height10,
                      Text("Update Remarks:", style: w500_17Poppins()),
                      height10,
                      CommonTextFormField(
                        controller: updateController,
                        maxLines: 5,
                        hintText: "Enter remarks",
                        hintStyle: w400_15Poppins(),
                        borderColor: Colors.grey.shade400,
                      ),
                      height10,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Bottom buttons
  Widget _buildBottomNavigationBar() {
    return Consumer<GetstructureProvider>(
      builder: (context, getStructureProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                buttonText: "Back",
                borderRadius: 10.r,
                buttonColor: Colors.transparent,
                buttonTextStyle: w700_15Poppins(color: Appcolors.buttonColor),
                width: 90.w,
                height: 30.h,
                borderColor: Appcolors.buttonColor,
                onTap: () => Navigator.pop(context),
              ),
              width40,
              CustomButton(
                buttonText: "Submit",
                borderRadius: 10.r,
                buttonColor: Colors.transparent,
                buttonTextStyle: w700_15Poppins(color: Appcolors.buttonColor),
                width: 90.w,
                height: 30.h,
                borderColor: Appcolors.buttonColor,
                onTap: () {
                  // Check if remark ID exists
                  if (remarkId == null) {
                    CustomToast.showInfoToast(msg: "No remark ID found to update for ${widget.userRole}");
                  
                    return;
                  }

                  // Submit with the appropriate remark ID
                  getStructureProvider.updateRemarks(
                    context,
                    widget.strId,
                    updateController.text,
                    remarkId!,
                  );

                  print("SUBMITTED: ${updateController.text}");
                  print("REMARK ID SENT (${widget.userRole}): $remarkId");
                },
              ),
            ],
          ),
        );
      },
    );
  }
}