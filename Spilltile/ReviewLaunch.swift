import Foundation

/// Live screenshot driver: `-ReviewScreen today|log|goals` (plus extra cover keys).
/// Read `ReviewLaunch.screen` once, after onboarding is done, and open that
/// screen. Keep this file; the navigation it drives belongs to the app.
enum ReviewLaunch {
    static let argument = "-ReviewScreen"

    /// The key after `-ReviewScreen`, or nil on a normal launch.
    static var screen: String? {
        screen(from: ProcessInfo.processInfo.arguments)
    }

    /// Parses a launch-argument list. `ProcessInfo` is read only by `screen`.
    static func screen(from arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}
