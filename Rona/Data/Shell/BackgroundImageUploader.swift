import Foundation

// Uploads PNGs through a background URLSession; results wait in `pending` until onFinish is set.
nonisolated final class BackgroundImageUploader: NSObject, ImageUploader, URLSessionTaskDelegate, @unchecked Sendable {
    static let sessionIdentifier = "LittleCrew.Rona.image-upload"

    struct Credentials: Sendable {
        let userID: UUID
        let accessToken: String
    }

    private let baseURL: URL
    private let apiKey: String
    private let credentials: @Sendable () async throws -> Credentials

    private let lock = NSLock()
    private var handler: (@Sendable (Painting.ID, Bool) -> Void)?
    private var pending: [(Painting.ID, Bool)] = []
    private var systemCompletion: (@MainActor @Sendable () -> Void)?

    nonisolated(unsafe) private var session: URLSession!

    // A test passes its own `identifier`, so it never meets the app's session.
    init(baseURL: URL, apiKey: String, identifier: String = BackgroundImageUploader.sessionIdentifier,
         credentials: @escaping @Sendable () async throws -> Credentials) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.credentials = credentials
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // Sets the finish handler and delivers anything that finished earlier.
    func setOnFinish(_ handler: @escaping @Sendable (Painting.ID, Bool) -> Void) {
        lock.lock()
        self.handler = handler
        let waiting = pending
        pending = []
        lock.unlock()
        for (id, success) in waiting { handler(id, success) }
    }

    // Called by the app delegate when the system relaunches the app for this session.
    func handleSystemEvents(completion: @escaping @MainActor @Sendable () -> Void) {
        lock.lock()
        systemCompletion = completion
        lock.unlock()
    }

    // MARK: ImageUploader

    func start(paintingID: Painting.ID, fileURL: URL) async throws {
        let credentials = try await credentials()
        let path = StoragePath.image(userID: credentials.userID, paintingID: paintingID)
        var request = URLRequest(url: baseURL.appending(path: "storage/v1/object/paintings/\(path)"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.taskDescription = paintingID.uuidString
        task.resume()
    }

    func activePaintingIDs() async -> Set<Painting.ID> {
        let tasks = await session.allTasks
        return Set(tasks.filter { $0.state == .running || $0.state == .suspended }
            .compactMap { $0.taskDescription.flatMap(UUID.init(uuidString:)) })
    }

    // MARK: URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let id = task.taskDescription.flatMap(UUID.init(uuidString:)) else { return }
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let success = error == nil && (200..<300).contains(status)
        lock.lock()
        let handler = handler
        if handler == nil { pending.append((id, success)) }
        lock.unlock()
        handler?(id, success)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let completion = systemCompletion
        systemCompletion = nil
        lock.unlock()
        guard let completion else { return }
        Task { @MainActor in completion() }
    }
}
