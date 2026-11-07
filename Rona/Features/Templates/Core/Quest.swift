//
//  Quest.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// Today's challenge; its id is saved with the painting.
nonisolated struct Quest: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
}

// Picks the challenge for a date, the same for every child.
nonisolated protocol QuestSource: Sendable {
    func quest(on date: Date) -> Quest
}
