import Foundation

/// RunoffLog is this app's count log: every tick, spill, drip, ghost, and day snap.
struct RunoffLog: Codable, Equatable, Sendable {
    var ticks: [TickMark]
    var spills: [SpillMark]
    var drips: [DripMark]
    var ghosts: [GhostMark]
    var snaps: [DaySnap]

    static let empty = RunoffLog(ticks: [], spills: [], drips: [], ghosts: [], snaps: [])
}

/// TrayDocument is the single Codable root. schemaVersion starts at 1.
struct TrayDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var tiles: [Tile]
    var catchRoutes: [CatchRoute]
    var tallies: [DayTally]
    var log: RunoffLog
    var nextSequence: Int
    var activeDaykey: Int

    static let empty = TrayDocument(
        schemaVersion: 1,
        tiles: [],
        catchRoutes: [],
        tallies: [],
        log: .empty,
        nextSequence: 1,
        activeDaykey: 0
    )

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case tiles
        case catchRoutes
        case tallies
        case log
        case nextSequence
        case activeDaykey
    }

    init(
        schemaVersion: Int,
        tiles: [Tile],
        catchRoutes: [CatchRoute],
        tallies: [DayTally],
        log: RunoffLog,
        nextSequence: Int,
        activeDaykey: Int
    ) {
        self.schemaVersion = schemaVersion
        self.tiles = tiles
        self.catchRoutes = catchRoutes
        self.tallies = tallies
        self.log = log
        self.nextSequence = nextSequence
        self.activeDaykey = activeDaykey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        switch version {
        case 1:
            schemaVersion = 1
            tiles = try container.decodeIfPresent([Tile].self, forKey: .tiles) ?? []
            catchRoutes = try container.decodeIfPresent([CatchRoute].self, forKey: .catchRoutes) ?? []
            tallies = try container.decodeIfPresent([DayTally].self, forKey: .tallies) ?? []
            log = try container.decodeIfPresent(RunoffLog.self, forKey: .log) ?? .empty
            nextSequence = try container.decodeIfPresent(Int.self, forKey: .nextSequence) ?? 1
            activeDaykey = try container.decodeIfPresent(Int.self, forKey: .activeDaykey) ?? 0
        default:
            throw TrayCodingError.unknownSchema(version)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(tiles, forKey: .tiles)
        try container.encode(catchRoutes, forKey: .catchRoutes)
        try container.encode(tallies, forKey: .tallies)
        try container.encode(log, forKey: .log)
        try container.encode(nextSequence, forKey: .nextSequence)
        try container.encode(activeDaykey, forKey: .activeDaykey)
    }
}

enum TrayCodingError: Error, Equatable {
    case unknownSchema(Int)
}

/// TrayFold is the spill-routing ADT. Bare is an empty tray, Flowing is a live tally, Dripping is a refused brim.
enum TrayFold: String, Codable, Equatable, Sendable {
    case bare
    case flowing
    case dripping
}

/// TrayEngine folds one daykey. Views call the store, and the store calls this type.
enum TrayEngine {
    static func fold(of document: TrayDocument) -> TrayFold {
        guard !document.tiles.isEmpty else { return .bare }
        let latestDrip = document.log.drips.map(\.sequence).max() ?? -1
        let latestTick = document.log.ticks.map(\.sequence).max() ?? -1
        let latestSpill = document.log.spills.map(\.sequence).max() ?? -1
        if latestDrip > latestTick && latestDrip > latestSpill {
            return .dripping
        }
        return .flowing
    }

    static func tally(in document: TrayDocument, tileID: UUID, daykey: Int) -> Int {
        document.tallies.first { $0.tileID == tileID && $0.daykey == daykey }?.value ?? 0
    }

    static func tick(
        _ document: TrayDocument,
        centeredTileID: UUID,
        pageTileID: UUID,
        on date: Date,
        calendar: Calendar = .current
    ) -> TrayDocument {
        var next = document
        let daykey = Daykey.make(from: date, calendar: calendar)
        roll(&next, to: daykey)
        guard !next.tiles.isEmpty else { return next }
        guard next.tiles.contains(where: { $0.id == pageTileID }) else { return next }
        guard next.tiles.contains(where: { $0.id == centeredTileID }) else { return next }
        if pageTileID != centeredTileID {
            let sequence = claim(&next)
            next.log.ghosts.append(
                GhostMark(
                    pageTileID: pageTileID,
                    centeredTileID: centeredTileID,
                    daykey: daykey,
                    sequence: sequence
                )
            )
            return next
        }
        guard let tile = next.tiles.first(where: { $0.id == centeredTileID }) else { return next }
        let current = tally(in: next, tileID: centeredTileID, daykey: daykey)
        if current < tile.brim.limit {
            let sequence = claim(&next)
            next.log.ticks.append(
                TickMark(tileID: centeredTileID, daykey: daykey, sequence: sequence)
            )
            applyDelta(&next, tileID: centeredTileID, daykey: daykey, delta: 1)
            return next
        }
        if let catchID = openCatch(in: next, from: centeredTileID) {
            let sequence = claim(&next)
            next.log.spills.append(
                SpillMark(
                    sourceTileID: centeredTileID,
                    catchTileID: catchID,
                    daykey: daykey,
                    sequence: sequence
                )
            )
            applyDelta(&next, tileID: catchID, daykey: daykey, delta: 1)
            return next
        }
        let sequence = claim(&next)
        next.log.drips.append(
            DripMark(tileID: centeredTileID, daykey: daykey, sequence: sequence)
        )
        return next
    }

