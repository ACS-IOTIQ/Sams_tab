import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/structure_view/get_administrative_details.dart';
import 'package:sams_engineering_console/structure/structure_view/view_form_widgets.dart';

class GetLocationdetails extends StatefulWidget {
  const GetLocationdetails({super.key, required this.structureId});

  final String structureId;

  @override
  State<GetLocationdetails> createState() => _GetLocationdetailsState();
}

class _GetLocationdetailsState extends State<GetLocationdetails> {
  late GetstructureProvider getstructureProvider;

  @override
  void initState() {
    super.initState();
    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );
    getstructureProvider.fetchLocationDetails(
      structureId: widget.structureId,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewFormScaffold(
      title: 'Location Details',
      bottomBar: ViewFormBottomBar(
        primaryLabel: 'Next',
        onPrimaryTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GetAdministrativedetails(structureId: widget.structureId),
            ),
          );
        },
        secondaryLabel: 'Back',
        onSecondaryTap: () => Navigator.pop(context),
      ),
      body: Consumer<GetstructureProvider>(
        builder: (context, getStructureProvider, child) {
          final locationDetails = getStructureProvider.getLocationDetailsByStrId;
          final locationData = locationDetails?.data;

          if (locationDetails == null || locationData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ViewFormPage(
            children: [
              ViewSectionCard(
                title: 'Structure Location',
                subtitle:
                    'Read-only overview of the structure identity and mapped coordinates.',
                child: Column(
                  children: [
                    ViewInfoBanner(
                      label: 'Structural Identity',
                      value: locationData
                          .structuralIdentity
                          .structuralIdentityNumber,
                    ),
                    const SizedBox(height: 14),
                    ViewChipRow(
                      items: [
                        ViewChipData(
                          label: 'Structure Type',
                          value: _valueOrNA(
                            locationData.structuralIdentity.typeOfStructure,
                          ),
                        ),
                        ViewChipData(
                          label: 'Location Code',
                          value: _valueOrNA(locationData.location.locationCode),
                          backgroundColor: const Color(0xffECFDF3),
                          textColor: const Color(0xff027A48),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ViewDetailGrid(
                      items: [
                        ViewDetailItemData(
                          label: 'State',
                          value: _valueOrNA(locationData.location.stateCode),
                          icon: Icons.map_outlined,
                        ),
                        ViewDetailItemData(
                          label: 'Zip Code',
                          value: _valueOrNA(locationData.location.zipCode),
                          icon: Icons.pin_drop_outlined,
                        ),
                        ViewDetailItemData(
                          label: 'City / Village / Town',
                          value: _valueOrNA(locationData.location.cityName),
                          icon: Icons.location_city_outlined,
                        ),
                        ViewDetailItemData(
                          label: 'Address',
                          value: _valueOrNA(locationData.location.address),
                          icon: Icons.home_work_outlined,
                        ),
                        ViewDetailItemData(
                          label: 'Latitude',
                          value: _valueOrNA(
                            locationData.location.latitude.toString(),
                          ),
                          icon: Icons.my_location_outlined,
                        ),
                        ViewDetailItemData(
                          label: 'Longitude',
                          value: _valueOrNA(
                            locationData.location.longitude.toString(),
                          ),
                          icon: Icons.explore_outlined,
                        ),
                      ],
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
