import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/provider/token_http_client.dart';
import 'package:sams_engineering_console/structure/add_structure/add_structure.dart';
import 'package:sams_engineering_console/ui/home_screen.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class AddstructureProvider extends ChangeNotifier {
  static const String baseUrl = 'https://sams.acstechnologies.co.in';

  late String structureIdInit = '';

  Future<void> initializeStructure(BuildContext context) async {
    const url = '$baseUrl/api/structures/initialize';
 
    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    final requestBody = {};

    try {
      final response = await TokenAwareHttpClient.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final id = data['data']['structure_id'];
        structureIdInit = id; // âœ… Save the ID internally

        CustomToast.showSuccessToast(msg: "Structure id created successfully.");
        notifyListeners();
        print('Initialization successful: Structure ID = $id');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddStructureScreen(structureId: id!),
          ),
        );
      } else {
        print('Failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> submitStructure(BuildContext context, String structureId) async {
    final url = '$baseUrl/api/structures/$structureId/submit-for-testing';

    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    const requestBody = <String, dynamic>{};

    try {
      final response = await TokenAwareHttpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final id = data['data']['structure_id'];
        structureIdInit = id; // âœ… Save the ID internally

        if (!context.mounted) return;

        // Return to the app shell instead of rendering StructureList as a
        // standalone route.  HomeScreen loads a persisted role when needed;
        // forcing a nullable role here could throw and leave a blank screen.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        notifyListeners();
        print('Initialization successful: Structure ID = $id');
      } else {
        print('Failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> submitAdministrativeData(
    BuildContext context,
    String clientName,
    String custodian,
    String engineerDesignation,
    String contactDetails,
    String email,
    String structureId,
    bool isUpdate,
  ) async {
    final url = isUpdate
        ? Uri.parse('$baseUrl/api/structures/$structureId/administrative')
        : Uri.parse('$baseUrl/api/structures/$structureId/administrative');

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    try {
      final requestBody = {
        "client_name": clientName,
        "custodian": custodian,
        "engineer_designation": engineerDesignation,
        "contact_details": contactDetails,
        "email_id": email,
      };

      print("ðŸ“§ Admin API URL: $url");
      print("ðŸ“ Request Body: $requestBody");
      print("ðŸ“¦ Method: ${isUpdate ? "PUT" : "POST"}");

      final response = await (isUpdate
          ? TokenAwareHttpClient.put(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
          : TokenAwareHttpClient.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            ));

      print("ðŸ“¬ Status Code: ${response.statusCode}");
      print("ðŸ“¬ Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('âœ… Administrative data submitted successfully');
        isUpdate
            ? CustomToast.showSuccessToast(
                msg: "Administrative details saved succesfully",
              )
            : CustomToast.showSuccessToast(
                msg: "Administrative details added succesfully",
              );
      } else {
        throw Exception('Failed to submit administrative data');
      }
    } catch (e) {
      print("âŒ Error in admin submission: $e");
      rethrow;
    }
  }

  Future<void> submitLocationData(
    BuildContext context,
    String state,
    String zipcode,
    String cityName,
    String structureType,
    dynamic latitude,
    dynamic longitude,
    String address,
    bool isUpdate,
    String structureId,
    String structureName,
    String structureSubtype,
    String commercialSubtype,
    dynamic structureAge,
    File? structureImage,
  ) async {
    final url = '$baseUrl/api/structures/$structureId/location';

    final requestBody = {
      "state_code": state,
      "district_code": "01",
      "zip_code": zipcode,
      "city_name": cityName,
      "location_code": "AP",
      "type_of_structure": structureType,
      "longitude": longitude,
      "latitude": latitude,
      "address": address,
      "structure_name": structureName,
      "structure_subtype": structureSubtype,
      "commercial_subtype": commercialSubtype,
      "age_of_structure": structureAge,
    };

    double? lat = double.tryParse(latitude.toString());
    double? lon = double.tryParse(longitude.toString());

    if (lat == null || lon == null) {
      print('Invalid latitude or longitude');
      return;
    }

    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    try {
      final uri = Uri.parse(url);
      http.Response response;

      if (structureImage != null) {
        final request = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', uri);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields.addAll(
          requestBody.map((key, value) => MapEntry(key, value.toString())),
        );
        request.files.add(
          await http.MultipartFile.fromPath('photo', structureImage.path),
        );

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await (isUpdate
            ? TokenAwareHttpClient.put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(requestBody),
              )
            : TokenAwareHttpClient.post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(requestBody),
              ));
      }

      print("Location data: $requestBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Success: ${response.body}');
        isUpdate
            ? CustomToast.showSuccessToast(
                msg: "Location details saved succesfully",
              )
            : CustomToast.showSuccessToast(
                msg: "Location details added succesfully",
              );
      } else {
        print('Failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> submitGeometricData(
    BuildContext context,
    dynamic totalFLoors,
    dynamic structureWidth,
    dynamic structureLength,
    dynamic structureHeight,
    bool isUpdate,
    String structureId,
  ) async {
    final url = '$baseUrl/api/structures/$structureId/geometric-details';
    final uri = Uri.parse(url);

    final requestBody = {
      "number_of_floors": totalFLoors,
      "structure_width": structureWidth,
      "structure_length": structureLength,
      "structure_height": structureHeight,
    };

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    try {
      final response = await (isUpdate
          ? TokenAwareHttpClient.put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            )
          : TokenAwareHttpClient.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Geometric data submission successful: ${response.body}');
        isUpdate
            ? CustomToast.showSuccessToast(
                msg: "Geometric details saved succesfully",
              )
            : CustomToast.showSuccessToast(
                msg: "Geometric details added succesfully",
              );
      } else {
        print('Failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String floorId = '';
  String flatId = '';

  /// Call this function with your auth token and raw floor data
  // FIXED addGeometricDataFloors method in addStructure_provider.dart

  Future<Map<String, dynamic>?> addGeometricDataFloors({
    required BuildContext context,
    required List<Map<String, dynamic>> rawFloors,
    required bool isUpdate,
    required String structureId,
  }) async {
    final url = Uri.parse('$baseUrl/api/structures/$structureId/floors');

    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    // ✅ 1. Enhanced data validation and processing
    final validFloors = rawFloors
        .where((f) {
          bool isValid = true;

          // Check floor_number
          if (f['floor_number'] == null ||
              f['floor_number'].toString().trim().isEmpty) {
            print('❌ Invalid floor_number: ${f['floor_number']}');
            isValid = false;
          }

          // Check parking_floor_type only if it's a parking floor
          if (f['is_parking_floor'] == true) {
            if (f['parking_floor_type'] == null ||
                f['parking_floor_type'].toString().trim().isEmpty) {
              print('❌ Invalid parking_floor_type: ${f['parking_floor_type']}');
              isValid = false;
            }
          }

          // Check floor_height (should be a number)
          if (f['floor_height'] == null) {
            print('❌ Invalid floor_height: ${f['floor_height']}');
            isValid = false;
          }

          // Check total_area_sq_mts (should be a number)
          if (f['total_area_sq_mts'] == null) {
            print('❌ Invalid total_area_sq_mts: ${f['total_area_sq_mts']}');
            isValid = false;
          }

          // Check floor_label_name
          if (f['floor_label_name'] == null ||
              f['floor_label_name'].toString().trim().isEmpty) {
            print('❌ Invalid floor_label_name: ${f['floor_label_name']}');
            isValid = false;
          }

          if (isValid) {
            print('✅ Valid floor: ${f['floor_number']}');
          }

          return isValid;
        })
        .map((f) {
          // Helper function to safely parse number_of_flats
          int parseNumberOfFlats(dynamic value) {
            if (value == null) return 0;
            if (value is int) return value;
            if (value is String) {
              if (value.trim().isEmpty) return 0;
              return int.tryParse(value.trim()) ?? 0;
            }
            return 0;
          }

          // Base floor data
          Map<String, dynamic> floorData = {
            "floor_number": f['floor_number'].toString(),
            "floor_height": f['floor_height'],
            "total_area_sq_mts": f['total_area_sq_mts'],
            "floor_label_name": f['floor_label_name'].toString(),
            "number_of_flats": parseNumberOfFlats(f['number_of_flats']),
            "floor_notes": f['floor_notes']?.toString() ?? "",
            "is_parking_floor": f['is_parking_floor'] ?? false,
          };

          // Add parking_floor_type only if it's a parking floor
          if (f['is_parking_floor'] == true &&
              f['parking_floor_type'] != null) {
            floorData["parking_floor_type"] = f['parking_floor_type']
                .toString();
          }

          return floorData;
        })
        .toList();

    if (validFloors.isEmpty) {
      print('❌ No valid floors to submit');
      CustomToast.showErrorToast(msg: "No valid floors to submit");
      return {'success': false, 'message': 'No valid floors to submit'};
    }

    final body = {"floors": validFloors};

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // ✅ 2. Add detailed logging
    print('🚀 Submitting floors to API');
    print('🔗 URL: $url');
    print('📦 Method: ${isUpdate ? "PUT" : "POST"}');
    print('📋 Headers: $headers');
    print('📄 Body: ${jsonEncode(body)}');
    print('🔢 Valid floors count: ${validFloors.length}');

    try {
      // ✅ 3. Use TokenAwareHttpClient for consistency
      final response = await TokenAwareHttpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📬 Response Status: ${response.statusCode}');
      print('📬 Response Body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ 4. Enhanced success handling
        if (data['data'] != null && data['data']['floors'] != null) {
          final floors = data['data']['floors'] as List<dynamic>;
          if (floors.isNotEmpty) {
            floorId = floors[0]['floor_id'];
            print("✅ Floor ID saved: $floorId");
          }
        }

        CustomToast.showSuccessToast(msg: "Floors added successfully");

        return {
          'success': true,
          'data': data['data'],
          'message': 'Floors added successfully',
        };
      } else {
        // ✅ 5. Enhanced error handling
        String errorMessage = data['message'] ?? 'Unknown error occurred';
        if (data['errors'] != null &&
            data['errors'] is List &&
            data['errors'].isNotEmpty) {
          errorMessage = data['errors'][0]['message'] ?? errorMessage;
        }
        print('❌ API Error: $errorMessage');

        CustomToast.showErrorToast(msg: "Failed to add floors: $errorMessage");

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('⚠️ Exception while posting floors: $e');

      // ✅ 6. Better exception handling
      String errorMessage = 'Network error occurred';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response format';
      }

      CustomToast.showErrorToast(msg: errorMessage);

      return {
        'success': false,
        'message': errorMessage,
        'exception': e.toString(),
      };
    }
  }

  Future<bool> deleteStructure(String structureId, BuildContext context) async {
    final url = Uri.parse('$baseUrl/api/structures/$structureId');
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final response = await TokenAwareHttpClient.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print("Structure deleted successfully");
      print("Response body: ${response.body}");

      try {
        if (response.body.isNotEmpty) {
          jsonDecode(response.body);
        }
      } catch (e) {
        print("Error decoding response body: $e");
      }

      CustomToast.showSuccessToast(msg: "Structure deleted successfully");

      Future.delayed(const Duration(milliseconds: 150), () {
        if (context.mounted) {
          Provider.of<GetstructureProvider>(
            context,
            listen: false,
          ).getStructures(context, page: 1);
        }
      });

      return true;
    } else {
      print(
        'Failed to delete structure: ${response.statusCode} - ${response.body}',
      );
      try {
        final data = jsonDecode(response.body);
        CustomToast.showErrorToast(msg: "${data['message']}");
      } catch (e) {
        CustomToast.showErrorToast(msg: "An unexpected error occurred.");
      }
      return false;
    }
  }

  Future<http.Response> putFloorDetails({
    required String structureId,
    required String floorId,
    required int floorNumber,
    required String floorType,
    required double floorHeight,
    required double totalAreaSqMts,
    required String floorLabelName,
    required int numberOfFlats,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId',
    );

    final Map<String, dynamic> requestBody = {
      "floor_number": floorNumber,
      "floor_type": floorType,
      "floor_height": floorHeight,
      "total_area_sq_mts": totalAreaSqMts,
      "floor_label_name": floorLabelName,
      "number_of_flats": numberOfFlats,
      "floor_notes": "Well-ventilated with balcony",
    };

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          // Add authorization token if needed:
          // "Authorization": "Bearer YOUR_TOKEN"
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Floor details updated successfully.');
      } else {
        print('Failed to update floor. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return response;
    } catch (e) {
      print('Error occurred while updating floor: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addGeometricFlatsByFloors({
    required BuildContext context,
    required String floorId,
    required List<Map<String, dynamic>> rawFlats,
    required bool isUpdate,
    required String structureId,
  }) async {
    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    // ALWAYS check which flats actually exist, regardless of isUpdate flag
    Set<String> existingFlatNumbers = {};
    Map<String, String> flatNumberToIdMap = {}; // Map flat numbers to their IDs

    try {
      // Get existing flats for this floor
      final checkUrl = Uri.parse(
        '$baseUrl/api/structures/$structureId/floors/$floorId/flats',
      );
      final checkResponse = await TokenAwareHttpClient.get(
        checkUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      print(
        "ðŸ” Checking existing flats - Status: ${checkResponse.statusCode}",
      );

      if (checkResponse.statusCode == 200) {
        final checkData =
            jsonDecode(checkResponse.body) as Map<String, dynamic>;
        final existingFlats =
            checkData['data']['flats'] as List<dynamic>? ?? [];

        for (var flat in existingFlats) {
          final flatNumber = flat['flat_number']?.toString() ?? '';
          final flatId =
              flat['flat_id']?.toString() ?? flat['id']?.toString() ?? '';
          if (flatNumber.isNotEmpty && flatId.isNotEmpty) {
            existingFlatNumbers.add(flatNumber);
            flatNumberToIdMap[flatNumber] = flatId;
          }
        }

        print(
          'ðŸ” Found ${existingFlatNumbers.length} existing flats: $existingFlatNumbers',
        );
      } else {
        print(
          'âš ï¸ No existing flats found or error checking (${checkResponse.statusCode})',
        );
      }
    } catch (e) {
      print('âš ï¸ Could not check existing flats: $e');
      // Clear the sets if we can't check
      existingFlatNumbers.clear();
      flatNumberToIdMap.clear();
    }

    // Validate and clean the flats data
    final validFlats = <Map<String, dynamic>>[];
    final seenFlatNumbers = <String>{};

    for (var flat in rawFlats) {
      final flatNumber = flat['flat_number']?.toString().trim() ?? '';
      if (flatNumber.isEmpty) {
        print('âš ï¸ Skipping flat with empty number');
        continue;
      }

      if (seenFlatNumbers.contains(flatNumber)) {
        print('âš ï¸ Skipping duplicate flat number in batch: $flatNumber');
        continue;
      }

      // Validate required fields
      if (flat['flat_type']?.toString().trim().isEmpty ?? true) {
        print('âš ï¸ Skipping flat $flatNumber - missing flat type');
        continue;
      }

      final area = flat['area_sq_mts'];
      if (area == null || (area is num && area <= 0)) {
        print('âš ï¸ Skipping flat $flatNumber - invalid area: $area');
        continue;
      }

      seenFlatNumbers.add(flatNumber);
      validFlats.add({
        "flat_number": flatNumber,
        "flat_type": flat['flat_type'].toString().trim(),
        "area_sq_mts": area,
        "direction_facing": flat['direction_facing']?.toString().trim() ?? "",
        "occupancy_status": flat['occupancy_status']?.toString().trim() ?? "",
        "flat_notes": flat['flat_notes']?.toString() ?? "",
      });
    }

    if (validFlats.isEmpty) {
      print('âš ï¸ No valid flats to process');
      return {
        'success': false,
        'message': 'No valid flats to process',
        'data': null,
      };
    }

    // Determine method based on whether ANY flats exist (not just isUpdate flag)
    bool shouldUsePUT = existingFlatNumbers.isNotEmpty;

    // NEW: If some flats exist and some don't, we need to handle both
    List<Map<String, dynamic>> flatsToUpdate = [];
    List<Map<String, dynamic>> flatsToCreate = [];

    if (shouldUsePUT) {
      for (var flat in validFlats) {
        final flatNumber = flat['flat_number'] as String;
        if (existingFlatNumbers.contains(flatNumber)) {
          flatsToUpdate.add(flat);
        } else {
          flatsToCreate.add(flat);
        }
      }
    } else {
      // If no existing flats or not in update mode, create all
      flatsToCreate.addAll(validFlats);
    }

    Map<String, dynamic> finalResponse = {
      'success': true,
      'data': {'flats': []},
      'message': 'Flats processed successfully',
    };

    try {
      // Handle updates (PUT) if any - INDIVIDUAL PUT REQUESTS FOR EACH FLAT
      if (flatsToUpdate.isNotEmpty) {
        print(
          "ðŸ”§ Updating ${flatsToUpdate.length} flats with individual PUT requests",
        );

        for (var flat in flatsToUpdate) {
          final flatNumber = flat['flat_number'] as String;
          final flatId = flatNumberToIdMap[flatNumber];

          if (flatId == null) {
            print('âš ï¸ No ID found for flat $flatNumber, skipping update');
            continue;
          }

          // NEW: Individual PUT endpoint with flatId
          final putUrl = Uri.parse(
            '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId',
          );

          final updateBody =
              flat; // Single flat data, not wrapped in "flats" array
          print("ðŸ” PUT Request to: $putUrl");
          print("ðŸ” PUT Request Body: $updateBody");

          final putResponse = await TokenAwareHttpClient.put(
            putUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updateBody),
          );

          print("ðŸ“¬ PUT Status Code: ${putResponse.statusCode}");
          print("ðŸ“¬ PUT Response Body: ${putResponse.body}");

          if (putResponse.statusCode == 200) {
            final putData =
                jsonDecode(putResponse.body) as Map<String, dynamic>;
            // Assuming the response contains the updated flat data
            if (putData['data'] != null) {
              finalResponse['data']['flats'].add(putData['data']);
            }
            print('âœ… Updated flat $flatNumber successfully');
          } else {
            final error = jsonDecode(putResponse.body) as Map<String, dynamic>;
            print('âŒ PUT failed for flat $flatNumber: ${error['message']}');
            // Continue with other flats
          }
        }
      }

      // Handle creates (POST) if any - BATCH POST REQUEST
      if (flatsToCreate.isNotEmpty) {
        // NEW: POST endpoint ends with /flats (collection endpoint)
        final postUrl = Uri.parse(
          '$baseUrl/api/structures/$structureId/floors/$floorId/flats',
        );

        final createBody = {"flats": flatsToCreate}; // Wrapped in "flats" array
        print("ðŸ”§ Creating ${flatsToCreate.length} flats with POST");
        print("ðŸ” POST Request to: $postUrl");
        print("ðŸ” POST Request Body: $createBody");

        final postResponse = await TokenAwareHttpClient.post(
          postUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(createBody),
        );

        print("ðŸ“¬ POST Status Code: ${postResponse.statusCode}");
        print("ðŸ“¬ POST Response Body: ${postResponse.body}");

        if (postResponse.statusCode == 201 || postResponse.statusCode == 200) {
          final postData =
              jsonDecode(postResponse.body) as Map<String, dynamic>;
          final createdFlats = postData['data']['flats'] as List<dynamic>;
          finalResponse['data']['flats'].addAll(createdFlats);
          print('âœ… Created ${createdFlats.length} flats successfully');
        } else if (postResponse.statusCode == 409) {
          // Some flats already exist - this is OK
          final postData =
              jsonDecode(postResponse.body) as Map<String, dynamic>;
          if (postData['data'] != null && postData['data']['flats'] != null) {
            final existingFlats = postData['data']['flats'] as List<dynamic>;
            finalResponse['data']['flats'].addAll(existingFlats);
          }
          print('âš ï¸ Some flats already exist (409 Conflict) - continuing');
        } else {
          final error = jsonDecode(postResponse.body) as Map<String, dynamic>;
          print('âŒ POST failed: ${error['message']}');

          // If we had successful updates but failed creates, still return partial success
          if (flatsToUpdate.isNotEmpty &&
              finalResponse['data']['flats'].isNotEmpty) {
            finalResponse['message'] =
                'Some flats updated successfully, but failed to create new flats';
            CustomToast.showWarningToast(msg: finalResponse['message']);
          } else {
            return {
              'success': false,
              'message': error['message'] ?? 'Failed to create flats',
              'statusCode': postResponse.statusCode,
              'data': null,
            };
          }
        }
      }

      // Show success message
      final totalProcessed = (finalResponse['data']['flats'] as List).length;
      if (totalProcessed > 0) {
        CustomToast.showSuccessToast(msg: "Flats created/updated succesfully");
        return finalResponse;
      } else {
        return {
          'success': false,
          'message': 'No flats were processed successfully',
          'data': null,
        };
      }
    } catch (e) {
      print("âŒ Error in flats submission: $e");
      CustomToast.showErrorToast(msg: "Network error occurred");
      return {
        'success': false,
        'message': 'Network error occurred',
        'exception': e.toString(),
        'data': null,
      };
    }
  }

  // Updated postFlatRating method to handle multipart form data
  Future<bool> postFlatRating({
    required BuildContext context,
    required String floorId,
    required String flatId,
    required FlatRatingData flatData,
    required String structureId,
    bool isUpdate = false,
  }) async {
    final token = Provider.of<CommonProvider>(
      listen: false,
      context,
    ).accessToken;

    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId/flats/$flatId/ratings',
    );

    print('ðŸš€ ${isUpdate ? 'PUT' : 'POST'} FlatRating() called');
    print('âž¡ï¸ URL: $url');
    print('ðŸ†” flatId: $flatId | floorId: $floorId');
    print('ðŸ“¦ flatData: ${flatData.flatNumber}');
    print('ðŸ”„ isUpdate: $isUpdate');

    try {
      // Create multipart request
      var request = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', url);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add structural_rating as JSON text field
      final structuralRating = {
        "beams": {
          "rating": flatData.structuralData?.beamsRating,
          "condition_comment": flatData.structuralData?.beamsComment ?? "",
          "inspector_notes": "",
        },
        "columns": {
          "rating": flatData.structuralData?.columnsRating,
          "condition_comment": flatData.structuralData?.columnsComment ?? "",
          "inspector_notes": "",
        },
        "slab": {
          "rating": flatData.structuralData?.slabRating,
          "condition_comment": flatData.structuralData?.slabComment ?? "",
          "inspector_notes": "",
        },
        "foundation": {
          "rating": flatData.structuralData?.foundationRating,
          "condition_comment": flatData.structuralData?.foundationComment ?? "",
          "inspector_notes": "",
        },
      };

      // Add non_structural_rating as JSON text field
      final nonStructuralRating = {
        "brick_plaster": {
          "rating": flatData.nonStructuralData?.brickValue,
          "condition_comment":
              flatData.nonStructuralData?.brickController?.text ?? "",
          "inspector_notes": "",
        },
        "doors_windows": {
          "rating": flatData.nonStructuralData?.doorWindowValue,
          "condition_comment":
              flatData.nonStructuralData?.doorWindowController?.text ?? "",
          "inspector_notes": "",
        },
        "flooring_tiles": {
          "rating": flatData.nonStructuralData?.tilesvalue,
          "condition_comment":
              flatData.nonStructuralData?.tiledController?.text ?? '',
          "inspector_notes": "",
        },
        "electrical_wiring": {
          "rating": flatData.nonStructuralData?.electricalValue,
          "condition_comment":
              flatData.nonStructuralData?.electricalController?.text ?? '',
          "inspector_notes": "",
        },
        "sanitary_fittings": {
          "rating": flatData.nonStructuralData?.fittingsValue,
          "condition_comment":
              flatData.nonStructuralData?.fittingsController?.text ?? '',
          "inspector_notes": "",
        },
        "railings": {
          "rating": flatData.nonStructuralData?.railingsValue,
          "condition_comment":
              flatData.nonStructuralData?.railingsController?.text ?? '',
          "inspector_notes": "",
        },
        "water_tanks": {
          "rating": flatData.nonStructuralData?.waterTankValue,
          "condition_comment":
              flatData.nonStructuralData?.waterTankController?.text ?? '',
          "inspector_notes": "",
        },
        "plumbing": {
          "rating": flatData.nonStructuralData?.plumbingValue,
          "condition_comment":
              flatData.nonStructuralData?.plumbingController?.text ?? '',
          "inspector_notes": "",
        },
        "sewage_system": {
          "rating": flatData.nonStructuralData?.sewageValue,
          "condition_comment":
              flatData.nonStructuralData?.sewageController?.text ?? '',
          "inspector_notes": "",
        },
        "panel_board": {
          "rating": flatData.nonStructuralData?.transformerValue,
          "condition_comment":
              flatData.nonStructuralData?.transformerController?.text ?? '',
          "inspector_notes": "",
        },
        "lifts": {
          "rating": flatData.nonStructuralData?.liftValue,
          "condition_comment":
              flatData.nonStructuralData?.liftController?.text ?? '',
          "inspector_notes": "",
        },
      };

      // Add JSON fields
      request.fields['structural_rating'] = jsonEncode(structuralRating);
      request.fields['non_structural_rating'] = jsonEncode(nonStructuralRating);

      // Add photo files
      await _addPhotoFiles(request, flatData);

      print('ðŸ§¾ Request Fields: ${request.fields}');
      print(
        'ðŸ“Ž Request Files: ${request.files.map((f) => f.field).toList()}',
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ðŸ“¬ HTTP Response: ${response.statusCode}');
      print('ðŸ“¬ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMessage = isUpdate
            ? 'Flat rating updated successfully'
            : 'Flat rating submitted successfully';

        print('âœ… $successMessage');
        CustomToast.showSuccessToast(msg: successMessage);
        return true;
      } else {
        final errorMessage = isUpdate
            ? 'Error updating flat rating: ${response.statusCode}'
            : 'Error submitting flat rating: ${response.statusCode}';

        print('âŒ $errorMessage');
        print('âŒ Response Body: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          final apiErrorMessage = errorData['message'] ?? errorMessage;
          CustomToast.showErrorToast(msg: apiErrorMessage);
        } catch (e) {
          CustomToast.showErrorToast(msg: errorMessage);
        }

        return false;
      }
    } catch (e) {
      final errorMessage = isUpdate
          ? 'Exception during rating update: $e'
          : 'Exception during rating post: $e';

      print('âš  $errorMessage');
      CustomToast.showErrorToast(
        msg: "Failed to ${isUpdate ? 'update' : 'submit'} rating",
      );
      return false;
    }
  }

  // Helper method to add photo files to multipart request
  Future<void> _addPhotoFiles(
    http.MultipartRequest request,
    FlatRatingData flatData,
  ) async {
    // Add structural photos
    if (flatData.structuralData?.beamsFile != null) {
      await _addFileToRequest(
        request,
        'beams_photos',
        flatData.structuralData!.beamsFile,
      );
    }
    if (flatData.structuralData?.columnsFile != null) {
      await _addFileToRequest(
        request,
        'columns_photos',
        flatData.structuralData!.columnsFile,
      );
    }
    if (flatData.structuralData?.slabFile != null) {
      await _addFileToRequest(
        request,
        'slab_photos',
        flatData.structuralData!.slabFile,
      );
    }
    if (flatData.structuralData?.foundationFile != null) {
      await _addFileToRequest(
        request,
        'foundation_photos',
        flatData.structuralData!.foundationFile,
      );
    }

    // Add non-structural photos
    if (flatData.nonStructuralData?.brickFile != null) {
      await _addFileToRequest(
        request,
        'brick_plaster_photos',
        flatData.nonStructuralData!.brickFile,
      );
    }
    if (flatData.nonStructuralData?.doorWindowFile != null) {
      await _addFileToRequest(
        request,
        'doors_windows_photos',
        flatData.nonStructuralData!.doorWindowFile,
      );
    }
    if (flatData.nonStructuralData?.tilesFile != null) {
      await _addFileToRequest(
        request,
        'flooring_tiles_photos',
        flatData.nonStructuralData!.tilesFile,
      );
    }
    if (flatData.nonStructuralData?.electricalFile != null) {
      await _addFileToRequest(
        request,
        'electrical_wiring_photos',
        flatData.nonStructuralData!.electricalFile,
      );
    }
    if (flatData.nonStructuralData?.fittingsFile != null) {
      await _addFileToRequest(
        request,
        'sanitary_fittings_photos',
        flatData.nonStructuralData!.fittingsFile,
      );
    }
    if (flatData.nonStructuralData?.railingsFile != null) {
      await _addFileToRequest(
        request,
        'railings_photos',
        flatData.nonStructuralData!.railingsFile,
      );
    }
    if (flatData.nonStructuralData?.waterTankFile != null) {
      await _addFileToRequest(
        request,
        'water_tanks_photos',
        flatData.nonStructuralData!.waterTankFile,
      );
    }
    if (flatData.nonStructuralData?.plumbingFile != null) {
      await _addFileToRequest(
        request,
        'plumbing_photos',
        flatData.nonStructuralData!.plumbingFile,
      );
    }
    if (flatData.nonStructuralData?.sewageFile != null) {
      await _addFileToRequest(
        request,
        'sewage_system_photos',
        flatData.nonStructuralData!.sewageFile,
      );
    }
    if (flatData.nonStructuralData?.transformerFile != null) {
      await _addFileToRequest(
        request,
        'panel_board_photos',
        flatData.nonStructuralData!.transformerFile,
      );
    }
    if (flatData.nonStructuralData?.liftFile != null) {
      await _addFileToRequest(
        request,
        'lifts_photos',
        flatData.nonStructuralData!.liftFile,
      );
    }
  }

  // Helper method to add a single file to the request
  Future<void> _addFileToRequest(
    http.MultipartRequest request,
    String fieldName,
    dynamic file,
  ) async {
    if (file is File) {
      try {
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
        );
        request.files.add(multipartFile);
        print('ðŸ“Ž Added file: $fieldName -> ${file.path}');
      } catch (e) {
        print('âŒ Error adding file $fieldName: $e');
      }
    } else if (file is List<String>) {
      // Handle existing photos (URLs) - you might need to download and re-upload them
      print('âš  Warning: Cannot upload existing photo URLs for $fieldName');
    } else if (file is List) {
      // Handle list of files
      for (int i = 0; i < file.length; i++) {
        if (file[i] is File) {
          try {
            final multipartFile = await http.MultipartFile.fromPath(
              '$fieldName[$i]', // or just fieldName if API doesn't support arrays
              (file[i] as File).path,
            );
            request.files.add(multipartFile);
            print(
              'ðŸ“Ž Added file: $fieldName[$i] -> ${(file[i] as File).path}',
            );
          } catch (e) {
            print('âŒ Error adding file $fieldName[$i]: $e');
          }
        }
      }
    }
  }

  Future<bool> postFloorRating({
    required BuildContext context,
    required String floorId,
    required FloorRatingData floorData,
    required String structureId,
    bool isUpdate = false,
  }) async {
    const String baseUrl = CommonProvider.baseUrl;

    final token = Provider.of<CommonProvider>(
      context,
      listen: false,
    ).accessToken;

    final url = Uri.parse(
      '$baseUrl/api/structures/$structureId/floors/$floorId/ratings',
    );

    print('ðŸš€ ${isUpdate ? 'PUT' : 'POST'} FloorRating() called');
    print('âž¡ï¸ URL: $url');
    print('ðŸ†” floorId: $floorId | structureId: $structureId');
    print('ðŸ“¦ floorNumber: ${floorData.floorNumber}');

    try {
      // Create multipart request
      var request = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', url);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // âœ… CRITICAL: Use the SAME structure as flat ratings
      // The API expects the same field names for both floors and flats

      // Build structural rating JSON
      final structuralRating = {
        "beams": {
          "rating": floorData.structuralData?.beamsRating,
          "condition_comment": floorData.structuralData?.beamsComment ?? "",
          "inspector_notes": "",
        },
        "columns": {
          "rating": floorData.structuralData?.columnsRating,
          "condition_comment": floorData.structuralData?.columnsComment ?? "",
          "inspector_notes": "",
        },
        "slab": {
          "rating": floorData.structuralData?.slabRating,
          "condition_comment": floorData.structuralData?.slabComment ?? "",
          "inspector_notes": "",
        },
        "foundation": {
          "rating": floorData.structuralData?.foundationRating,
          "condition_comment":
              floorData.structuralData?.foundationComment ?? "",
          "inspector_notes": "",
        },
      };

      // Build non-structural rating JSON
      // âœ… Use the SAME field names as flats, just provide only relevant values
      final nonStructuralRating = {
        "brick_plaster": {
          "rating": floorData.nonStructuralData?.brickValue,
          "condition_comment":
              floorData.nonStructuralData?.brickController?.text ?? "",
          "inspector_notes": "",
        },
        "doors_windows": {
          "rating": floorData.nonStructuralData?.doorWindowValue,
          "condition_comment":
              floorData.nonStructuralData?.doorWindowController?.text ?? "",
          "inspector_notes": "",
        },
        "flooring_tiles": {
          "rating": floorData.nonStructuralData?.tilesvalue,
          "condition_comment":
              floorData.nonStructuralData?.tiledController?.text ?? '',
          "inspector_notes": "",
        },
        "electrical_wiring": {
          "rating": floorData.nonStructuralData?.electricalValue,
          "condition_comment":
              floorData.nonStructuralData?.electricalController?.text ?? '',
          "inspector_notes": "",
        },
        "sanitary_fittings": {
          "rating": floorData.nonStructuralData?.fittingsValue,
          "condition_comment":
              floorData.nonStructuralData?.fittingsController?.text ?? '',
          "inspector_notes": "",
        },
        // Floor-specific ratings - these can be null or 0 for floors
        "railings": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
        "water_tanks": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
        "plumbing": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
        "sewage_system": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
        "panel_board": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
        "lifts": {
          "rating": null,
          "condition_comment": "",
          "inspector_notes": "",
        },
      };

      // Add JSON fields
      request.fields['structural_rating'] = jsonEncode(structuralRating);
      request.fields['non_structural_rating'] = jsonEncode(nonStructuralRating);

      // Add photo files - use SAME field names as flats
      await _addFloorPhotoFilesWithDebug(request, floorData);

      print('ðŸ§¾ Request Fields: ${request.fields}');
      print('ðŸ“Ž Request Files: ${request.files.length} file(s)');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ðŸ“¬ HTTP Response: ${response.statusCode}');
      print('ðŸ“¬ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMessage = isUpdate
            ? 'Floor rating updated successfully'
            : 'Floor rating submitted successfully';

        print('âœ… $successMessage');
        // CustomToast.showSuccessToast(msg: successMessage);
        return true;
      } else {
        final errorMessage = isUpdate
            ? 'Error updating floor rating: ${response.statusCode}'
            : 'Error submitting floor rating: ${response.statusCode}';

        print('âŒ $errorMessage');
        print('âŒ Response Body: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          final apiErrorMessage = errorData['message'] ?? errorMessage;
          CustomToast.showErrorToast(msg: apiErrorMessage);
        } catch (e) {
          // CustomToast.showErrorToast(msg: errorMessage);
        }

        return false;
      }
    } catch (e) {
      final errorMessage = isUpdate
          ? 'Exception during floor rating update: $e'
          : 'Exception during floor rating post: $e';

      print('âš ï¸ $errorMessage');
      // CustomToast.showErrorToast(
      //   msg: "Failed to ${isUpdate ? 'update' : 'submit'} floor rating",
      // );
      return false;
    }
  }

  // Enhanced helper method with debugging for photo files
  Future<void> _addFloorPhotoFilesWithDebug(
    http.MultipartRequest request,
    FloorRatingData floorData,
  ) async {
    print('ðŸ“¸ Starting photo file processing...');
    int totalFilesAdded = 0;

    // Add structural photos
    print('ðŸ—ï¸ Processing structural photos...');

    if (floorData.structuralData?.beamsFile != null) {
      print('  ðŸ“· Processing beams photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'structural_photos[beams]',
        floorData.structuralData!.beamsFile,
      );
    }

    if (floorData.structuralData?.columnsFile != null) {
      print('  ðŸ“· Processing columns photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'structural_photos[columns]',
        floorData.structuralData!.columnsFile,
      );
    }

    if (floorData.structuralData?.slabFile != null) {
      print('  ðŸ“· Processing slab photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'structural_photos[slab]',
        floorData.structuralData!.slabFile,
      );
    }

    if (floorData.structuralData?.foundationFile != null) {
      print('  ðŸ“· Processing foundation photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'structural_photos[foundation]',
        floorData.structuralData!.foundationFile,
      );
    }

    // Add non-structural photos
    print('ðŸ¢ Processing non-structural photos...');

    if (floorData.nonStructuralData?.brickFile != null) {
      print('  ðŸ“· Processing walls photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'non_structural_photos[walls]',
        floorData.nonStructuralData!.brickFile,
      );
    }

    if (floorData.nonStructuralData?.tilesFile != null) {
      print('  ðŸ“· Processing flooring photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'non_structural_photos[flooring]',
        floorData.nonStructuralData!.tilesFile,
      );
    }

    if (floorData.nonStructuralData?.electricalFile != null) {
      print('  ðŸ“· Processing electrical photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'non_structural_photos[electrical_system]',
        floorData.nonStructuralData!.electricalFile,
      );
    }

    if (floorData.nonStructuralData?.fittingsFile != null) {
      print('  ðŸ“· Processing fire safety photos...');
      totalFilesAdded += await _addFileToRequestWithDebug(
        request,
        'non_structural_photos[fire_safety]',
        floorData.nonStructuralData!.fittingsFile,
      );
    }

    print(
      'ðŸ“Š Photo processing complete. Total files added: $totalFilesAdded',
    );
  }

  // Helper method with debugging for file addition
  Future<int> _addFileToRequestWithDebug(
    http.MultipartRequest request,
    String fieldName,
    dynamic file,
  ) async {
    print('    ðŸ” Processing file for field: $fieldName');
    print('    ðŸ“ File type: ${file.runtimeType}');

    int filesAdded = 0;

    try {
      if (file is File) {
        print('    ðŸ“ Single File detected: ${file.path}');

        // Check if file exists
        if (!await file.exists()) {
          print('    âŒ File does not exist: ${file.path}');
          return 0;
        }

        // Check file size
        final fileSize = await file.length();
        print('    ðŸ“ File size: $fileSize bytes');

        final multipartFile = await http.MultipartFile.fromPath(
          '$fieldName[0]',
          file.path,
        );
        request.files.add(multipartFile);
        filesAdded = 1;
        print('    âœ… Added single file: $fieldName[0] -> ${file.path}');
      } else if (file is List) {
        print('    ðŸ“‚ List of files detected. Count: ${file.length}');

        for (int i = 0; i < file.length; i++) {
          if (file[i] is File) {
            final currentFile = file[i] as File;
            print('      ðŸ“„ Processing file $i: ${currentFile.path}');

            // Check if file exists
            if (!await currentFile.exists()) {
              print('      âŒ File $i does not exist: ${currentFile.path}');
              continue;
            }

            // Check file size
            final fileSize = await currentFile.length();
            print('      ðŸ“ File $i size: $fileSize bytes');

            final multipartFile = await http.MultipartFile.fromPath(
              '$fieldName[$i]',
              currentFile.path,
            );
            request.files.add(multipartFile);
            filesAdded++;
            print(
              '      âœ… Added file: $fieldName[$i] -> ${currentFile.path}',
            );
          } else {
            print(
              '      âš ï¸ Item $i is not a File object: ${file[i].runtimeType}',
            );
          }
        }
      } else if (file is String) {
        print('    ðŸ“ String detected (possibly URL): $file');
        print('    âš ï¸ Cannot upload string as file - skipping');
      } else {
        print('    â“ Unknown file type: ${file.runtimeType}');
        print('    âš ï¸ Cannot process this file type - skipping');
      }
    } catch (e) {
      print('    âŒ Error processing file for $fieldName: $e');
    }

    print('    ðŸ“Š Files added for $fieldName: $filesAdded');
    return filesAdded;
  }

  // Additional debugging method to check if method is even being called
  void debugFloorRatingCall({
    required String floorId,
    required FloorRatingData floorData,
    required String structureId,
    bool isUpdate = false,
  }) {
    print('ðŸš¨ DEBUG: Floor Rating Call Tracker');
    print('  Method: debugFloorRatingCall');
    print('  Timestamp: ${DateTime.now()}');
    print('  Floor ID: $floorId');
    print('  Structure ID: $structureId');
    print('  Floor Number: ${floorData.floorNumber}');
    print('  Is Update: $isUpdate');
    print('  Has Structural Data: ${floorData.structuralData != null}');
    print('  Has Non-Structural Data: ${floorData.nonStructuralData != null}');
    print('ðŸš¨ END DEBUG');
  }

  // Helper method to add photo files for floor ratings
  Future<void> addFloorPhotoFiles(
    http.MultipartRequest request,
    FloorRatingData floorData,
  ) async {
    // Add structural photos using the correct field names from your data model
    if (floorData.structuralData?.beamsFile != null) {
      // Handle single file or list of files
      final beamsFile = floorData.structuralData!.beamsFile;
      if (beamsFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'structural_photos[beams][0]',
            beamsFile.path,
          ),
        );
      } else if (beamsFile is List) {
        for (int i = 0; i < beamsFile.length; i++) {
          if (beamsFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'structural_photos[beams][$i]',
                beamsFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.structuralData?.columnsFile != null) {
      final columnsFile = floorData.structuralData!.columnsFile;
      if (columnsFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'structural_photos[columns][0]',
            columnsFile.path,
          ),
        );
      } else if (columnsFile is List) {
        for (int i = 0; i < columnsFile.length; i++) {
          if (columnsFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'structural_photos[columns][$i]',
                columnsFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.structuralData?.slabFile != null) {
      final slabFile = floorData.structuralData!.slabFile;
      if (slabFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'structural_photos[slab][0]',
            slabFile.path,
          ),
        );
      } else if (slabFile is List) {
        for (int i = 0; i < slabFile.length; i++) {
          if (slabFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'structural_photos[slab][$i]',
                slabFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.structuralData?.foundationFile != null) {
      final foundationFile = floorData.structuralData!.foundationFile;
      if (foundationFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'structural_photos[foundation][0]',
            foundationFile.path,
          ),
        );
      } else if (foundationFile is List) {
        for (int i = 0; i < foundationFile.length; i++) {
          if (foundationFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'structural_photos[foundation][$i]',
                foundationFile[i].path,
              ),
            );
          }
        }
      }
    }

    // Add non-structural photos using correct field names (mapped to floor-specific categories only)
    if (floorData.nonStructuralData?.brickFile != null) {
      final brickFile = floorData.nonStructuralData!.brickFile;
      if (brickFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'non_structural_photos[walls][0]', // Mapped to walls
            brickFile.path,
          ),
        );
      } else if (brickFile is List) {
        for (int i = 0; i < brickFile.length; i++) {
          if (brickFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'non_structural_photos[walls][$i]', // Mapped to walls
                brickFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.nonStructuralData?.tilesFile != null) {
      final tilesFile = floorData.nonStructuralData!.tilesFile;
      if (tilesFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'non_structural_photos[flooring][0]', // Mapped to flooring
            tilesFile.path,
          ),
        );
      } else if (tilesFile is List) {
        for (int i = 0; i < tilesFile.length; i++) {
          if (tilesFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'non_structural_photos[flooring][$i]', // Mapped to flooring
                tilesFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.nonStructuralData?.electricalFile != null) {
      final electricalFile = floorData.nonStructuralData!.electricalFile;
      if (electricalFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'non_structural_photos[electrical_system][0]',
            electricalFile.path,
          ),
        );
      } else if (electricalFile is List) {
        for (int i = 0; i < electricalFile.length; i++) {
          if (electricalFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'non_structural_photos[electrical_system][$i]',
                electricalFile[i].path,
              ),
            );
          }
        }
      }
    }

    if (floorData.nonStructuralData?.fittingsFile != null) {
      final fittingsFile = floorData.nonStructuralData!.fittingsFile;
      if (fittingsFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'non_structural_photos[fire_safety][0]', // Mapped to fire safety
            fittingsFile.path,
          ),
        );
      } else if (fittingsFile is List) {
        for (int i = 0; i < fittingsFile.length; i++) {
          if (fittingsFile[i] is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'non_structural_photos[fire_safety][$i]', // Mapped to fire safety
                fittingsFile[i].path,
              ),
            );
          }
        }
      }
    }
  }
}

