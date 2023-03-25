import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/repository/notes_repository.dart';

final getIt = GetIt.instance;

//TODO: Create a user repository to get the details realted to that user like the uid and any other metadata related to the user

void SetupContainer() {
  getIt
      .registerLazySingleton<INotesRepository>(() => FirebaseNotesRepository());
}
