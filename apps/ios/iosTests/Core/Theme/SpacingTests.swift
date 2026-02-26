import Testing
import CoreGraphics
@testable import ios

@Suite("Spacing")
struct SpacingTests {

    @Test("xxs equals 4pt")
    func xxs() {
        #expect(Spacing.xxs == 4)
    }

    @Test("xs equals 8pt")
    func xs() {
        #expect(Spacing.xs == 8)
    }

    @Test("sm equals 12pt")
    func sm() {
        #expect(Spacing.sm == 12)
    }

    @Test("md equals 16pt")
    func md() {
        #expect(Spacing.md == 16)
    }

    @Test("lg equals 20pt")
    func lg() {
        #expect(Spacing.lg == 20)
    }

    @Test("xl equals 24pt")
    func xl() {
        #expect(Spacing.xl == 24)
    }

    @Test("xxl equals 32pt")
    func xxl() {
        #expect(Spacing.xxl == 32)
    }
}
