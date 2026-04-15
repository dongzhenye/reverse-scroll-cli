func printStatus() {
    let running = isDaemonRunning()
    let accessible = isAccessibilityGranted()

    if running && accessible {
        print("Running ✓  Accessibility ✓")
        if isNaturalScrollingEnabled() {
            print("Mouse: traditional  |  Trackpad: natural")
        } else {
            print("⚠ Natural scrolling is OFF — mouse is being reversed to \"natural\" direction.")
            print("Recommended: enable Natural Scrolling, this tool handles the mouse.")
        }
        let conflicts = runningConflictingTools()
        if !conflicts.isEmpty {
            let names = conflicts.joined(separator: ", ")
            print("⚠ \(names) is also running — two reversals cancel out.")
            print("Quit \(conflicts.first!) or uninstall this tool.")
        }
        print("Uninstall: brew uninstall --cask reverse-scroll-cli")
    } else if running {
        print("Running ✓  Accessibility ✗")
        print("Grant: System Settings > Privacy & Security > Accessibility")
    } else {
        print("Not running ✗")
        print("Restart: brew reinstall --cask reverse-scroll-cli")
        print("Test:    reverse-scroll-cli --foreground")
    }
}
