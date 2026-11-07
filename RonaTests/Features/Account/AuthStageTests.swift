import Foundation
import Testing
@testable import Rona

@MainActor
struct AuthStageTests {
    private struct Offline: Error {}

    private let userID = UUID()
    private let agreement = ConsentRecord(acceptedAt: Date(timeIntervalSince1970: 1_000), version: 1)

    private var anonymous: AuthState { .signedIn(userID: userID, isAnonymous: true) }

    private func makeStage(
        restored: Result<AuthState, Error> = .success(.signedOut),
        signedIn: Result<AuthState, Error>? = nil,
        profileFails: Bool = false
    ) -> (AuthStage, FakeAuth, FakeProfiles) {
        let service = FakeAuth(restored: restored, signedIn: signedIn ?? .success(anonymous))
        let profiles = FakeProfiles(fails: profileFails)
        return (AuthStage(service: service, profiles: profiles), service, profiles)
    }

    @Test func nothingHappensBeforeConsent() async {
        let (stage, service, profiles) = makeStage()

        await stage.start(agreement: nil)

        #expect(stage.state == .signedOut)
        #expect(await service.restoreCalls == 0)
        #expect(await service.signInCalls == 0)
        #expect(await profiles.recorded.isEmpty)
    }

    @Test func consentWithoutASessionSignsInAnonymouslyAndRecordsTheConsent() async {
        let (stage, service, profiles) = makeStage()

        await stage.start(agreement: agreement)

        #expect(stage.state == anonymous)
        #expect(await service.signInCalls == 1)
        #expect(await profiles.recorded == [.init(userID: userID, consent: agreement)])
        #expect(!stage.failed)
    }

    @Test func aSavedSessionIsRestoredWithoutANewSignIn() async {
        let saved = AuthState.signedIn(userID: userID, isAnonymous: false)
        let (stage, service, profiles) = makeStage(restored: .success(saved))

        await stage.start(agreement: agreement)

        #expect(stage.state == saved)
        #expect(await service.signInCalls == 0)
        #expect(await profiles.recorded.count == 1)
    }

    @Test func aFailedRestoreDoesNotCreateANewAnonymousUser() async {
        let (stage, service, profiles) = makeStage(restored: .failure(Offline()))

        await stage.start(agreement: agreement)

        #expect(stage.state == .signedOut)
        #expect(stage.failed)
        #expect(await service.signInCalls == 0)
        #expect(await profiles.recorded.isEmpty)
    }

    @Test func aFailedSignInIsReportedAndCanBeRetried() async {
        let (stage, service, profiles) = makeStage(signedIn: .failure(Offline()))

        await stage.start(agreement: agreement)
        #expect(stage.state == .signedOut)
        #expect(stage.failed)

        await service.setSignIn(.success(anonymous))
        await stage.start(agreement: agreement)
        #expect(stage.state == anonymous)
        #expect(!stage.failed)
        #expect(await profiles.recorded.count == 1)
    }

    @Test func aFailedProfileWriteKeepsTheSignInAndRetriesTheWriteOnly() async {
        let (stage, service, profiles) = makeStage(profileFails: true)

        await stage.start(agreement: agreement)
        #expect(stage.state == anonymous)
        #expect(stage.failed)

        await profiles.setFails(false)
        await stage.start(agreement: agreement)
        #expect(!stage.failed)
        #expect(await service.signInCalls == 1)
        #expect(await profiles.recorded.count == 1)
    }

    @Test func startingAgainWithTheSameConsentDoesNothing() async {
        let (stage, service, profiles) = makeStage()

        await stage.start(agreement: agreement)
        await stage.start(agreement: agreement)

        #expect(await service.signInCalls == 1)
        #expect(await service.restoreCalls == 1)
        #expect(await profiles.recorded.count == 1)
    }

    @Test func theStageIsReadyOnlyOnceSignedInAndTheProfileIsRecorded() async {
        let (stage, _, profiles) = makeStage(profileFails: true)
        #expect(!stage.isReady)

        await stage.start(agreement: agreement)
        #expect(!stage.isReady)               // signed in, but the consent is not on the profile yet

        await profiles.setFails(false)
        await stage.start(agreement: agreement)
        #expect(stage.isReady)
    }

    @Test func theStageIsNotReadyWithoutASession() async {
        let (stage, _, _) = makeStage(restored: .failure(Offline()))

        await stage.start(agreement: agreement)

        #expect(!stage.isReady)
    }

    @Test func linkingAppleKeepsTheSameUserAndMarksItNotAnonymous() async throws {
        let (stage, service, _) = makeStage()
        await stage.start(agreement: agreement)
        await service.setLink(.success(.signedIn(userID: userID, isAnonymous: false)))

        try await stage.linkApple(idToken: "token", nonce: "nonce")

        #expect(stage.state == .signedIn(userID: userID, isAnonymous: false))
        #expect(await service.linked == [.init(idToken: "token", nonce: "nonce")])
    }

    @Test func linkingAnAppleAccountThatIsTakenFailsAndKeepsTheAnonymousUser() async {
        let (stage, service, _) = makeStage()
        await stage.start(agreement: agreement)
        await service.setLink(.failure(AccountLinkError.alreadyUsed))

        await #expect(throws: AccountLinkError.alreadyUsed) {
            try await stage.linkApple(idToken: "token", nonce: "nonce")
        }
        #expect(stage.state == anonymous)
    }

    @Test func aNewConsentVersionIsRecordedWithoutSigningInAgain() async {
        let (stage, service, profiles) = makeStage()
        await stage.start(agreement: agreement)

        let newer = ConsentRecord(acceptedAt: Date(timeIntervalSince1970: 2_000), version: 2)
        await stage.start(agreement: newer)

        #expect(await service.signInCalls == 1)
        #expect(await profiles.recorded.map(\.consent) == [agreement, newer])
    }
}

// A sign-in service that answers with what the test gives it and counts the calls.
actor FakeAuth: AuthService {
    private let restored: Result<AuthState, Error>
    private var signedIn: Result<AuthState, Error>
    private(set) var restoreCalls = 0
    private(set) var signInCalls = 0

    init(restored: Result<AuthState, Error>, signedIn: Result<AuthState, Error>) {
        self.restored = restored
        self.signedIn = signedIn
    }

    struct Link: Equatable {
        let idToken: String
        let nonce: String
    }

    private var linkResult: Result<AuthState, Error> = .failure(URLError(.badServerResponse))
    private(set) var linked: [Link] = []

    func setSignIn(_ result: Result<AuthState, Error>) { signedIn = result }
    func setLink(_ result: Result<AuthState, Error>) { linkResult = result }

    func restore() async throws -> AuthState {
        restoreCalls += 1
        return try restored.get()
    }

    func signInAnonymously() async throws -> AuthState {
        signInCalls += 1
        return try signedIn.get()
    }

    func linkApple(idToken: String, nonce: String) async throws -> AuthState {
        linked.append(Link(idToken: idToken, nonce: nonce))
        return try linkResult.get()
    }
}

// A profile store that remembers what it was asked to record.
actor FakeProfiles: ProfileRepository {
    struct Entry: Equatable {
        let userID: UUID
        let consent: ConsentRecord
    }

    private var fails: Bool
    private(set) var recorded: [Entry] = []

    init(fails: Bool = false) { self.fails = fails }

    func setFails(_ value: Bool) { fails = value }

    func record(_ consent: ConsentRecord, for userID: UUID) async throws {
        if fails { throw URLError(.notConnectedToInternet) }
        recorded.append(Entry(userID: userID, consent: consent))
    }
}
