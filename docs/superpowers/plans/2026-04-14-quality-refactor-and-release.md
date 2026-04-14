# Quality Refactor & Release Prep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pay down tech debt, restructure for future iteration, and complete pre-open-source hardening so `brew install --cask reverse-scroll-cli` works end-to-end with signing + notarization.

**Architecture:** Two sequential phases on branch `feat/v0.2.0-quality-refactor`. Phase 1 restructures `main.swift` into a SwiftPM package with focused modules, unifies version/error handling, and fixes fragile runtime checks. Phase 2 wires code signing, notarization, Cask publication, and release plumbing. Docs (`product.md`, `architecture.md`, `roadmap.md`) are updated as part of the relevant tasks so they never drift from code.

**Tech Stack:** Swift 5.9+ / SwiftPM, CoreGraphics/ApplicationServices/AppKit, Makefile, Homebrew Cask, `codesign`, `notarytool`, GitHub Releases, GitHub Actions.

---

## Audit Summary (Fresh Eyes, 2026-04-14)

### Product layer (`docs/product.md`)
- Positioning and mental model solid; 4 output states well-specified.
- Minor drift: doc implies "negate `DeltaAxis1`" only; code negates three fields (Delta / PointDelta / FixedPtDelta). Doc should catch up.
- Missing: documented behavior for axis-2 (horizontal) scroll — currently passed through unchanged, consistent with "P2 horizontal reversal" but not stated.

### Architecture layer (`docs/architecture.md`)
- Size estimate (~70 lines) is stale; actual ~225 lines, all in one file.
- Risk table covers what we know; Logitech `isContinuous` fallback still an open known risk, deferred to feature iteration (not this plan).

### Design / structure
- Everything in `Sources/main.swift` (225 lines). Acceptable now, but planned next features (per-device rules, Logitech fallback, axis-2) will crowd it. Split into SwiftPM modules now while surface is small.
- Hand-rolled `switch` on `args.first` is fine at current scale; no arg-parser library needed.

### Implementation issues found
| # | Location | Issue |
|---|---|---|
| A | `main.swift:5`, `Makefile:3`, `Info.plist:13-15`, `Cask/*.rb:2` | Version string in 4 places; Cask is `0.1.0`, others `0.1.1`. |
| B | `main.swift:47–61` `isDaemonRunning()` | Forks `pgrep -f` every `status` call, regex is fragile, self-filter relies on PID. |
| C | `main.swift:38–45` `runningConflictingTools()` | Uses `localizedName`, breaks on non-English locales. |
| D | `Cask/reverse-scroll-cli.rb:22, 29` | `launchctl load/unload` deprecated since macOS 10.11 — use `bootstrap gui/<uid>` / `bootout`. |
| E | `main.swift:136, 145-148, 166-168, 221-223` | `fputs(stderr)` + `exit(N)` scattered; extract a `die()` helper. |
| F | `Makefile` | `VERSION` variable not injected into the binary; version strings get out of sync at compile time. |
| G | `Cask/reverse-scroll-cli.rb:2` | `sha256 "TODO"` — no release artifact yet. |
| H | Build pipeline | No code signing, no notarization; Gatekeeper will warn on install. |
| I | Repo | No CI. A trivial "compile + `--version`" check in GitHub Actions would catch breakages cheaply. |
| J | `docs/roadmap.md` | Several Phase 2 / Phase 3 items are already shipped (badges, "Why CLI?", comparison table, SECURITY.md, issue templates); roadmap needs to reflect reality before we start. |
| K | `docs/architecture.md` | Stale line count; should note module split. |
| L | `docs/product.md` | Inverted fields list is incomplete. |

### Out of scope for this plan (tracked in roadmap Future Enhancements)
- Logitech `isContinuous` fallback detection
- Horizontal scroll reversal (axis 2)
- Per-app / per-device exceptions
- Homebrew-core submission (will happen in v0.4.0)
- Blog / X / Reddit outreach (v0.3.0)
- Unit-test suite beyond pure helper coverage added here

