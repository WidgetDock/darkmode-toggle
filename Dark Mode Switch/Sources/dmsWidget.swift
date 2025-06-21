//
//  dmsWidget.swift
//  Dark Mode Switch - Ultimate
//

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

final class UltimateDarkModeSwitch: NSView {
    // Layout
    let widgetWidth: CGFloat = 68
    let widgetHeight: CGFloat = 36
    let pillInset: CGFloat = 0
    let pillHeight: CGFloat = 32
    let pillWidth: CGFloat = 68
    let knobSize: CGFloat = 30
    let knobMargin: CGFloat = 1

    // Layers/Views
    private let pillLayer = CALayer()
    private let knobLayer = CALayer()
    private let sunIcon: NSImageView
    private let moonIcon: NSImageView

    // State
    private(set) var isDark: Bool = false

    override var intrinsicContentSize: NSSize {
        NSSize(width: widgetWidth, height: widgetHeight)
    }

    init() {
        // SF Symbols
        let config = NSImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        let sunImage = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Light")?
            .withSymbolConfiguration(config)?.withTintColor(.systemYellow)
        let moonImage = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Dark")?
            .withSymbolConfiguration(config)?.withTintColor(NSColor(white: 1, alpha: 1).blended(withFraction: 0.5, of: .systemGray) ?? .gray)

        sunIcon = NSImageView(image: sunImage ?? NSImage())
        moonIcon = NSImageView(image: moonImage ?? NSImage())

        super.init(frame: NSRect(x: 0, y: 0, width: widgetWidth, height: widgetHeight))
        wantsLayer = true

        // Pill
        pillLayer.backgroundColor = lightPillColor().cgColor
        pillLayer.cornerRadius = pillHeight/2
        pillLayer.frame = CGRect(x: pillInset, y: (widgetHeight-pillHeight)/2, width: pillWidth, height: pillHeight)
        pillLayer.shadowColor = NSColor.black.cgColor
        pillLayer.shadowOpacity = 0.12
        pillLayer.shadowRadius = 3.8
        pillLayer.shadowOffset = CGSize(width: 0, height: 1)
        layer?.addSublayer(pillLayer)

        // Knob
        knobLayer.backgroundColor = NSColor.white.cgColor
        knobLayer.cornerRadius = knobSize/2
        knobLayer.frame = CGRect(x: knobMargin, y: (widgetHeight-knobSize)/2, width: knobSize, height: knobSize)
        knobLayer.shadowColor = NSColor.black.cgColor
        knobLayer.shadowOpacity = 0.22
        knobLayer.shadowRadius = 3.3
        knobLayer.shadowOffset = CGSize(width: 0, height: 1)
        layer?.addSublayer(knobLayer)

        // Sun Icon
        sunIcon.frame = CGRect(x: pillInset+7, y: (widgetHeight-20)/2, width: 20, height: 20)
        sunIcon.wantsLayer = true
        sunIcon.alphaValue = 1
        addSubview(sunIcon)

        // Moon Icon
        moonIcon.frame = CGRect(x: pillInset+pillWidth-27, y: (widgetHeight-20)/2, width: 20, height: 20)
        moonIcon.wantsLayer = true
        moonIcon.alphaValue = 0
        addSubview(moonIcon)

        // Initial State
        isDark = systemIsDark()
        updateUI(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    // Mouse
    override func mouseDown(with event: NSEvent) {
        isDark.toggle()
        animateSwitch(to: isDark)
        toggleSystemDarkMode(to: isDark)
    }

    // UI Logic
    private func lightPillColor() -> NSColor {
        NSColor(deviceWhite: 0.89, alpha: 1)
    }
    private func darkPillColor() -> NSColor {
        NSColor(deviceWhite: 0.17, alpha: 1)
    }
    private func knobOnColor() -> NSColor {
        NSColor(deviceWhite: 0.18, alpha: 1)
    }

    private func animateSwitch(to dark: Bool) {
        // Animate pill color
        let pillColorAnim = CABasicAnimation(keyPath: "backgroundColor")
        pillColorAnim.fromValue = pillLayer.backgroundColor
        pillColorAnim.toValue = (dark ? darkPillColor() : lightPillColor()).cgColor
        pillColorAnim.duration = 0.28
        pillLayer.add(pillColorAnim, forKey: "bg")
        pillLayer.backgroundColor = (dark ? darkPillColor() : lightPillColor()).cgColor

        // Animate knob position (spring)
        let knobTargetX = dark ?
            pillWidth-knobSize-knobMargin :
            knobMargin
        let currentX = knobLayer.frame.origin.x

        let bouncy = CASpringAnimation(keyPath: "position.x")
        bouncy.fromValue = currentX + knobSize/2
        bouncy.toValue = knobTargetX + knobSize/2
        bouncy.mass = 0.98
        bouncy.stiffness = 180
        bouncy.damping = 13
        bouncy.initialVelocity = dark ? 10 : -10
        bouncy.duration = bouncy.settlingDuration
        knobLayer.add(bouncy, forKey: "knobMove")

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        knobLayer.frame.origin.x = knobTargetX
        // Animate knob color
        knobLayer.backgroundColor = dark ? knobOnColor().cgColor : NSColor.white.cgColor
        CATransaction.commit()

        // SF Symbol icons: animate scale and alpha
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.20
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            sunIcon.animator().alphaValue = dark ? 0 : 1
            moonIcon.animator().alphaValue = dark ? 1 : 0
            sunIcon.animator().frame.origin.x = pillInset+6
            moonIcon.animator().frame.origin.x = pillInset+pillWidth-26
            sunIcon.animator().frame.size = NSSize(width: 22, height: 22)
            moonIcon.animator().frame.size = NSSize(width: 22, height: 22)
        }, completionHandler: nil)
        // Add a little pop to the toggled-in icon
        let poppedIcon = dark ? moonIcon : sunIcon
        let pop = CABasicAnimation(keyPath: "transform.scale")
        pop.fromValue = 1.28
        pop.toValue = 1
        pop.timingFunction = CAMediaTimingFunction(name: .easeOut)
        pop.duration = 0.18
        poppedIcon.layer?.add(pop, forKey: "pop")
    }

    private func updateUI(animated: Bool) {
        if animated {
            animateSwitch(to: isDark)
        } else {
            pillLayer.backgroundColor = (isDark ? darkPillColor() : lightPillColor()).cgColor
            let knobTargetX = isDark ? pillWidth-knobSize-knobMargin : knobMargin
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            knobLayer.backgroundColor = isDark ? knobOnColor().cgColor : NSColor.white.cgColor
            knobLayer.frame.origin.x = knobTargetX
            CATransaction.commit()
            sunIcon.alphaValue = isDark ? 0 : 1
            moonIcon.alphaValue = isDark ? 1 : 0
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
