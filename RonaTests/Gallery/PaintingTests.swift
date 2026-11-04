import Foundation
import Testing
@testable import Rona

struct PaintingTests {
    @Test func newPaintingIsFreeformLiveAndHasNoRecording() {
        let p = Painting(paintedAt: Date(timeIntervalSince1970: 0))
        #expect(p.templateID == nil)
        #expect(!p.hasRecording)
        #expect(!p.isDeleted)
    }

    @Test func tombstoneMarksDeleted() {
        var p = Painting(paintedAt: Date(timeIntervalSince1970: 0))
        p.deletedAt = Date(timeIntervalSince1970: 10)
        #expect(p.isDeleted)
    }

    @Test func idsAreUnique() {
        let date = Date(timeIntervalSince1970: 0)
        #expect(Painting(paintedAt: date).id != Painting(paintedAt: date).id)
    }

    @Test func codableRoundTrip() throws {
        let p = Painting(templateID: "quest-rocket", paintedAt: Date(timeIntervalSince1970: 100), hasRecording: true)
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Painting.self, from: data) == p)
    }
}
