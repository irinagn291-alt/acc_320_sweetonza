import Foundation

/// TickMark records one centered tick that landed below brim and raised that tile.
struct TickMark: Codable, Equatable, Identifiable, Sendable {
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
