import SwiftUI

/// OnboardingFlow is the three-page cover. Continue and Skip both finish with the tray ready.
struct OnboardingFlow: View {
    @EnvironmentObject private var tray: TrayStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.l) {
            art
            VStack(alignment: .leading, spacing: DesignTokens.Space.s) {
                Text(pages[page].title)
                    .font(DesignTokens.display(DesignTokens.TypeStep.title))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pages[page].line)
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: DesignTokens.Space.l)
            Button(page == pages.count - 1 ? "Start ticking" : "Continue") {
                advance()
            }
            .buttonStyle(SpillPress())
            Button("Skip") {
                Task { await finish() }
            }
            .buttonStyle(SpillPress())
            .accessibilityHint("Writes the tray defaults and opens the counters.")
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    private var art: some View {
        Image(pages[page].asset)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Space.xxl * 5)
            .clipped()
            .accessibilityHidden(true)
    }

    private var pages: [(title: String, line: String, asset: String)] {
        [
            (
                "Daily caps",
                "Spilltile keeps a tile for each cap. Tick the one sitting in the center.",
                "spt_Onboarding1"
            ),
            (
                "Tick until it spills",
                "Below the brim, the tick stays on this tile. At the brim it spills into the catch, or drips if the catch is closed.",
                "spt_Onboarding2"
            ),
            (
                "Peel the last mark",
                "Hold the tile to drop the last tick or spill for today. Swipe only changes the page.",
                "spt_Onboarding3"
            )
        ]
    }

    private func advance() {
        if page < pages.count - 1 {
            if reduceMotion {
                page += 1
            } else {
                withAnimation(.easeOut(duration: DesignTokens.Motion.sheetDuration)) {
                    page += 1
                }
            }
        } else {
            Task { await finish() }
        }
    }

    private func finish() async {
        await tray.markOnboardingComplete()
    }
}
