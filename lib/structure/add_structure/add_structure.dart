// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/structure/add_structure/administrative_details.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/form_kit.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/radio_group_dropdown.dart';
import 'package:sams_engineering_console/utils/wizard_scaffold.dart';
import 'package:sams_engineering_console/models/get_locationby_strid_model.dart'
    hide Location;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddStructureScreen extends StatefulWidget {
  const AddStructureScreen({super.key, required this.structureId});

  final String structureId;

  @override
  State<AddStructureScreen> createState() => _AddStructureScreenState();
}

class _AddStructureScreenState extends State<AddStructureScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  final _formKey = GlobalKey<FormState>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(28.6139, 77.2090), // New Delhi coordinates
    zoom: 5.5, // Zoom out to show more of India initially
  );

  final LatLngBounds indiaBounds = LatLngBounds(
    southwest: LatLng(6.5546079, 68.1113787), // Approx southern-west corner
    northeast: LatLng(35.6745457, 97.395561), // Approx northern-east corner
  );

  final List<String> structureList = [
    "commercial",
    "residential",
    "industrial",
  ];

  final List<String> structureSubList = ["rcc", "steel"];

  final List<String> commercialList = [
    "only_commercial",
    "commercial_residential",
  ];

  final Map<String, String> stateCodeMap = {
    'Andhra Pradesh': 'AP',
    'Arunachal Pradesh': 'AR',
    'Assam': 'AS',
    'Bihar': 'BR',
    'Chhattisgarh': 'CG',
    'Goa': 'GA',
    'Gujarat': 'GJ',
    'Haryana': 'HR',
    'Himachal Pradesh': 'HP',
    'Jharkhand': 'JH',
    'Karnataka': 'KA',
    'Kerala': 'KL',
    'Madhya Pradesh': 'MP',
    'Maharashtra': 'MH',
    'Manipur': 'MN',
    'Meghalaya': 'ML',
    'Mizoram': 'MZ',
    'Nagaland': 'NL',
    'Odisha': 'OD',
    'Punjab': 'PB',
    'Rajasthan': 'RJ',
    'Sikkim': 'SK',
    'Tamil Nadu': 'TN',
    'Telangana': 'TS',
    'Tripura': 'TR',
    'Uttar Pradesh': 'UP',
    'Uttarakhand': 'UK',
    'West Bengal': 'WB',
    'Delhi': 'DL',
    'Jammu and Kashmir': 'JK',
    'Ladakh': 'LA',
    'Puducherry': 'PY',
  };

  late final List<String> statesList = stateCodeMap.values.toList();

  String? selectedState;
  String? selectedStructureType;
  String? selectedStructureSubType;
  String? selectedCommercialType;

  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController locationCodeController = TextEditingController();
  final TextEditingController structureNameController = TextEditingController();
  final TextEditingController structureAgeController = TextEditingController();

  late GetstructureProvider getstructureProvider;
  bool isDataLoaded = false;
  bool _isLoadingLocation = false;
  bool hasExistingData = false;
  LatLng? lastMarkerPosition;
  File? _selectedStructureImage;
  String? _existingStructureImageUrl;

  @override
  void initState() {
    super.initState();
    getstructureProvider = Provider.of<GetstructureProvider>(
      context,
      listen: false,
    );

    // Defer until after first frame so GoogleMap is mounted and _controller is completable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Set<Marker> _markers = {};
  LatLng? _pendingLatLng; // Stores coordinates to pan to once map is ready

  Future<void> _initializeData() async {
    try {
      final structureId = widget.structureId;

      // Fetch existing structure data
      await getstructureProvider.fetchLocationDetails(
        structureId: structureId,
        context: context,
      );

      final locationData = getstructureProvider.getLocationDetailsByStrId?.data;

      if (locationData != null) {
        final hasCoordinates =
            locationData.location.latitude != null &&
            locationData.location.longitude != null;
        final hasAddressData =
            locationData.location.zipCode.isNotEmpty ||
            locationData.location.address.isNotEmpty;

        if (hasCoordinates) {
          // ✅ Has complete location data with coordinates
          debugPrint("✅ Loading existing structure data WITH coordinates");
          _loadExistingData(locationData);
        } else if (hasAddressData) {
          // ⚠️ Has address but no coordinates - load data and try to geocode
          debugPrint("⚠️ Loading existing structure data WITHOUT coordinates");
          _loadExistingData(locationData);

          // Show a message to the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location coordinates not available. Please use "Locate on Map" to set the location.',
                ),
                duration: Duration(seconds: 4),
                action: SnackBarAction(label: 'OK', onPressed: () {}),
              ),
            );
          }

          // Try to geocode from the address if available
          if (addressController.text.isNotEmpty &&
              cityController.text.isNotEmpty) {
            debugPrint("Attempting to geocode from address...");
            await _moveMapToAddress();
          }
        } else {
          // ❌ No meaningful location data at all
          debugPrint("❌ No location data found, getting current location");
          await _getCurrentLocation();
        }
      } else {
        // No data from API
        debugPrint(
          "No structure data returned from API, getting current location",
        );
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint("❌ Error in initialization: $e");

      // Show error to user
      if (mounted) {
        CustomToast.showErrorToast(
          msg: "Could not load structure location. Using current location.",
        );
      }

      // Fallback to current location
      await _getCurrentLocation();
    }
  }

  void _loadExistingData(Data locationData) {
    debugPrint("Loading existing data: $locationData");

    final structuralIdentity = locationData.structuralIdentity;
    final location = locationData.location;

    setState(() {
      zipCodeController.text = location.zipCode;
      cityController.text = location.cityName;

      selectedState = statesList.contains(location.stateCode)
          ? location.stateCode
          : null;

      selectedStructureType =
          structureList.contains(structuralIdentity.typeOfStructure)
          ? structuralIdentity.typeOfStructure
          : null;

      selectedStructureSubType =
          structureSubList.contains(structuralIdentity.structureSubtype)
          ? structuralIdentity.structureSubtype
          : null;

      selectedCommercialType =
          structuralIdentity.commercialSubtype != null &&
              commercialList.contains(structuralIdentity.commercialSubtype)
          ? structuralIdentity.commercialSubtype
          : null;

      structureNameController.text = location.structureName;
      addressController.text = location.address;
      _existingStructureImageUrl = location.structureImage.isNotEmpty
          ? location.structureImage
          : null;
      structureAgeController.text = structuralIdentity.ageOfStructure
          .toString();
      latitudeController.text = location.latitude?.toString() ?? '';
      longitudeController.text = location.longitude?.toString() ?? '';

      locationCodeController.text = location.locationCode;

      isDataLoaded = true;
      hasExistingData = true;
    });

    // Add marker ONLY if coordinates exist
    if (location.latitude != null && location.longitude != null) {
      final lat = location.latitude!;
      final lng = location.longitude!;
      final position = LatLng(lat, lng);

      setState(() {
        lastMarkerPosition = position;
        _markers = {
          Marker(
            markerId: const MarkerId('existing_location'),
            position: position,
            infoWindow: InfoWindow(
              title: location.structureName,
              snippet: addressController.text,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
      });

      _moveMapToCoordinates(lat, lng);
    }

    debugPrint("Existing data loaded successfully with marker");
  }

  Future<void> _pickStructureImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _selectedStructureImage = File(result.files.single.path!);
    });
  }

  Widget _buildStructureImagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xffEEF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.domain_rounded,
        color: Appcolors.buttonColor,
        size: 26,
      ),
    );
  }

  // Add method to get current location
  Future<void> _getCurrentLocation() async {
    debugPrint("Getting current location...");
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled");
        CustomToast.showErrorToast(
          msg: "Location services are disabled. Please enable them.",
        );
        setState(() {
          _isLoadingLocation = false;
          isDataLoaded = true; // Allow user to continue manually
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied, requesting...");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied by user");
          CustomToast.showErrorToast(msg: "Location permissions are denied.");
          setState(() {
            _isLoadingLocation = false;
            isDataLoaded = true; // Allow user to continue manually
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied");
        CustomToast.showErrorToast(
          msg:
              "Location permissions are permanently denied. Please enable them in settings.",
        );
        setState(() {
          _isLoadingLocation = false;
          isDataLoaded = true; // Allow user to continue manually
        });
        return;
      }

      debugPrint("Getting current position...");
      // Get current position with timeout
      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Location request timed out after 15s'),
          );

      debugPrint(
        "Current position: ${position.latitude}, ${position.longitude}",
      );

      // Update coordinates
      setState(() {
        latitudeController.text = position.latitude.toStringAsFixed(6);
        longitudeController.text = position.longitude.toStringAsFixed(6);

        lastMarkerPosition = LatLng(position.latitude, position.longitude);
        _markers = {
          Marker(
            markerId: const MarkerId("current_location"),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: 'Current Location',
              snippet:
                  '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        };
      });

      // Move map to current location
      await _moveMapToCoordinates(position.latitude, position.longitude);

      // Get address details from coordinates
      await _getAddressFromLatLng(
        LatLng(position.latitude, position.longitude),
      );

      setState(() {
        isDataLoaded = true;
        _isLoadingLocation = false;
      });

      CustomToast.showSuccessToast(msg: "Current location loaded successfully");
    } catch (e) {
      debugPrint("Error getting current location: $e");
      String errorMessage = "Unable to get current location.";

      if (e.toString().contains('timeout') ||
          e.toString().contains('TIMEOUT')) {
        errorMessage = "Location request timed out. Please try again.";
      } else if (e.toString().contains('network') ||
          e.toString().contains('NETWORK')) {
        errorMessage = "Network error while getting location.";
      }

      CustomToast.showErrorToast(msg: errorMessage);

      setState(() {
        _isLoadingLocation = false;
        isDataLoaded = true; // Allow user to continue without location
      });
    }
  }

  // Helper method to move map to specific coordinates
  Future<void> _moveMapToCoordinates(double latitude, double longitude) async {
    _pendingLatLng = LatLng(latitude, longitude);
    try {
      if (!_controller.isCompleted) {
        debugPrint(
          "Map controller not ready yet — coordinates saved, will apply on map creation",
        );
        return;
      }
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 17.0),
      );
      _pendingLatLng = null;
      debugPrint("Map moved to coordinates: $latitude, $longitude");
    } catch (e) {
      debugPrint("Error moving map to coordinates: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    zipCodeController.clear();
    cityController.clear();
    addressController.clear();
    longitudeController.clear();
    latitudeController.clear();
    locationCodeController.clear();
  }

  void _goToAdministrative() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdministrativeGeometricdetails(
          structureId: widget.structureId,
          selectedCommercialType: selectedCommercialType ?? "",
          selectedStructureType: selectedStructureType ?? "",
          selectedStructureSubType: selectedStructureSubType ?? "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AddstructureProvider, GetstructureProvider>(
      builder: (context, addStructureProvider, getStructureProvider, child) {
        final strNumber = getStructureProvider.getLocationDetailsByStrId?.data
                .structuralIdentity.structuralIdentityNumber ??
            widget.structureId;

        return WizardScaffold(
          title: "Location Details",
          subtitle: "Step 1 of 4 · STR $strNumber",
          appBarActions: [
            if (hasExistingData) WizardSkipButton(onTap: _goToAdministrative),
          ],
          onNext: () async {
            if (!(_formKey.currentState?.validate() ?? false)) {
              CustomToast.showErrorToast(
                msg: "Please complete the highlighted fields.",
              );
              return;
            }

            // `getLocationDetailsByStrId.data` is non-null even for a structure
            // that has no location saved yet, so testing it sent a PUT for the
            // very first save and the server rejected it. `hasExistingData` is
            // set only when a record was actually loaded, which is the real
            // create-vs-update signal.
            final isUpdate = hasExistingData;

            final saved = await addStructureProvider.submitLocationData(
              context,
              selectedState!,
              zipCodeController.text,
              cityController.text,
              selectedStructureType!,
              latitudeController.text,
              longitudeController.text,
              addressController.text,
              isUpdate,
              widget.structureId,
              structureNameController.text,
              selectedStructureSubType!,
              selectedCommercialType ?? "only_commercial",
              structureAgeController.text.toString(),
              _selectedStructureImage,
            );

            if (!mounted || !saved) return;

            _goToAdministrative();
            await getstructureProvider.getStructures(context);
          },
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAddressCard(),
                const SizedBox(height: 12),
                _buildMapCard(),
                const SizedBox(height: 12),
                _buildStructureCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Address ────────────────────────────────────────────────────────────────
  Widget _buildAddressCard() {
    return FormCard(
      title: "Address",
      trailing: IconButton(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        tooltip: 'Use my current location',
        icon: Icon(
          Icons.my_location_rounded,
          size: 20,
          color: _isLoadingLocation ? FormKit.hintColor : Appcolors.buttonColor,
        ),
      ),
      children: [
        FormGrid(
          children: [
            LabeledField(
              label: "State",
              isRequired: true,
              child: RadioGroupDropdown<String>(
                options: radioOptionsFromStrings(statesList),
                value: selectedState,
                hintText: "Select state",
                sheetTitle: "Select state",
                validator: (value) =>
                    value == null ? "Please select a state" : null,
                onChanged: (value) => setState(() => selectedState = value),
              ),
            ),
            LabeledField(
              label: "Zip code",
              isRequired: true,
              child: FormTextField(
                controller: zipCodeController,
                hintText: "Enter zip code",
                keyboardType: TextInputType.number,
                validator: (val, String? f) =>
                    FormValidations.requiredFieldValidation(
                  val,
                  "Please enter zip code",
                ),
              ),
            ),
            LabeledField(
              label: "City / Village / Town",
              isRequired: true,
              child: FormTextField(
                controller: cityController,
                hintText: "Enter city, village or town",
                validator: (val, String? f) =>
                    FormValidations.requiredFieldValidation(
                  val,
                  "Please enter City/village/Town",
                ),
              ),
            ),
            LabeledField(
              label: "Address",
              child: FormTextField(
                controller: addressController,
                hintText: "Enter address",
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Map + coordinates ──────────────────────────────────────────────────────
  Widget _buildMapCard() {
    return FormCard(
      title: "Pin the location",
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                GoogleMap(
                  cameraTargetBounds: CameraTargetBounds(indiaBounds),
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  markers: _markers,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    // Apply any coordinates that were ready before the map was built
                    if (_pendingLatLng != null) {
                      final pending = _pendingLatLng!;
                      _pendingLatLng = null;
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(pending, 17.0),
                      );
                    }
                  },
                  onTap: (LatLng position) {
                    setState(() {
                      latitudeController.text =
                          position.latitude.toStringAsFixed(6);
                      longitudeController.text =
                          position.longitude.toStringAsFixed(6);

                      lastMarkerPosition = position;
                      _markers = {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: position,
                          infoWindow: InfoWindow(
                            title: 'Selected Location',
                            snippet:
                                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      };
                    });

                    _getAddressFromLatLng(position);
                  },
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _MapChipButton(
                    icon: Icons.my_location_rounded,
                    label: 'My location',
                    isBusy: _isLoadingLocation,
                    onTap: _isLoadingLocation ? null : _getCurrentLocation,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: _MapChipButton(
                    icon: Icons.travel_explore_rounded,
                    label: 'Locate address',
                    onTap: _moveMapToAddress,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FormKit.rowGap),
        FormGrid(
          columns: 3,
          minItemWidth: 170,
          children: [
            LabeledField(
              label: "Latitude",
              isRequired: true,
              child: FormTextField(
                controller: latitudeController,
                hintText: "Latitude",
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val, String? f) =>
                    FormValidations.requiredFieldValidation(
                  val,
                  "Please enter latitude code",
                ),
              ),
            ),
            LabeledField(
              label: "Longitude",
              isRequired: true,
              child: FormTextField(
                controller: longitudeController,
                hintText: "Longitude",
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val, String? f) =>
                    FormValidations.requiredFieldValidation(
                  val,
                  "Please enter longitude code",
                ),
              ),
            ),
            LabeledField(
              label: "Age of structure (Yrs)",
              isRequired: true,
              child: FormTextField(
                controller: structureAgeController,
                hintText: "Enter age",
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val, String? f) =>
                    FormValidations.requiredFieldValidation(
                  val,
                  "Please enter structure age",
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Structure identity ─────────────────────────────────────────────────────
  Widget _buildStructureCard() {
    final isCommercial = selectedStructureType == "commercial";

    return FormCard(
      title: "Structure",
      children: [
        _buildImagePicker(),
        const SizedBox(height: FormKit.rowGap),
        FormGrid(
          children: [
            LabeledField(
              label: "Structure name",
              child: FormTextField(
                controller: structureNameController,
                hintText: "Enter structure name",
              ),
            ),
            LabeledField(
              label: "Structure type",
              isRequired: true,
              child: RadioGroupDropdown<String>(
                options: radioOptionsFromStrings(
                  structureList,
                  labelBuilder: prettifyOptionLabel,
                ),
                value: selectedStructureType,
                hintText: "Select structure type",
                sheetTitle: "Structure type",
                validator: (value) =>
                    value == null ? "Please select a structure type" : null,
                onChanged: (value) => setState(() {
                  selectedStructureType = value;
                  // Commercial subtype only applies to commercial structures —
                  // drop a stale selection so it can't be submitted.
                  if (value != "commercial") selectedCommercialType = null;
                }),
              ),
            ),
            LabeledField(
              label: "Structure sub-type",
              isRequired: true,
              child: RadioGroupDropdown<String>(
                options: radioOptionsFromStrings(
                  structureSubList,
                  labelBuilder: (v) => v.toUpperCase(),
                ),
                value: selectedStructureSubType,
                hintText: "Select sub-type",
                sheetTitle: "Structure sub-type",
                validator: (value) =>
                    value == null ? "Please select a sub-type" : null,
                onChanged: (value) =>
                    setState(() => selectedStructureSubType = value),
              ),
            ),
            if (isCommercial)
              LabeledField(
                label: "Commercial structure type",
                isRequired: true,
                child: RadioGroupDropdown<String>(
                  options: radioOptionsFromStrings(
                    commercialList,
                    labelBuilder: prettifyOptionLabel,
                  ),
                  value: selectedCommercialType,
                  hintText: "Select commercial type",
                  sheetTitle: "Commercial structure type",
                  validator: (value) => value == null
                      ? "Please select commercial structure type"
                      : null,
                  onChanged: (value) =>
                      setState(() => selectedCommercialType = value),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasNewImage = _selectedStructureImage != null;
    final hasExistingImage = _existingStructureImageUrl != null &&
        _existingStructureImageUrl!.isNotEmpty;

    return LabeledField(
      label: "Structure image",
      child: InkWell(
        onTap: _pickStructureImage,
        borderRadius: BorderRadius.circular(FormKit.radius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FormKit.fillColor,
            borderRadius: BorderRadius.circular(FormKit.radius),
            border: Border.all(color: FormKit.borderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasNewImage
                    ? Image.file(
                        _selectedStructureImage!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : hasExistingImage
                        ? Image.network(
                            _existingStructureImageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildStructureImagePlaceholder(),
                          )
                        : _buildStructureImagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNewImage
                          ? 'Image selected'
                          : hasExistingImage
                              ? 'Current image'
                              : 'Upload structure thumbnail',
                      style: w600_13Poppins(color: FormKit.labelColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasNewImage
                          ? _selectedStructureImage!.path
                              .split(Platform.pathSeparator)
                              .last
                          : 'Tap to choose an image for the structure card',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: w400_12Poppins(color: FormKit.hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.photo_camera_back_outlined,
                size: 20,
                color: Appcolors.buttonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modified reverse geocoding that preserves user address when needed
  Future<void> _getAddressFromLatLngPreserved(
    LatLng position,
    String? preserveAddress,
  ) async {
    debugPrint("== START REVERSE GEOCODING ==");
    debugPrint(
      "Coordinates received: ${position.latitude}, ${position.longitude}",
    );

    // Additional checks
    if (position.latitude < 10 ||
        position.latitude > 40 ||
        position.longitude < 60 ||
        position.longitude > 100) {
      debugPrint("Coordinates out of expected range for India.");
      CustomToast.showErrorToast(
        msg: "Location coordinates are not within India. Please try again.",
      );
      return;
    }

    try {
      debugPrint(
        "Reverse geocoding for: ${position.latitude}, ${position.longitude}",
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'en_IN',
      );

      debugPrint("Found ${placemarks.length} placemarks");

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        debugPrint("Placemark details: ${place.toString()}");

        // Check if the location is in India
        if (place.country != null && place.country!.toLowerCase() == 'india') {
          String? adminArea = place.administrativeArea ?? '';
          String normalizedAdminArea = adminArea.toLowerCase().trim();

          debugPrint("Administrative area: $adminArea");

          String? matchedStateName = stateCodeMap.keys.firstWhere(
            (state) => state.toLowerCase().trim() == normalizedAdminArea,
            orElse: () => '',
          );

          String? matchedStateCode = stateCodeMap[matchedStateName];

          debugPrint("Matched state: $matchedStateName -> $matchedStateCode");

          if (matchedStateName.isEmpty) {
            debugPrint(
              "Could not match '$adminArea' to any state in the list.",
            );
          }

          setState(() {
            selectedState = matchedStateCode;
            zipCodeController.text = place.postalCode ?? '';
            cityController.text =
                place.locality ?? place.subAdministrativeArea ?? '';

            // Only update address if we're not preserving user input
            if (preserveAddress == null) {
              String newAddress = "";
              if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                newAddress += place.subLocality!;
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                if (newAddress.isNotEmpty) newAddress += ", ";
                newAddress += place.locality!;
              }
              addressController.text = newAddress;
            } else {
              addressController.text = preserveAddress;
            }
          });

          debugPrint("Address fields updated successfully");
        } else {
          debugPrint("Location is outside India: ${place.country}");
          // Location outside India
          setState(() {
            selectedState = null;
            zipCodeController.text = '';
            cityController.text = '';
            if (preserveAddress == null) {
              addressController.text = '';
            }
          });
        }
      } else {
        debugPrint("No placemarks found for the given coordinates");
      }
    } catch (e) {
      debugPrint("Error in reverse geocoding: $e");
      CustomToast.showErrorToast(
        msg: "Unable to get address details for this location.",
      );
    }
  }

  // Update the original _getAddressFromLatLng to use the new method
  Future<void> _getAddressFromLatLng(LatLng position) async {
    await _getAddressFromLatLngPreserved(position, null);
  }

  Future<void> _moveMapToAddress() async {
    // Store the current address before geocoding
    String userEnteredAddress = addressController.text;

    String fullAddress =
        "${addressController.text}, ${cityController.text}, ${selectedState ?? ''}, ${zipCodeController.text}, India";

    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      debugPrint(
        'Geocode found: ${locations.first.latitude}, ${locations.first.longitude}',
      );

      if (locations.isNotEmpty) {
        final Location loc = locations.first;
        final controller = await _controller.future;

        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 17.0),
        );

        // Update lat/lng coordinates but preserve the user's address
        setState(() {
          latitudeController.text = loc.latitude.toStringAsFixed(6);
          longitudeController.text = loc.longitude.toStringAsFixed(6);
          // Keep the user's original address input
          addressController.text = userEnteredAddress;

          // Add marker for the searched location
          lastMarkerPosition = LatLng(loc.latitude, loc.longitude);
          _markers = {
            Marker(
              markerId: const MarkerId('searched_location'),
              position: LatLng(loc.latitude, loc.longitude),
              infoWindow: InfoWindow(
                title: 'Searched Location',
                snippet: userEnteredAddress,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          };
        });

        debugPrint('Map moved to user-specified location: $userEnteredAddress');
      }
    } catch (e) {
      debugPrint("Error moving map to address: $e");
      CustomToast.showErrorToast(
        msg: "Unable to locate address. Please check input.",
      );
    }
  }
}
/// Compact pill button overlaid on the map. Sized in raw doubles so it stays a
/// thumb-sized control on tablets rather than scaling up with ScreenUtil.
class _MapChipButton extends StatelessWidget {
  const _MapChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isBusy;
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  size: 15,
                  color: enabled ? Appcolors.buttonColor : FormKit.hintColor,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: w600_12Poppins(
                  color: enabled ? Appcolors.buttonColor : FormKit.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
