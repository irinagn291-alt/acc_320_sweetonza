import Foundation

/// Catch route sends brim overflow to one downstream tile. A closed route drips.
struct CatchRoute: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var fromTileID: UUID
    var toTileID: UUID
    var isOpen: Bool

    init(id: UUID = UUID(), fromTileID: UUID, toTileID: UUID, isOpen: Bool) {
        self.id = id
        self.fromTileID = fromTileID
        self.toTileID = toTileID
        self.isOpen = isOpen
    }
}
