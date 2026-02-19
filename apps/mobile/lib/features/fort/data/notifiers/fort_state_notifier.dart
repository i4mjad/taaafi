import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/fort/data/repositories/fort_repository.dart';
import 'package:reboot_app_3/features/fort/domain/models/fort_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fort_state_notifier.g.dart';

@riverpod
class FortStateNotifier extends _$FortStateNotifier {
  @override
  FutureOr<FortState> build() async {
    // Wait for user doc to be ready
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    if (userDocAsync.isLoading || userDocAsync.hasError) {
      return FortState.initial();
    }
    if (userDocAsync.value == null) {
      return FortState.initial();
    }

    final accountStatus = ref.watch(accountStatusProvider);
    if (accountStatus != AccountStatus.ok) {
      return FortState.initial();
    }

    final repo = ref.read(fortRepositoryProvider);
    return repo.getFortState();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(fortRepositoryProvider);
      final fortState = await repo.getFortState();
      state = AsyncValue.data(fortState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Real-time stream of fort state changes.
@riverpod
Stream<FortState> fortStateStream(Ref ref) {
  final repo = ref.read(fortRepositoryProvider);
  return repo.fortStateStream();
}