---

## File Structure (target after Phase 1)

```
reverse-scroll-cli/
  Package.swift                              # NEW — SwiftPM manifest
  Sources/
    ReverseScrollCLI/
      main.swift                             # entry + arg dispatch only (~40 lines)
      Version.swift                          # NEW — generated at build, single source
      Die.swift                              # NEW — unified stderr+exit helper
      EventTap.swift                         # NEW — scroll tap create/callback/signals
      Status.swift                           # NEW — printStatus + helpers
      SystemChecks.swift                     # NEW — accessibility / natural / macOS ver
      ConflictDetection.swift                # NEW — bundleIdentifier-based detection
      DaemonStatus.swift                     # NEW — launchctl-based running check
  Tests/
    ReverseScrollCLITests/
      ConflictDetectionTests.swift           # NEW
      VersionTests.swift                     # NEW
  Resources/Info.plist                       # version substituted at build
  LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist
  Cask/reverse-scroll-cli.rb                 # bootstrap/bootout + real sha256
  Makefile                                   # wraps swift build + codesign + notarize
  .github/workflows/ci.yml                   # NEW — build sanity
  docs/
    product.md                               # updated (inverted fields, axis-2 note)
    architecture.md                          # updated (module map, line count)
    roadmap.md                               # updated (Phase 1+2 merged, done items struck)
    superpowers/plans/
      2026-04-14-quality-refactor-and-release.md  # THIS FILE
```

---

## Phase 1 — Tech Debt & Refactor

### Task 1: Update roadmap to reflect reality, absorb new scope

**Files:**
- Modify: `docs/roadmap.md`

- [ ] **Step 1: Edit roadmap**

Mark as done (already shipped): badges, "Why CLI?" section, comparison table, troubleshooting section, SECURITY.md, issue templates, PR template, GitHub topics.

Restructure v0.2.0 as two waves matching this plan:

```markdown
## v0.2.0 — Quality Refactor & Public Release (in progress)

### Wave A — Refactor & Tech Debt (Phase 1 of quality-refactor plan)
- [ ] SwiftPM migration + module split
- [ ] Single-source version string (build-time injection)
- [ ] Replace `pgrep` with `launchctl print` for daemon status
- [ ] Conflict detection via bundleIdentifier (locale-safe)
- [ ] `launchctl load/unload` → `bootstrap/bootout`
- [ ] Unified `die()` error helper
- [ ] Pure-helper unit tests (conflict detection, version)
- [ ] Sync product.md + architecture.md to code

### Wave B — Release Hardening (Phase 2)
- [ ] Apple Developer Program enrollment ($99)
- [ ] Developer ID Application signing in Makefile
- [ ] Notarization (`notarytool submit` + `stapler staple`)
- [ ] Create `dongzhenye/homebrew-tap` repo + move Cask there
- [ ] GitHub Release v0.2.0 + real sha256 in Cask
- [ ] GitHub Actions CI (build + `--version` smoke check)
- [ ] Verify clean install flow end-to-end
```

Move content strategy (blog, X, products entry, Reddit threads) to v0.3.0 — already correctly placed.

- [ ] **Step 2: Commit**

```bash
git add docs/roadmap.md
git commit -m "docs(roadmap): reflect shipped work + absorb refactor plan"
```

---

### Task 2: Scaffold SwiftPM package (no code move yet)

**Files:**
- Create: `Package.swift`
- Create: `Sources/ReverseScrollCLI/` (move target — done in Task 3)
- Create: `Tests/ReverseScrollCLITests/`
- Modify: `.gitignore`

