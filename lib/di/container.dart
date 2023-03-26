import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/repository/notes_repository.dart';

final getIt = GetIt.instance;

void SetupContainer() {
  getIt.registerSingleton<INotesRepository>(FirebaseNotesRepository());
}
