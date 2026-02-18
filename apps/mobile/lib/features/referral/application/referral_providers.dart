import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/referral_repository_impl.dart';
import '../domain/repositories/referral_repository.dart';

part 'referral_providers.g.dart';

// External dependencies
@riverpod
FirebaseFirestore firestore(ref) => FirebaseFirestore.instance;

@riverpod
FirebaseFunctions functions(ref) => FirebaseFunctions.instance;

// Repository provider
@riverpod
ReferralRepository referralRepository(ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(functionsProvider);
  return ReferralRepositoryImpl(firestore, functions);
}