- [ ] **Step 1: Write `Package.swift`**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "reverse-scroll-cli",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ReverseScrollCLI",
            path: "Sources/ReverseScrollCLI"
        ),
        .testTarget(
            name: "ReverseScrollCLITests",
            dependencies: ["ReverseScrollCLI"],
            path: "Tests/ReverseScrollCLITests"
        ),
    ]
)
```

- [ ] **Step 2: Append to `.gitignore`**

```
# SwiftPM
.build/
.swiftpm/
Package.resolved
```

- [ ] **Step 3: Verify package resolves**

Run: `swift package dump-package >/dev/null`
Expected: no output, exit 0

- [ ] **Step 4: Commit**

```bash
git add Package.swift .gitignore
git commit -m "chore: scaffold SwiftPM package"
```

---

### Task 3: Split `main.swift` into focused files

**Files:**
- Create: `Sources/ReverseScrollCLI/main.swift`
- Create: `Sources/ReverseScrollCLI/Die.swift`
- Create: `Sources/ReverseScrollCLI/SystemChecks.swift`
- Create: `Sources/ReverseScrollCLI/ConflictDetection.swift`
- Create: `Sources/ReverseScrollCLI/DaemonStatus.swift`
- Create: `Sources/ReverseScrollCLI/Status.swift`
- Create: `Sources/ReverseScrollCLI/EventTap.swift`
- Delete: `Sources/main.swift`
- Modify: `Makefile` (swap `swiftc` for `swift build`)

- [ ] **Step 1: Create `Die.swift`**

```swift
import Foundation

/// Print one or more lines to stderr and exit.
func die(_ lines: [String], code: Int32 = 1) -> Never {
    for line in lines { fputs(line + "\n", stderr) }
    exit(code)
}

func die(_ line: String, code: Int32 = 1) -> Never {
    die([line], code: code)
}
```

- [ ] **Step 2: Create `SystemChecks.swift`**

```swift
import ApplicationServices
import Foundation

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
        return true
    }
    return (value as? Bool) ?? true
}

func requireMinimumMacOS() {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    if v.majorVersion < 13 {
        die("reverse-scroll-cli requires macOS 13.0 or later (current: \(v.majorVersion).\(v.minorVersion))")
    }
}
```

- [ ] **Step 3: Create `ConflictDetection.swift`**

See Task 5 for the final content (bundleIdentifier-based). For now create stub that matches current behavior, to keep the refactor commit mechanical:

```swift
import AppKit

struct ConflictingTool {
    let displayName: String
    let bundleIdentifiers: [String]
}

let knownConflictingTools: [ConflictingTool] = [
    ConflictingTool(displayName: "Scroll Reverser",
                    bundleIdentifiers: ["com.pilotmoon.scroll-reverser"]),
    ConflictingTool(displayName: "Mos",
                    bundleIdentifiers: ["cn.caldis.Mos"]),
    ConflictingTool(displayName: "LinearMouse",
                    bundleIdentifiers: ["com.lujjjh.LinearMouse"]),
    ConflictingTool(displayName: "UnnaturalScrollWheels",
                    bundleIdentifiers: ["com.theron.UnnaturalScrollWheels"]),
    ConflictingTool(displayName: "Mac Mouse Fix",
                    bundleIdentifiers: ["com.nuebling.mac-mouse-fix"]),
]

func runningConflictingTools() -> [String] {
    let bundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
    return knownConflictingTools.compactMap { tool in
        tool.bundleIdentifiers.contains(where: bundleIDs.contains) ? tool.displayName : nil
    }
}
```

- [ ] **Step 4: Create `DaemonStatus.swift`**

See Task 4 for the launchctl-based content; stub here with current pgrep behavior kept inline to isolate Task 3 as pure move:

```swift
import Foundation

func isDaemonRunning() -> Bool {
    let selfPID = ProcessInfo.processInfo.processIdentifier
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-f", "reverse-scroll-cli --(daemon|foreground)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    let output = String(data: data, encoding: .utf8) ?? ""
    return output.split(separator: "\n")
        .compactMap { Int32($0) }
        .contains { $0 != selfPID }
}
```

- [ ] **Step 5: Create `Status.swift`**

```swift
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
```

- [ ] **Step 6: Create `EventTap.swift`**

```swift
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
```

- [ ] **Step 7: Create new `main.swift`** (entry only)

```swift
import Foundation

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
    print("""
    reverse-scroll-cli v\(version)

    Usage:
      reverse-scroll-cli              Show status
      reverse-scroll-cli --foreground Run in foreground (testing)
      reverse-scroll-cli --version    Show version

    Install: brew install --cask reverse-scroll-cli
    """)
