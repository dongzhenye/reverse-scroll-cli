# reverse-scroll-cli — Product Spec

> **Created**: 2026-03-02
> **Status**: Design complete — ready for implementation
> **Author**: Zhenye Dong

**Reverse mouse scroll on macOS. Lightweight CLI, no GUI.**

## 1. Problem

macOS forces mouse and trackpad to share the same "Natural Scrolling" setting. Both UI toggles in System Settings write to a single key (`com.apple.swipescrolldirection`). macOS Sequoia split the UI panels but the underlying boolean remains shared.

This is Apple's intentional design — they treat scroll direction as a system-wide user preference. But the physical metaphor is fundamentally different:

- **Trackpad**: finger pushes content directly → natural scrolling feels right
- **Mouse wheel**: rotating a wheel to move a viewport → traditional scrolling feels right

Most users who connect an external mouse want: **natural for trackpad, traditional for mouse**. macOS won't let them.

### Previous Workarounds

- **Logi Options+**: Works, but bloated (hundreds of MB), introduces unneeded features, has crashed
- **GUI apps** (Scroll Reverser, Mos, etc.): Work well, but all require menu bar icons, preferences windows, and manual configuration

## 2. Product Vision

A zero-config CLI daemon that reverses mouse scroll direction on macOS. Install and forget.

**One sentence**: `brew install` to fix, `brew uninstall` to revert. Nothing else.

### Taglines

| Context | Text |
|---------|------|
| GitHub description | Reverse mouse scroll on macOS. Lightweight CLI, no GUI. |
| Homebrew desc | Lightweight CLI daemon to reverse mouse scroll direction on macOS |
| README hero | Reverse mouse scroll direction on macOS. A zero-config CLI daemon — no menu bar, no preferences window. Just `brew install` and it works. |

## 3. Naming

### User Mental Model

When a user hits this problem, their first reaction is:

> "I want to **reverse** my **mouse scroll** direction"

Analysis of Reddit / StackExchange / Apple Discussions post titles confirmed the high-frequency keywords: **reverse**, **scroll**, **mouse**, **direction**. Users Google "reverse mouse scroll macOS".

### Decision Process

**Round 1 — Keyword alignment** (eliminated non-matching names):

| Eliminated | Reason |
|------------|--------|
| `splitscroll` | Users think "reverse", not "split" |
| `natscroll` | Abbreviation of "natural scroll" — wrong framing |
| `scrollfix` / `scroll-fix` | Sounds like a one-time fix, not a persistent daemon |
| `revscroll` / `mouserev` | Abbreviations hurt SEO |

**Round 2 — Format and positioning** (finalists):

| Candidate | SEO | Brand Independence | Length | Verdict |
|-----------|-----|-------------------|--------|---------|
| `reversescroll` | Good — "reverse scroll" | Independent | 13 chars | No hyphens hurts readability |
| `reverse-scroll` | Best — hyphens are natural word separators for search engines | Independent | 14 chars | Strong, but missing differentiator |
| `scroll-reverser-cli` | Good — rides existing search volume | **Bad** — looks like Scroll Reverser's official CLI | 19 chars | Rejected: brand confusion |
| **`reverse-scroll-cli`** | **Best** — "reverse scroll cli macOS" hits all keywords | **Good** — independent brand, `-cli` states the differentiator | 18 chars | **Winner** |

### Final Decision: `reverse-scroll-cli`

**Why this name works**:

