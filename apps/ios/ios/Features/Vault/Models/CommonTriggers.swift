import Foundation

enum CommonTriggers {
    static let all: [(key: String, icon: String)] = [
        (key: "stress", icon: "flame.fill"),
        (key: "boredom", icon: "clock.fill"),
        (key: "loneliness", icon: "person.slash.fill"),
        (key: "late-night", icon: "moon.fill"),
        (key: "social-media", icon: "iphone"),
        (key: "urges", icon: "bolt.fill"),
        (key: "anxiety", icon: "waveform.path.ecg"),
        (key: "anger", icon: "exclamationmark.triangle.fill"),
        (key: "sadness", icon: "cloud.rain.fill"),
        (key: "peer-pressure", icon: "person.2.fill"),
    ]

    static let keys: [String] = all.map(\.key)
}
