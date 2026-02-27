import Foundation

// MARK: - Ban Display Extensions

extension Ban {

    /// Formatted duration string based on severity and expiry
    var formattedDuration: String {
        if severity == .permanent {
            return Strings.Ban.permanent
        }

        guard let expiresAt else {
            return Strings.Ban.unknown
        }

        if expiresAt < Date.now {
            return Strings.Ban.expired
        }

        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: issuedAt,
            to: expiresAt
        )

        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if days > 0 {
            let label = days == 1 ? Strings.Ban.day : Strings.Ban.days
            return "\(days) \(label)"
        } else if hours > 0 {
            let label = hours == 1 ? Strings.Ban.hour : Strings.Ban.hours
            return "\(hours) \(label)"
        } else {
            let label = minutes == 1 ? Strings.Ban.minute : Strings.Ban.minutes
            return "\(max(1, minutes)) \(label)"
        }
    }

    /// Formatted issued date using medium style with Arabic locale
    var formattedIssuedDate: String {
        Self.mediumDateFormatter.string(from: issuedAt)
    }

    /// Formatted expiry date using medium style with Arabic locale, nil if no expiry
    var formattedExpiresDate: String? {
        guard let expiresAt else { return nil }
        return Self.mediumDateFormatter.string(from: expiresAt)
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ar")
        return formatter
    }()
}

// MARK: - BanType Display Extensions

extension BanType {

    /// Localized display text for the ban type
    var displayText: String {
        switch self {
        case .user_ban: return Strings.Ban.typeUser
        case .device_ban: return Strings.Ban.typeDevice
        case .feature_ban: return Strings.Ban.typeFeature
        }
    }
}

// MARK: - BanScope Display Extensions

extension BanScope {

    /// Localized display text for the ban scope
    var displayText: String {
        switch self {
        case .app_wide: return Strings.Ban.scopeAppWide
        case .feature_specific: return Strings.Ban.scopeFeature
        }
    }
}
