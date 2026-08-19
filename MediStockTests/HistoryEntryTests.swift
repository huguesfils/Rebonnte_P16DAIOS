import Foundation
import Testing
@testable import MediStock

struct HistoryEntryTests {
    @Test func displayedUserPrefersTheEmail() {
        let entry = HistoryEntry.stub(user: "uid-1", userEmail: "operateur@medistock.app")

        #expect(entry.displayedUser == "operateur@medistock.app")
    }

    @Test(arguments: [nil, ""])
    func legacyEntriesFallBackToId(email: String?) {
        let entry = HistoryEntry.stub(user: "uid-1", userEmail: email)

        #expect(entry.displayedUser == "uid-1")
    }
}
