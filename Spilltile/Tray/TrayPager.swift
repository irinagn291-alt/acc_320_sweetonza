import SwiftUI
import UIKit

/// TrayPager is the UIPageViewController root. One tile per page. Swipe only changes the page.
struct TrayPager: UIViewControllerRepresentable {
    var tiles: [Tile]
    var document: TrayDocument
    var pageIndex: Int
    var onPage: (Int) -> Void
    var onTick: (UUID) -> Void
    var onGhost: (UUID) -> Void
    var onPeel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.view.backgroundColor = UIColor(DesignTokens.bg)
        context.coordinator.parent = self
        context.coordinator.install(in: controller)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sync(controller)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: TrayPager
        private var hosts: [UUID: UIHostingController<TrayFace>] = [:]

        init(parent: TrayPager) {
            self.parent = parent
        }

        func install(in controller: UIPageViewController) {
            guard let first = host(at: clampedIndex) else { return }
            controller.setViewControllers([first], direction: .forward, animated: false)
        }

        func sync(_ controller: UIPageViewController) {
            let alive = Set(parent.tiles.map(\.id))
            hosts = hosts.filter { alive.contains($0.key) }
            for tile in parent.tiles {
                hosts[tile.id]?.rootView = face(for: tile)
            }
            guard let current = controller.viewControllers?.first as? UIHostingController<TrayFace> else {
                install(in: controller)
                return
            }
            let index = indexOf(current) ?? clampedIndex
            guard let settled = host(at: clampedIndex), index != clampedIndex else { return }
            let direction: UIPageViewController.NavigationDirection = clampedIndex >= index ? .forward : .reverse
            controller.setViewControllers([settled], direction: direction, animated: false)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = indexOf(viewController), index > 0 else { return nil }
            return host(at: index - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = indexOf(viewController), index + 1 < parent.tiles.count else { return nil }
            return host(at: index + 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed, let current = pageViewController.viewControllers?.first, let index = indexOf(current) else {
                return
            }
            parent.onPage(index)
        }

        private var clampedIndex: Int {
            guard !parent.tiles.isEmpty else { return 0 }
            return min(max(parent.pageIndex, 0), parent.tiles.count - 1)
        }

        private func indexOf(_ controller: UIViewController) -> Int? {
            guard let host = controller as? UIHostingController<TrayFace> else { return nil }
            return parent.tiles.firstIndex { $0.id == host.rootView.tile.id }
        }

        private func host(at index: Int) -> UIHostingController<TrayFace>? {
            guard parent.tiles.indices.contains(index) else { return nil }
            let tile = parent.tiles[index]
            if let existing = hosts[tile.id] {
                existing.rootView = face(for: tile)
                return existing
            }
            let created = UIHostingController(rootView: face(for: tile))
            created.view.backgroundColor = UIColor(DesignTokens.bg)
            hosts[tile.id] = created
            return created
        }

        private func face(for tile: Tile) -> TrayFace {
            let centered = parent.tiles.indices.contains(clampedIndex) ? parent.tiles[clampedIndex] : tile
            let neighbor = parent.tiles.first { $0.id != tile.id }
            return TrayFace(
                tile: tile,
                centered: centered,
                neighbor: neighbor,
                document: parent.document,
                onTick: { self.parent.onTick(tile.id) },
                onGhost: { ghostID in self.parent.onGhost(ghostID) },
                onPeel: { self.parent.onPeel() }
            )
        }
    }
}

/// TrayFace is one pager page: the centered bento, the catch column, and the off-page ghost control.
struct TrayFace: View {
    var tile: Tile
    var centered: Tile
    var neighbor: Tile?
    var document: TrayDocument
    var onTick: () -> Void
    var onGhost: (UUID) -> Void
    var onPeel: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var tallySize = DesignTokens.TypeStep.display
    @State private var peelArmed = false

