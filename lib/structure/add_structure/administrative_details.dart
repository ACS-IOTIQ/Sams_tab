import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/geometric_details.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/wizard_scaffold.dart';

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

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    Widget? icon,
    int? maxLength,
    bool isRequired = true,
    String? Function(String?, String)? validator,
  }) {
    return LabeledField(
      label: label,
      isRequired: isRequired,
      child: FormTextField(
        controller: controller,
        hintText: "Enter ${label.toLowerCase()}",
        maxLength: maxLength,
        validator: validator,
        keyboardType: keyboardType,
        prefixIcon: icon == null
            ? null
            : IconTheme(
                data: const IconThemeData(size: 18, color: FormKit.hintColor),
                child: icon,
              ),
      ),
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

        void goToGeometric() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Geometricdetails(
                structureId: widget.structureId,
                selectedStructureType: widget.selectedStructureType,
                selectedCommercialType: widget.selectedCommercialType,
                selectedStructureSubType: widget.selectedStructureSubType,
              ),
            ),
          );
        }

        return Consumer<AddstructureProvider>(
          builder: (context, addProvider, _) {
            return WizardScaffold(
              title: "Administrative Details",
              subtitle: "Step 2 of 4",
              appBarActions: [
                if (hasExistingAdminData) WizardSkipButton(onTap: goToGeometric),
              ],
              onNext: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final existing = getstructureProvider
                      .getAdminstrativeDetailsByStrIdModel
                      ?.data
                      ?.administration;

                  await addProvider.submitAdministrativeData(
                    context,
                    clientNameController.text,
                    custodianController.text,
                    engineerDesignationController.text,
                    contactController.text,
                    emailController.text,
                    widget.structureId,
                    existing != null,
                  );

                  if (!mounted) return;
                  goToGeometric();
                }
              },
              body: Form(
                key: _formKey,
                child: FormCard(
                  title: "Who is this structure for?",
                  children: [
                    FormGrid(
                      children: [
                        _field(
                          label: "Client Name",
                          controller: clientNameController,
                          validator: (val, _) =>
                              FormValidations.requiredFieldValidation(
                            val,
                            "Enter client name",
                          ),
                          icon: const Icon(Icons.person_outline),
                        ),
                        _field(
                          label: "Custodian",
                          controller: custodianController,
                          validator: (val, _) =>
                              FormValidations.requiredFieldValidation(
                            val,
                            "Enter custodian",
                          ),
                          icon: const Icon(Icons.shield_outlined),
                        ),
                        _field(
                          label: "Engineer Designation",
                          controller: engineerDesignationController,
                          validator: (val, _) =>
                              FormValidations.requiredFieldValidation(
                            val,
                            "Enter designation",
                          ),
                          icon: const Icon(Icons.engineering_outlined),
                        ),
                        _field(
                          label: "Contact",
                          controller: contactController,
                          maxLength: 10,
                          keyboardType: TextInputType.phone,
                          validator: (val, String? f) =>
                              FormValidations.phoneNoValidation(
                            contactController.text,
                            "Enter valid contact",
                          ),
                          icon: const Icon(Icons.phone_outlined),
                        ),
                        _field(
                          label: "Email",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val, String? f) =>
                              FormValidations.emailValidation(
                            emailController.text,
                            "Please enter email id",
                          ),
                          icon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