class StructuralRatingData {
  // Beams
  final int? beamsRating;
  final String? beamsComment;
  final dynamic beamsFile;
  final String? beamsFileName;
  final TextEditingController? beamsController;
  final TextEditingController? beamsRatingController;

  // Columns
  final int? columnsRating;
  final String? columnsComment;
  final dynamic columnsFile;
  final String? columnsFileName;
  final TextEditingController? columnsController;
  final TextEditingController? columnsRatingController;

  // Slab
  final int? slabRating;
  final String? slabComment;
  final dynamic slabFile;
  final String? slabFileName;
  final TextEditingController? slabController;
  final TextEditingController? slabRatingController;

  // Foundation
  final int? foundationRating;
  final String? foundationComment;
  final dynamic foundationFile;
  final String? foundationFileName;
  final TextEditingController? foundationController;
  final TextEditingController? foundationRatingController;

  StructuralRatingData({
    this.beamsRating,
    this.beamsComment,
    this.beamsFile,
    this.beamsFileName,
    this.beamsController,
    this.beamsRatingController,
    this.columnsRating,
    this.columnsComment,
    this.columnsFile,
    this.columnsFileName,
    this.columnsController,
    this.columnsRatingController,
    this.slabRating,
    this.slabComment,
    this.slabFile,
    this.slabFileName,
    this.slabController,
    this.slabRatingController,
    this.foundationRating,
    this.foundationComment,
    this.foundationFile,
    this.foundationFileName,
    this.foundationController,
    this.foundationRatingController,
  });
}

