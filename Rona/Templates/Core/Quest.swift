import Foundation

/// The challenge of the day. The outline art is added when the quest pool is ported (chunk D2).
nonisolated struct Quest: Equatable, Identifiable, Sendable {
    /// Stable id such as `quest-rocket`; saved as `Painting.templateID`.
    let id: String
    let title: String
}

/// Picks the quest for a date. Pure: no clock, randomness or I/O, so every child gets the same quest.
nonisolated protocol QuestSource: Sendable {
    func quest(on date: Date) -> Quest
}
