import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retry/retry.dart';

const _retryOptions = RetryOptions(
  maxAttempts: 3,
  delayFactor: Duration(seconds: 1),
  maxDelay: Duration(seconds: 4),
);

/// A helper function to wrap any Firestore operation in retry logic.
/// Only retries on network-related exceptions.
Future<T> retryFirestore<T>(Future<T> Function() operation,
    {String? operationName}) async {
  try {
    return await _retryOptions.retry(
      operation,
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
  } on FirebaseException catch (e) {
    // Log the specific Firebase error for debugging
    print(
        'Firestore operation "${operationName ?? 'unknown'}" failed with code: ${e.code}');
    rethrow;
  } catch (e) {
    // Catch any other errors and wrap or rethrow them
    print(
        'Non-Firebase error in operation "${operationName ?? 'unknown'}": $e');
    rethrow;
  }
}
