//
//  StoragePathTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation
import Testing
@testable import Rona

struct StoragePathTests {
    @Test func pathIsLowercaseUserFolderThenPaintingPng() {
        let user = UUID(uuidString: "A1B2C3D4-0000-4000-8000-00000000ABCD")!
        let painting = UUID(uuidString: "FFFFFFFF-1111-4222-8333-444444444444")!

        let path = StoragePath.image(userID: user, paintingID: painting)

        #expect(path == "a1b2c3d4-0000-4000-8000-00000000abcd/ffffffff-1111-4222-8333-444444444444.png")
    }

    @Test func firstFolderMatchesWhatPostgresCallsTheUserId() {
        let user = UUID()
        let firstFolder = StoragePath.image(userID: user, paintingID: UUID()).split(separator: "/")[0]
        #expect(String(firstFolder) == user.uuidString.lowercased())
    }
}
