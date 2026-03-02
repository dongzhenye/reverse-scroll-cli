import AppKit
import CoreGraphics
import ApplicationServices

let version = "0.1.0"

// MARK: - Global state

/// Stored globally so the callback can re-enable the tap on timeout.
var eventTap: CFMachPort?

// MARK: - Known conflicting tools

let conflictingTools = [
    "Scroll Reverser", "Mos", "LinearMouse",
    "UnnaturalScrollWheels", "Mac Mouse Fix",
]

// MARK: - Helpers

func isAccessibilityGranted() -> Bool {
    AXIsProcessTrusted()
}

func isNaturalScrollingEnabled() -> Bool {
    let key = "com.apple.swipescrolldirection" as CFString
    guard let value = CFPreferencesCopyValue(
        key,
        kCFPreferencesAnyApplication,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    ) else {
        return true // default is ON
    }
    return (value as? Bool) ?? true
}

func runningConflictingTools() -> [String] {
    let workspace = NSWorkspace.shared
    return conflictingTools.filter { name in
        workspace.runningApplications.contains { app in
            app.localizedName == name
        }
    }
}

func isDaemonRunning() -> Bool {
    let selfPID = ProcessInfo.processInfo.processIdentifier
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-f", "reverse-scroll-cli --(daemon|foreground)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    let pids = output.split(separator: "\n").compactMap { Int32($0) }
    return pids.contains { $0 != selfPID }
}

// MARK: - Status output (no args)

func printStatus() {
    let running = isDaemonRunning()
    let accessible = isAccessibilityGranted()

    if running && accessible {
        let natural = isNaturalScrollingEnabled()
        print("Running ✓  Accessibility ✓")
        if natural {
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
    } else if running && !accessible {
        print("Running ✓  Accessibility ✗")
        print("Grant: System Settings > Privacy & Security > Accessibility")
    } else {
        print("Not running ✗")
        print("Restart: brew reinstall --cask reverse-scroll-cli")
        print("Test:    reverse-scroll-cli --foreground")
    }
}

// MARK: - Event tap callback

func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Re-enable tap if macOS disables it due to timeout
    if type == .tapDisabledByTimeout {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Mouse wheel = discrete (isContinuous == 0)
    // Trackpad = continuous (isContinuous != 0)
    if event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 {
        let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)
    }

    return Unmanaged.passUnretained(event)
}

// MARK: - Daemon

func runDaemon(foreground: Bool) {
    // Check macOS version
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    if osVersion.majorVersion < 13 {
        let current = "\(osVersion.majorVersion).\(osVersion.minorVersion)"
        fputs("reverse-scroll-cli requires macOS 13.0 or later (current: \(current))\n", stderr)
        exit(1)
    }

    // Check accessibility permission
    if !isAccessibilityGranted() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        fputs("Accessibility permission required.\n", stderr)
        fputs("Grant: System Settings > Privacy & Security > Accessibility\n", stderr)
        exit(1)
    }

    if foreground {
        print("reverse-scroll-cli v\(version)")
        print("Running in foreground — Ctrl-C to stop.")
    }

    // Create event tap
    let eventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

    guard let tap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .tailAppendEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: scrollCallback,
        userInfo: nil
    ) else {
        fputs("Failed to create event tap.\n", stderr)
        fputs("Grant Accessibility permission and try again.\n", stderr)
        exit(1)
    }

    // Store globally for re-enable on timeout
    eventTap = tap

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    // Signal handling for clean shutdown
    let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSource.setEventHandler {
        if foreground { print("\nStopped.") }
        exit(0)
    }
    sigintSource.resume()
    signal(SIGINT, SIG_IGN)

    let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    sigtermSource.setEventHandler { exit(0) }
    sigtermSource.resume()
    signal(SIGTERM, SIG_IGN)

    CFRunLoopRun()
}

// MARK: - Main

let args = CommandLine.arguments.dropFirst()

if args.isEmpty {
    printStatus()
    exit(0)
}

switch args.first {
case "--version", "-v":
    print("reverse-scroll-cli v\(version)")
case "--daemon":
    runDaemon(foreground: false)
case "--foreground":
    runDaemon(foreground: true)
case "--help", "-h":
    print("reverse-scroll-cli v\(version)")
    print("")
    print("Usage:")
    print("  reverse-scroll-cli              Show status")
    print("  reverse-scroll-cli --foreground  Run in foreground (testing)")
    print("  reverse-scroll-cli --version     Show version")
    print("")
    print("Install: brew install --cask reverse-scroll-cli")
default:
    fputs("Unknown option: \(args.first!)\n", stderr)
    fputs("Run with --help for usage.\n", stderr)
    exit(1)
}
