import Foundation

nonisolated enum GalleryStoreError: Error, Equatable, Sendable {
    // No live painting has this id: it was never saved, or it was deleted.
    case notFound(UUID)
}
