import SwiftUI

/// SpillPress is the primary control style: default, pressed, disabled, and loading.
struct SpillPress: ButtonStyle {
    var loading: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.text(DesignTokens.TypeStep.body))
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit)
            .padding(.horizontal, DesignTokens.Space.m)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                            .fill(DesignTokens.accent.opacity(isEnabled ? (configuration.isPressed ? 0.38 : 0.22) : 0.08))
                    }
            }
            .overlay {
                if loading {
                    ProgressView()
                        .tint(DesignTokens.ink)
                }
            }
            .opacity(!isEnabled ? 0.45 : (loading ? 0.72 : 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? DesignTokens.Motion.pressScale : 1)
            .animation(
                reduceMotion ? .linear(duration: DesignTokens.Motion.pressDuration) : .easeOut(duration: DesignTokens.Motion.pressDuration),
                value: configuration.isPressed
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous))
    }
}

/// SpillDestroy is the destructive control. It does not wear the accent.
struct SpillDestroy: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.text(DesignTokens.TypeStep.body))
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit)
            .padding(.horizontal, DesignTokens.Space.m)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                            .stroke(DesignTokens.muted.opacity(0.6), lineWidth: 1)
                    }
            }
            .opacity(!isEnabled ? 0.45 : (configuration.isPressed ? 0.7 : 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? DesignTokens.Motion.pressScale : 1)
            .animation(.easeOut(duration: DesignTokens.Motion.pressDuration), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous))
    }
}

/// SpillSheetFade scales a sheet from 0.96 to 1 and fades. Reduce Motion keeps opacity only.
struct SpillSheetFade<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(reduceMotion ? 1 : (shown ? 1 : DesignTokens.Motion.sheetScale))
            .opacity(shown ? 1 : 0)
            .onAppear {
                var transaction = Transaction(animation: .easeOut(duration: DesignTokens.Motion.sheetDuration))
                transaction.disablesAnimations = false
                withTransaction(transaction) {
                    shown = true
                }
            }
    }
}

@MainActor
enum SpillReadout {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func parseWhole(_ text: String) -> Int? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: text) else { return nil }
        let value = number.intValue
        guard value >= 0 else { return nil }
        return value
    }
}

enum SpillHaptic {
    static func commit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