class NonStructuralRatingData {
  // Brick
  final int? brickValue;
  final String? brickComment;
  final dynamic brickFile;
  final String? brickName;
  final TextEditingController? brickController;
  final TextEditingController? brickRatingController;

  // Door Window
  final int? doorWindowValue;
  final String? doorWindowComment;
  final dynamic doorWindowFile;
  final String? doorWindowName;
  final TextEditingController? doorWindowController;
  final TextEditingController? doorWindowRatingController;

  // Tiles
  final int? tilesvalue;
  final String? tilesComment;
  final dynamic tilesFile;
  final String? tilesName;
  final TextEditingController? tiledController;
  final TextEditingController? tilesRatingController;

  // Electrical
  final int? electricalValue;
  final String? electricalComment;
  final dynamic electricalFile;
  final String? electricalName;
  final TextEditingController? electricalController;
  final TextEditingController? electricalRatingController;

  // Fittings
  final int? fittingsValue;
  final String? fittingsComment;
  final dynamic fittingsFile;
  final String? fittingsName;
  final TextEditingController? fittingsController;
  final TextEditingController? fittingsRatingController;

  // Railings
  final int? railingsValue;
  final String? railingsComment;
  final dynamic railingsFile;
  final String? railingsName;
  final TextEditingController? railingsController;
  final TextEditingController? railingsRatingController;