1. **SEO**: "reverse mouse scroll on macOS" — directly hits `reverse` + `scroll`. Adding `cli` captures the "lightweight alternative" search intent
2. **Positioning via suffix**: `-cli` is not just a technical label — it's a value statement. It says: "you know those GUI scroll reversers? This is the CLI version — lighter, simpler, invisible"
3. **Respectful differentiation**: Acknowledges the scroll-reverser category without copying any specific brand name. The improvement (CLI, zero-config, no GUI) is stated in the name itself
4. **Homebrew convention**: `-cli` suffix is an [officially recommended pattern](https://docs.brew.sh/Cask-Cookbook) for distinguishing CLI from GUI tools

## 4. Interaction Design

### Final Design

```bash
brew install --cask reverse-scroll-cli      # install + start + auto-login
brew uninstall --cask reverse-scroll-cli    # stop + remove + done

reverse-scroll-cli                          # help/status message
reverse-scroll-cli --version                # version info
```

### Output Design

The binary has two modes: **status** (no args) and **daemon** (`--daemon` for LaunchAgent, `--foreground` for testing).

No-args output is context-aware — shows only what the user needs right now, no version (that's `--version`'s job), no self-introduction (the name already says it all).

**State 1 — Running, permission granted** (most common: user forgot about it, or just checking)
```
Running ✓  Accessibility ✓
Mouse: traditional  |  Trackpad: natural
Uninstall: brew uninstall --cask reverse-scroll-cli
```

**State 2 — Running, permission missing** (e.g., macOS upgrade revoked permission)
```
Running ✓  Accessibility ✗
Grant: System Settings > Privacy & Security > Accessibility
```

**State 3 — Service not running** (LaunchAgent crashed or was stopped)
```
Not running ✗
Restart: brew reinstall --cask reverse-scroll-cli
Test:    reverse-scroll-cli --foreground
```

**`--foreground`** (testing/debugging — version shown here since it's a diagnostic context)
```
reverse-scroll-cli v0.1.0
Running in foreground — Ctrl-C to stop.
```

**`--version`**
```
reverse-scroll-cli v0.1.0
```

### Design Rationale (Decision Log)

Three interaction models were evaluated:

**Option A — Full CLI (rejected)**
```
reverse-scroll-cli install / uninstall / status
```
Rejected because: reinvents lifecycle management that Homebrew + launchd already handle. Users must learn subcommands for no added value.

**Option B — Zero-CLI (adopted)**
```
brew install --cask reverse-scroll-cli    # everything happens here
brew uninstall --cask reverse-scroll-cli  # and here
reverse-scroll-cli                        # just help/status, not a required step
```
Adopted because: matches users' existing mental model (`brew install` = done). No new concepts to learn.

**Option C — Minimal CLI (considered)**
```
reverse-scroll-cli                  # foreground daemon
reverse-scroll-cli service install  # manual LaunchAgent
```
Not adopted because: `service install` is still redundant if brew handles it. But the foreground mode concept was kept — running the binary directly is useful for testing.

**Key insight**: `install`/`uninstall`/`status` are solving problems that don't exist when the package manager handles lifecycle. The binary itself should be the daemon, nothing more. Running with no args doubles as a friendly help message that tells users "you're already set up, nothing to do here."

## 5. Competitive Landscape

### Existing Tools

| Tool | Stars | Latest Release | Scope | GUI? |
|------|-------|----------------|-------|------|
| [Mos](https://github.com/Caldis/Mos) | 19.1k | Feb 2026 (v4.0) | Direction + smooth scroll | Menu bar app |
| [LinearMouse](https://github.com/linearmouse/linearmouse) | 5.6k | Sep 2025 (v0.10.2) | Full mouse/trackpad customization | Preferences app |
| [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels) | 4k | Aug 2022 (v1.3) | Direction + acceleration | Menu bar app (stale) |
| [Scroll Reverser](https://github.com/pilotmoon/Scroll-Reverser) | 3.3k | Jun 2024 (v1.9) | Direction only | Menu bar app |
| [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) | — | Active | Full mouse enhancement | Preferences pane (paid) |

### Market Gap

Every existing tool is a GUI application with menu bar icon and preferences window. None offer:
- Pure CLI / invisible daemon
- `brew install` as the only setup step
- Zero configuration (just works with sensible defaults)

### Differentiation

| Dimension | Existing Tools | reverse-scroll-cli |
|-----------|---------------|-------------------|
| Setup | Open app → configure → add to login items | `brew install` (done) |
| Teardown | Quit app → remove from login items → delete | `brew uninstall` (done) |
| Menu bar icon | Yes (always visible) | None |
| Preferences window | Yes | None |
| Config file | Some | None |
| Features | Multiple (smooth scroll, acceleration, per-app) | One (reverse mouse scroll) |

## 6. Edge Cases

### Unsupported macOS Version

Minimum: macOS 13.0 (Ventura). Covers last 3 major versions. Below that:
```
reverse-scroll-cli requires macOS 13.0 or later (current: 12.7)
```
One line, exit 1. No explanation needed — users on old macOS are technical enough to understand.

Not-macOS is a non-issue: Swift compiles to macOS-only target, binary won't exist on other platforms.

### Natural Scrolling Already OFF

The tool always does one thing: negate mouse scroll delta on axis 1 (vertical). Specifically, three fields are negated — `scrollWheelEventDeltaAxis1` (line delta), `scrollWheelEventPointDeltaAxis1` (pixel delta), and `scrollWheelEventFixedPtDeltaAxis1` (sub-pixel fixed-point) — with a read-before-write ordering: all three originals are captured first, then all three are written, because setting `DeltaAxis1` causes macOS to internally recalculate `PointDeltaAxis1` and `FixedPtDeltaAxis1`. Axis 2 (horizontal scroll) is intentionally passed through unchanged; per-axis horizontal reversal is deferred to a future enhancement (v2.x).

The tool does not read or adapt to the system setting. This means:

| System Setting | Tool Effect | Result |
|---------------|------------|--------|
| Natural ON (default) | Reverse mouse | Trackpad: natural ✓, Mouse: traditional ✓ |
| Natural OFF | Reverse mouse | Trackpad: traditional, Mouse: natural ← inverted |

Design decision: **detect and warn, don't auto-adapt.**

Rationale:
1. **Predictability** — tool always does the same thing. User doesn't need to guess what mode it's in.
2. **Complexity** — auto-adapting requires monitoring `NSUserDefaultsDidChangeNotification` and dynamically flipping behavior. Doubles the state space.
3. **Product name** — "reverse scroll" means reverse scroll. Not "intelligently manage scroll directions."
4. **Real usage** — 99% of users enable Natural Scrolling (for trackpad), then install this tool for the mouse. The inverse case is rare.

No-args output when Natural OFF is detected:
```
Running ✓  Accessibility ✓
⚠ Natural scrolling is OFF — mouse is being reversed to "natural" direction.
Recommended: enable Natural Scrolling, this tool handles the mouse.
```

### Conflicting Scroll Tools

If another scroll tool (Mos, Scroll Reverser, etc.) is running, two event taps both negate the delta → net zero effect. Detection: check running processes for known tool names, warn in no-args output:
```
Running ✓  Accessibility ✓
⚠ Scroll Reverser is also running — two reversals cancel out.
Quit Scroll Reverser or uninstall this tool.
```

## 7. References

- [shadowfacts.net — Auto-switch scroll direction](https://shadowfacts.net/2021/auto-switch-scroll-direction/)
- [Apple CGEventCreateScrollWheelEvent](https://developer.apple.com/documentation/coregraphics/cgeventcreatescrollwheelevent)
- [NSEvent.isDirectionInvertedFromDevice](https://developer.apple.com/documentation/appkit/nsevent/isdirectioninvertedfromdevice)
- [Scroll Reverser source — MouseTap.m](https://github.com/pilotmoon/Scroll-Reverser/blob/master/MouseTap.m)
- [UnnaturalScrollWheels source](https://github.com/ther0n/UnnaturalScrollWheels)
- [Homebrew Cask Cookbook — naming conventions](https://docs.brew.sh/Cask-Cookbook)
