import SwiftUI

/// ContentView is the pager-locked root. Stats, Editor, and Settings arrive as sheets.
struct ContentView: View {
    @EnvironmentObject private var tray: TrayStore
    @State private var pageIndex = 0
    @State private var sheet: TraySheet?
    @State private var launchConsumed = false

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            if !tray.isReady {
                loadingPlate
            } else if tray.document.tiles.isEmpty {
                emptyTray
            } else {
                populated
            }
        }
        .fullScreenCover(isPresented: onboardingPresented) {
            OnboardingFlow()
                .environmentObject(tray)
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .stats:
                StatsSheet().environmentObject(tray)
            case .editor:
                EditorSheet().environmentObject(tray)
            case .settings:
                SettingsSheet().environmentObject(tray)
            }
        }
        .onChange(of: tray.isReady) { _, _ in
            openReviewIfNeeded()
            tray.alignToToday()
        }
        .onChange(of: tray.onboardingComplete) { _, _ in
            openReviewIfNeeded()
        }
        .onChange(of: tray.document.tiles.count) { _, count in
            if pageIndex >= count {
                pageIndex = max(0, count - 1)
            }
        }
    }

    private var onboardingPresented: Binding<Bool> {
        Binding(
            get: { tray.isReady && !tray.onboardingComplete },
            set: { _ in }
        )
    }

    private var loadingPlate: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                .fill(.regularMaterial)
                .frame(height: DesignTokens.Space.xxl * 6)
                .redacted(reason: .placeholder)
            Text("Loading tray")
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyTray: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            if let note = tray.recoveryNote {
                Text("Tray unreadable")
                    .font(DesignTokens.display(DesignTokens.TypeStep.title))
                    .foregroundStyle(DesignTokens.ink)
                Text(note)
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .foregroundStyle(DesignTokens.muted)
                Button("Retry") {
                    Task { await tray.reload() }
                }
                .buttonStyle(SpillPress())
            }
            Image("spt_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: DesignTokens.Space.xxl * 5)
                .clipped()
                .accessibilityHidden(true)
            Text("Tray empty")
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
            Text("Add a counter to start a daily cap.")
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
            Spacer(minLength: DesignTokens.Space.l)
            Button("Add a counter") {
                sheet = .editor
            }
            .buttonStyle(SpillPress())
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s) {
            chrome
            if let note = tray.recoveryNote {
                Text(note)
                    .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.horizontal, DesignTokens.Space.m)
                Button("Retry") {
                    Task { await tray.reload() }
                }
                .buttonStyle(SpillPress())
                .padding(.horizontal, DesignTokens.Space.m)
            }
            Image("spt_HeaderDecor")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Space.xxl)
                .clipped()
                .accessibilityHidden(true)
                .padding(.horizontal, DesignTokens.Space.m)
            TrayPager(
                tiles: tray.document.tiles,
                document: tray.document,
                pageIndex: pageIndex,
                onPage: { pageIndex = $0 },
                onTick: { id in commitTick(centered: id, page: id) },
                onGhost: { id in
                    guard let centered = centeredTile else { return }
                    commitTick(centered: centered.id, page: id)
                },
                onPeel: commitPeel
            )
            pageChips
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var chrome: some View {
        HStack(spacing: DesignTokens.Space.s) {
            VStack(alignment: .leading, spacing: DesignTokens.Space.xs) {
                Text(foldWord)
                    .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                    .foregroundStyle(DesignTokens.accent)
                Text("Daily caps")
                    .font(DesignTokens.display(DesignTokens.TypeStep.headline))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                Text("Tick the center.")
                    .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: DesignTokens.Space.s)
            chromeButton("Stats", system: "list.bullet.rectangle") { sheet = .stats }
            chromeButton("Editor", system: "square.and.pencil") { sheet = .editor }
            chromeButton("Settings", system: "gearshape") { sheet = .settings }
        }
        .padding(.horizontal, DesignTokens.Space.m)
        .padding(.top, DesignTokens.Space.s)
    }

    private var pageChips: some View {
        HStack(spacing: DesignTokens.Space.s) {
            ForEach(Array(tray.document.tiles.enumerated()), id: \.element.id) { index, tile in
                let title = tile.title
                Button {
                    pageIndex = index
                } label: {
                    Text(title)
                        .font(DesignTokens.text(DesignTokens.TypeStep.micro))
                        .foregroundStyle(index == pageIndex ? DesignTokens.ink : DesignTokens.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, DesignTokens.Space.s)
                        .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit)
                        .background {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                                .fill(.thinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                                        .fill(index == pageIndex ? DesignTokens.accent.opacity(0.28) : Color.clear)
                                }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
                }
                .buttonStyle(TilePressStyle())
                .accessibilityLabel("Show \(title)")
                .accessibilityAddTraits(index == pageIndex ? .isSelected : [])
            }
        }
        .padding(.horizontal, DesignTokens.Space.m)
        .padding(.bottom, DesignTokens.Space.s)
    }

    private var foldWord: String {
        switch TrayEngine.fold(of: tray.document) {
        case .bare: "Bare"
        case .flowing: "Flowing"
        case .dripping: "Dripping"
        }
    }

    private var centeredTile: Tile? {
        guard tray.document.tiles.indices.contains(pageIndex) else { return tray.document.tiles.first }
        return tray.document.tiles[pageIndex]
    }

    private func chromeButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(DesignTokens.text(DesignTokens.TypeStep.headline))
                .foregroundStyle(DesignTokens.ink)
                .frame(width: DesignTokens.Space.hit, height: DesignTokens.Space.hit)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                        .fill(.thinMaterial)
                }
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityLabel(title)
    }

    private func commitTick(centered: UUID, page: UUID) {
        let before = tray.document.tallies
        tray.tick(centeredTileID: centered, pageTileID: page)
        if tray.document.tallies != before {
            SpillHaptic.commit()
        }
    }

    private func commitPeel() {
        let before = tray.document.tallies
        tray.peel()
        if tray.document.tallies != before {
            SpillHaptic.commit()
        }
    }

    private func openReviewIfNeeded() {
        guard tray.isReady, tray.onboardingComplete, !launchConsumed else { return }
        launchConsumed = true
        switch ReviewLaunch.screen {
        case "log":
            sheet = .stats
        case "goals":
            sheet = .editor
        case "settings":
            sheet = .settings
        default:
            sheet = nil
        }
    }
}

/// TraySheet is the only way Stats, Editor, and Settings appear. The tray never pushes away.
enum TraySheet: String, Identifiable {
    case stats
    case editor
    case settings

    var id: String { rawValue }
}

#Preview {
    ContentView()
        .environmentObject(TrayStore(suiteName: nil))
}
