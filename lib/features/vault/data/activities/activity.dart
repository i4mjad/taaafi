class Activity {
  //TODO: this is inital strcture, do update it when you work in the Activities feature
  final String id;
  final String name;
  final Difficulties difficulty;
  final String describition;
  final DateTime subscribeDate;
  final List<UsersLevels> levels;

  Activity(this.id, this.name, this.difficulty, this.describition,
      this.subscribeDate, this.levels);
}

enum Difficulties { easy, medium, hard }

enum UsersLevels { starter, intermediate, advanced, expert }
