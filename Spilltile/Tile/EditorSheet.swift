import SwiftUI

/// EditorSheet adds a tile and sets brim plus an optional catch. It is the goals launch surface.
struct EditorSheet: View {
    @EnvironmentObject private var tray: TrayStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var brimText = ""
    @State private var selectedID: UUID?
    @State private var catchID: UUID?
    @State private var catchOpen = true
    @State private var saving = false
    @State private var fieldError: String?
    @FocusState private var focusedField: EditorField?

    var body: some View {
        SpillSheetFade {
            NavigationStack {
                Group {
                    if let note = tray.recoveryNote, tray.document.tiles.isEmpty {
                        errorState(note)
                    } else {
                        form
                    }
                }
                .navigationTitle("Editor")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close editor")
                        .frame(minWidth: DesignTokens.Space.hit, minHeight: DesignTokens.Space.hit)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                        .frame(minWidth: DesignTokens.Space.hit, minHeight: DesignTokens.Space.hit)
                    }
                }
            }
        }
        .presentationBackground(DesignTokens.bg)
        .onAppear(perform: syncSelection)
    }

    private var form: some View {
        ZStack {
            DesignTokens.bg
                .ignoresSafeArea()
                .onTapGesture(perform: dismissKeyboard)
            Form {
                if tray.document.tiles.isEmpty {
                    Section {
                        Image("spt_EmptyHome")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.Space.xxl * 4)
                            .clipped()
                            .accessibilityHidden(true)
                        Text("Tray empty")
                            .font(DesignTokens.display(DesignTokens.TypeStep.title))
                            .foregroundStyle(DesignTokens.ink)
                        Text("Add a counter, then set its cap and an optional catch.")
                            .font(DesignTokens.text(DesignTokens.TypeStep.body))
                            .foregroundStyle(DesignTokens.muted)
                    }
                } else {
                    Section("Counters") {
                        Picker("Edit", selection: $selectedID) {
                            Text("New counter").tag(UUID?.none)
                            ForEach(tray.document.tiles) { tile in
                                Text(tile.title).tag(Optional(tile.id))
                            }
                        }
                        .onChange(of: selectedID) { _, _ in
                            syncSelection()
                        }
                    }
                }
                editorFields
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(DesignTokens.bg)
    }

    private var editorFields: some View {
        Group {
            Section("Counter") {
                TextField("Name", text: $title)
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .name)
                TextField("Cap", text: $brimText)
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .cap)
                    .onChange(of: brimText) { _, newValue in
                        brimText = filtered(newValue)
                    }
                if tray.document.tiles.contains(where: { $0.id != selectedID }) {
                    Toggle("Catch open", isOn: $catchOpen)
                        .tint(DesignTokens.accent)
                    Picker("Catch", selection: $catchID) {
                        Text("None").tag(UUID?.none)
                        ForEach(tray.document.tiles.filter { $0.id != selectedID }) { tile in
                            Text(tile.title).tag(Optional(tile.id))
                        }
                    }
                } else {
                    Text("Add another counter before a catch can open.")
                        .font(DesignTokens.text(DesignTokens.TypeStep.body))
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            if let fieldError {
                Section {
                    Text(fieldError)
                        .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            Section {
                Button(saving ? "Saving" : "Save counter") {
                    save()
                }
                .buttonStyle(SpillPress(loading: saving))
                .disabled(saving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func errorState(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            Text("Editor unavailable")
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
        .padding(DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func syncSelection() {
        guard let selectedID, let tile = tray.document.tiles.first(where: { $0.id == selectedID }) else {
            if self.selectedID != nil && !tray.document.tiles.contains(where: { $0.id == selectedID }) {
                self.selectedID = nil
            }
            return
        }
        title = tile.title
        brimText = SpillReadout.whole(tile.brim.limit)
        if let route = tray.document.catchRoutes.first(where: { $0.fromTileID == tile.id }) {
            catchID = route.toTileID
            catchOpen = route.isOpen
        } else {
            catchID = nil
            catchOpen = true
        }
    }

    private func filtered(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits) else { return "" }
        return SpillReadout.whole(value)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fieldError = "Name the counter, then save."
            return
        }
        guard let brim = SpillReadout.parseWhole(brimText), brim >= 1 else {
            fieldError = "Cap needs a whole number of at least 1."
            return
        }
        fieldError = nil
        saving = true
        if let selectedID, tray.document.tiles.contains(where: { $0.id == selectedID }) {
            tray.renameTile(tileID: selectedID, title: trimmed)
            tray.setBrim(tileID: selectedID, limit: brim)
            if catchOpen, let catchID {
                tray.setCatch(from: selectedID, to: catchID, open: true)
            } else {
                tray.setCatch(from: selectedID, to: nil, open: false)
            }
        } else {
            tray.addTile(title: trimmed, brim: brim)
            if let created = tray.document.tiles.last?.id, catchOpen, let catchID {
                tray.setCatch(from: created, to: catchID, open: true)
            }
            title = ""
            brimText = ""
        }
        saving = false
    }
}

private enum EditorField: Hashable {
    case name
    case cap
}

/// EditorView is the goals surface named for the live driver. The sheet stays the implementation.
struct EditorView: View {
    var body: some View {
        EditorSheet()
    }
}
