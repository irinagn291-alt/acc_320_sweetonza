import Foundation

/// Tile is this app's counter. Identity is stable so lists never use row index.
struct Tile: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var brim: Brim

    init(id: UUID = UUID(), title: String, brim: Brim) {
        self.id = id
        self.title = title
        self.brim = brim
    }
}
