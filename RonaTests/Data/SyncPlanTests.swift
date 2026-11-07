//
//  SyncPlanTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Testing
@testable import Rona

struct SyncPlanTests {
    private func painting(_ seconds: TimeInterval = 100, deleted: Bool = false) -> Painting {
        Painting(paintedAt: Date(timeIntervalSince1970: seconds),
                 deletedAt: deleted ? Date(timeIntervalSince1970: seconds + 1) : nil)
    }

    private func local(_ painting: Painting, hasStats: Bool = false, _ sync: SyncState = SyncState()) -> LocalPaintingState {
        LocalPaintingState(painting: painting, hasStats: hasStats, sync: sync)
    }

    private func plan(local: [LocalPaintingState] = [], remote: [Painting] = []) -> [SyncAction] {
        SyncPlan.actions(local: local, remote: remote)
    }

    // MARK: sending

    @Test func aNewPaintingStartsWithItsImage() {
        let p = painting()
        #expect(plan(local: [local(p)]) == [.uploadImage(p.id)])
    }

    @Test func anImageStillOnItsWayIsLeftAlone() {
        let p = painting()
        #expect(plan(local: [local(p, SyncState(imageInFlight: true))]).isEmpty)
    }

    @Test func onceTheImageIsUpTheRowIsPushed() {
        let p = painting()
        #expect(plan(local: [local(p, SyncState(imageUploaded: true))]) == [.pushRow(p.id)])
    }

    @Test func theStatsFollowTheRowInTheSameRun() {
        let p = painting()
        let actions = plan(local: [local(p, hasStats: true, SyncState(imageUploaded: true))])
        #expect(actions == [.pushRow(p.id), .pushStats(p.id)])
    }

    @Test func stalePushedFlagsDoNotStopARowTheServerLacks() {
        let p = painting()
        let state = SyncState(imageUploaded: true, statsPushed: true)
        #expect(plan(local: [local(p, hasStats: true, state)]) == [.pushRow(p.id)])
    }

    @Test func statsAddedLaterAreSentForAPaintingTheServerHas() {
        let p = painting()
        let actions = plan(local: [local(p, hasStats: true, SyncState(imageUploaded: true))], remote: [p])
        #expect(actions == [.pushStats(p.id)])
    }

    @Test func aSyncedPaintingNeedsNothing() {
        let p = painting()
        let state = SyncState(imageUploaded: true, statsPushed: true)
        #expect(plan(local: [local(p, hasStats: true, state)], remote: [p]).isEmpty)
        #expect(plan(local: [local(p)], remote: [p]).isEmpty)
    }

    // MARK: deleting

    @Test func aDeleteIsPushedWhenTheServerHoldsThePaintingLive() {
        let p = painting(deleted: true)
        var theirs = p
        theirs.deletedAt = nil
        #expect(plan(local: [local(p)], remote: [theirs]) == [.pushTombstone(p.id)])
    }

    @Test func aDeleteOfAPaintingTheServerNeverSawNeedsNothing() {
        #expect(plan(local: [local(painting(deleted: true))]).isEmpty)
    }

    @Test func aDeleteTheServerAlreadyHasNeedsNothing() {
        let p = painting(deleted: true)
        #expect(plan(local: [local(p)], remote: [p]).isEmpty)
    }

    @Test func aDeleteFromAnotherDeviceIsAppliedHere() {
        let p = painting()
        var theirs = p
        theirs.deletedAt = Date(timeIntervalSince1970: 500)
        #expect(plan(local: [local(p)], remote: [theirs]) == [.applyRemoteTombstone(p.id)])
    }

    @Test func aDeleteWinsOverPendingUploads() {
        let p = painting()
        var theirs = p
        theirs.deletedAt = Date(timeIntervalSince1970: 500)
        let actions = plan(local: [local(p, hasStats: true)], remote: [theirs])
        #expect(actions == [.applyRemoteTombstone(p.id)])
    }

    // MARK: fetching

    @Test func aPaintingOnlyTheServerHasIsDownloaded() {
        let p = painting()
        #expect(plan(remote: [p]) == [.download(p.id)])
    }

    @Test func aTombstoneOnlyTheServerHasIsIgnored() {
        #expect(plan(remote: [painting(deleted: true)]).isEmpty)
    }

    @Test func downloadsComeNewestFirstAfterTheLocalWork() {
        let sending = painting(10)
        let old = painting(100)
        let new = painting(300)
        let actions = plan(local: [local(sending)], remote: [old, new])
        #expect(actions == [.uploadImage(sending.id), .download(new.id), .download(old.id)])
    }
}
