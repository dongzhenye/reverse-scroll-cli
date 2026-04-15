import CoreGraphics
import Foundation

private var eventTap: CFMachPort?

private let scrollCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    if event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 {
        let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let ptDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let fixedDelta = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -ptDelta)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDelta)
    }
    return Unmanaged.passUnretained(event)
}

func runDaemon(foreground: Bool) {
    requireMinimumMacOS()

    if !isAccessibilityGranted() {
        // exit(0) so KeepAlive does not treat this as a crash and loop.
        die([
            "Accessibility permission required.",
            "Grant: System Settings > Privacy & Security > Accessibility",
            "Add: /Applications/ReverseScrollCLI.app",
        ], code: 0)
    }

    if foreground {
        print("reverse-scroll-cli v\(version)")
        print("Running in foreground — Ctrl-C to stop.")
    }

    let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
    guard let tap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .tailAppendEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: scrollCallback,
        userInfo: nil
    ) else {
        die([
            "Failed to create event tap.",
            "Grant Accessibility permission and try again.",
        ])
    }
    eventTap = tap

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigint.setEventHandler {
        if foreground { print("\nStopped.") }
        exit(0)
    }
    sigint.resume()
    signal(SIGINT, SIG_IGN)

    let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    sigterm.setEventHandler { exit(0) }
    sigterm.resume()
    signal(SIGTERM, SIG_IGN)

    CFRunLoopRun()
}
