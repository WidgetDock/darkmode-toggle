import Foundation
import AppKit
import PockKit

class dmsWidget: PKWidget {
    static var identifier: String = "widgetdock.Dark-Mode-Switch"
    var customizationLabel: String = "Dark Mode Switch"
    var view: NSView!

    required init() {
        view = UltimateDarkModeSwitch()
    }
}

final class UltimateDarkModeSwitch: NSButton {
    // Layout - Premium, larger, balanced
    let pillInset: CGFloat = 8
    let pillWidth: CGFloat = 80
    let widgetWidth: CGFloat
    let widgetHeight: CGFloat = 48
    let pillHeight: CGFloat = 40
    let knobSize: CGFloat = 32
    let knobMargin: CGFloat = 2

    // Layers/Views
    private let pillLayer = CALayer()
    private let pillGradientLayer = CAGradientLayer()
    private let knobLayer = CALayer()
    private let knobGlowLayer = CALayer()
    let sunIcon: NSImageView
    let moonIcon: NSImageView

    // Background Blur View (if macOS supports)
    private var blurView: NSVisualEffectView?

    // State
    private(set) var isDark: Bool = false

    override var intrinsicContentSize: NSSize {
        NSSize(width: widgetWidth, height: widgetHeight)
    }

    override var acceptsFirstResponder: Bool { true }

    init() {
        widgetWidth = pillWidth + 2 * pillInset

        // SF Symbols 24pt, weight bold
        let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .bold)

        let sunImage = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Light")?
            .withSymbolConfiguration(config)
        let moonImage = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Dark")?
            .withSymbolConfiguration(config)

        sunIcon = NSImageView(image: sunImage ?? NSImage())
        moonIcon = NSImageView(image: moonImage ?? NSImage())

        super.init(frame: NSRect(x: 0, y: 0, width: widgetWidth, height: widgetHeight))
        title = ""
        wantsLayer = true
        layer?.masksToBounds = false

        target = self
        action = #selector(handlePress)

