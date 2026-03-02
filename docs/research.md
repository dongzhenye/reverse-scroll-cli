# macOS Scroll Direction CLI Tool: Competitive Research

## Problem Statement

macOS links trackpad and mouse scroll direction into a single global setting (`com.apple.swipescrolldirection`). Users who want "natural scrolling" on the trackpad but "classic scrolling" on an external mouse must use third-party tools. All existing tools are GUI apps. The question: **can this be a zero-config CLI tool?**

---

## 1. Scroll Reverser - Source Code Analysis

**Repo**: https://github.com/pilotmoon/Scroll-Reverser
**Language**: Objective-C
**License**: Apache 2.0
**Core file**: `MouseTap.m` (~250 lines including logging)

### 1.1 How It Intercepts Scroll Events

Scroll Reverser creates **two** CGEvent taps via `CGEventTapCreate`:

```objc
// Passive tap: monitors gesture events (touch tracking) without modifying them
// Uses kCGEventTapOptionListenOnly - no accessibility permission needed for this one
self.passiveTapPort = (CFMachPortRef)CGEventTapCreate(
    kCGSessionEventTap,          // session-level tap
    kCGTailAppendEventTap,       // append to end of event chain
    kCGEventTapOptionListenOnly, // passive - listen only
    NSEventMaskGesture,          // gesture events (finger touches)
    _callback,
    (__bridge void *)(self));

// Active tap: intercepts and MODIFIES scroll wheel events
// Requires Accessibility permission
self.activeTapPort = (CFMachPortRef)CGEventTapCreate(
    kCGSessionEventTap,
    kCGTailAppendEventTap,
    kCGEventTapOptionDefault,    // active - can modify events
    NSEventMaskScrollWheel,      // scroll wheel events only
    _callback,
    (__bridge void *)(self));
```

The taps are added to `CFRunLoopGetMain()` via `CFMachPortCreateRunLoopSource`.

**Key insight**: The dual-tap architecture exists because using an active tap for gesture events causes side effects (interferes with "shake to locate cursor", notification center gesture, authorization dialogs).

### 1.2 How It Distinguishes Mouse vs Trackpad

This is the most sophisticated part. Scroll Reverser uses a **heuristic approach** combining multiple signals:

```objc
// Source detection logic (simplified from the callback)
const ScrollEventSource source = (^{

    // Signal 1: "continuous" flag
    // Mouse scroll wheels produce discrete (non-continuous) events
    // Trackpads and Magic Mouse produce continuous events
    if (!continuous) {
        return ScrollEventSourceMouse;  // Definitive: discrete = mouse
    }

    // Signal 2: Touch tracking
    // If 2+ fingers were touching within the last 222ms, it's a trackpad
    if (touching >= 2 && touchElapsed < (MILLISECOND * 222)) {
        return ScrollEventSourceTrackpad;
    }

    // Signal 3: Touch elapsed time
    // If no recent touches and we're in normal phase, it's a mouse
    if (phase == ScrollPhaseNormal && touchElapsed > (MILLISECOND * 333)) {
        return ScrollEventSourceMouse;
    }

    // Fallback: assume same source as last event
    return tap->lastSource;
})();
```

The `continuous` flag (`kCGScrollWheelEventIsContinuous`) is the primary discriminator:
- **0** = traditional mouse scroll wheel (discrete clicks)
- **1** = trackpad, Magic Mouse, or high-resolution scroll (continuous)

Touch tracking via the passive gesture tap provides additional confidence for trackpad detection.

### 1.3 How It Flips Scroll Direction

The reversal modifies **four** parallel representations of the scroll delta:

```objc
// All four must be set to maintain smooth scrolling
// Setting DeltaAxis causes macOS to internally recalculate PointDelta and FixedPtDelta,
// so PointDelta and FixedPtDelta must be set AFTER DeltaAxis

// 1. Integer delta (line-based)
CGEventSetIntegerValueField(eventRef, kCGScrollWheelEventDeltaAxis1, axis1 * vmul);

// 2. Fixed-point delta (sub-pixel precision)
CGEventSetDoubleValueField(eventRef, kCGScrollWheelEventFixedPtDeltaAxis1, fixedpt_axis1 * vmul);

// 3. Point delta (pixel-based)
CGEventSetIntegerValueField(eventRef, kCGScrollWheelEventPointDeltaAxis1, point_axis1 * vmul);

// 4. IOHIDEvent float value (lowest-level HID representation)
if (ioHidEventRef) {
    IOHIDEventSetFloatValue(ioHidEventRef, kIOHIDEventFieldScrollY, iohid_axis1 * vmul);
}
```

