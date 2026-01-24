import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  /// Saves organisation data through the cloud function
  /// ✅ Option A: Send ONLY the allowed fields (no organisationId / createdAt / showMenuItemPrices etc.)
  Future<Organisation> saveCompanyInfo(Organisation organisation) async {
    final callable = _functions.httpsCallable('saveCompanyInfo');

    final address = <String, dynamic>{
      'street': organisation.street.trim(),
      'city': organisation.city.trim(),
      'zip': organisation.zip.toString().trim(),
      'country': organisation.country.trim(),
      if (organisation.country.trim() == 'United States' &&
          (organisation.state ?? '').trim().isNotEmpty)
        'state': organisation.state!.trim(),
    };

    final payload = <String, dynamic>{
      'name': organisation.name.trim(),
      'phone': organisation.phone.toString().trim(),
      'website': (organisation.website ?? '').trim().isEmpty
          ? null
          : organisation.website!.trim(),
      'timezone': organisation.timezone.trim(),
      'currency': 'USD', // ✅ keep fixed if model doesn’t have currency
      'logo':
          (organisation.logo ?? '').trim().isEmpty ? null : organisation.logo,
      'assignedSalesPersonId':
          (organisation.assignedSalesPersonId ?? '').trim().isEmpty
              ? null
              : organisation.assignedSalesPersonId!.trim(),
      'address': address,
    }..removeWhere((k, v) => v == null);

    print('Calling saveCompanyInfo cloud function with payload: $payload');

    try {
      final result = await callable.call(payload);
      final response = Map<String, dynamic>.from(result.data as Map);
      print('Cloud function response: $response');

      return organisation.copyWith(
        organisationId: response['organisationId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      print('❌ saveCompanyInfo failed: code=${e.code}');
      print('message=${e.message}');
      print('details=${e.details}');
      rethrow;
    }
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
    String? invitationCode,
    String? batchId,
  }) async {
    if (event.eventId == null || event.eventId!.isEmpty) {
      throw ArgumentError('event.eventId is required');
    }
    if (guests.isEmpty) {
      throw ArgumentError('guests must not be empty');
    }

    final invitations = guests
        .where((g) => g.email.trim().isNotEmpty)
        .map((g) => {
              'guestEmail': g.email.trim(),
              'guestId': g.guestId,
              'guestName': g.name,
              if (g.batchId != null && g.batchId!.trim().isNotEmpty)
                'batchId': g.batchId,
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
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode,
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
    required String dietPreference,
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
      'dietPreference': dietPreference,
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

  Future<Map<String, dynamic>> deleteHostUser({
    required String organisationId,
    required String hostUid,
    bool deleteAuth = false,
  }) async {
    final callable = _functions.httpsCallable('deleteHostUser');
    final result = await callable.call({
      'organisationId': organisationId,
      'hostUid': hostUid,
      'deleteAuth': deleteAuth,
    });
    if (result.data is Map) return Map<String, dynamic>.from(result.data);
    return {'data': result.data};
  }

  // -----------------------------
  // Hosts: Create + Resend Verify
  // -----------------------------

  /// Creates/updates a Host user (Auth + Firestore) and optionally sends email.
  /// For "Add Host" popup you will call with sendEmail=false.
  Future<Map<String, dynamic>> createHostUser({
    required String organisationId,
    required String name,
    required String email,
    String? address,
    String? country,
    bool isDisabled = false,
    bool sendEmail = false, // ✅ keep false for Add Host popup
  }) async {
    final callable = _functions.httpsCallable(
      'createHostUser',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    try {
      final result = await callable.call(<String, dynamic>{
        'organisationId': organisationId.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'address': (address ?? '').trim(),
        'country': (country ?? '').trim(),
        'isDisabled': isDisabled,
        'sendEmail': sendEmail,
      });

      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
          'createHostUser failed: ${e.code} ${e.message} ${e.details ?? ''}');
    }
  }

  /// Sends verification email (and optionally password link) from the Host table.
  Future<Map<String, dynamic>> resendHostVerificationEmail({
    required String organisationId,
    required String hostUid,
    bool sendPasswordLink = true,
  }) async {
    final callable = _functions.httpsCallable(
      'resendHostVerificationEmail',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    try {
      final result = await callable.call(<String, dynamic>{
        'organisationId': organisationId.trim(),
        'hostUid': hostUid.trim(),
        'sendPasswordLink': sendPasswordLink,
      });

      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
          'resendHostVerificationEmail failed: ${e.code} ${e.message}');
    }
  }
}
