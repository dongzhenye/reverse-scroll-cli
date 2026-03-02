# reverse-scroll-cli — Development Roadmap

## v0.1.0 — MVP

- [x] Swift CLI daemon with CGEvent tap
- [x] `isContinuous` mouse detection
- [x] `.app` bundle with `LSUIElement=true`
- [x] Homebrew cask formula
- [x] LaunchAgent auto-registration via cask postflight
- [x] `--version` flag
- [x] Help/status output when run with no args
- [x] README with install instructions

## v0.2.0 — Polish

- [ ] `--verbose` flag for debug logging
- [ ] Homebrew-core submission

### Testing Plan

#### Manual Testing Matrix

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| 1 | **Mouse scroll reversal** | `--foreground`, scroll mouse wheel down | Content scrolls down (traditional direction) |
| 2 | **Trackpad passthrough** | `--foreground`, two-finger swipe down on trackpad | Content scrolls up (natural direction preserved) |
| 3 | **Magic Mouse passthrough** | `--foreground`, swipe on Magic Mouse surface | Natural scrolling preserved (continuous event) |
| 4 | **Horizontal scroll unchanged** | `--foreground`, tilt/shift mouse wheel horizontally | Horizontal scroll direction unchanged |
| 5 | **No-args status: running** | Start daemon, run `reverse-scroll-cli` | Shows `Running ✓  Accessibility ✓` with direction info |
| 6 | **No-args status: not running** | Kill daemon, run `reverse-scroll-cli` | Shows `Not running ✗` with restart instructions |
| 7 | **No-args status: no permission** | Revoke Accessibility, start daemon | Shows `Accessibility ✗` with grant instructions |
| 8 | **Natural scrolling OFF warning** | Disable Natural Scrolling in System Settings, run no-args | Shows `⚠ Natural scrolling is OFF` warning |
| 9 | **Conflicting tool warning** | Run Scroll Reverser + this tool, run no-args | Shows `⚠ Scroll Reverser is also running` warning |
| 10 | **--foreground Ctrl-C** | Run `--foreground`, press Ctrl-C | Prints `Stopped.`, exits cleanly |
| 11 | **SIGTERM clean exit** | Run `--daemon`, send SIGTERM | Process exits cleanly |
| 12 | **Tap timeout re-enable** | Run daemon, let macOS disable tap (heavy load) | Tap re-enables automatically |
| 13 | **LaunchAgent auto-start** | Install via cask, log out/in | Daemon starts automatically on login |
| 14 | **LaunchAgent KeepAlive** | Kill daemon process | launchd restarts it automatically |
| 15 | **brew install flow** | `brew install --cask reverse-scroll-cli` | App installed, LaunchAgent loaded, daemon running |
| 16 | **brew uninstall flow** | `brew uninstall --cask reverse-scroll-cli` | LaunchAgent unloaded, app removed, scroll back to default |
| 17 | **Permission prompt on first run** | Run binary without Accessibility permission | System prompt appears, binary exits with guidance |
| 18 | **macOS < 13 rejection** | (simulated) Run on older macOS | Shows version requirement error, exits 1 |
| 19 | **Unknown flag** | `reverse-scroll-cli --foo` | Shows error + `--help` hint, exits 1 |

#### Device Compatibility

| Device | Detection Method | Expected Behavior |
|--------|-----------------|-------------------|
| Standard USB mouse | `isContinuous == 0` | Scroll reversed ✓ |
| Standard Bluetooth mouse | `isContinuous == 0` | Scroll reversed ✓ |
| Built-in trackpad | `isContinuous != 0` | Natural preserved ✓ |
| Magic Trackpad (external) | `isContinuous != 0` | Natural preserved ✓ |
| Magic Mouse | `isContinuous != 0` | Natural preserved ✓ |
| Logitech w/ Options+ | `isContinuous` may be wrong | ⚠ Known risk — v0.2.0 fallback detection |

#### Regression Checklist (run before each release)

1. Fresh `make clean && make bundle` compiles without warnings
2. `file` confirms universal binary (arm64 + x86_64)
3. `--version` prints correct version
4. `--help` output matches README
5. No-args status output covers all 4 states
6. `--foreground` + mouse scroll → reversed
7. `--foreground` + trackpad scroll → unchanged
8. Ctrl-C exits cleanly with "Stopped."
9. `.app` bundle structure: `Contents/{MacOS/reverse-scroll-cli, Info.plist}`
10. Info.plist version matches `Sources/main.swift` version constant

## Future (maybe)

- [ ] Alternate detection method for Logitech mice
- [ ] Horizontal scroll reversal option
- [ ] Notarization for Gatekeeper
- [ ] Per-app exceptions (e.g., don't reverse in certain apps)
