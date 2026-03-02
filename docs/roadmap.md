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
- [ ] Manual test pass: mouse reversal, trackpad passthrough, status output states
- [ ] Device compatibility validation (USB mouse, Bluetooth mouse, Magic Mouse, trackpad)
- [ ] Homebrew-core submission

## Future (maybe)

- [ ] Alternate detection method for Logitech mice
- [ ] Horizontal scroll reversal option
- [ ] Notarization for Gatekeeper
- [ ] Per-app exceptions (e.g., don't reverse in certain apps)
