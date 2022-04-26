import '../Model/Relapse.dart';
import 'models/user_profile.dart';

abstract class FollowUpRepository {
  Stream<FollowUpData> relapses();
}
