import XCTest
@testable import Spilltile

final class SpilltileTests: XCTestCase {
    private var suiteName = ""

    override func setUp() {
        super.setUp()
        suiteName = "spt.tests.\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testReviewLaunchParsesScreenKey() {
        XCTAssertEqual(ReviewLaunch.screen(from: ["Spilltile", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Spilltile", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Spilltile", "-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Spilltile", "-ReviewScreen", "settings"]), "settings")
        XCTAssertNil(ReviewLaunch.screen(from: ["Spilltile"]))
        XCTAssertNil(ReviewLaunch.screen(from: ["Spilltile", "-ReviewScreen"]))
    }

    func testEmptyTrayStaysBare() {
        let document = TrayEngine.tick(
            .empty,
            centeredTileID: UUID(),
            pageTileID: UUID(),
            on: Date(),
            calendar: utc
        )
        XCTAssertEqual(TrayEngine.fold(of: document), .bare)
        XCTAssertTrue(document.log.ticks.isEmpty)
        XCTAssertTrue(document.tallies.isEmpty)
    }

    func testTickBelowBrimLogsAndIncrements() throws {
        let fixture = try pair()
        let ticked = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.source,
            on: fixture.day,
            calendar: utc
        )
        XCTAssertEqual(TrayEngine.tally(in: ticked, tileID: fixture.source, daykey: fixture.daykey), 1)
        XCTAssertEqual(ticked.log.ticks.count, 1)
        XCTAssertEqual(TrayEngine.fold(of: ticked), .flowing)
        XCTAssertTrue(ticked.log.spills.isEmpty)
    }

    func testSpillRoutesOnceToOpenCatch() throws {
        let fixture = try pair(sourceBrim: 1, sourceValue: 1, catchBrim: 1, catchValue: 1)
        let spilled = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.source,
            on: fixture.day,
            calendar: utc
        )
        XCTAssertEqual(TrayEngine.tally(in: spilled, tileID: fixture.source, daykey: fixture.daykey), 1)
        XCTAssertEqual(TrayEngine.tally(in: spilled, tileID: fixture.catchTile, daykey: fixture.daykey), 2)
        XCTAssertEqual(spilled.log.spills.count, 1)
        XCTAssertTrue(spilled.log.drips.isEmpty)
        XCTAssertEqual(TrayEngine.fold(of: spilled), .flowing)
    }

    func testClosedCatchWritesDripAndRefusesIncrement() throws {
        let fixture = try pair(sourceBrim: 2, sourceValue: 2, openCatch: false)
        let dripped = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.source,
            on: fixture.day,
            calendar: utc
        )
        XCTAssertEqual(TrayEngine.tally(in: dripped, tileID: fixture.source, daykey: fixture.daykey), 2)
        XCTAssertEqual(TrayEngine.tally(in: dripped, tileID: fixture.catchTile, daykey: fixture.daykey), 0)
        XCTAssertEqual(dripped.log.drips.count, 1)
        XCTAssertEqual(TrayEngine.fold(of: dripped), .dripping)
    }

    func testOffCenterTickWritesGhost() throws {
        let fixture = try pair()
        let ghosted = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.catchTile,
            on: fixture.day,
            calendar: utc
        )
        XCTAssertEqual(ghosted.log.ghosts.count, 1)
        XCTAssertEqual(TrayEngine.tally(in: ghosted, tileID: fixture.source, daykey: fixture.daykey), 0)
        XCTAssertTrue(ghosted.log.ticks.isEmpty)
        XCTAssertEqual(TrayEngine.fold(of: ghosted), .flowing)
    }

    func testMissingTileIsIgnored() throws {
        let fixture = try pair()
        let ignored = TrayEngine.tick(
            fixture.document,
            centeredTileID: UUID(),
            pageTileID: fixture.source,
            on: fixture.day,
            calendar: utc
        )
        XCTAssertEqual(ignored.log.ticks.count, 0)
        XCTAssertEqual(ignored.tallies, fixture.document.tallies)
    }

    func testPeelReversesLastTickOrSpillAndClampsAtZero() throws {
        let fixture = try pair()
        let ticked = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.source,
            on: fixture.day,
            calendar: utc
        )
        let peeled = TrayEngine.peel(ticked, on: fixture.day, calendar: utc)
        XCTAssertEqual(TrayEngine.tally(in: peeled, tileID: fixture.source, daykey: fixture.daykey), 0)
        XCTAssertTrue(peeled.log.ticks.isEmpty)

        let atBrim = try pair(sourceBrim: 1, sourceValue: 1)
        let spilled = TrayEngine.tick(
            atBrim.document,
            centeredTileID: atBrim.source,
            pageTileID: atBrim.source,
            on: atBrim.day,
            calendar: utc
        )
        let unspilled = TrayEngine.peel(spilled, on: atBrim.day, calendar: utc)
        XCTAssertEqual(TrayEngine.tally(in: unspilled, tileID: atBrim.catchTile, daykey: atBrim.daykey), 0)
        XCTAssertTrue(unspilled.log.spills.isEmpty)

        let clamped = TrayEngine.peel(unspilled, on: atBrim.day, calendar: utc)
        XCTAssertEqual(TrayEngine.tally(in: clamped, tileID: atBrim.source, daykey: atBrim.daykey), 1)
        XCTAssertGreaterThanOrEqual(
            TrayEngine.tally(in: clamped, tileID: atBrim.source, daykey: atBrim.daykey),
            0
        )
    }

    func testInvariantClampsManualUnderflow() throws {
        let fixture = try pair(sourceValue: 0)
        var logged = fixture.document
        logged.log.spills = [
            SpillMark(
                sourceTileID: fixture.source,
                catchTileID: fixture.catchTile,
                daykey: fixture.daykey,
                sequence: 1
            )
        ]
        logged.nextSequence = 2
        let peeled = TrayEngine.peel(logged, on: fixture.day, calendar: utc)
        let value = TrayEngine.tally(in: peeled, tileID: fixture.catchTile, daykey: fixture.daykey)
        XCTAssertEqual(value, max(0, 0 + -1))
        XCTAssertEqual(value, 0)
    }

    func testDayElapsedSnapsLiveCountAndLogsNegativeOld() throws {
        let fixture = try pair(sourceValue: 4)
        let later = try XCTUnwrap(utc.date(byAdding: .day, value: 1, to: fixture.day))
        let rolled = TrayEngine.tick(
            fixture.document,
            centeredTileID: fixture.source,
            pageTileID: fixture.source,
            on: later,
            calendar: utc
        )
        let newKey = Daykey.make(from: later, calendar: utc)
        XCTAssertEqual(TrayEngine.tally(in: rolled, tileID: fixture.source, daykey: newKey), 1)
        XCTAssertEqual(TrayEngine.tally(in: rolled, tileID: fixture.source, daykey: fixture.daykey), 4)
        let snap = try XCTUnwrap(rolled.log.snaps.first)
        XCTAssertEqual(snap.delta, -4)
        XCTAssertEqual(snap.daykey, fixture.daykey)
    }

    func testFoldBareWhenTrayHasNoTiles() {
        XCTAssertEqual(TrayEngine.fold(of: .empty), .bare)
    }

    @MainActor
    func testPersistenceRoundTripAndReset() async throws {
        let store = TrayStore(suiteName: suiteName)
        store.addTile(title: "Calls", brim: 4)
        await store.flush()
        let relaunch = TrayStore(suiteName: suiteName)
        await relaunch.reload()
        XCTAssertEqual(relaunch.document.tiles.map(\.title), ["Calls"])
        XCTAssertEqual(relaunch.document.schemaVersion, 1)
        await relaunch.resetAllData()
        XCTAssertTrue(relaunch.document.tiles.isEmpty)
        let present = await relaunch.trayKeyPresent()
        XCTAssertFalse(present)
        let again = TrayStore(suiteName: suiteName)
        await again.reload()
        XCTAssertTrue(again.document.tiles.isEmpty)
    }

    @MainActor
    func testCorruptRecordFallsBackThenEmpties() async throws {
        let store = TrayStore(suiteName: suiteName)
        store.addTile(title: "Inbox", brim: 3)
        await store.flush()
        store.addTile(title: "Errands", brim: 2)
        await store.flush()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(Data("{\"schemaVersion\":99}".utf8), forKey: TrayVault.trayKey)
        let restored = TrayStore(suiteName: suiteName)
        await restored.reload()
        XCTAssertEqual(restored.document.tiles.map(\.title), ["Inbox"])
        XCTAssertNotNil(restored.recoveryNote)

        defaults.set(Data("{\"schemaVersion\":99}".utf8), forKey: TrayVault.trayKey)
        defaults.set(Data("{\"schemaVersion\":0}".utf8), forKey: TrayVault.backupKey)
        let emptied = TrayStore(suiteName: suiteName)
        await emptied.reload()
        XCTAssertTrue(emptied.document.tiles.isEmpty)
        XCTAssertNotNil(emptied.recoveryNote)
    }

    @MainActor
    func testDemoSeedNeverWritesWhenNotSimulator() async {
        let store = TrayStore(suiteName: suiteName)
        await store.installDemoSeed(runningOnSimulator: false)
        XCTAssertTrue(store.document.tiles.isEmpty)
        let flagged = await store.demoFlag()
        XCTAssertFalse(flagged)
    }

    @MainActor
    func testDemoSeedSeatsOpeningTick() async throws {
        let store = TrayStore(suiteName: suiteName)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        await store.installDemoSeed(runningOnSimulator: true, on: day)
        XCTAssertEqual(store.document.tiles.count, 3)
        let centered = try XCTUnwrap(store.document.tiles.first)
        let daykey = Daykey.make(from: day)
        let value = TrayEngine.tally(in: store.document, tileID: centered.id, daykey: daykey)
        XCTAssertEqual(value, centered.brim.limit - 1)
        XCTAssertTrue(store.onboardingComplete)
        let flagged = await store.demoFlag()
        XCTAssertTrue(flagged)
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private struct Pair {
        var document: TrayDocument
        var source: UUID
        var catchTile: UUID
        var day: Date
        var daykey: Int
    }

    private func pair(
        sourceBrim: Int = 4,
        sourceValue: Int = 0,
        catchBrim: Int = 5,
        catchValue: Int = 0,
        openCatch: Bool = true
    ) throws -> Pair {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let daykey = Daykey.make(from: day, calendar: utc)
        let source = Tile(title: "Calls", brim: Brim(limit: sourceBrim))
        let catchTile = Tile(title: "Inbox", brim: Brim(limit: catchBrim))
        var tallies: [DayTally] = []
        if sourceValue > 0 {
            tallies.append(DayTally(tileID: source.id, daykey: daykey, value: sourceValue))
        }
        if catchValue > 0 {
            tallies.append(DayTally(tileID: catchTile.id, daykey: daykey, value: catchValue))
        }
        let document = TrayDocument(
            schemaVersion: 1,
            tiles: [source, catchTile],
            catchRoutes: [
                CatchRoute(fromTileID: source.id, toTileID: catchTile.id, isOpen: openCatch)
            ],
            tallies: tallies,
            log: .empty,
            nextSequence: 1,
            activeDaykey: daykey
        )
        return Pair(document: document, source: source.id, catchTile: catchTile.id, day: day, daykey: daykey)
    }
}