    static func peel(
        _ document: TrayDocument,
        on date: Date,
        calendar: Calendar = .current
    ) -> TrayDocument {
        var next = document
        let daykey = Daykey.make(from: date, calendar: calendar)
        roll(&next, to: daykey)
        let tick = next.log.ticks.filter { $0.daykey == daykey }.max { $0.sequence < $1.sequence }
        let spill = next.log.spills.filter { $0.daykey == daykey }.max { $0.sequence < $1.sequence }
        switch (tick, spill) {
        case let (tick?, spill?) where spill.sequence > tick.sequence:
            next.log.spills.removeAll { $0.id == spill.id }
            applyDelta(&next, tileID: spill.catchTileID, daykey: daykey, delta: -1)
        case let (tick?, _):
            next.log.ticks.removeAll { $0.id == tick.id }
            applyDelta(&next, tileID: tick.tileID, daykey: daykey, delta: -1)
        case let (nil, spill?):
            next.log.spills.removeAll { $0.id == spill.id }
            applyDelta(&next, tileID: spill.catchTileID, daykey: daykey, delta: -1)
        case (nil, nil):
            break
        }
        return next
    }

    static func resetDay(_ document: TrayDocument, tileID: UUID, daykey: Int) -> TrayDocument {
        var next = document
        let current = tally(in: next, tileID: tileID, daykey: daykey)
        guard current > 0 else { return next }
        let sequence = claim(&next)
        next.log.snaps.append(
            DaySnap(tileID: tileID, daykey: daykey, delta: -current, sequence: sequence)
        )
        applyDelta(&next, tileID: tileID, daykey: daykey, delta: -current)
        return next
    }

    static func alignDay(
        _ document: TrayDocument,
        on date: Date,
        calendar: Calendar = .current
    ) -> TrayDocument {
        var next = document
        roll(&next, to: Daykey.make(from: date, calendar: calendar))
        return next
    }

    static func addTile(_ document: TrayDocument, title: String, brim: Int) -> TrayDocument {
        var next = document
        let tile = Tile(title: title, brim: Brim(limit: brim))
        next.tiles.append(tile)
        return next
    }

    static func renameTile(_ document: TrayDocument, tileID: UUID, title: String) -> TrayDocument {
        var next = document
        guard let index = next.tiles.firstIndex(where: { $0.id == tileID }) else { return next }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return next }
        next.tiles[index].title = trimmed
        return next
    }

    static func setBrim(_ document: TrayDocument, tileID: UUID, limit: Int) -> TrayDocument {
        var next = document
        guard let index = next.tiles.firstIndex(where: { $0.id == tileID }) else { return next }
        next.tiles[index].brim = Brim(limit: limit)
        return next
    }

    static func setCatch(
        _ document: TrayDocument,
        from source: UUID,
        to target: UUID?,
        open: Bool
    ) -> TrayDocument {
        var next = document
        next.catchRoutes.removeAll { $0.fromTileID == source }
        if let target, target != source, next.tiles.contains(where: { $0.id == target }) {
            next.catchRoutes.append(
                CatchRoute(fromTileID: source, toTileID: target, isOpen: open)
            )
        }
        return next
    }

    static func demoDocument(on date: Date, calendar: Calendar = .current) -> TrayDocument {
        let calls = Tile(title: "Calls", brim: Brim(limit: 4))
        let inbox = Tile(title: "Inbox", brim: Brim(limit: 6))
        let errands = Tile(title: "Errands", brim: Brim(limit: 3))
        let daykey = Daykey.make(from: date, calendar: calendar)
        var log = RunoffLog.empty
        log.ticks = (1...3).map { sequence in
            TickMark(tileID: calls.id, daykey: daykey, sequence: sequence)
        }
        return TrayDocument(
            schemaVersion: 1,
            tiles: [calls, inbox, errands],
            catchRoutes: [
                CatchRoute(fromTileID: calls.id, toTileID: inbox.id, isOpen: true)
            ],
            tallies: [DayTally(tileID: calls.id, daykey: daykey, value: 3)],
            log: log,
            nextSequence: 4,
            activeDaykey: daykey
        )
    }

    private static func roll(_ document: inout TrayDocument, to daykey: Int) {
        if document.activeDaykey == 0 {
            document.activeDaykey = daykey
            return
        }
        guard daykey > document.activeDaykey else { return }
        let elapsed = document.activeDaykey
        let rows = document.tallies.filter { $0.daykey == elapsed && $0.value > 0 }
        for row in rows {
            let sequence = claim(&document)
            document.log.snaps.append(
                DaySnap(tileID: row.tileID, daykey: elapsed, delta: -row.value, sequence: sequence)
            )
        }
        document.activeDaykey = daykey
    }

    private static func openCatch(in document: TrayDocument, from source: UUID) -> UUID? {
        guard let route = document.catchRoutes.first(where: { $0.fromTileID == source && $0.isOpen }) else {
            return nil
        }
        guard route.toTileID != source else { return nil }
        guard document.tiles.contains(where: { $0.id == route.toTileID }) else { return nil }
        return route.toTileID
    }

    private static func claim(_ document: inout TrayDocument) -> Int {
        let sequence = document.nextSequence
        document.nextSequence += 1
        return sequence
    }

    /// Holds every tally at max(0, value + delta). Missing rows appear only for a positive delta.
    private static func applyDelta(
        _ document: inout TrayDocument,
        tileID: UUID,
        daykey: Int,
        delta: Int
    ) {
        if let index = document.tallies.firstIndex(where: { $0.tileID == tileID && $0.daykey == daykey }) {
            let updated = max(0, document.tallies[index].value + delta)
            document.tallies[index].value = updated
            return
        }
        guard delta > 0 else { return }
        document.tallies.append(DayTally(tileID: tileID, daykey: daykey, value: delta))
    }
}
