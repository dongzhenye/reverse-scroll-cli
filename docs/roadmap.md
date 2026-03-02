# reverse-scroll-cli — Development Roadmap

## v0.1.0 — MVP ✅

- [x] Swift CLI daemon with CGEvent tap
- [x] `isContinuous` mouse detection
- [x] `.app` bundle with `LSUIElement=true`
- [x] Homebrew cask formula
- [x] LaunchAgent auto-registration via cask postflight
- [x] `--version` flag
- [x] Help/status output when run with no args
- [x] README with install instructions

## v0.2.0 — Distribution & Quality (P0)

**Goal:** Make it installable and reliable for early adopters.

- [ ] **Homebrew tap setup** — `dongzhenye/tap` for testing before core submission
- [ ] **Local cask install test** — verify postflight, LaunchAgent, permission flow
- [ ] **Manual test pass** — mouse reversal, trackpad passthrough, all 4 status states
- [ ] **Device compatibility validation** — USB mouse, Bluetooth mouse, Magic Mouse, trackpad
- [ ] **Fix remaining review issues:**
  - [ ] Migrate `launchctl load/unload` → `bootstrap/bootout` (deprecated API)
  - [ ] Add `--verbose` flag for debug logging
- [ ] **Release artifact** — `make zip`, upload to GitHub release, update cask sha256

## v0.3.0 — Community Validation (P1)

**Goal:** Get real-world feedback before Homebrew-core submission.

- [ ] **Reddit outreach** — authentic posts/comments in r/macOS, r/mac:
  - Target threads: "separate mouse trackpad scroll", "natural scrolling mouse"
  - Positioning: "I built a CLI alternative to Scroll Reverser — zero config, no menu bar"
  - Include: GitHub link, `brew install` command, comparison table
- [ ] **Apple Discussions / StackExchange** — answer existing questions with solution
- [ ] **Collect feedback** — GitHub issues, Reddit comments, usage patterns
- [ ] **Bug fixes** — address any edge cases discovered by early users

## v0.4.0 — Homebrew-core Submission (P1)

**Goal:** Official distribution via `brew install reverse-scroll-cli`.

- [ ] **Homebrew-core PR** — submit cask to homebrew/homebrew-cask
- [ ] **Address review feedback** — cask style, naming, audit compliance
- [ ] **Merge & announce** — update README, post to Reddit/HN

## Future Enhancements (P2)

- [ ] **Alternate detection for Logitech mice** — fallback heuristic when `isContinuous` is wrong
- [ ] **Horizontal scroll reversal** — optional flag for tilt wheels
- [ ] **Notarization** — Apple Developer ID signing for Gatekeeper
- [ ] **Per-app exceptions** — config file to disable reversal in specific apps (e.g., games)
- [ ] **Telemetry opt-in** — anonymous usage stats (device types, macOS versions)

---

## Priority Rationale

**P0 (v0.2.0):** Must work reliably for anyone who tries it. Homebrew tap allows safe testing before core submission.

**P1 (v0.3.0 → v0.4.0):** Community validation de-risks Homebrew-core submission. Real users will find edge cases we missed.

**P2 (Future):** Nice-to-haves that expand use cases but aren't blockers for the core value prop.

---

## Reddit Outreach Strategy

### Target Threads (2024-2025)

From search results, these are active discussions where our tool is directly relevant:

1. **r/mac** — "Turn off natural scrolling for mouse, retain for trackpad" (151 upvotes, 2023)
2. **r/MacOS** — "Natural scrolling isn't separated for mouse/trackpad" (2024)
3. **r/MacOS** — "Love macOS but hate that I cannot have separate scroll settings" (2025)
4. **r/mac** — "Separate scroll direction for touchpad and mouse" (2024)

### Comment Template (Authentic, Not Spammy)

> I had the same frustration and ended up building a CLI tool for this: [reverse-scroll-cli](https://github.com/dongzhenye/reverse-scroll-cli)
>
> It's basically Scroll Reverser but without the menu bar icon or preferences window. Just `brew install --cask reverse-scroll-cli` and it works.
>
> - Zero config (detects mouse vs trackpad automatically)
> - Invisible daemon (no GUI)
> - MIT licensed, ~200 lines of Swift
>
> I built it because I wanted something that just runs in the background and doesn't ask me to configure anything. If you're looking for a lightweight alternative, give it a shot.

### Positioning vs Competitors

| Tool | Pros | Cons | Our Differentiator |
|------|------|------|-------------------|
| Scroll Reverser | Free, reliable, popular | Menu bar icon, preferences window | CLI-only, zero config |
| LinearMouse | Feature-rich, modern | Heavy (full preferences app) | Minimal, single-purpose |
| Mos | Smooth scrolling + reversal | Complex settings, per-app config | Install and forget |
| Logi Options+ | Official Logitech support | Bloated (hundreds of MB), Logitech-only | Universal, 150KB binary |

**Key message:** "If you just want mouse scroll reversed and don't need 50 other features, this is the simplest option."
