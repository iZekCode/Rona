//
//  PaintingRowTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Testing
@testable import Rona

struct PaintingRowTests {
    private let user = UUID()
    private let date = Date(timeIntervalSince1970: 1_762_300_000)

    @Test func rowCarriesThePaintingAndItsImagePath() {
        let painting = Painting(templateID: "cat", paintedAt: date)

        let row = PaintingRow(painting, userID: user)

        #expect(row.id == painting.id)
        #expect(row.userID == user)
        #expect(row.templateID == "cat")
        #expect(row.paintedAt == date)
        #expect(row.imagePath == StoragePath.image(userID: user, paintingID: painting.id))
    }

    @Test func jsonUsesTheColumnNamesAndLeavesNilColumnsOut() throws {
        let painting = Painting(paintedAt: date)
        let data = try JSONEncoder().encode(PaintingRow(painting, userID: user))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(json.keys) == ["id", "user_id", "painted_at", "image_path"])
    }

    @Test func rowFromTheServerBecomesAPainting() throws {
        let id = UUID()
        let json = """
        {"id":"\(id.uuidString)","user_id":"\(user.uuidString)","template_id":"fish","painted_at":"2025-11-04T23:46:40Z",
         "image_path":"x/y.png","recording_path":null,"deleted_at":"2025-11-05T00:00:00Z"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let painting = try decoder.decode(PaintingRow.self, from: Data(json.utf8)).painting

        #expect(painting.id == id)
        #expect(painting.templateID == "fish")
        #expect(painting.paintedAt == date)
        #expect(painting.isDeleted)
        #expect(!painting.hasRecording)
    }

    @Test func aRecordingPathMeansTheRowHasARecording() throws {
        let json = """
        {"id":"\(UUID().uuidString)","user_id":"\(user.uuidString)","painted_at":"2025-11-04T23:46:40Z",
         "image_path":"x/y.png","recording_path":"x/y.rec"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(try decoder.decode(PaintingRow.self, from: Data(json.utf8)).painting.hasRecording)
    }
}
