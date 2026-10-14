import Foundation

/// Brim is the daily cap on one tile. A tick below this limit stays on the tile.
struct Brim: Codable, Equatable, Sendable {
    var limit: Int

    init(limit: Int) {
        self.limit = max(1, limit)
    }
}
