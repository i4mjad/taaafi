import Testing
import Foundation
@testable import ios

@Suite("UserDocument")
struct UserDocumentTests {

    // MARK: - Missing Data Detection

    @Test("hasMissingData returns true when displayName is nil")
    func missingDisplayName() {
        let doc = UserDocument(
            displayName: nil,
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date()
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns true when displayName is empty")
    func emptyDisplayName() {
        let doc = UserDocument(
            displayName: "",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date()
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns true when email is nil")
    func missingEmail() {
        let doc = UserDocument(
            displayName: "Test",
            email: nil,
            gender: "male",
            locale: "en",
            dayOfBirth: Date()
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns true when gender is nil")
    func missingGender() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: nil,
            locale: "en",
            dayOfBirth: Date()
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns true when locale is nil")
    func missingLocale() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: nil,
            dayOfBirth: Date()
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns true when dayOfBirth is nil")
    func missingDayOfBirth() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: nil
        )
        #expect(doc.hasMissingData)
    }

    @Test("hasMissingData returns false when all required fields are present")
    func allFieldsPresent() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date()
        )
        #expect(!doc.hasMissingData)
    }

    // MARK: - Legacy Document Detection

    @Test("isLegacyDocument returns true when userFirstDate is nil")
    func legacyDocumentMissingFirstDate() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date(),
            userFirstDate: nil
        )
        #expect(doc.isLegacyDocument)
    }

    @Test("isLegacyDocument returns true when hasMissingData is true")
    func legacyDocumentMissingData() {
        let doc = UserDocument(
            displayName: nil,
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date(),
            userFirstDate: Date()
        )
        #expect(doc.isLegacyDocument)
    }

    @Test("isLegacyDocument returns false when all fields are present including userFirstDate")
    func notLegacyDocument() {
        let doc = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: Date(),
            userFirstDate: Date()
        )
        #expect(!doc.isLegacyDocument)
    }

    // MARK: - All Fields Nil

    @Test("All fields nil has missing data and is legacy")
    func allFieldsNil() {
        let doc = UserDocument()
        #expect(doc.hasMissingData)
        #expect(doc.isLegacyDocument)
        #expect(doc.id == nil)
    }

    // MARK: - Equatable

    @Test("Two documents with same values are equal")
    func equatable() {
        let date = Date()
        let doc1 = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: date,
            userFirstDate: date
        )
        let doc2 = UserDocument(
            displayName: "Test",
            email: "test@example.com",
            gender: "male",
            locale: "en",
            dayOfBirth: date,
            userFirstDate: date
        )
        #expect(doc1 == doc2)
    }

    // MARK: - Identifiable

    @Test("Document id matches DocumentID")
    func identifiable() {
        var doc = UserDocument()
        doc.id = "user-123"
        #expect(doc.id == "user-123")
    }
}