        // Background blur if available (macOS 10.14+)
        if #available(macOS 10.14, *) {
            let blur = NSVisualEffectView(frame: bounds)
            blur.autoresizingMask = [.width, .height]
            blur.material = .sidebar
            blur.blendingMode = .withinWindow
            blur.state = .active
            blur.wantsLayer = true
            blur.layer?.cornerRadius = pillHeight / 2
            blur.layer?.masksToBounds = true
            addSubview(blur, positioned: .below, relativeTo: nil)
            blurView = blur
        }

        // Pill Layer
        pillLayer.cornerRadius = pillHeight / 2
        pillLayer.frame = CGRect(x: pillInset, y: (widgetHeight - pillHeight) / 2, width: pillWidth, height: pillHeight)
        pillLayer.masksToBounds = true
        pillLayer.shadowColor = NSColor.black.cgColor
        pillLayer.shadowOpacity = 0.12
        pillLayer.shadowRadius = 6
        pillLayer.shadowOffset = CGSize(width: 0, height: 2)
        layer?.addSublayer(pillLayer)

        // Pill Gradient Layer
        pillGradientLayer.frame = pillLayer.bounds
        pillGradientLayer.cornerRadius = pillHeight / 2
        pillLayer.addSublayer(pillGradientLayer)

        // Knob Layer
        let knobX = knobMargin + pillInset
        knobLayer.backgroundColor = NSColor.white.cgColor
        knobLayer.cornerRadius = knobSize / 2
        knobLayer.frame = CGRect(x: knobX, y: (widgetHeight - knobSize) / 2, width: knobSize, height: knobSize)
        knobLayer.shadowColor = NSColor.black.cgColor
        knobLayer.shadowOpacity = 0.12
        knobLayer.shadowRadius = 4
        knobLayer.shadowOffset = CGSize(width: 0, height: 1)
        knobLayer.masksToBounds = true
        layer?.addSublayer(knobLayer)

        // Knob inner shadow (using shadowPath trick)
        let innerShadowLayer = CALayer()
        innerShadowLayer.frame = knobLayer.bounds
        innerShadowLayer.cornerRadius = knobSize / 2
        innerShadowLayer.shadowColor = NSColor.black.withAlphaComponent(0.15).cgColor
        innerShadowLayer.shadowOffset = CGSize(width: 0, height: 1)
        innerShadowLayer.shadowOpacity = 1
        innerShadowLayer.shadowRadius = 3
        innerShadowLayer.masksToBounds = false
        innerShadowLayer.shadowPath = CGPath(roundedRect: innerShadowLayer.bounds.insetBy(dx: -1.5, dy: -1.5), cornerWidth: knobSize / 2, cornerHeight: knobSize / 2, transform: nil)
        knobLayer.addSublayer(innerShadowLayer)

        // Knob glowing border layer (initially hidden)
        knobGlowLayer.frame = knobLayer.bounds
        knobGlowLayer.cornerRadius = knobSize / 2
        knobGlowLayer.borderWidth = 3
        knobGlowLayer.borderColor = NSColor(calibratedRed: 0.3, green: 0.55, blue: 1.0, alpha: 0.8).cgColor // blue glow color
        knobGlowLayer.shadowColor = NSColor(calibratedRed: 0.3, green: 0.55, blue: 1.0, alpha: 0.9).cgColor
        knobGlowLayer.shadowRadius = 8
        knobGlowLayer.shadowOpacity = 1
        knobGlowLayer.shadowOffset = CGSize.zero
        knobGlowLayer.opacity = 0
        knobLayer.addSublayer(knobGlowLayer)

        // Sun Icon
        sunIcon.frame = CGRect(x: pillInset + 4, y: (widgetHeight - 24) / 2, width: 24, height: 24)
        sunIcon.wantsLayer = true
        sunIcon.layer?.shadowColor = NSColor.black.cgColor
        sunIcon.layer?.shadowOpacity = 0.15
        sunIcon.layer?.shadowRadius = 1.5
        sunIcon.layer?.shadowOffset = CGSize(width: 0, height: 1)
        sunIcon.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addSubview(sunIcon)

        // Moon Icon
        moonIcon.frame = CGRect(x: pillInset + pillWidth - 28, y: (widgetHeight - 24) / 2, width: 24, height: 24)
        moonIcon.wantsLayer = true
        moonIcon.layer?.shadowColor = NSColor.black.cgColor
        moonIcon.layer?.shadowOpacity = 0.15
        moonIcon.layer?.shadowRadius = 1.5
        moonIcon.layer?.shadowOffset = CGSize(width: 0, height: 1)
        moonIcon.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addSubview(moonIcon)

        // Initial State
        isDark = systemIsDark()
        updateUI(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handlePress() {
        isDark.toggle()
        animateSwitch(to: isDark)
        toggleSystemDarkMode(to: isDark)
    }

    // MARK: - Colors and Gradients for Pill

    private func lightPillGradientColors() -> [CGColor] {
        [
            NSColor(calibratedWhite: 1.0, alpha: 0.95).cgColor,
            NSColor(calibratedRed: 0.8, green: 0.9, blue: 1.0, alpha: 0.9).cgColor
        ]
    }

    private func darkPillGradientColors() -> [CGColor] {
        [
            NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.85, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.45, green: 0.25, blue: 0.75, alpha: 1.0).cgColor
        ]
    }

    // MARK: - Animations

    private func animateSwitch(to dark: Bool) {
        // Animate pill gradient colors
        let fromColors = pillGradientLayer.colors
        let toColors = dark ? darkPillGradientColors() : lightPillGradientColors()
        let colorAnim = CABasicAnimation(keyPath: "colors")
        colorAnim.fromValue = fromColors
        colorAnim.toValue = toColors
        colorAnim.duration = 0.28
        colorAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pillGradientLayer.colors = toColors
        pillGradientLayer.add(colorAnim, forKey: "colors")

        // Animate knob position with spring
        let knobTargetX = dark ?
            pillInset + pillWidth - knobSize - knobMargin :
            pillInset + knobMargin
        let currentX = knobLayer.frame.origin.x

        let springAnim = CASpringAnimation(keyPath: "position.x")
        springAnim.fromValue = currentX + knobSize / 2
        springAnim.toValue = knobTargetX + knobSize / 2
        springAnim.mass = 0.9
        springAnim.stiffness = 200
        springAnim.damping = 14
        springAnim.initialVelocity = dark ? 10 : -10
        springAnim.duration = springAnim.settlingDuration
        springAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        knobLayer.add(springAnim, forKey: "position.x")

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        knobLayer.frame.origin.x = knobTargetX
        CATransaction.commit()

        // Animate knob glowing border opacity
        let glowOpacityAnim = CABasicAnimation(keyPath: "opacity")
        glowOpacityAnim.fromValue = knobGlowLayer.opacity
        glowOpacityAnim.toValue = dark ? 1 : 0
        glowOpacityAnim.duration = 0.28
        glowOpacityAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        knobGlowLayer.opacity = dark ? 1 : 0
        knobGlowLayer.add(glowOpacityAnim, forKey: "opacity")

        // Animate icons (scale + alpha)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            if dark {
                // Sun: fade out and shrink (0.85x)
                sunIcon.animator().alphaValue = 0.35
                sunIcon.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 0.85, y: 0.85))

                // Moon: full alpha and scale up (1.15x)
                moonIcon.animator().alphaValue = 1.0
                moonIcon.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1.15, y: 1.15))
            } else {
                // Sun: full alpha and scale up (1.15x)
                sunIcon.animator().alphaValue = 1.0
                sunIcon.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1.15, y: 1.15))

                // Moon: fade out and shrink (0.85x)
                moonIcon.animator().alphaValue = 0.35
                moonIcon.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 0.85, y: 0.85))
            }
        }, completionHandler: nil)
    }

    private func updateUI(animated: Bool) {
        if animated {
            animateSwitch(to: isDark)
        } else {
            // Pill Gradient
            pillGradientLayer.colors = isDark ? darkPillGradientColors() : lightPillGradientColors()

            // Knob position
            let knobTargetX = isDark ? pillInset + pillWidth - knobSize - knobMargin : pillInset + knobMargin
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            knobLayer.frame.origin.x = knobTargetX
            CATransaction.commit()

            // Knob glow
            knobGlowLayer.opacity = isDark ? 1 : 0

            // Icons scale and alpha
            if isDark {
                sunIcon.alphaValue = 0.35
                sunIcon.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.85, y: 0.85))
                moonIcon.alphaValue = 1.0
                moonIcon.layer?.setAffineTransform(CGAffineTransform(scaleX: 1.15, y: 1.15))
            } else {
                sunIcon.alphaValue = 1.0
                sunIcon.layer?.setAffineTransform(CGAffineTransform(scaleX: 1.15, y: 1.15))
                moonIcon.alphaValue = 0.35
                moonIcon.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.85, y: 0.85))
            }
        }
    }

    // System Control
    private func toggleSystemDarkMode(to dark: Bool) {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(dark ? "true" : "false")
            end tell
        end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
    }

    private func systemIsDark() -> Bool {
        let dict = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        if let style = dict?["AppleInterfaceStyle"] as? String {
            return style.lowercased() == "dark"
        }
        return false
    }
}

#if DEBUG
import SwiftUI
struct UltimateDarkModeSwitchPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> UltimateDarkModeSwitch {
        UltimateDarkModeSwitch()
    }
    func updateNSView(_ nsView: UltimateDarkModeSwitch, context: Context) {}
}
#Preview {
    UltimateDarkModeSwitchPreview()
        .frame(width: 120, height: 60)
}
#endif // DEBUG
