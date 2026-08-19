import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/geometric_details.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/floating_action_bar.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';

class AdministrativeGeometricdetails extends StatefulWidget {
  const AdministrativeGeometricdetails({
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
  State<AdministrativeGeometricdetails> createState() =>
      _AdministrativeGeometricdetailsState();
}

class _AdministrativeGeometricdetailsState
    extends State<AdministrativeGeometricdetails> {
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController custodianController = TextEditingController();
  final TextEditingController engineerDesignationController =
      TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  late GetstructureProvider getstructureProvider;

  bool _isDataLoaded = false;
  bool hasExistingAdminData = false;

  @override
  void initState() {
    super.initState();

    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );

    _fetchData();
  }

  /// 🔁 Fetch API + reset state
  void _fetchData() {
    _isDataLoaded = false;
    hasExistingAdminData = false;

    clearControllers();
    getstructureProvider.clearAdministrativeDetails();

    getstructureProvider.getAdministrativeDetailsByStructureId(
      structureId: widget.structureId,
      context: context,
    );
  }

  /// 🧹 Clear all fields
  void clearControllers() {
    clientNameController.clear();
    custodianController.clear();
    engineerDesignationController.clear();
    contactController.clear();
    emailController.clear();
  }

  /// 🔁 Detect structureId change
  @override
  void didUpdateWidget(covariant AdministrativeGeometricdetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.structureId != widget.structureId) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    clientNameController.dispose();
    custodianController.dispose();
    engineerDesignationController.dispose();
    contactController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Widget commonTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    Widget? icon,
    int? maxLength,
    String? Function(String?, String)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label:", style: w500_15Poppins()),
        SizedBox(height: 5.h),
        SizedBox(
          height: 40.h,
          width: MediaQuery.of(context).size.width * 0.33,
          child: CommonTextFormField(
            fillColor: Appcolors.textformFillColor,
            borderColor: Colors.grey.shade400,
            controller: controller,
            hintText: "Enter $label",
            maxLength: maxLength,
            validator: validator,
            keyboardType: keyboardType,
            labelStyle: w400_15Poppins(),
            hintStyle: w400_14Poppins(),
            suffixIcon: icon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GetstructureProvider>(
      builder: (context, provider, child) {
        final adminData =
            provider.getAdminstrativeDetailsByStrIdModel?.data?.administration;

        /// ✅ Populate data ONLY ONCE
        if (!_isDataLoaded && adminData != null) {
          clientNameController.text = adminData.clientName ?? '';
          custodianController.text = adminData.custodian ?? '';
          engineerDesignationController.text =
              adminData.engineerDesignation ?? '';
          contactController.text = adminData.contactDetails ?? '';
          emailController.text = adminData.emailId ?? '';

          hasExistingAdminData = true;
          _isDataLoaded = true;
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  10,
                  10,
                  FloatingActionBar.contentBottomPadding(context),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🔹 Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Administrative Details",
                                style: w700_20Poppins(),
                              ),

                              if (hasExistingAdminData)
                                CustomButton(
                                  buttonText: "Skip",
                                  borderRadius: 10.r,
                                  buttonColor: Colors.transparent,
                                  buttonTextStyle: w700_15Poppins(
                                    color: Appcolors.buttonColor,
                                  ),
                                  width: 60.w,
                                  height: 30.h,
                                  borderColor: Appcolors.buttonColor,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Geometricdetails(
                                          structureId: widget.structureId,
                                          selectedStructureType:
                                              widget.selectedStructureType,
                                          selectedCommercialType:
                                              widget.selectedCommercialType,
                                          selectedStructureSubType:
                                              widget.selectedStructureSubType,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),

                          SizedBox(height: 15.h),

                          /// 🔹 Fields
                          Row(
                            children: [
                              commonTextField(
                                label: "Client Name",
                                controller: clientNameController,
                                validator: (val, _) =>
                                    FormValidations.requiredFieldValidation(
                                      val,
                                      "Enter client name",
                                    ),
                                icon: Icon(Icons.person),
                              ),
                              SizedBox(width: 10.w),
                              commonTextField(
                                label: "Custodian",
                                controller: custodianController,
                                validator: (val, _) =>
                                    FormValidations.requiredFieldValidation(
                                      val,
                                      "Enter custodian",
                                    ),
                                icon: Icon(Icons.person_outline),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          Row(
                            children: [
                              commonTextField(
                                label: "Engineer Designation",
                                controller: engineerDesignationController,
                                validator: (val, _) =>
                                    FormValidations.requiredFieldValidation(
                                      val,
                                      "Enter designation",
                                    ),
                                icon: Icon(Icons.engineering),
                              ),
                              SizedBox(width: 10.w),
                              commonTextField(
                                label: "Contact",
                                controller: contactController,
                                maxLength: 10,
                                keyboardType: TextInputType.phone,
                                validator: (val, String? f) =>
                                    FormValidations.phoneNoValidation(
                                      contactController.text,
                                      "Enter valid contact",
                                    ),
                                icon: Icon(Icons.phone),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          commonTextField(
                            label: "Email",
                            controller: emailController,
                            validator: (val, String? f) =>
                                FormValidations.emailValidation(
                                  emailController.text,
                                  "Please enter email id",
                                ),
                            icon: Icon(Icons.email),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 🔹 Bottom Buttons
          extendBody: true,
          bottomNavigationBar: Consumer<AddstructureProvider>(
            builder: (context, addProvider, child) {
              return FloatingActionBar(
                children: [
                  CustomButton(
                    buttonText: "Back",
                    borderRadius: 10.r,
                    buttonColor: Colors.transparent,
                    buttonTextStyle: w700_15Poppins(
                      color: Appcolors.buttonColor,
                    ),
                    width: 140.w,
                    height: 40.h,
                    borderColor: Appcolors.buttonColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  CustomButton(
                    buttonText: "Next",
                    borderRadius: 10.r,
                    buttonColor: Appcolors.buttonColor,
                    buttonTextStyle: w700_15Poppins(color: Colors.white),
                    width: 160.w,
                    height: 40.h,
                    borderColor: Appcolors.buttonColor,
                    onTap: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final adminData = getstructureProvider
                            .getAdminstrativeDetailsByStrIdModel
                            ?.data
                            ?.administration;

                        final isUpdate = adminData != null;

                        await addProvider.submitAdministrativeData(
                          context,
                          clientNameController.text,
                          custodianController.text,
                          engineerDesignationController.text,
                          contactController.text,
                          emailController.text,
                          widget.structureId,
                          isUpdate,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Geometricdetails(
                              structureId: widget.structureId,
                              selectedStructureType:
                                  widget.selectedStructureType,
                              selectedCommercialType:
                                  widget.selectedCommercialType,
                              selectedStructureSubType:
                                  widget.selectedStructureSubType,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
