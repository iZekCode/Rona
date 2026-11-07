//
//  ProfileRepository.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// The account's profile, which stores the parent's agreement.
nonisolated protocol ProfileRepository: Sendable {
    // Saves this agreement unless the profile already has this version or a newer one.
    func record(_ consent: ConsentRecord, for userID: UUID) async throws
}
