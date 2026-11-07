import Foundation

// Why linking an Apple account failed, in terms the pages can show.
nonisolated enum AccountLinkError: Error, Equatable, Sendable {
    // This Apple account is already linked to another account, for example one made on an earlier iPad.
    case alreadyUsed
}
