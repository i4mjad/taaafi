import SwiftUI

enum AppIcon: String, CaseIterable {
    case alertCircle = "exclamationmark.circle"
    case alertTriangle = "exclamationmark.triangle"
    case check = "checkmark"
    case checkCircle = "checkmark.circle.fill"
    case checkSquare = "checkmark.square"
    case chevronRight = "chevron.right"
    case chevronDown = "chevron.down"
    case clock = "clock"
    case eye = "eye"
    case eyeOff = "eye.slash"
    case info = "info.circle"
    case mail = "envelope"
    case pencil = "pencil"
    case shieldOff = "shield.slash"
    case signOut = "rectangle.portrait.and.arrow.right"
    case trash = "trash"
    case userX = "person.crop.circle.badge.xmark"
    case warning = "exclamationmark.triangle.fill"
    case wifiOff = "wifi.slash"
    case xmark = "xmark"
    case xmarkCircle = "xmark.circle.fill"

    var systemName: String { rawValue }

    /// Brand plus icon from Asset Catalog (not SF Symbol)
    static let plusIconName = "Ta3aafiPlus"
}