**Critical detail**: The IOHID layer access uses **private SPI** (System Programming Interface):

```c
// CoreGraphicsSPI.h - private API
IOHIDEventRef CGEventCopyIOHIDEvent(CGEventRef);

// IOKitSPI.h - private types and functions
typedef struct __IOHIDEvent * IOHIDEventRef;
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef, IOHIDEventField);
void IOHIDEventSetFloatValue(IOHIDEventRef, IOHIDEventField, IOHIDFloat);
```

These are undocumented APIs. They work but could break in future macOS versions.

### 1.4 Permissions Required

From `PermissionsManager.m`:

1. **Accessibility** (macOS 10.14+): Required for the active CGEvent tap that modifies events
   ```objc
   // Check via public API
   AXIsProcessTrustedWithOptions(options);
   ```

2. **Input Monitoring** (macOS 10.15+): Required for reading input events
   ```objc
   // Check via IOKit
   IOHIDCheckAccess(kIOHIDRequestTypeListenEvent);
   // Request via IOKit
   IOHIDRequestAccess(kIOHIDRequestTypeListenEvent);
   ```

### 1.5 Complexity Assessment

| Component | Lines | Purpose |
|-----------|-------|---------|
| `MouseTap.m` | ~250 | Core event interception and reversal |
| `MouseTap.h` | ~30 | Type definitions |
| `CoreGraphicsSPI.h` | ~5 | Private CG API declaration |
| `IOKitSPI.h` | ~30 | Private IOKit type/function declarations |
| `PermissionsManager.m` | ~120 | Permission checking/requesting |
| **Essential total** | **~435** | Everything needed for the core mechanism |

The remaining ~1500 lines are GUI: menu bar icon, preferences window, welcome window, debug/test windows, app delegate, logging.

---

## 2. UnnaturalScrollWheels - Source Code Analysis

**Repo**: https://github.com/ther0n/UnnaturalScrollWheels
**Language**: Swift (99%) + Objective-C bridging header
**License**: Not specified (README only)
**Core file**: `ScrollInterceptor.swift` (~55 lines)

### 2.1 How It Intercepts Scroll Events

Much simpler than Scroll Reverser -- a single event tap:

```swift
class ScrollInterceptor {
    static let shared = ScrollInterceptor()

    func interceptScroll() {
        DispatchQueue.global(qos: .userInteractive).async {
            let eventTap = CGEvent.tapCreate(
                tap: .cghidEventTap,          // HID-level tap (lower than session)
                place: .tailAppendEventTap,
                options: .defaultTap,          // active - can modify
                eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
                callback: self.scrollEventCallback,
                userInfo: nil
            )
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes)
            CGEvent.tapEnable(tap: eventTap!, enable: true)
            CFRunLoopRun()
        }
    }
}
```

**Key difference**: Uses `.cghidEventTap` (kCGHIDEventTap) instead of `.cgSessionEventTap`. This is a lower-level tap point that intercepts events before they reach the session, closer to the hardware.

### 2.2 How It Distinguishes Mouse vs Trackpad

Much simpler heuristic -- no gesture tap needed:

```swift
let scrollEventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
    var isWheel: Bool = true

    if !Options.shared.alternateDetectionMethod {
        // Primary method: check the "continuous" flag
        // 0 = discrete mouse wheel, non-0 = trackpad/continuous device
        if event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 {
            isWheel = false
        }
    } else {
        // Alternate method: check undocumented fields
        if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 ||
            event.getDoubleValueField(.scrollWheelEventScrollCount) != 0.0 ||
            event.getDoubleValueField(.scrollWheelEventScrollPhase) != 0.0 {
            isWheel = false
        }
    }
    // ...
}
```

The primary detection method is identical to Scroll Reverser's first check: `scrollWheelEventIsContinuous == 0` means mouse.