default:
    die([
        "Unknown option: \(args.first!)",
        "Run with --help for usage.",
    ])
}
```

- [ ] **Step 8: Create temporary `Version.swift`** (Task 6 replaces this with build-injected version)

```swift
let version = "0.2.0-dev"
```

- [ ] **Step 9: Delete old file**

```bash
rm Sources/main.swift
```

- [ ] **Step 10: Update Makefile for `swift build`**

Replace `build:` and `bundle:` targets:

```makefile
APP_NAME = ReverseScrollCLI
BINARY_NAME = reverse-scroll-cli
VERSION = 0.2.0-dev
MIN_MACOS = 13.0
BUNDLE_ID = com.dongzhenye.reverse-scroll-cli

BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources

.PHONY: all clean build bundle zip

all: bundle

build:
	@mkdir -p $(BUILD_DIR)
	swift build -c release --arch arm64 --arch x86_64
	cp .build/apple/Products/Release/$(BINARY_NAME) $(BUILD_DIR)/$(BINARY_NAME)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/
	cp Resources/Info.plist $(CONTENTS)/
	codesign --force --deep --sign - --identifier $(BUNDLE_ID) $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

zip: bundle
	@mkdir -p $(BUILD_DIR)/LaunchAgent
	cp LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist $(BUILD_DIR)/LaunchAgent/
	cd $(BUILD_DIR) && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Created $(BUILD_DIR)/$(APP_NAME).app.zip"

clean:
	rm -rf $(BUILD_DIR) .build
```

- [ ] **Step 11: Verify build**

Run: `make clean && make bundle && build/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli --version`
Expected: `reverse-scroll-cli v0.2.0-dev`

- [ ] **Step 12: Manual sanity check — status + foreground**

Run: `build/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli`
Expected: one of the three documented status states.

Run: `build/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli --foreground` (Ctrl-C after verifying scroll reversal on mouse)
Expected: banner + working reversal on mouse wheel; trackpad untouched.

- [ ] **Step 13: Commit**

```bash
git add -A
git commit -m "refactor: split main.swift into SwiftPM modules"
```

---

### Task 4: Replace `pgrep` with launchctl-based daemon check

**Files:**
- Modify: `Sources/ReverseScrollCLI/DaemonStatus.swift`
- Create: `Tests/ReverseScrollCLITests/DaemonStatusTests.swift` *(skipped — depends on live launchctl; documented instead)*

- [ ] **Step 1: Rewrite `DaemonStatus.swift`**

```swift
import Foundation

private let launchAgentLabel = "com.dongzhenye.reverse-scroll-cli"

