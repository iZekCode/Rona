//
//  HandFrameRelay.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

// Passes hand positions to whichever page is listening; a page only stops its own listening.
final class HandFrameRelay {
    private var owner: AnyObject?
    private var listener: ((HandFrame) -> Void)?

    func listen(owner: AnyObject, _ listener: @escaping (HandFrame) -> Void) {
        self.owner = owner
        self.listener = listener
    }

    // Stops listening only if `owner` is still the one listening.
    func stopListening(owner: AnyObject) {
        guard self.owner === owner else { return }
        self.owner = nil
        listener = nil
    }

    func send(_ frame: HandFrame) { listener?(frame) }
}
