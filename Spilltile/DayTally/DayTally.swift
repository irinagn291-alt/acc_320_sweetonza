import Foundation

/// DayTally is the stored count for one tile on one civil day. It is never a derived total.
struct DayTally: Codable, Equatable, Identifiable, Sendable {
    var tileID: UUID
    var daykey: Int
    var value: Int

    var id: String { "\(tileID.uuidString).\(daykey)" }

    init(tileID: UUID, daykey: Int, value: Int) {
        self.tileID = tileID
        self.daykey = daykey
        self.value = max(0, value)
    }
}

/// DaySnap logs the tally that elapsed when the civil day rolled. Delta is the negation of that value.
struct DaySnap: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var tileID: UUID
    var daykey: Int
    var delta: Int
    var sequence: Int

    init(id: UUID = UUID(), tileID: UUID, daykey: Int, delta: Int, sequence: Int) {
        self.id = id
        self.tileID = tileID
        self.daykey = daykey
        self.delta = delta
        self.sequence = sequence
    }
}

enum Daykey {
    /// YYYYMMDD from `calendar.startOfDay`, so daylight-saving edges share one key.
    static func make(from date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}