The alternate detection method uses undocumented event fields (`momentumPhase`, `scrollCount`, `scrollPhase`) that are non-zero only for trackpad events. This is provided as a fallback for edge cases where Logitech Options or similar drivers set `isContinuous` incorrectly.

### 2.3 How It Flips Scroll Direction

Simpler reversal -- only modifies the integer delta:

```swift
if isWheel {
    if Options.shared.invertVerticalScroll {
        event.setIntegerValueField(
            .scrollWheelEventDeltaAxis1,
            value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
    }
    if Options.shared.invertHorizontalScroll {
        event.setIntegerValueField(
            .scrollWheelEventDeltaAxis2,
            value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
    }
}
```

**Only modifies `DeltaAxis1`/`DeltaAxis2`** -- does NOT touch `PointDeltaAxis`, `FixedPtDeltaAxis`, or IOHIDEvent values. This is sufficient for discrete mouse wheels but may cause issues with smooth scrolling on certain setups.

### 2.4 Permissions Required

Only **Accessibility** permission, checked via:

```swift
let trusted = AXIsProcessTrusted()
if trusted {
    ScrollInterceptor.shared.interceptScroll()
} else {
    accessibilityAlert()   // shows dialog, opens System Preferences
    pollAccessibility()    // polls every 1s until granted
}
```

No Input Monitoring permission requested (unlike Scroll Reverser).

### 2.5 Complexity Assessment

| Component | Lines | Purpose |
|-----------|-------|---------|
| `ScrollInterceptor.swift` | ~55 | Core event interception and reversal |
| `Options.swift` | ~70 | User preferences |
| `AppDelegate.swift` | ~80 | App lifecycle, permission handling |
| `DisableMouseAccel.swift` | ~? | Mouse acceleration disable (optional feature) |
| `MenuBarItem.swift` | ~? | Menu bar icon |
| `PreferencesViewController.swift` | ~? | Preferences GUI |
| **Essential total** | **~125** | Core mechanism only |

The absolute minimum scroll reversal logic is **~30 lines of Swift**. UnnaturalScrollWheels proves this.

---

## 3. Existing CLI-Only Tools

### 3.1 Homebrew Formula Search Results

**No CLI-only scroll direction tool exists in Homebrew formulae.** All existing tools are distributed as casks (GUI apps):

| Tool | Homebrew | Type |
|------|----------|------|
| Scroll Reverser | `brew install --cask scroll-reverser` | GUI (menu bar app) |
| UnnaturalScrollWheels | `brew install --cask unnaturalscrollwheels` | GUI (menu bar app) |
| LinearMouse | `brew install --cask linearmouse` | GUI (preferences app) |
| Mos | `brew install --cask mos` | GUI (menu bar app) |
| Mac Mouse Fix | `brew install --cask mac-mouse-fix` | GUI (preferences pane, paid) |

### 3.2 `defaults write` Tricks

The global scroll direction is stored in:

```bash
defaults read -g com.apple.swipescrolldirection
# true = natural scrolling, false = classic scrolling
```

You can toggle it:

```bash
defaults write -g com.apple.swipescrolldirection -bool NO
```

