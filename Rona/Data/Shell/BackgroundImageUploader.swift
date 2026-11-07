import Foundation

// Sends a painting's PNG to Storage through a background URLSession: the system keeps the upload going
// when the app is closed, and relaunches the app to report the result. The request is the plain Storage
// upload (POST of the raw PNG with the user's token and x-upsert), so a repeated upload just replaces the file.
//
// Results come back through `onFinish`. They may arrive before the engine has set it (after a relaunch),
// so they wait in `pending` until it is set.
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

    // Set once in init, after super.init, because the delegate is self.
    nonisolated(unsafe) private var session: URLSession!

    // `identifier` names the system's session; a test uses its own so it does not meet the app's session.
    init(baseURL: URL, apiKey: String, identifier: String = BackgroundImageUploader.sessionIdentifier,
         credentials: @escaping @Sendable () async throws -> Credentials) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.credentials = credentials
        super.init()
        // Creating the session now reattaches the tasks the system kept while the app was not running.
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // The engine's way to hear about finished uploads. Anything that finished earlier is delivered now.
    func setOnFinish(_ handler: @escaping @Sendable (Painting.ID, Bool) -> Void) {
        lock.lock()
        self.handler = handler
        let waiting = pending
        pending = []
        lock.unlock()
        for (id, success) in waiting { handler(id, success) }
    }

    // From the app delegate: the system relaunched the app for this session and wants a call when the
    // events have been handled.
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
