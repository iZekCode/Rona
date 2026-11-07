//
//  GalleryStoreError.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

nonisolated enum GalleryStoreError: Error, Equatable, Sendable {
    case notFound(UUID)
}
