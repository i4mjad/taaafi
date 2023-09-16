import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/repository/notes_repository.dart';
import 'package:reboot_app_3/repository/user_context.dart';
import 'package:reboot_app_3/shared/services/promize_service.dart';

import '../repository/follow_up_data_repository.dart';

final getIt = GetIt.instance;

void SetupContainer() {
  getIt.registerSingleton<INotesRepository>(FirebaseNotesRepository());
  getIt.registerSingleton<IUserContext>(FireStoreUserContext());
  getIt.registerSingleton<IFollowUpDataRepository>(
      FirebaseFollowUpDataRepository());
  getIt.registerSingleton<IPromizeService>(PromizeService());
}