/// Return true if the LaunchAgent is loaded AND has a live PID.
/// Uses `launchctl print` under gui/<uid>, which is the documented query path
/// for per-user agents on macOS 10.11+. Falls back to returning false on any
/// parse failure — status output will then suggest `brew reinstall`.
func isDaemonRunning() -> Bool {
    let uid = getuid()
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    task.arguments = ["print", "gui/\(uid)/\(launchAgentLabel)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do {
        try task.run()
    } catch {
        return false
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard task.terminationStatus == 0,
          let output = String(data: data, encoding: .utf8) else {
        return false
    }
    // `launchctl print` for an agent with a live child shows `pid = <n>`.
    // Agents that are loaded but not currently running show `state = not running`.
    return output.contains(" pid = ")
}
```

- [ ] **Step 2: Verify on current running daemon**

Run: `make bundle && build/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli`
Expected (if installed and running): `Running ✓  Accessibility ✓`
Expected (if not installed): `Not running ✗`

Cross-check the shell: `launchctl print gui/$(id -u)/com.dongzhenye.reverse-scroll-cli | grep -E 'pid|state'`

- [ ] **Step 3: Commit**

```bash
git add Sources/ReverseScrollCLI/DaemonStatus.swift
git commit -m "fix: use launchctl print for daemon status check"
```

---

### Task 5: Conflict detection via `bundleIdentifier`

**Files:**
- Modify: `Sources/ReverseScrollCLI/ConflictDetection.swift` (already shipped in Task 3 step 3)
- Create: `Tests/ReverseScrollCLITests/ConflictDetectionTests.swift`

*Note: Task 3 already introduced the bundleIdentifier-based structure. This task adds test coverage and verifies the bundle IDs against reality.*

- [ ] **Step 1: Verify bundle IDs are correct**

Install each competitor in a throwaway way or check their released `.app` bundles:

```bash
for app in "Scroll Reverser" "Mos" "LinearMouse" "UnnaturalScrollWheels" "Mac Mouse Fix"; do
  defaults read "/Applications/$app.app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "$app: not installed"
done
```

If any bundle ID is wrong, update `knownConflictingTools` in `ConflictDetection.swift`. If a tool isn't locally installable, verify from its public GitHub repo `Info.plist`.

- [ ] **Step 2: Write test**

```swift
import XCTest
@testable import ReverseScrollCLI

final class ConflictDetectionTests: XCTestCase {
    func test_allToolsHaveAtLeastOneBundleIdentifier() {
        for tool in knownConflictingTools {
            XCTAssertFalse(tool.bundleIdentifiers.isEmpty, "\(tool.displayName) has no bundle IDs")
            XCTAssertFalse(tool.displayName.isEmpty)
        }
    }

    func test_bundleIdentifiersAreReverseDNS() {
        for tool in knownConflictingTools {
            for bid in tool.bundleIdentifiers {
                XCTAssertTrue(bid.contains("."), "\(bid) does not look like reverse-DNS")
            }
        }
    }
}
```

- [ ] **Step 3: Run tests**

Run: `swift test`
Expected: both tests pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/ReverseScrollCLI/ConflictDetection.swift Tests/
git commit -m "fix: detect conflicts by bundle identifier (locale-safe)"
```

---

### Task 6: Build-time version injection (single source of truth)

**Files:**
- Modify: `Makefile`
- Modify: `Sources/ReverseScrollCLI/Version.swift` (will be generated)
- Modify: `.gitignore`
- Modify: `Resources/Info.plist` (make version a placeholder substituted at build)
- Create: `Tests/ReverseScrollCLITests/VersionTests.swift`

- [ ] **Step 1: Replace `Info.plist` version with placeholders**

```xml
<key>CFBundleVersion</key>
<string>__VERSION__</string>
<key>CFBundleShortVersionString</key>
<string>__VERSION__</string>
```

- [ ] **Step 2: Make `Version.swift` generated**

Add to `.gitignore`:
```
Sources/ReverseScrollCLI/Version.swift
```

Add a committed template at `Sources/ReverseScrollCLI/Version.swift.in`:
```swift
// Auto-generated by make. Do not edit.
let version = "__VERSION__"
```

Remove the tracked `Version.swift` and commit the template:
```bash
git rm --cached Sources/ReverseScrollCLI/Version.swift
git add Sources/ReverseScrollCLI/Version.swift.in .gitignore
```

- [ ] **Step 3: Makefile generates Version.swift + substituted Info.plist**

```makefile
.PHONY: version

version:
	@sed 's/__VERSION__/$(VERSION)/g' Sources/ReverseScrollCLI/Version.swift.in > Sources/ReverseScrollCLI/Version.swift
	@sed 's/__VERSION__/$(VERSION)/g' Resources/Info.plist > $(BUILD_DIR)/Info.plist

build: version
	@mkdir -p $(BUILD_DIR)
	swift build -c release --arch arm64 --arch x86_64
	cp .build/apple/Products/Release/$(BINARY_NAME) $(BUILD_DIR)/$(BINARY_NAME)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/
	cp $(BUILD_DIR)/Info.plist $(CONTENTS)/
	codesign --force --deep --sign - --identifier $(BUNDLE_ID) $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"
```

Bump `VERSION = 0.2.0` in the Makefile.

- [ ] **Step 4: Write version test**

```swift
import XCTest
@testable import ReverseScrollCLI

final class VersionTests: XCTestCase {
    func test_versionIsSemver() {
        let pattern = #"^\d+\.\d+\.\d+(-[a-z0-9.]+)?$"#
        XCTAssertNotNil(version.range(of: pattern, options: .regularExpression),
                        "version '\(version)' is not semver-shaped")
    }
}
```

- [ ] **Step 5: Verify**

Run: `make clean && make bundle`
Run: `build/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli --version`
Expected: `reverse-scroll-cli v0.2.0`
Run: `/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" build/ReverseScrollCLI.app/Contents/Info.plist`
Expected: `0.2.0`
Run: `swift test`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: single-source version via build-time injection"
```

---

### Task 7: Migrate Cask to `bootstrap/bootout`

**Files:**
- Modify: `Cask/reverse-scroll-cli.rb`

- [ ] **Step 1: Update Cask**

```ruby
cask "reverse-scroll-cli" do
  version "0.2.0"
  sha256 "TODO"  # filled in by Task 13

  url "https://github.com/dongzhenye/reverse-scroll-cli/releases/download/v#{version}/ReverseScrollCLI.app.zip"
  name "ReverseScrollCLI"
  desc "Lightweight CLI daemon to reverse mouse scroll direction on macOS"
  homepage "https://github.com/dongzhenye/reverse-scroll-cli"

  depends_on macos: ">= :ventura"

  app "ReverseScrollCLI.app"
  binary "#{appdir}/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli"

  postflight do
    plist = "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
    system_command "cp",
      args: ["#{staged_path}/LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist", plist],
      sudo: false
    # bootout is a no-op if the label is not currently loaded.
    system_command "/bin/launchctl",
      args: ["bootout", "gui/#{Process.uid}/com.dongzhenye.reverse-scroll-cli"],
      sudo: false,
      must_succeed: false
    system_command "/bin/launchctl",
      args: ["bootstrap", "gui/#{Process.uid}", plist],
      sudo: false
  end

  uninstall_postflight do
    plist = "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
    system_command "/bin/launchctl",
      args: ["bootout", "gui/#{Process.uid}/com.dongzhenye.reverse-scroll-cli"],
      sudo: false,
      must_succeed: false
    system_command "rm",
      args: ["-f", plist],
      sudo: false
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add Cask/reverse-scroll-cli.rb
git commit -m "fix(cask): use launchctl bootstrap/bootout (deprecation)"
```

---

### Task 8: Sync `product.md` and `architecture.md` to code

**Files:**
- Modify: `docs/product.md`
- Modify: `docs/architecture.md`

- [ ] **Step 1: Update `product.md`**

In the "Output Design" section, add a note that axis-2 (horizontal) scroll is intentionally passed through in v0.2.0.

In "How it works" / technical overview, correct the fields-negated list to three:
```
- scrollWheelEventDeltaAxis1 (integer line delta)
- scrollWheelEventPointDeltaAxis1 (pixel delta)
- scrollWheelEventFixedPtDeltaAxis1 (sub-pixel fixed-point delta)
```
and note that the read-all-then-write ordering is required because macOS recalculates PointDelta / FixedPt when DeltaAxis is set first.

- [ ] **Step 2: Update `architecture.md`**

Replace the size estimate table with the post-split reality, and add a "Module Map" section pointing at each `Sources/ReverseScrollCLI/*.swift`. Keep the CGEvent-tap snippet but fix the field-reversal example to show all three fields with the read-before-write ordering.

- [ ] **Step 3: Commit**

```bash
git add docs/product.md docs/architecture.md
git commit -m "docs: sync product + architecture to refactored code"
```

---

## Phase 2 — Release Hardening

### Task 9: Apple Developer Program enrollment (user action)

- [ ] **Step 1: User enrolls at https://developer.apple.com/programs/ ($99/yr)**
- [ ] **Step 2: User confirms "Developer ID Application" certificate is available in Keychain Access**
- [ ] **Step 3: User generates App Store Connect API key** (Issuer ID + Key ID + `.p8` file) and stores it in `~/.appstoreconnect/private/AuthKey_<KeyID>.p8`

*Not committed — waits on external action. Plan proceeds when user confirms "done".*

---

### Task 10: Wire Developer ID signing into Makefile

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Parameterize signing identity**

```makefile
# Developer ID Application identity (full common name with team ID in parens)
SIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)".*/\1/')

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/
	cp $(BUILD_DIR)/Info.plist $(CONTENTS)/
	codesign --force --deep --options runtime --timestamp \
		--sign "$(SIGN_IDENTITY)" \
		--identifier $(BUNDLE_ID) \
		$(APP_BUNDLE)
	codesign --verify --deep --strict --verbose=2 $(APP_BUNDLE)
	@echo "Built and signed $(APP_BUNDLE)"
```

Note `--options runtime` (hardened runtime, required for notarization) and `--timestamp`.

- [ ] **Step 2: Verify**

Run: `make clean && make bundle`
Run: `codesign -dv --verbose=4 build/ReverseScrollCLI.app 2>&1 | grep -E 'Authority|TeamIdentifier|Runtime'`
Expected: Authority shows Developer ID Application + Apple intermediate + Apple Root; Runtime Version present; TeamIdentifier is your 10-char ID.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "build: sign bundle with Developer ID + hardened runtime"
```

---

### Task 11: Notarization target

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Add `notarize` target**

```makefile
# App Store Connect API key identifiers (set in env or override on command line)
AC_KEY_ID       ?= $(shell echo $$AC_KEY_ID)
AC_ISSUER_ID    ?= $(shell echo $$AC_ISSUER_ID)
AC_KEY_PATH     ?= $(HOME)/.appstoreconnect/private/AuthKey_$(AC_KEY_ID).p8

notarize: zip
	@test -n "$(AC_KEY_ID)" || (echo "AC_KEY_ID not set"; exit 1)
	xcrun notarytool submit $(BUILD_DIR)/$(APP_NAME).app.zip \
		--key $(AC_KEY_PATH) \
		--key-id $(AC_KEY_ID) \
		--issuer $(AC_ISSUER_ID) \
		--wait
	xcrun stapler staple $(APP_BUNDLE)
	# Re-zip with stapled ticket
	cd $(BUILD_DIR) && rm -f $(APP_NAME).app.zip && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Notarized and stapled — $(BUILD_DIR)/$(APP_NAME).app.zip ready for release"
```

- [ ] **Step 2: Run notarization**

Run: `AC_KEY_ID=XXX AC_ISSUER_ID=YYY make notarize`
Expected: notarytool returns `status: Accepted`; stapler confirms.

Run: `spctl --assess --type execute --verbose build/ReverseScrollCLI.app`
Expected: `accepted  source=Notarized Developer ID`.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "build: add notarize target (notarytool + stapler)"
```

---

### Task 12: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write workflow**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Show toolchain
        run: swift --version
      - name: Build
        run: swift build -c release
      - name: Test
        run: swift test
      - name: Smoke — version
        run: .build/release/reverse-scroll-cli --version
```

- [ ] **Step 2: Push branch and verify run is green**

(Will happen naturally when the PR opens; include a local `swift build && swift test` check before commit.)

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add build + test + version smoke"
```

---

### Task 13: Cut GitHub Release v0.2.0 + update Cask sha256

**Files:**
- Modify: `Cask/reverse-scroll-cli.rb`

- [ ] **Step 1: Build, sign, notarize**

Run: `make clean && AC_KEY_ID=... AC_ISSUER_ID=... make notarize`
Expected: notarized `build/ReverseScrollCLI.app.zip` ready.

- [ ] **Step 2: Compute sha256**

Run: `shasum -a 256 build/ReverseScrollCLI.app.zip`
Record the hash.

- [ ] **Step 3: Create git tag and release**

```bash
git tag v0.2.0
git push origin v0.2.0
gh release create v0.2.0 build/ReverseScrollCLI.app.zip \
  --title "v0.2.0 — Quality refactor & notarized release" \
  --generate-notes
```

- [ ] **Step 4: Update Cask with real sha256**

Edit `Cask/reverse-scroll-cli.rb`, replace `sha256 "TODO"` with the recorded hash.

- [ ] **Step 5: Commit**

```bash
git add Cask/reverse-scroll-cli.rb
git commit -m "chore(cask): real sha256 for v0.2.0 release"
```

---

### Task 14: Create `dongzhenye/homebrew-tap` repo + publish Cask

*This is a cross-repo action. The file operations happen in a separate repository.*

- [ ] **Step 1: Create repo**

```bash
gh repo create dongzhenye/homebrew-tap --public --description "Homebrew tap for Zhenye's tools"
cd /path/to/new/clone
mkdir -p Casks
```

- [ ] **Step 2: Copy Cask**

```bash
cp /path/to/reverse-scroll-cli/Cask/reverse-scroll-cli.rb Casks/reverse-scroll-cli.rb
git add Casks/reverse-scroll-cli.rb
git commit -m "feat: add reverse-scroll-cli cask"
git push
```

- [ ] **Step 3: End-to-end install test**

```bash
brew tap dongzhenye/tap
brew install --cask reverse-scroll-cli
launchctl print gui/$(id -u)/com.dongzhenye.reverse-scroll-cli | grep pid
reverse-scroll-cli
```
Expected: installs cleanly, daemon starts (user grants Accessibility on first run), `reverse-scroll-cli` reports `Running ✓`.

- [ ] **Step 4: Teardown test**

```bash
brew uninstall --cask reverse-scroll-cli
launchctl print gui/$(id -u)/com.dongzhenye.reverse-scroll-cli 2>&1 | head -1
```
Expected: returns "Could not find service" — bootout ran.

---

### Task 15: Post-release doc sweep

**Files:**
- Modify: `docs/roadmap.md`
- Modify: `README.md`

- [ ] **Step 1: Mark v0.2.0 done in roadmap; set v0.3.0 "in progress"**

- [ ] **Step 2: README — replace "future versions will be notarized" language** (currently in Gatekeeper troubleshooting), since 0.2.0 is the first notarized build.

- [ ] **Step 3: Commit + merge feature branch**

```bash
git add docs/roadmap.md README.md
git commit -m "docs: mark v0.2.0 shipped"
git checkout main
git merge --no-ff feat/v0.2.0-quality-refactor -m "merge: v0.2.0 quality refactor & release"
git push origin main
```

---

## Self-Review (2026-04-14)

**Spec coverage:**
- ✅ Version unification (Task 6)
- ✅ `pgrep` → `launchctl` (Task 4)
- ✅ Conflict detection via bundleIdentifier (Task 5)
- ✅ `launchctl load/unload` → `bootstrap/bootout` (Task 7)
- ✅ `die()` helper (Task 3 step 1)
- ✅ Module split (Tasks 2, 3)
- ✅ Apple Developer + signing + notarization (Tasks 9, 10, 11)
- ✅ Homebrew tap + release (Tasks 13, 14)
- ✅ CI (Task 12)
- ✅ Doc sync (Tasks 1, 8, 15)

**Placeholder scan:** No "TBD / add appropriate X / handle edge cases" strings. Code blocks show actual code. `sha256 "TODO"` in the Cask is intentional — removed in Task 13.

**Type consistency:** `knownConflictingTools` / `ConflictingTool` / `displayName` / `bundleIdentifiers` used identically in Task 3 step 3 and Task 5 test. `version` constant referenced consistently from Tasks 3, 6, 12.
