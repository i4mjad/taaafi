import Testing
@testable import ios

@Suite("ActionItem")
struct ActionItemTests {

    @Test("isDestructive defaults to false")
    func defaultNonDestructive() {
        let item = ActionItem(title: "Edit")
        #expect(!item.isDestructive)
    }

    @Test("isDestructive can be set to true")
    func destructiveItem() {
        let item = ActionItem(title: "Delete", isDestructive: true)
        #expect(item.isDestructive)
    }

    @Test("Icon is optional and nil by default")
    func optionalIcon() {
        let item = ActionItem(title: "Test")
        #expect(item.icon == nil)
    }

    @Test("Icon can be set")
    func iconSet() {
        let item = ActionItem(icon: "trash", title: "Delete")
        #expect(item.icon == "trash")
    }

    @Test("Each item gets a unique id")
    func uniqueIds() {
        let a = ActionItem(title: "A")
        let b = ActionItem(title: "B")
        #expect(a.id != b.id)
    }
}
