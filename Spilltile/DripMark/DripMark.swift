import Foundation

/// DripMark records a brim tick with no open catch. The tally does not move.
struct DripMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var tileID: UUID
    var daykey: Int
    var sequence: Int

    init(id: UUID = UUID(), tileID: UUID, daykey: Int, sequence: Int) {
        self.id = id
        self.tileID = tileID
        self.daykey = daykey
        self.sequence = sequence
    }
}
