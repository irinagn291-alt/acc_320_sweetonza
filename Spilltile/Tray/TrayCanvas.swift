import SwiftUI
import UIKit

/// TrayPlate draws the centered tile with Core Graphics. It is the only custom surface.
struct TrayPlate: UIViewRepresentable {
    var emphasized: Bool

    func makeUIView(context: Context) -> TrayPlateView {
        let view = TrayPlateView()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.emphasized = emphasized
        return view
    }

    func updateUIView(_ uiView: TrayPlateView, context: Context) {
        uiView.emphasized = emphasized
        uiView.setNeedsDisplay()
    }
}

final class TrayPlateView: UIView {
    var emphasized = true

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let inset = rect.insetBy(dx: 1, dy: 1)
        let radius = DesignTokens.Radius.tile
        let path = UIBezierPath(roundedRect: inset, cornerRadius: radius)
        context.addPath(path.cgPath)
        if emphasized {
            context.setStrokeColor(UIColor(DesignTokens.accent).withAlphaComponent(0.85).cgColor)
            context.setLineWidth(2)
        } else {
            context.setStrokeColor(UIColor(DesignTokens.muted).withAlphaComponent(0.55).cgColor)
            context.setLineWidth(1)
        }
        context.strokePath()
    }
}
