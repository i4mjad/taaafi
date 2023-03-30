import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/repository/notes_repository.dart';
import 'package:reboot_app_3/viewmodels/notes_viewmodel.dart';

final noteRepositoryProvider = Provider<INotesRepository>((ref) {
  return getIt<INotesRepository>();
});

final noteViewModelProvider = StateNotifierProvider(
  (ref) {
    return NoteViewModel();
  },
);
