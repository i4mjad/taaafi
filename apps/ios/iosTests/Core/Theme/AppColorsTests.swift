import Testing
import SwiftUI
@testable import ios

@Suite("AppColors")
struct AppColorsTests {

    // MARK: - Color Family Shade Count

    @Test("primary has 10 shades")
    func primaryShadeCount() {
        let shades: [Color] = [
            AppColors.primary50, AppColors.primary100, AppColors.primary200,
            AppColors.primary300, AppColors.primary400, AppColors.primary500,
            AppColors.primary600, AppColors.primary700, AppColors.primary800,
            AppColors.primary900
        ]
        #expect(shades.count == 10)
    }

    @Test("secondary has 10 shades")
    func secondaryShadeCount() {
        let shades: [Color] = [
            AppColors.secondary50, AppColors.secondary100, AppColors.secondary200,
            AppColors.secondary300, AppColors.secondary400, AppColors.secondary500,
            AppColors.secondary600, AppColors.secondary700, AppColors.secondary800,
            AppColors.secondary900
        ]
        #expect(shades.count == 10)
    }

    @Test("tint has 10 shades")
    func tintShadeCount() {
        let shades: [Color] = [
            AppColors.tint50, AppColors.tint100, AppColors.tint200,
            AppColors.tint300, AppColors.tint400, AppColors.tint500,
            AppColors.tint600, AppColors.tint700, AppColors.tint800,
            AppColors.tint900
        ]
        #expect(shades.count == 10)
    }

    @Test("success has 10 shades")
    func successShadeCount() {
        let shades: [Color] = [
            AppColors.success50, AppColors.success100, AppColors.success200,
            AppColors.success300, AppColors.success400, AppColors.success500,
            AppColors.success600, AppColors.success700, AppColors.success800,
            AppColors.success900
        ]
        #expect(shades.count == 10)
    }

    @Test("warning has 10 shades")
    func warningShadeCount() {
        let shades: [Color] = [
            AppColors.warning50, AppColors.warning100, AppColors.warning200,
            AppColors.warning300, AppColors.warning400, AppColors.warning500,
            AppColors.warning600, AppColors.warning700, AppColors.warning800,
            AppColors.warning900
        ]
        #expect(shades.count == 10)
    }

    @Test("error has 10 shades")
    func errorShadeCount() {
        let shades: [Color] = [
            AppColors.error50, AppColors.error100, AppColors.error200,
            AppColors.error300, AppColors.error400, AppColors.error500,
            AppColors.error600, AppColors.error700, AppColors.error800,
            AppColors.error900
        ]
        #expect(shades.count == 10)
    }

    @Test("grey has 10 shades")
    func greyShadeCount() {
        let shades: [Color] = [
            AppColors.grey50, AppColors.grey100, AppColors.grey200,
            AppColors.grey300, AppColors.grey400, AppColors.grey500,
            AppColors.grey600, AppColors.grey700, AppColors.grey800,
            AppColors.grey900
        ]
        #expect(shades.count == 10)
    }

    @Test("background color exists")
    func backgroundExists() {
        let _: Color = AppColors.background
    }

    // MARK: - Semantic Aliases

    @Test("primary is primary500")
    func primaryAlias() {
        #expect(AppColors.primary == AppColors.primary500)
    }

    @Test("secondary is secondary500")
    func secondaryAlias() {
        #expect(AppColors.secondary == AppColors.secondary500)
    }

    @Test("success is success500")
    func successAlias() {
        #expect(AppColors.success == AppColors.success500)
    }

    @Test("warning is warning500")
    func warningAlias() {
        #expect(AppColors.warning == AppColors.warning500)
    }

    @Test("error is error500")
    func errorAlias() {
        #expect(AppColors.error == AppColors.error500)
    }
}
