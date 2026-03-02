# reverse-scroll-cli — Architecture & Implementation Guide

> This document contains everything needed to build the MVP autonomously.
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

## 7. File Structure (MVP)

```
reverse-scroll-cli/
  Sources/
    main.swift                  # CLI entry point + daemon logic (~70 lines)
  Resources/
    Info.plist                  # .app bundle metadata
    AppIcon.icns                # app icon (can be placeholder)
  LaunchAgent/
    com.dongzhenye.reverse-scroll-cli.plist   # launchd config
  Makefile                      # build + package commands
  README.md                     # user-facing README (install instructions)
  LICENSE                       # MIT
  .gitignore
```

## 8. Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.dongzhenye.reverse-scroll-cli</string>
    <key>CFBundleName</key>
    <string>ReverseScrollCLI</string>
    <key>CFBundleExecutable</key>
    <string>reverse-scroll-cli</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
```

## 9. LaunchAgent Plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dongzhenye.reverse-scroll-cli</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli</string>
        <string>--daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

## 10. Build Commands

```bash
# Compile (universal binary: Apple Silicon + Intel)
swiftc Sources/main.swift \
  -o reverse-scroll-cli \
  -target arm64-apple-macos13 \
  -O

# Or for universal binary:
swiftc Sources/main.swift -o reverse-scroll-cli-arm64 -target arm64-apple-macos13 -O
swiftc Sources/main.swift -o reverse-scroll-cli-x86 -target x86_64-apple-macos13 -O
lipo -create reverse-scroll-cli-arm64 reverse-scroll-cli-x86 -output reverse-scroll-cli

# Package as .app bundle
mkdir -p ReverseScrollCLI.app/Contents/MacOS
mkdir -p ReverseScrollCLI.app/Contents/Resources
cp reverse-scroll-cli ReverseScrollCLI.app/Contents/MacOS/
cp Resources/Info.plist ReverseScrollCLI.app/Contents/
# cp Resources/AppIcon.icns ReverseScrollCLI.app/Contents/Resources/  # optional
```

## 11. main.swift — Full Implementation Outline

```swift
import Foundation
import CoreGraphics
import ApplicationServices  // for AXIsProcessTrusted

// MARK: - Version
let version = "0.1.0"

// MARK: - Argument handling
//   (no args)        → status/help mode
//   --daemon         → run as daemon (LaunchAgent uses this)
//   --foreground     → run in foreground with version banner (user testing)
//   --version        → print version and exit

// MARK: - Status mode (no args)
// 1. Check if daemon is already running (check for running process or LaunchAgent status)
// 2. Check AXIsProcessTrusted()
// 3. Check com.apple.swipescrolldirection (Natural Scrolling ON/OFF)
// 4. Check for conflicting tools (pgrep for "Scroll Reverser", "Mos", etc.)
// 5. Print context-aware status (see Output Design in product doc)

// MARK: - Daemon mode (--daemon / --foreground)
// 1. Check macOS version >= 13.0
// 2. Check AXIsProcessTrusted(), print guidance if not
// 3. Create CGEvent tap
// 4. Handle kCGEventTapDisabledByTimeout → re-enable tap
// 5. Handle SIGTERM/SIGINT → clean shutdown
// 6. CFRunLoopRun()

// MARK: - Event tap callback
// if scrollWheelEventIsContinuous == 0 → mouse → negate DeltaAxis1
// else → trackpad → pass through
```

## 12. Homebrew Cask (for reference)

```ruby
cask "reverse-scroll-cli" do
  version "0.1.0"
  sha256 "TODO"

  url "https://github.com/dongzhenye/reverse-scroll-cli/releases/download/v#{version}/ReverseScrollCLI.app.zip"
  name "ReverseScrollCLI"
  desc "Lightweight CLI daemon to reverse mouse scroll direction on macOS"
  homepage "https://github.com/dongzhenye/reverse-scroll-cli"

  app "ReverseScrollCLI.app"
  binary "#{appdir}/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli"

  postflight do
    # Install LaunchAgent
    system_command "cp",
      args: ["#{staged_path}/com.dongzhenye.reverse-scroll-cli.plist",
             "#{ENV["HOME"]}/Library/LaunchAgents/"],
      sudo: false
    system_command "launchctl",
      args: ["load", "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"],
      sudo: false
  end

  uninstall_postflight do
    system_command "launchctl",
      args: ["unload", "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"],
      sudo: false
    system_command "rm",
      args: ["-f", "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"],
      sudo: false
  end
end
```
