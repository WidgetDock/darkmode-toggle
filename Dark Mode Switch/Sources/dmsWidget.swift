import Foundation
import AppKit
import PockKit

class dmsWidget: PKWidget {
    static var identifier: String = "widgetdock.Dark-Mode-Switch"
    var customizationLabel: String = "Dark Mode Switch"
    var view: NSView!

    required init() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.alignment = .centerY
        stack.edgeInsets = .zero

        let sun = NSImageView(image: NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Light") ?? NSImage())
        sun.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        sun.contentTintColor = .systemYellow

        let moon = NSImageView(image: NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Dark") ?? NSImage())
        moon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        moon.contentTintColor = NSColor.systemBlue

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.state = systemIsDark() ? .on : .off
        toggle.action = #selector(toggleDarkMode(_:))
        toggle.target = self

        stack.addArrangedSubview(sun)
        stack.addArrangedSubview(toggle)
        stack.addArrangedSubview(moon)
        self.view = stack
    }

    @objc private func toggleDarkMode(_ sender: NSSwitch) {
        let isDark = sender.state == .on
        toggleSystemDarkMode(to: isDark)
    }

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
