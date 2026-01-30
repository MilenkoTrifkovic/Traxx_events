// import 'package:get/get.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
// import 'package:traxx_wepapp/models/demographic_response_model.dart';
// import 'package:traxx_wepapp/models/host_questions.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// /// Controller for editing demographic responses
// class GuestDemographicsEditController extends GetxController {
//   final isLoading = false.obs;
//   final isSaving = false.obs;

//   // Session controller
//   final _guestSession = Get.find<GuestSessionController>();

//   // 🆕 Guest ID for editing (can be main guest or companion)
//   String? _editingGuestId;
  
//   // Flag to prevent re-initialization
//   bool _isInitialized = false;

//   // 🆕 Current response - now gets from session using guestId
//   DemographicResponseModel? get demographicsResponse {
//     final guestId = _editingGuestId ?? _guestSession.guest.value?.guestId;
//     if (guestId == null) return null;
//     return _guestSession.getDemographicsResponseForGuest(guestId);
//   }

//   // Demographics questions
//   final demographicQuestions = <DemographicQuestion>[].obs;

//   // Form answers (map of questionId -> answer)
//   final formAnswers = <String, dynamic>{}.obs;

//   /// 🆕 Initialize with optional guestId (for companion editing)
//   void initialize({String? guestId}) {
//     // Check if we're editing a different guest
//     final isDifferentGuest = _editingGuestId != null && _editingGuestId != guestId;
    
//     // Prevent re-initialization on widget rebuilds for the SAME guest
//     if (_isInitialized && !isDifferentGuest) {
//       print('⚠️ Controller already initialized for same guest, skipping...');
//       return;
//     }
    
//     // If different guest, clear previous state
//     if (isDifferentGuest) {
//       print('🔄 Switching to different guest, clearing state...');
//       _clearState();
//     }
    
//     _editingGuestId = guestId;
//     _isInitialized = true;
//     _loadDemographicsQuestions();
//   }
  
//   /// Clear all state when switching guests
//   void _clearState() {
//     demographicQuestions.clear();
//     formAnswers.clear();
//     isLoading.value = false;
//     isSaving.value = false;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     // Will be called with guestId from navigation extra
//   }

//   /// Load demographic questions from Firestore
//   Future<void> _loadDemographicsQuestions() async {
//     try {
//       isLoading.value = true;

//       final response = demographicsResponse;
//       if (response == null || response.demographicQuestionSetId == null) {
//         print('⚠️ No demographics question set found');
//         return;
//       }

//       print('📋 Loading questions for set: ${response.demographicQuestionSetId}');

//       // Fetch questions from Firestore
//       final questionsSnapshot = await FirebaseFirestore.instance
//           .collection('demographicQuestions')
//           .where('questionSetId', isEqualTo: response.demographicQuestionSetId)
//           .where('isDisabled', isEqualTo: false)
//           .orderBy('displayOrder')
//           .get();

//       demographicQuestions.value = questionsSnapshot.docs
//           .map((doc) => DemographicQuestion.fromDoc(doc))
//           .toList();

//       print('✅ Loaded ${demographicQuestions.length} questions');

//       // Initialize form answers from current response
//       _initializeFormAnswers();

//     } catch (e) {
//       print('❌ Error loading demographic questions: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Initialize form answers from current response
//   void _initializeFormAnswers() {
//     if (demographicsResponse == null) return;

//     for (final answer in demographicsResponse!.answers) {
//       formAnswers[answer.questionId] = answer.answer;
//     }

//     print('📝 Initialized ${formAnswers.length} form answers');
//   }

//   /// Update answer for a specific question
//   void updateAnswer(String questionId, dynamic answer) {
//     formAnswers[questionId] = answer;
//   }

//   /// Validate form before saving
//   bool _validateForm() {
//     // Check if all required questions are answered
//     for (final question in demographicQuestions) {
//       if (question.isRequired) {
//         final answer = formAnswers[question.questionId];
//         if (answer == null || 
//             (answer is String && answer.trim().isEmpty) ||
//             (answer is List && answer.isEmpty)) {
//           print('⚠️ Required question not answered: ${question.questionText}');
//           return false;
//         }
//       }
//     }
//     return true;
//   }

//   /// Save demographics responses
//   Future<bool> saveResponses() async {
//     if (!_validateForm()) {
//       return false;
//     }

//     try {
//       isSaving.value = true;

//       // Build answers list
//       final answers = <DemographicAnswer>[];
//       for (final question in demographicQuestions) {
//         final answer = formAnswers[question.questionId];
//         if (answer != null) {
//           answers.add(DemographicAnswer(
//             questionId: question.questionId,
//             questionText: question.questionText,
//             type: question.questionType,
//             isRequired: question.isRequired,
//             answer: answer,
//           ));
//         }
//       }

//       // Create updated response
//       final updatedResponse = demographicsResponse!.copyWith(
//         answers: answers,
//       );

//       // Update in session controller (which will save to Firestore)
//       await _guestSession.updateDemographicsResponse(updatedResponse);

//       print('✅ Demographics responses saved successfully');
//       return true;

//     } catch (e) {
//       print('❌ Error saving demographics responses: $e');
//       return false;
//     } finally {
//       isSaving.value = false;
//     }
//   }

//   /// Cancel editing and go back
//   void cancel(BuildContext context) {
//     context.pop();
//   }
  
//   @override
//   void onClose() {
//     // Clear state when controller is disposed
//     _clearState();
//     _isInitialized = false;
//     _editingGuestId = null;
//     super.onClose();
//   }
// }
