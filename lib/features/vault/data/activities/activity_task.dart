class ActivityTask {
//TODO: this is inital strcture, do update it when you work in the Activities feature
  final String id;
  final String taskName;
  final String activityName;
  final String linkedDiaryId;
  final String description;
  final DateTime taskDatetime;
  final bool isLinkedToADiary;

  ActivityTask(this.id, this.taskName, this.activityName, this.linkedDiaryId,
      this.isLinkedToADiary, this.taskDatetime, this.description);
}
