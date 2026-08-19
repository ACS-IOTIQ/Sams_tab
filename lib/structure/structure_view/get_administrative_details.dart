import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/structure_view/get_geometric_details.dart';
import 'package:sams_engineering_console/structure/structure_view/view_form_widgets.dart';

class GetAdministrativedetails extends StatefulWidget {
  const GetAdministrativedetails({super.key, required this.structureId});

  final String structureId;

  @override
  State<GetAdministrativedetails> createState() =>
      _GetAdministrativedetailsState();
}

class _GetAdministrativedetailsState extends State<GetAdministrativedetails> {
  late GetstructureProvider getstructureProvider;

  @override
  void initState() {
    super.initState();
    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );
    getstructureProvider.getAdministrativeDetailsByStructureId(
      structureId: widget.structureId,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewFormScaffold(
      title: 'Administrative Details',
      bottomBar: ViewFormBottomBar(
        primaryLabel: 'Next',
        onPrimaryTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GetGeometricdetails(structureId: widget.structureId),
            ),
          );
        },
        secondaryLabel: 'Back',
        onSecondaryTap: () => Navigator.pop(context),
      ),
      body: Consumer<GetstructureProvider>(
        builder: (context, getStructureProvider, child) {
          final adminData = getStructureProvider
              .getAdminstrativeDetailsByStrIdModel
              ?.data
              ?.administration;

          if (adminData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ViewFormPage(
            children: [
              ViewSectionCard(
                title: 'Client & Ownership',
                subtitle:
                    'Administrative contacts and project ownership data for this structure.',
                child: ViewDetailGrid(
                  items: [
                    ViewDetailItemData(
                      label: 'Client Name',
                      value: _valueOrNA(adminData.clientName),
                      icon: Icons.business_outlined,
                    ),
                    ViewDetailItemData(
                      label: 'Custodian',
                      value: _valueOrNA(adminData.custodian),
                      icon: Icons.badge_outlined,
                    ),
                    ViewDetailItemData(
                      label: 'Engineer Designation',
                      value: _valueOrNA(adminData.engineerDesignation),
                      icon: Icons.engineering_outlined,
                    ),
                    ViewDetailItemData(
                      label: 'Contact Details',
                      value: _valueOrNA(adminData.contactDetails),
                      icon: Icons.phone_outlined,
                    ),
                    ViewDetailItemData(
                      label: 'Email ID',
                      value: _valueOrNA(adminData.emailId),
                      icon: Icons.mail_outline_rounded,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _valueOrNA(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'N/A' : trimmed;
}
