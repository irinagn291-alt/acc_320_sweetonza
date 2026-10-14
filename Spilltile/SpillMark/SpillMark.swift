import Foundation

/// SpillMark records overflow from a tile at brim into its open catch. One hop only.
struct SpillMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var sourceTileID: UUID
    var catchTileID: UUID
    var daykey: Int
    var sequence: Int

    init(
        id: UUID = UUID(),
        sourceTileID: UUID,
        catchTileID: UUID,
        daykey: Int,
        sequence: Int
    ) {
        self.id = id
        self.sourceTileID = sourceTileID
        self.catchTileID = catchTileID
        self.daykey = daykey
        self.sequence = sequence
    }
}
