import Foundation

/// GhostMark records a tick that was not on the centered page. Tallies stay put.
struct GhostMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var pageTileID: UUID
    var centeredTileID: UUID
    var daykey: Int
    var sequence: Int

    init(
        id: UUID = UUID(),
        pageTileID: UUID,
        centeredTileID: UUID,
        daykey: Int,
        sequence: Int
    ) {
        self.id = id
        self.pageTileID = pageTileID
        self.centeredTileID = centeredTileID
        self.daykey = daykey
        self.sequence = sequence
    }
}
