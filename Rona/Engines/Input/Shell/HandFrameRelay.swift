// Passes hand frames to the listening page outside the canvas; a page drops only its own listener.
final class HandFrameRelay {
    private var owner: AnyObject?
    private var listener: ((HandFrame) -> Void)?

    func listen(owner: AnyObject, _ listener: @escaping (HandFrame) -> Void) {
        self.owner = owner
        self.listener = listener
    }

    // Drops the listener only if `owner` still holds it.
    func stopListening(owner: AnyObject) {
        guard self.owner === owner else { return }
        self.owner = nil
        listener = nil
    }

    func send(_ frame: HandFrame) { listener?(frame) }
}