    private var daykey: Int { Daykey.make(from: Date()) }
    private var tally: Int { TrayEngine.tally(in: document, tileID: tile.id, daykey: daykey) }
    private var catchRoute: CatchRoute? {
        document.catchRoutes.first { $0.fromTileID == tile.id && $0.isOpen }
    }
    private var catchTile: Tile? {
        guard let catchRoute else { return nil }
        return document.tiles.first { $0.id == catchRoute.toTileID }
    }
    private var catchValue: Int {
        guard let catchTile else { return 0 }
        return TrayEngine.tally(in: document, tileID: catchTile.id, daykey: daykey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.m) {
            statusLine
            bento
            if let neighbor, neighbor.id != tile.id {
                ghostControl(neighbor)
            }
        }
        .padding(.horizontal, DesignTokens.Space.m)
        .padding(.vertical, DesignTokens.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }

    private var statusLine: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.xs) {
            Text(tile.title)
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(brimLine)
                .font(DesignTokens.text(DesignTokens.TypeStep.body))
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(ghostStatus)
                .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var brimLine: String {
        let count = SpillReadout.whole(tally)
        let limit = SpillReadout.whole(tile.brim.limit)
        if tally < tile.brim.limit {
            let room = SpillReadout.whole(tile.brim.limit - tally)
            return "Below brim \(limit). Count \(count). Room \(room). Tick this tile."
        }
        if catchTile != nil {
            return "At brim \(limit). Count \(count). Next tick spills."
        }
        return "At brim \(limit). Count \(count). Catch closed, drip."
    }

    private var ghostStatus: String {
        let count = document.log.ghosts.filter { $0.daykey == daykey }.count
        let shown = SpillReadout.whole(count)
        return "Ghosts \(shown). Off-page taps stay off the count."
    }

    private var bento: some View {
        HStack(alignment: .top, spacing: DesignTokens.Space.s) {
            tickControl
            catchColumn
                .padding(.top, DesignTokens.Space.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var tickControl: some View {
        Button(action: fireTick) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                            .fill(DesignTokens.accent.opacity(0.22))
                    }
                TrayPlate(emphasized: tile.id == centered.id)
                VStack(alignment: .leading, spacing: DesignTokens.Space.s) {
                    Text("Tick")
                        .font(DesignTokens.text(DesignTokens.TypeStep.headline))
                        .foregroundStyle(DesignTokens.accent)
                    Text(SpillReadout.whole(tally))
                        .font(DesignTokens.display(tallySize))
                        .foregroundStyle(DesignTokens.ink)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text("Hold to peel")
                        .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                        .foregroundStyle(DesignTokens.muted)
                }
                .padding(DesignTokens.Space.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                Image("spt_ControlFace")
                    .resizable()
                    .scaledToFill()
                    .frame(width: DesignTokens.Space.xxl, height: DesignTokens.Space.xxl)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
                    .clipped()
                    .padding(DesignTokens.Space.m)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: DesignTokens.Space.hit * 4)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityLabel("Tick \(tile.title)")
        .accessibilityHint("Adds one below brim. At brim it spills or drips. Hold to peel the last mark.")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                peelArmed = true
                onPeel()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    peelArmed = false
                }
            }
        )
    }

    private var catchColumn: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s) {
            Text("Catch")
                .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                .foregroundStyle(DesignTokens.muted)
            Text(catchTile?.title ?? "Closed")
                .font(DesignTokens.display(DesignTokens.TypeStep.headline))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(SpillReadout.whole(catchTile == nil ? 0 : catchValue))
                .font(DesignTokens.display(DesignTokens.TypeStep.title))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(DesignTokens.Space.m)
        .frame(width: DesignTokens.Space.xxl * 3, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
                .fill(.thinMaterial)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(catchLabel)
    }

    private var catchLabel: String {
        if let catchTile {
            return "Catch \(catchTile.title), \(SpillReadout.whole(catchValue))"
        }
        return "Catch closed"
    }

    private func ghostControl(_ neighbor: Tile) -> some View {
        Button {
            onGhost(neighbor.id)
        } label: {
            HStack(spacing: DesignTokens.Space.s) {
                Text(neighbor.title)
                    .font(DesignTokens.text(DesignTokens.TypeStep.body))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                Text(ghostLine(neighbor))
                    .font(DesignTokens.text(DesignTokens.TypeStep.caption))
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(2)
            }
            .padding(.horizontal, DesignTokens.Space.m)
            .frame(maxWidth: .infinity, minHeight: DesignTokens.Space.hit, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                    .fill(.thinMaterial)
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityLabel("Tick \(neighbor.title) off the centered page")
        .accessibilityHint("Writes a ghost mark and does not change a count.")
    }

    private func ghostLine(_ neighbor: Tile) -> String {
        let count = document.log.ghosts.filter { $0.daykey == daykey && $0.pageTileID == neighbor.id }.count
        let shown = SpillReadout.whole(count)
        return "Off page. Ghosts \(shown)."
    }

    private func fireTick() {
        guard !peelArmed else { return }
        if tile.id == centered.id {
            onTick()
        } else {
            onGhost(tile.id)
        }
    }
}

/// TilePressStyle scales the centered tile to 0.97. Reduce Motion keeps opacity only.
struct TilePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? DesignTokens.Motion.pressScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: DesignTokens.Motion.pressDuration),
                value: configuration.isPressed
            )
    }
}
