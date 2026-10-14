import Foundation
import SwiftUI

/// TrayVault is the only UserDefaults seam. The tray key and the simulator flag never share a write.
actor TrayVault {
    static let trayKey = "spt.tray.v1"
    static let backupKey = "spt.tray.v1.backup"
    static let demoKey = "spt.demo.v1"
    static let onboardKey = "spt.onboarded.v1"

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(suiteName: String?) {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            defaults = suite
        } else {
            defaults = .standard
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    func load() -> (document: TrayDocument, note: String?) {
        guard let primary = defaults.data(forKey: Self.trayKey) else {
            return (.empty, nil)
        }
        do {
            return (try decoder.decode(TrayDocument.self, from: primary), nil)
        } catch {
            if let backup = defaults.data(forKey: Self.backupKey) {
                do {
                    let restored = try decoder.decode(TrayDocument.self, from: backup)
                    return (restored, "Tray record was unreadable. Restored the last good copy.")
                } catch {
                    return (.empty, "Tray record was unreadable. Started from an empty tray.")
                }
            }
            return (.empty, "Tray record was unreadable. Started from an empty tray.")
        }
    }

    func store(_ document: TrayDocument) throws {
        let data = try encoder.encode(document)
        if let existing = defaults.data(forKey: Self.trayKey), decodes(existing) {
            defaults.set(existing, forKey: Self.backupKey)
        }
        defaults.set(data, forKey: Self.trayKey)
    }

    func eraseTray() {
        defaults.removeObject(forKey: Self.trayKey)
        defaults.removeObject(forKey: Self.backupKey)
    }

    func hasTrayKey() -> Bool {
        defaults.data(forKey: Self.trayKey) != nil
    }

    func bool(_ key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func setBool(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func decodes(_ data: Data) -> Bool {
        do {
            _ = try decoder.decode(TrayDocument.self, from: data)
            return true
        } catch {
            return false
        }
    }
}

/// TrayStore is the seam screens use. Memory is the source of truth. The defaults record is a projection.
@MainActor
final class TrayStore: ObservableObject {
    @Published private(set) var document: TrayDocument
    @Published private(set) var recoveryNote: String?
    @Published private(set) var onboardingComplete: Bool
    @Published private(set) var isReady = false

    var debounceNanoseconds: UInt64 = 400_000_000

    private let vault: TrayVault
    private var saveTask: Task<Void, Never>?
    private var phaseTask: Task<Void, Never>?
    private var epoch = 0
    private var loaded = false
    private var wiped = false

    init(suiteName: String?, document: TrayDocument = .empty) {
        vault = TrayVault(suiteName: suiteName)
        self.document = document
        onboardingComplete = false
    }

    func loadIfNeeded() async {
        guard !loaded else { return }
        loaded = true
        await reload()
        await installDemoSeed(runningOnSimulator: Self.runsOnSimulator)
        isReady = true
    }

    func reload() async {
        let outcome = await vault.load()
        document = outcome.document
        recoveryNote = outcome.note
        onboardingComplete = await vault.bool(TrayVault.onboardKey)
        wiped = false
    }

    /// Simulator-only. A device pass leaves `spt.demo.v1` untouched.
    func installDemoSeed(runningOnSimulator: Bool, on date: Date = Date()) async {
        guard runningOnSimulator else { return }
        if await vault.bool(TrayVault.demoKey) { return }
        if document.tiles.isEmpty {
            document = TrayEngine.demoDocument(on: date)
            recoveryNote = nil
            wiped = false
            await flush()
        }
        await vault.setBool(true, for: TrayVault.demoKey)
        await vault.setBool(true, for: TrayVault.onboardKey)
        onboardingComplete = true
    }

    func tick(centeredTileID: UUID, pageTileID: UUID, on date: Date = Date()) {
        document = TrayEngine.tick(
            document,
            centeredTileID: centeredTileID,
            pageTileID: pageTileID,
            on: date
        )
        scheduleSave()
    }

    func peel(on date: Date = Date()) {
        document = TrayEngine.peel(document, on: date)
        scheduleSave()
    }

    func resetTileDay(tileID: UUID, on date: Date = Date()) {
        let daykey = Daykey.make(from: date)
        document = TrayEngine.resetDay(document, tileID: tileID, daykey: daykey)
        scheduleSave()
    }

    func addTile(title: String, brim: Int) {
        document = TrayEngine.addTile(document, title: title, brim: brim)
        scheduleSave()
    }

    func renameTile(tileID: UUID, title: String) {
        document = TrayEngine.renameTile(document, tileID: tileID, title: title)
        scheduleSave()
    }

    func setBrim(tileID: UUID, limit: Int) {
        document = TrayEngine.setBrim(document, tileID: tileID, limit: limit)
        scheduleSave()
    }

    func setCatch(from source: UUID, to target: UUID?, open: Bool) {
        document = TrayEngine.setCatch(document, from: source, to: target, open: open)
        scheduleSave()
    }

    func alignToToday(on date: Date = Date()) {
        let next = TrayEngine.alignDay(document, on: date)
        guard next != document else { return }
        document = next
        scheduleSave()
    }

    func reopenOnboarding() async {
        onboardingComplete = false
        await vault.setBool(false, for: TrayVault.onboardKey)
    }

    func noteScenePhase(_ phase: ScenePhase) {
        guard phase == .inactive || phase == .background else { return }
        saveTask?.cancel()
        saveTask = nil
        let ticket = epoch
        let snapshot = document
        let shouldErase = wiped
        phaseTask?.cancel()
        phaseTask = Task { await self.finish(snapshot: snapshot, ticket: ticket, erase: shouldErase) }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        let ticket = epoch
        await finish(snapshot: document, ticket: ticket, erase: wiped)
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        epoch += 1
        document = .empty
        recoveryNote = nil
        wiped = true
        await vault.eraseTray()
    }

    func markOnboardingComplete() async {
        onboardingComplete = true
        await vault.setBool(true, for: TrayVault.onboardKey)
    }

    func trayKeyPresent() async -> Bool {
        await vault.hasTrayKey()
    }

    func demoFlag() async -> Bool {
        await vault.bool(TrayVault.demoKey)
    }

    private func scheduleSave() {
        wiped = false
        epoch += 1
        let ticket = epoch
        saveTask?.cancel()
        let delay = debounceNanoseconds
        let snapshot = document
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.finish(snapshot: snapshot, ticket: ticket, erase: false)
        }
    }

    private func finish(snapshot: TrayDocument, ticket: Int, erase: Bool) async {
        guard ticket == epoch else { return }
        do {
            if erase {
                await vault.eraseTray()
            } else {
                try await vault.store(snapshot)
            }
        } catch {
            recoveryNote = "Tray save failed. The on-screen tray is unchanged."
        }
    }

    private static var runsOnSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}
