import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #332848
    static let bg = Color(red: 0.200000, green: 0.156863, blue: 0.282353)
    static let bgHex = "#332848"
    /// #423857
    static let surface = Color(red: 0.258824, green: 0.219608, blue: 0.341176)
    static let surfaceHex = "#423857"
    /// #F4F4F6
    static let ink = Color(red: 0.956863, green: 0.956863, blue: 0.964706)
    static let inkHex = "#F4F4F6"
    /// #9673DE
    static let accent = Color(red: 0.588235, green: 0.450980, blue: 0.870588)
    static let accentHex = "#9673DE"
    /// #BAB6C3
    static let muted = Color(red: 0.729412, green: 0.713725, blue: 0.764706)
    static let mutedHex = "#BAB6C3"
    static let fontFamily = "Trebuchet MS"
    static let fontBold = "TrebuchetMS-Bold"

    enum Space {
        static let unit: CGFloat = 8
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let hit: CGFloat = 44
    }

    enum Radius {
        static let tile: CGFloat = 20
        static let chip: CGFloat = 12
    }

    enum Motion {
        static let pressScale: CGFloat = 0.97
        static let pressDuration: Double = 0.16
        static let sheetScale: CGFloat = 0.96
        static let sheetDuration: Double = 0.22
    }

    enum TypeStep {
        static let display: CGFloat = 72
        static let title: CGFloat = 34
        static let headline: CGFloat = 22
        static let body: CGFloat = 17
        static let caption: CGFloat = 14
        static let micro: CGFloat = 12
    }

    static func display(_ size: CGFloat) -> Font {
        Font.custom(fontBold, size: size, relativeTo: .largeTitle)
    }

    static func text(_ size: CGFloat) -> Font {
        Font.custom(fontFamily, size: size, relativeTo: .body)
    }
}
