# reverse-scroll-cli — Architecture

> Technical design decisions and risk analysis.
> For step-by-step build recipe, see [implementation.md](./implementation.md).
> For product context, see [product.md](./product.md).
> For competitive source code analysis, see [research.md](./research.md).

## 1. Hybrid App Bundle

CLI binary packaged inside a minimal `.app` bundle:

```
ReverseScrollCLI.app/
  Contents/
    MacOS/
      reverse-scroll-cli      # the daemon binary
    Info.plist                # bundle ID + LSUIElement=true
    Resources/
      AppIcon.icns            # for Accessibility permission UI
```

**Why hybrid** (not pure CLI binary):
- macOS Accessibility permission is identified by **bundle ID**, stable across upgrades
- Bare binary path changes on `brew upgrade`, breaking permission grants
- `LSUIElement=true` = no dock icon, no menu bar — truly invisible
- Still works as CLI: binary can be run directly for testing

## 2. Core Mechanism

Verbatim from `Sources/ReverseScrollCLI/EventTap.swift` — the scroll callback and tap-create call. Note the three-field read-before-write ordering: setting `DeltaAxis1` causes macOS to internally recalculate `PointDeltaAxis1` and `FixedPtDeltaAxis1`, so all three originals must be captured before any write. Axis 2 (horizontal) is intentionally passed through (deferred to v2.x).

```swift
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
```

### Mouse vs Trackpad Detection

The `isContinuous` field (`scrollWheelEventIsContinuous`) is the primary discriminator:
- **0** = traditional mouse scroll wheel (discrete clicks)
- **non-zero** = trackpad, Magic Mouse, or high-resolution scroll (continuous)

This is the same approach used by UnnaturalScrollWheels (~55 lines of core code, proven reliable for most users). Scroll Reverser adds a second gesture tap for extra confidence, but that's optional complexity.

### Fallback Detection (v0.2.0)

For Logitech mice with custom drivers that set `isContinuous` incorrectly:

```swift
// Alternate method: check undocumented fields
if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 ||
    event.getDoubleValueField(.scrollWheelEventScrollCount) != 0.0 ||
    event.getDoubleValueField(.scrollWheelEventScrollPhase) != 0.0 {
    isWheel = false  // trackpad
}
```

## 3. Module Map

The codebase was split from a single `main.swift` into 8 files under `Sources/ReverseScrollCLI/` as of v0.2.0:

| File | Lines | Responsibility |
|------|-------|----------------|
| `main.swift` | 33 | Entry point + argument dispatch (`--daemon`, `--foreground`, `--version`, no-args) |
| `Die.swift` | 11 | Unified `die()` helper — writes to stderr and exits |
| `SystemChecks.swift` | 26 | Accessibility permission check, natural scrolling detection, macOS version gate |
| `ConflictDetection.swift` | 26 | Bundle-ID-based detection of competing scroll tools (Mos, Scroll Reverser, etc.) |
| `DaemonStatus.swift` | 31 | `launchctl`-based daemon liveness check |
| `Status.swift` | 28 | `printStatus()` — renders the four documented no-args output states |
| `EventTap.swift` | 73 | CGEvent tap creation, scroll callback, daemon run loop, SIGINT/SIGTERM handling |
| `Version.swift` | 2 | Generated from `Version.swift.in`; exports single-source `version` constant |
| **Total** | **230** | |

## 4. Permissions

- **Accessibility** (required): `AXIsProcessTrustedWithOptions` — system dialog guides user to Settings
- **Input Monitoring** (not required): only needed for `kCGEventTapOptionListenOnly`; we use active tap

## 5. Distribution

- **Primary**: Homebrew cask with `postflight` (register LaunchAgent) and `uninstall_postflight` (remove LaunchAgent)
- **Secondary**: GitHub release binary for manual download/test

## 6. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `isContinuous` unreliable with Logitech drivers | Medium | Fallback: check `momentumPhase`/`scrollPhase` fields |
| Accessibility permission UX friction | High | `.app` bundle shows recognizable name; clear terminal message |
| CGEvent tap auto-disabled by timeout | Low | Re-enable on `kCGEventTapDisabledByTimeout` event |
| macOS update breaks private SPI | Low | Core uses public API only; private SPI is optional enhancement |