  // Water Tank
  final int? waterTankValue;
  final String? waterTankComment;
  final dynamic waterTankFile;
  final String? waterTankName;
  final TextEditingController? waterTankController;
  final TextEditingController? waterTankRatingController;

  // Plumbing
  final int? plumbingValue;
  final String? plumbingComment;
  final dynamic plumbingFile;
  final String? plumbingName;
  final TextEditingController? plumbingController;
  final TextEditingController? plumbingRatingController;

  // Sewage
  final int? sewageValue;
  final String? sewageComment;
  final dynamic sewageFile;
  final String? sewageName;
  final TextEditingController? sewageController;
  final TextEditingController? sewageRatingController;

  // Transformer
  final int? transformerValue;
  final String? transformerComment;
  final dynamic transformerFile;
  final String? transformerName;
  final TextEditingController? transformerController;
  final TextEditingController? transformerRatingController;

  // Lift
  final int? liftValue;
  final String? liftComment;
  final dynamic liftFile;
  final String? liftName;
  final TextEditingController? liftController;
  final TextEditingController? liftRatingController;

  NonStructuralRatingData({
    this.brickValue,
    this.brickComment,
    this.brickFile,
    this.brickName,
    this.brickController,
    this.brickRatingController,
    this.doorWindowValue,
    this.doorWindowComment,
    this.doorWindowFile,
    this.doorWindowName,
    this.doorWindowController,
    this.doorWindowRatingController,
    this.tilesvalue,
    this.tilesComment,
    this.tilesFile,
    this.tilesName,
    this.tiledController,
    this.tilesRatingController,
    this.electricalValue,
    this.electricalComment,
    this.electricalFile,
    this.electricalName,
    this.electricalController,
    this.electricalRatingController,
    this.fittingsValue,
    this.fittingsComment,
    this.fittingsFile,
    this.fittingsName,
    this.fittingsController,
    this.fittingsRatingController,
    this.railingsValue,
    this.railingsComment,
    this.railingsFile,
    this.railingsName,
    this.railingsController,
    this.railingsRatingController,
    this.waterTankValue,
    this.waterTankComment,
    this.waterTankFile,
    this.waterTankName,
    this.waterTankController,
    this.waterTankRatingController,
    this.plumbingValue,
    this.plumbingComment,
    this.plumbingFile,
    this.plumbingName,
    this.plumbingController,
    this.plumbingRatingController,
    this.sewageValue,
    this.sewageComment,
    this.sewageFile,
    this.sewageName,
    this.sewageController,
    this.sewageRatingController,
    this.transformerValue,
    this.transformerComment,
    this.transformerFile,
    this.transformerName,
    this.transformerController,
    this.transformerRatingController,
    this.liftValue,
    this.liftComment,
    this.liftFile,
    this.liftName,
    this.liftController,
    this.liftRatingController,
  });
}

class FlatRatingData {
  final String flatNumber;
  final String flatId;
  final String floorId;
  final StructuralRatingData? structuralData;
  final NonStructuralRatingData? nonStructuralData;

  FlatRatingData({
    required this.flatNumber,
    required this.flatId,
    required this.floorId,
    this.structuralData,
    this.nonStructuralData,
  });
}

class FloorRatingData {
  final String floorNumber;
  final String floorId;
  final StructuralRatingData? structuralData;
  final NonStructuralRatingData? nonStructuralData;

  FloorRatingData({
    required this.floorNumber,
    required this.floorId,
    this.structuralData,
    this.nonStructuralData,
  });
}
