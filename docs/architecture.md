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

```swift
// ~25 lines — the entire scroll reversal logic
let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    // Mouse wheel = discrete (isContinuous == 0)
    // Trackpad = continuous (isContinuous != 0)
    if event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 {
        let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)
    }
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .tailAppendEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
    callback: callback, userInfo: nil
) else { exit(1) }

let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
CFRunLoopRun()
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

## 3. Size Estimate

| Component | ~Lines (Swift) |
|-----------|----------------|
| Event tap + scroll reversal | 25 |
| Mouse vs trackpad detection | 5 |
| Permission check + user guidance | 15 |
| Signal handling (SIGTERM/SIGINT) | 10 |
| `--version` and help output | 15 |
| **Total** | **~70** |

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
