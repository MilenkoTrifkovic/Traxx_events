import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import '../models/organisation.dart';
import '../models/organisation_check_response.dart';

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
    final callable = _functions.httpsCallable('saveCompanyInfo');
    final data = organisation.toJson();
    print('Calling saveCompanyInfo cloud function with data: $data');
    final result = await callable.call(data);
    final response = result.data as Map<String, dynamic>;
    print('Cloud function response: $response');

    // You already parse this into Organisation
    return organisation.copyWith(
      organisationId: response['organisationId'] as String?,
    );
  }

  Future<void> attachUserToExistingOrganisation(String organisationId) async {
    final callable =
        _functions.httpsCallable('attachUserToExistingOrganisation');
    await callable.call({
      'organisationId': organisationId,
    });
  }

  /// Checks if organisation info already exists for the current user
  /// Returns OrganisationCheckResponse with hasOrganisation, organisationId, and role
  Future<OrganisationCheckResponse> checkOrganisationInfo() async {
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

      // The cloud function returns an object with hasOrganisation, organisationId, and role
      final responseData = Map<String, dynamic>.from(result.data);
      final response = OrganisationCheckResponse.fromJson(responseData);

      print('Organisation check response: $response');
      return response;
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
          // If organisation is not found, return false response
          print('Organisation not found for user');
          return const OrganisationCheckResponse(
            hasOrganisation: false,
            organisationId: null,
            role: null,
          );
        default:
          throw Exception('Cloud function error: ${e.message}');
      }
    } catch (e) {
      print('Error calling checkOrganisationInfo cloud function: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendInvitationsForEvent(
    Event event, {
    required List<GuestModel> guests,
  }) async {
    if (event.eventId == null || event.eventId!.isEmpty) {
      throw ArgumentError('event.eventId is required');
    }
    if (guests.isEmpty) {
      throw ArgumentError('guests must not be empty');
    }

    final invitations = guests
        .where((g) => (g.email ?? '').trim().isNotEmpty)
        .map((g) => {
              'guestEmail': g.email!.trim(),
              'guestId': g.guestId,
              'guestName': g.name, // ✅ add this
            })
        .toList();

    if (invitations.isEmpty) {
      throw ArgumentError('No guest email addresses found');
    }

    try {
      final callable = _functions.httpsCallable('sendInvitations');

      final result = await callable.call(<String, dynamic>{
        'eventId': event.eventId,
        'organisationId': event.organisationId,
        'invitations': invitations,
        'demographicQuestionSetId': event.selectedDemographicQuestionSetId,
      });

      final data = result.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else {
        return {'data': data};
      }
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitDemographics({
    required String invitationId,
    required String token,
    required List<Map<String, dynamic>> answers,
    int? companionIndex,
  }) async {
    final callable = _functions.httpsCallable(
      'submitDemographics',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(<String, dynamic>{
      'invitationId': invitationId,
      'token': token.trim(),
      'answers': answers,
      if (companionIndex != null) 'companionIndex': companionIndex,
    });

    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  Future<Map<String, dynamic>> getSelectedMenuItemsForInvitation({
    required String invitationId,
    required String token,
  }) async {
    final callable = _functions.httpsCallable(
      'getSelectedMenuItemsForInvitation',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(<String, dynamic>{
      'invitationId': invitationId,
      'token': token.trim(),
    });

    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  Future<Map<String, dynamic>> submitMenuSelection({
    required String invitationId,
    required String token,
    required List<String> selectedMenuItemIds,
    int? companionIndex,
  }) async {
    final callable = _functions.httpsCallable(
      'submitMenuSelection',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(<String, dynamic>{
      'invitationId': invitationId,
      'token': token.trim(),
      'selectedMenuItemIds': selectedMenuItemIds,
      if (companionIndex != null) 'companionIndex': companionIndex,
    });

    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  Future<Map<String, dynamic>> getEventAnalytics({
    required String eventId,
  }) async {
    final callable = _functions.httpsCallable(
      'getEventAnalytics',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(<String, dynamic>{
      'eventId': eventId.trim(),
    });

    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
