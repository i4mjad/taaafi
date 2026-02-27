import Foundation

struct Emotion: Identifiable, Equatable {
    let id: String
    let emoji: String
    let nameKey: String
    let isPositive: Bool
}

enum Emotions {
    static let bad: [Emotion] = [
        Emotion(id: "angry", emoji: "\u{1F620}", nameKey: "emotion.angry", isPositive: false),
        Emotion(id: "sad", emoji: "\u{1F622}", nameKey: "emotion.sad", isPositive: false),
        Emotion(id: "regret", emoji: "\u{1F61E}", nameKey: "emotion.regret", isPositive: false),
        Emotion(id: "anxious", emoji: "\u{1F630}", nameKey: "emotion.anxious", isPositive: false),
        Emotion(id: "fear", emoji: "\u{1F628}", nameKey: "emotion.fear", isPositive: false),
        Emotion(id: "frustration", emoji: "\u{1F624}", nameKey: "emotion.frustration", isPositive: false),
        Emotion(id: "overwhelmed", emoji: "\u{1F635}", nameKey: "emotion.overwhelmed", isPositive: false),
        Emotion(id: "disgust", emoji: "\u{1F922}", nameKey: "emotion.disgust", isPositive: false),
        Emotion(id: "despair", emoji: "\u{1F629}", nameKey: "emotion.despair", isPositive: false),
        Emotion(id: "resentment", emoji: "\u{1F612}", nameKey: "emotion.resentment", isPositive: false),
        Emotion(id: "disappointment", emoji: "\u{1F614}", nameKey: "emotion.disappointment", isPositive: false),
        Emotion(id: "dread", emoji: "\u{1F61F}", nameKey: "emotion.dread", isPositive: false),
        Emotion(id: "confusion", emoji: "\u{1F615}", nameKey: "emotion.confusion", isPositive: false),
        Emotion(id: "awkwardness", emoji: "\u{1F62C}", nameKey: "emotion.awkwardness", isPositive: false),
        Emotion(id: "exhaustion", emoji: "\u{1F62E}\u{200D}\u{1F4A8}", nameKey: "emotion.exhaustion", isPositive: false),
    ]

    static let good: [Emotion] = [
        Emotion(id: "happy", emoji: "\u{1F60A}", nameKey: "emotion.happy", isPositive: true),
        Emotion(id: "gratitude", emoji: "\u{1F64F}", nameKey: "emotion.gratitude", isPositive: true),
        Emotion(id: "serenity", emoji: "\u{1F60C}", nameKey: "emotion.serenity", isPositive: true),
        Emotion(id: "confidence", emoji: "\u{1F4AA}", nameKey: "emotion.confidence", isPositive: true),
        Emotion(id: "satisfaction", emoji: "\u{1F601}", nameKey: "emotion.satisfaction", isPositive: true),
        Emotion(id: "excitement", emoji: "\u{1F929}", nameKey: "emotion.excitement", isPositive: true),
        Emotion(id: "love", emoji: "\u{2764}\u{FE0F}", nameKey: "emotion.love", isPositive: true),
        Emotion(id: "contentment", emoji: "\u{263A}\u{FE0F}", nameKey: "emotion.contentment", isPositive: true),
        Emotion(id: "compassion", emoji: "\u{1F917}", nameKey: "emotion.compassion", isPositive: true),
        Emotion(id: "pride", emoji: "\u{1F972}", nameKey: "emotion.pride", isPositive: true),
        Emotion(id: "joy", emoji: "\u{1F604}", nameKey: "emotion.joy", isPositive: true),
        Emotion(id: "inspiration", emoji: "\u{2728}", nameKey: "emotion.inspiration", isPositive: true),
        Emotion(id: "connection", emoji: "\u{1F91D}", nameKey: "emotion.connection", isPositive: true),
        Emotion(id: "determination", emoji: "\u{1F525}", nameKey: "emotion.determination", isPositive: true),
    ]

    static let all: [Emotion] = bad + good
}
