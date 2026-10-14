import SwiftUI

/// SettingsSheet holds contact, a confirmed day reset, reset all, and onboarding again.
struct SettingsSheet: View {
    @EnvironmentObject private var tray: TrayStore
    @Environment(\.dismiss) private var dismiss

    @State private var tileID: UUID?
    @State private var confirmTile = false
    @State private var confirmAll = false

    private var contactURL: URL? {
        URL(string: "https://spilltile-tray.pro/contact-us")
    }

    var body: some View {
        SpillSheetFade {
            NavigationStack {
                Group {
                    if let note = tray.recoveryNote {
                        errorBody(note)
                    } else if tray.document.tiles.isEmpty {
                        emptyBody
                    } else {
                        populated
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close settings")
                        .frame(minWidth: DesignTokens.Space.hit, minHeight: DesignTokens.Space.hit)
                    }
                }
            }
        }
        .presentationBackground(DesignTokens.bg)
        .onAppear {
            if tileID == nil {
                tileID = tray.document.tiles.first?.id
            }
        }
        .confirmationDialog(
            "Reset this day tally",
            isPresented: $confirmTile,
            titleVisibility: .visible
        ) {
            Button("Reset day tally", role: .destructive) {
                if let tileID {
                    tray.resetTileDay(tileID: tileID)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The selected counter returns to zero for today. Earlier days stay in the log.")
        }
        .confirmationDialog(
            "Erase the tray",
            isPresented: $confirmAll,
            titleVisibility: .visible
        ) {
            Button("Erase tray", role: .destructive) {
                Task { await tray.resetAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletes every counter, mark, and tally on this device. This cannot be undone.")
        }
    }

    private var populated: some View {
        Form {
            Section("Day tally") {
                Picker("Counter", selection: $tileID) {
                    ForEach(tray.document.tiles) { tile in
                        Text(tile.title).tag(Optional(tile.id))
                    }
                }
                Button("Reset day tally") {
                    confirmTile = true
                }
                .buttonStyle(SpillDestroy())
                .disabled(tileID == nil)
            }
            Section("Contact") {
                Text("Opens the support page.")
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .foregroundStyle(DesignTokens.muted)
                if let contactURL {
                    Link(destination: contactURL) {
                        Label("Contact support", systemImage: "link")
                            .font(DesignTokens.text(DesignTokens.TypeStep.body))
                            .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit, alignment: .leading)
                    }
                    .accessibilityHint("Opens the support page.")
                }
            }
            Section {
                Button("Show onboarding again") {
                    Task {
                        await tray.reopenOnboarding()
                        dismiss()
                    }
                }
                .buttonStyle(SpillPress())
                Button("Erase tray") {
                    confirmAll = true
                }
                .buttonStyle(SpillDestroy())
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignTokens.bg)
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            Image("spt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Space.xxl * 3)
                .clipped()
                .accessibilityHidden(true)
            Text("No counters to reset")
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
            Text("The tray has no counters. Contact and onboarding stay available.")
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
            sharedSections
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }

    private func errorBody(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            Text("Settings blocked")
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
            Text(note)
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
            Button("Retry") {
                Task { await tray.reload() }
            }
            .buttonStyle(SpillPress())
            sharedSections
        }
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }

    private var sharedSections: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            if let contactURL {
                Link(destination: contactURL) {
                    Label("Contact support", systemImage: "link")
                        .font(DesignTokens.text(DesignTokens.TypeStep.body))
                        .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit, alignment: .leading)
                }
                .accessibilityHint("Opens the support page.")
            }
            Button("Show onboarding again") {
                Task {
                    await tray.reopenOnboarding()
                    dismiss()
                }
            }
            .buttonStyle(SpillPress())
            Button("Erase tray") {
                confirmAll = true
            }
            .buttonStyle(SpillDestroy())
        }
    }
}

/// SettingsView is the profile surface named for the live driver. The sheet stays the implementation.
struct SettingsView: View {
    var body: some View {
        SettingsSheet()
    }
}
