import Foundation

nonisolated enum GalleryStoreError: Error, Equatable, Sendable {
    case notFound(UUID)
}
