import Testing
import Foundation
@testable import ios

@Suite("AppFeature.generateUniqueName")
struct GenerateUniqueNameTests {

    @Test("Lowercases and strips punctuation")
    func basicTransform() {
        #expect(AppFeature.generateUniqueName(from: "My Feature!") == "my_feature")
    }

    @Test("Collapses multiple spaces into single underscore")
    func multipleSpaces() {
        #expect(AppFeature.generateUniqueName(from: "Hello   World") == "hello_world")
    }

    @Test("Strips non-ASCII characters")
    func nonAscii() {
        #expect(AppFeature.generateUniqueName(from: "café") == "caf")
    }

    @Test("Preserves digits")
    func digits() {
        #expect(AppFeature.generateUniqueName(from: "Feature 123") == "feature_123")
    }

    @Test("Handles already-clean input")
    func alreadyClean() {
        #expect(AppFeature.generateUniqueName(from: "simple") == "simple")
    }

    @Test("Handles mixed special characters")
    func mixedSpecials() {
        #expect(AppFeature.generateUniqueName(from: "A/B Test (v2)") == "ab_test_v2")
    }
}

@Suite("AppFeature.localizedName")
struct LocalizedNameTests {

    private static let feature = AppFeature(
        id: "feat-1",
        uniqueName: "test_feature",
        nameEn: "Test Feature",
        nameAr: "ميزة اختبار",
        descriptionEn: "English desc",
        descriptionAr: "وصف عربي",
        category: .core,
        iconName: "star",
        isActive: true,
        isBannable: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    @Test("Arabic language code returns nameAr")
    func arabic() {
        #expect(Self.feature.localizedName(languageCode: "ar") == "ميزة اختبار")
    }

    @Test("English language code returns nameEn")
    func english() {
        #expect(Self.feature.localizedName(languageCode: "en") == "Test Feature")
    }

    @Test("Unknown language code falls back to nameEn")
    func fallback() {
        #expect(Self.feature.localizedName(languageCode: "fr") == "Test Feature")
    }

    @Test("localizedDescription follows same pattern")
    func localizedDescription() {
        #expect(Self.feature.localizedDescription(languageCode: "ar") == "وصف عربي")
        #expect(Self.feature.localizedDescription(languageCode: "en") == "English desc")
    }
}

@Suite("FeatureCategory raw value round-trips")
struct FeatureCategoryTests {

    @Test("All cases round-trip from rawValue")
    func roundTrip() {
        for value in [FeatureCategory.core, .social, .content, .communication, .settings] {
            #expect(FeatureCategory(rawValue: value.rawValue) == value)
        }
    }
}
