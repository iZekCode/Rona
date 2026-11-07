import Foundation

// Why linking an Apple account failed, in terms the pages can show.
nonisolated enum AccountLinkError: Error, Equatable, Sendable {
    case alreadyUsed
}