**But this does NOT work per-device.** It is a single global boolean. Changing it requires either:
- A logout/login cycle, or
- Calling the private `setSwipeScrollDirection()` function from `PreferencePanesSupport.framework` and posting `SwipeScrollDirectionDidChangeNotification` (as discovered by the [ScrollSwitcher](https://shadowfacts.net/2021/scrollswitcher/) project)

This approach is unsuitable because:
1. It affects both mouse and trackpad identically
2. It requires private framework calls to take effect immediately
3. There is no per-device preference key

### 3.3 Other GitHub Projects

No Swift/Objective-C command-line-only tools were found on GitHub for this purpose. The closest is the ScrollSwitcher blog post, which describes a minimal menu bar app that toggles the global `com.apple.swipescrolldirection` setting -- but that still changes both devices at once and is still a GUI app.

---

## 4. Feasibility of a Zero-Config CLI Approach

### 4.1 Can a CLI Daemon Intercept CGEvent Taps Without a GUI?

**Yes, with caveats.**

`CGEventTapCreate` does not require `NSApplication` or a GUI window. It requires:
1. A `CFRunLoop` (or `DispatchQueue`-based equivalent) to process events
2. Accessibility permission granted to the binary
3. The process must run within a **user login session** (not a root-level LaunchDaemon)

A minimal CLI daemon in Swift:

```swift
import Foundation
import CoreGraphics

let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    if event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 {
        // Mouse wheel: invert vertical scroll
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
    callback: callback,
    userInfo: nil
) else {
    print("Failed to create event tap. Grant Accessibility permission.")
    exit(1)
}

let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
CFRunLoopRun()  // blocks forever, processing events
```

**This is approximately 25 lines of functional code.** The entire core mechanism is trivial.

### 4.2 Can It Run as a launchd Service?

**Yes, but only as a LaunchAgent (not a LaunchDaemon).**

- **LaunchAgent** (`~/Library/LaunchAgents/`): Runs in the user's login session. Has access to the window server and can create CGEvent taps. This is the correct choice.
- **LaunchDaemon** (`/Library/LaunchDaemons/`): Runs as root outside the user session. Cannot access the window server. `CGEventTapCreate` will fail.

Example LaunchAgent plist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.scroll-fix</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/scroll-fix</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

### 4.3 The Accessibility Permission Problem

This is the **single biggest obstacle** for a CLI tool:

1. **Bare binaries CAN get Accessibility permission** -- they appear in System Settings > Privacy & Security > Accessibility as their full path (e.g., `/usr/local/bin/scroll-fix`).

2. **However**, there is no way to programmatically grant this permission. The user must:
   - Open System Settings
   - Navigate to Privacy & Security > Accessibility
   - Click the "+" button
   - Navigate to the binary location and add it
   - Toggle it on

3. **App bundles (.app)** have a better UX because:
   - `AXIsProcessTrustedWithOptions` can show a system prompt directing users to Settings
   - The app appears with a recognizable icon and name instead of a bare path
   - It is the expected UX pattern on macOS

4. **Practical workaround**: A CLI tool can detect that it lacks permission (`AXIsProcessTrusted() == false`) and print instructions:
   ```
   scroll-fix requires Accessibility permission.
   Open: System Settings > Privacy & Security > Accessibility
   Add: /usr/local/bin/scroll-fix
   Then restart scroll-fix.
   ```

5. **Homebrew complication**: If installed via Homebrew formula, the binary lives at `/opt/homebrew/Cellar/scroll-fix/0.1.0/bin/scroll-fix` with a symlink at `/opt/homebrew/bin/scroll-fix`. The user must add the **real path** (not the symlink) to Accessibility, or macOS may not recognize it. After `brew upgrade`, the path changes and the permission must be re-granted.

### 4.4 Homebrew Formula vs Cask

| Aspect | Formula (CLI) | Cask (GUI) |
|--------|--------------|------------|
| Install command | `brew install scroll-fix` | `brew install --cask scroll-fix` |
| Binary location | `/opt/homebrew/bin/scroll-fix` | `/Applications/ScrollFix.app` |
| Accessibility permission | Fragile (path changes on upgrade) | Stable (app bundle identity persists) |
| Auto-start | Manual launchd setup | App can register login item |
| User expectation | CLI users, power users | General macOS users |
| Homebrew-core acceptance | More likely (simpler review) | Standard for GUI apps |

### 4.5 Minimal Code Estimate

| Component | Lines (Swift) | Notes |
|-----------|---------------|-------|
| Event tap + callback | ~25 | Core scroll reversal |
| Mouse vs trackpad detection | ~5 | `isContinuous` check |
| Permission check | ~10 | `AXIsProcessTrusted` + error message |
| Signal handling (SIGTERM/SIGINT) | ~10 | Clean shutdown |
| CLI argument parsing (optional) | ~20 | `--help`, `--version`, `--no-daemon` |
| **Total** | **~70** | Fully functional CLI tool |

### 4.6 Architecture Recommendation

The ideal approach is a **hybrid**: a CLI binary packaged inside a minimal `.app` bundle.

```
ScrollFix.app/
  Contents/
    MacOS/
      scroll-fix          # The actual binary (can also be run directly)
    Info.plist            # Minimal: bundle ID, version, LSUIElement=true
    Resources/
      AppIcon.icns        # Optional but helps with permission UI
```

This gives you:
- **CLI usability**: `scroll-fix` binary can be symlinked or invoked directly
- **Stable Accessibility permission**: macOS identifies by bundle ID, survives upgrades
- **LSUIElement=true**: No dock icon, no menu bar -- truly invisible
- **Homebrew cask**: More natural distribution, but could also be a formula that installs the .app

---

## 5. Competitive Landscape Summary

| Tool | Approach | Detection Method | GUI Weight | Open Source |
|------|----------|-----------------|------------|-------------|
| Scroll Reverser | Dual CGEvent tap + gesture monitoring | `isContinuous` + touch heuristics + timing | Medium (menu bar + prefs) | Yes (Apache 2.0) |
| UnnaturalScrollWheels | Single CGEvent tap | `isContinuous` only (+ alternate mode) | Light (menu bar + prefs) | Yes (no explicit license) |
| LinearMouse | CGEvent tap | Per-device matching | Heavy (full preferences app) | Yes (MIT) |
| Mos | CGEvent tap | Unknown (likely similar) | Medium (menu bar + prefs) | Yes |
| Mac Mouse Fix | CGEvent tap | Per-device matching | Heavy (preferences pane) | Yes (paid) |
| **Proposed CLI** | Single CGEvent tap | `isContinuous` check | **None** | TBD |

### Gap in the Market

Every single existing tool is a **GUI application with a menu bar icon**. None offer:
- A pure CLI interface
- `brew install` (formula, not cask)
- Zero configuration (just works with sensible defaults)
- No menu bar icon, no preferences window, no dock icon

The "natural scrolling for trackpad + classic scrolling for mouse" use case is extremely common (evidenced by 5+ competing GUI apps), yet there is no tool that treats this as a simple daemon that should run silently in the background.

---

## 6. Risks and Considerations

### 6.1 Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `isContinuous` flag unreliable with Logitech/driver software | Medium | Offer `--alternate-detection` flag (like UnnaturalScrollWheels) |
| Private SPI breakage in future macOS | Low | Only needed for IOHID-level reversal; basic `DeltaAxis` reversal uses public API |
| CGEvent tap disabled by macOS after timeout | Low | Re-enable tap on `kCGEventTapDisabledByTimeout` (standard pattern) |
| Accessibility permission UX friction | High | Clear error messages; consider .app bundle hybrid |
| Homebrew path changes breaking permission | Medium | Use .app bundle or stable binary path |

### 6.2 macOS Version Compatibility

- `CGEventTapCreate`: Available since macOS 10.4
- `scrollWheelEventIsContinuous`: Available since macOS 10.5
- Accessibility permission requirement: macOS 10.14+ (Mojave)
- Input Monitoring permission: macOS 10.15+ (Catalina) -- only if using `kCGEventTapOptionListenOnly`
- Minimum viable target: **macOS 13.0** (Ventura) for modern Swift toolchain

### 6.3 Naming Candidates

| Name | `brew install` | Available? |
|------|---------------|------------|
| `scroll-fix` | `brew install scroll-fix` | Likely |
| `scrolld` | `brew install scrolld` | Likely |
| `mousescroll` | `brew install mousescroll` | Likely |
| `unnatural` | `brew install unnatural` | Likely |

---

## 7. Conclusion

A zero-config CLI scroll direction tool is **absolutely feasible**. The core mechanism is ~25 lines of Swift. The main complexity is not the scroll interception -- it is the **Accessibility permission UX** and **distribution packaging**.

**Recommended MVP**:
1. Swift CLI binary, ~70 lines
2. Single `isContinuous` check for mouse detection (proven by UnnaturalScrollWheels to be sufficient for most users)
3. Invert only `DeltaAxis1` for vertical scroll (sufficient for discrete mouse wheels)
4. Package as minimal `.app` bundle with `LSUIElement=true` for stable Accessibility permission
5. Distribute as Homebrew cask initially; provide the raw binary for power users who want formula/manual install
6. LaunchAgent plist for auto-start, installed by `scroll-fix install` subcommand
