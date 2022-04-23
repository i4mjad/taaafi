

import '../Model/Relapse.dart';

abstract class FollowUpRepository {
  Stream<List<Day>> relapses();
  
}
