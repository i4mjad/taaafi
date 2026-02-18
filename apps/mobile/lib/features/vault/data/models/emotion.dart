class Emotion {
  final String emotionEmoji;
  final String emotionNameTranslationKey;

  Emotion(this.emotionEmoji, this.emotionNameTranslationKey);
}

var badEmotions = [
  Emotion("😠", "angry"),
  Emotion("😞", "sad"),
  Emotion("😪", "regret"),
  Emotion("😥", "anxious"),
  Emotion("😰", "fear"),
  Emotion("😖", "frustration"),
  Emotion("😵", "overwhelmed"),
  Emotion("🤢", "disgust"),
  Emotion("😭", "despair"),
  Emotion("😤", "resentment"),
  Emotion("😔", "disappointment"),
  Emotion("😨", "dread"),
  Emotion("😵‍💫", "confusion"),
  Emotion("😬", "awkwardness"),
  Emotion("😩", "exhaustion"),
];

var goodEmotions = [
  Emotion("😄", "happy"),
  Emotion("😇", "gratitude"),
  Emotion("🧘‍♂️", "serenity"),
  Emotion("💪", "confidence"),
  Emotion("😌", "satisfaction"),
  Emotion("🤩", "excitement"),
  Emotion("🥰", "love"),
  Emotion("😊", "contentment"),
  Emotion("🤗", "compassion"),
  Emotion("😎", "pride"),
  Emotion("🎉", "joy"),
  Emotion("🌟", "inspiration"),
  Emotion("🤝", "connection"),
  Emotion("🎯", "determination"),
  Emotion("🕊", "peace"),
];
