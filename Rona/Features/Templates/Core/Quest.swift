import Foundation

// The challenge of the day; its id is saved as the painting's templateID.
nonisolated struct Quest: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
}

// Picks the quest for a date without I/O, clock or randomness, so every child gets the same one.
nonisolated protocol QuestSource: Sendable {
    func quest(on date: Date) -> Quest
}
