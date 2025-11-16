import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/organisation.dart';

class CloudFunctionsService extends GetxService {
  late final FirebaseFunctions _functions;

  @override
  void onInit() {
    super.onInit();
    _functions = FirebaseFunctions.instance;
  }

  /// Saves organisation data through the cloud function
  /// The cloud function will assign organisationId and handle server-side validation
  Future<Organisation> saveCompanyInfo(Organisation organisation) async {
    try {
      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to save organisation');
      }

      // Prepare data for cloud function
      final data = organisation.toJson();
      print(data);

      // Remove organisationId if it exists (cloud function will assign it)
      data.remove('organisationId');

      print('Calling saveCompanyInfo cloud function with data: $data');

      // Call the cloud function
      final callable = _functions.httpsCallable('saveCompanyInfo');
      final result = await callable.call(data);

      print('Cloud function response: ${result.data}');

      // Parse the response
      if (result.data == null) {
        throw Exception('Cloud function returned null data');
      }

      final responseData = Map<String, dynamic>.from(result.data);

      // Ensure required fields are present
      if (!responseData.containsKey('organisationId')) {
        throw Exception('Cloud function did not return organisationId');
      }

      // Create Organisation object from response
      // The cloud function should return the complete organisation data
      // including organisationId, userId, createdAt, modifiedDate, etc.
      final savedOrganisation = Organisation.fromJson(responseData);

      print(
          'Successfully saved organisation: ${savedOrganisation.organisationId}');

      return savedOrganisation;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      print('Details: ${e.details}');

      // Handle specific error codes
      switch (e.code) {
        case 'permission-denied':
          throw Exception(
              'Permission denied: You are not authorized to save organisation data');
        case 'invalid-argument':
          throw Exception('Invalid data provided: ${e.message}');
        case 'already-exists':
          throw Exception('Organisation already exists');
        case 'not-found':
          throw Exception('Required resources not found');
        default:
          throw Exception('Cloud function error: ${e.message}');
      }
    } catch (e) {
      print('Error calling saveCompanyInfo cloud function: $e');
      rethrow;
    }
  }

  /// Checks if organisation info already exists for the current user
  /// Returns true if organisation exists, false otherwise
  Future<bool> checkOrganisationInfo() async {
    try {
      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to check organisation');
      }

      print(
          'Checking if organisation info exists for user: ${currentUser.uid}');

      // Call the cloud function
      final callable = _functions.httpsCallable('checkOrganisationInfo');
      final result = await callable.call();

      print('Check organisation response: ${result.data}');

      // Parse the response
      if (result.data == null) {
        throw Exception('Cloud function returned null data');
      }

      // The cloud function should return a boolean or an object with a boolean field
      final responseData = result.data;

      bool exists;
      if (responseData is bool) {
        exists = responseData;
      } else if (responseData is Map && responseData.containsKey('hasOrganisation')) {
        exists = responseData['hasOrganisation'] as bool;
      } else if (responseData is Map && responseData.containsKey('exists')) {
        exists = responseData['exists'] as bool;
      } else {
        throw Exception('Invalid response format from cloud function');
      }

      print('Organisation exists: $exists');
      return exists;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      print('Details: ${e.details}');

      // Handle specific error codes
      switch (e.code) {
        case 'permission-denied':
          throw Exception(
              'Permission denied: You are not authorized to check organisation data');
        case 'unauthenticated':
          throw Exception('User must be authenticated to check organisation');
        case 'not-found':
          // If organisation is not found, return false
          print('Organisation not found for user');
          return false;
        default:
          throw Exception('Cloud function error: ${e.message}');
      }
    } catch (e) {
      print('Error calling checkOrganisationInfo cloud function: $e');
      rethrow;
    }
  }
}
