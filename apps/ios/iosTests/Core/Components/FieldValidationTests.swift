import Testing
@testable import ios

@Suite("AppTextField validation")
struct FieldValidationTests {

    @Test("Character count reflects text length")
    @MainActor
    func characterCount() {
        let field = AppTextField(text: .constant("Hello"), label: "Name")
        #expect(field.characterCount == 5)
    }

    @Test("Empty text has zero character count")
    @MainActor
    func emptyCharacterCount() {
        let field = AppTextField(text: .constant(""), label: "Name")
        #expect(field.characterCount == 0)
    }

    @Test("isOverLimit when text exceeds maxLength")
    @MainActor
    func overLimit() {
        let field = AppTextField(
            text: .constant("This is a long string that is over ten"),
            label: "Name",
            maxLength: 10
        )
        #expect(field.isOverLimit)
    }

    @Test("Not over limit when at or below maxLength")
    @MainActor
    func withinLimit() {
        let field = AppTextField(
            text: .constant("Hello"),
            label: "Name",
            maxLength: 100
        )
        #expect(!field.isOverLimit)
    }
}
