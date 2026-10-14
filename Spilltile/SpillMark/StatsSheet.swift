import SwiftUI

/// StatsSheet lists today's tallies and spill chains. It is the log launch surface.
struct StatsSheet: View {
    @EnvironmentObject private var tray: TrayStore
    @Environment(\.dismiss) private var dismiss

    private var daykey: Int { Daykey.make(from: Date()) }

    var body: some View {
        SpillSheetFade {
            NavigationStack {
                Group {
                    if let note = tray.recoveryNote {
                        statusPage(title: "Stats unavailable", line: note, action: "Retry") {
                            Task { await tray.reload() }
                        }
                    } else if tray.document.tiles.isEmpty {
                        statusPage(
                            title: "No tallies yet",
                            line: "Add a counter on the editor, then tick the centered page.",
                            action: "Close"
                        ) {
                            dismiss()
                        }
                    } else {
                        populated
                    }
                }
                .navigationTitle("Stats")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close stats")
                        .frame(minWidth: DesignTokens.Space.hit, minHeight: DesignTokens.Space.hit)
                    }
                }
            }
        }
        .presentationBackground(DesignTokens.bg)
    }

    private var populated: some View {
        let spills = tray.document.log.spills.filter { $0.daykey == daykey }
        return List {
            Section("Today") {
                ForEach(tray.document.tiles) { tile in
                    VStack(alignment: .leading, spacing: DesignTokens.Space.xs) {
                        Text(tile.title)
                            .font(DesignTokens.text(DesignTokens.TypeStep.headline))
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                        Text(tallyLine(tile))
                            .font(DesignTokens.text(DesignTokens.TypeStep.body))
                            .foregroundStyle(DesignTokens.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, DesignTokens.Space.xs)
                }
            }
            Section("Spills") {
                if spills.isEmpty {
                    Text("No spills today.")
                        .font(DesignTokens.text(DesignTokens.TypeStep.body))
                        .foregroundStyle(DesignTokens.ink)
                } else {
                    ForEach(spills) { spill in
                        Text(spillLine(spill))
                            .font(DesignTokens.text(DesignTokens.TypeStep.body))
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignTokens.bg)
    }

    private func tallyLine(_ tile: Tile) -> String {
        let value = TrayEngine.tally(in: tray.document, tileID: tile.id, daykey: daykey)
        return "Count \(SpillReadout.whole(value)). Brim \(SpillReadout.whole(tile.brim.limit))."
    }

    private func spillLine(_ spill: SpillMark) -> String {
        let source = name(spill.sourceTileID)
        let catchName = name(spill.catchTileID)
        return "\(source) spilled to \(catchName)."
    }

    private func name(_ id: UUID) -> String {
        tray.document.tiles.first { $0.id == id }?.title ?? "Tile"
    }

    private func statusPage(title: String, line: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            Image("spt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Space.xxl * 4)
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: DesignTokens.Space.l)
            Button(action, action: perform)
                .buttonStyle(SpillPress())
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }
}

/// StatsView is the log surface named for the live driver. The sheet stays the implementation.
struct StatsView: View {
    var body: some View {
        StatsSheet()
    }
}
