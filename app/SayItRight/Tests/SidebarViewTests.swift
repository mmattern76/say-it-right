import Testing
@testable import SayItRight

@Suite("SessionTypeItem")
struct SessionTypeItemTests {

    @Test("All session types have unique IDs")
    func uniqueIDs() {
        let ids = SessionTypeItem.allTypes.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test("All session types have both language titles")
    func bothLanguages() {
        for item in SessionTypeItem.allTypes {
            #expect(!item.titleEN.isEmpty, "EN title missing for \(item.id)")
            #expect(!item.titleDE.isEmpty, "DE title missing for \(item.id)")
        }
    }

    @Test("Title returns English for en language")
    func titleEnglish() {
        let item = SessionTypeItem.allTypes[0]
        #expect(item.title(language: "en") == item.titleEN)
    }

    @Test("Title returns German for de language")
    func titleGerman() {
        let item = SessionTypeItem.allTypes[0]
        #expect(item.title(language: "de") == item.titleDE)
    }

    @Test("All session types have SF Symbol icons")
    func iconsNotEmpty() {
        for item in SessionTypeItem.allTypes {
            #expect(!item.icon.isEmpty, "Icon missing for \(item.id)")
        }
    }

    @Test("All session types have subtitles")
    func subtitlesNotEmpty() {
        for item in SessionTypeItem.allTypes {
            #expect(!item.subtitle.isEmpty, "Subtitle missing for \(item.id)")
        }
    }

    @Test("Expected session type count matches curriculum")
    func expectedCount() {
        #expect(SessionTypeItem.allTypes.count == 7)
    }

    @Test("SessionTypeItem conforms to Hashable")
    func hashable() {
        let a = SessionTypeItem.allTypes[0]
        let b = SessionTypeItem.allTypes[1]
        let set: Set<SessionTypeItem> = [a, b, a]
        #expect(set.count == 2)
    }

    @Test("Say it clearly is first session type")
    func firstType() {
        let first = SessionTypeItem.allTypes[0]
        #expect(first.id == "say-it-clearly")
        #expect(first.titleEN == "Say it clearly")
    }
}

@Suite("AdaptiveChatView Integration")
struct AdaptiveChatViewTests {

    @MainActor
    @Test("ViewModel session type updates from selection")
    func sessionTypeSync() {
        let vm = ChatViewModel()
        let sessionType = SessionTypeItem.allTypes[2] // "fix-this-mess"
        vm.sessionType = sessionType.id
        #expect(vm.sessionType == "fix-this-mess")
    }

    @MainActor
    @Test("Default session type is say-it-clearly")
    func defaultSessionType() {
        let vm = ChatViewModel()
        #expect(vm.sessionType == "say-it-clearly")
    }
}
