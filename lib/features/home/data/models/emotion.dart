class Emotion {
  final String emotionEmoji;
  final String emotionNameTranslationKey;

  Emotion(this.emotionEmoji, this.emotionNameTranslationKey);
}

//TODO: figure out what is the best way to name those two types
var badEmotions = [
  Emotion("😠", "angry"),
  Emotion("😞", "sad"),
  Emotion("😪", "regret"),
  Emotion("😥", "anxious"),
  Emotion("😰", "fear"),
];

var goodEmotions = [
  Emotion("😄", "happy"),
  Emotion("😇", "gratitude"),
  Emotion("🧘‍♂️", "serenity"),
  Emotion("💪", "confidence"),
  Emotion("😌", "satisfaction"),
];
