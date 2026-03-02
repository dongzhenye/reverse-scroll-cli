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

## v0.2.0 — Open Source Prep & Distribution (P0)

**Goal:** Make it production-ready and publicly discoverable.

### Phase 1: Distribution (Priority 1)
- [ ] **Homebrew tap setup:**
  - [ ] Create `dongzhenye/homebrew-tap` repo
  - [ ] Add `Casks/reverse-scroll-cli.rb` with correct structure
  - [ ] Test: `brew tap dongzhenye/tap && brew install --cask reverse-scroll-cli`
- [ ] **GitHub release v0.1.0:**
  - [ ] Run `make zip` to generate artifact
  - [ ] Create release: `gh release create v0.1.0 build/ReverseScrollCLI.app.zip`
  - [ ] Get sha256: `shasum -a 256 build/ReverseScrollCLI.app.zip`
  - [ ] Update cask with real sha256
- [ ] **Local cask install test:**
  - [ ] Verify postflight installs LaunchAgent
  - [ ] Verify daemon starts automatically
  - [ ] Test permission flow
  - [ ] Test all 4 status output states

### Phase 2: README Polish (Priority 2)
- [ ] **Add badges:**
  - [ ] License: MIT
  - [ ] macOS: 13.0+
  - [ ] GitHub stars
- [ ] **Add "Why CLI?" section** — positioning vs GUI tools
- [ ] **Add comparison table** — vs Scroll Reverser, Mos, LinearMouse
- [ ] **Add troubleshooting section:**
  - [ ] Permission not granted → System Settings path
  - [ ] Conflicting tools detected → how to check/remove
  - [ ] Natural scrolling OFF warning → why it matters
- [ ] **Add contributing guidelines** — basic PR workflow

### Phase 3: Open Source Checklist (Priority 3)
- [ ] **GitHub repo settings:**
  - [ ] Add topics: `macos`, `scroll`, `mouse`, `trackpad`, `cli`, `swift`
  - [ ] Add issue templates (bug report, feature request)
  - [ ] Add PR template
- [ ] **Security & privacy:**
  - [ ] Add SECURITY.md (vulnerability reporting)
  - [ ] Review code for any hardcoded paths/credentials
  - [ ] Confirm no telemetry/analytics
- [ ] **License verification:**
  - [ ] Confirm MIT license in all source files
  - [ ] Check dependencies (none currently)

### Phase 4: Quality & Polish (Priority 4)
- [ ] **Manual test pass:**
  - [ ] Mouse reversal works
  - [ ] Trackpad passthrough works
  - [ ] All 4 status states display correctly
- [ ] **Device compatibility validation:**
  - [ ] USB mouse
  - [ ] Bluetooth mouse
  - [ ] Magic Mouse
  - [ ] Trackpad
- [ ] **Fix remaining review issues:**
  - [ ] Migrate `launchctl load/unload` → `bootstrap/bootout` (deprecated API)
  - [ ] Add `--verbose` flag for debug logging (optional, can defer)
- [ ] **Set repo to public** — final step before v0.3.0

## v0.3.0 — Content & Outreach (P1)

**Goal:** Build awareness through authentic content and community engagement.

### Content Creation
- [ ] **Blog post draft** — `dongzhenye/blog` repo:
  - Title: "Building a Zero-Config macOS Scroll Reverser in 200 Lines of Swift"
  - Sections: Problem, Why CLI?, Architecture (CGEvent tap), Lessons (delta ordering bug), Comparison
  - Target: Dev.to, Medium, personal blog
- [ ] **X (Twitter) thread** — @dongzhenye:
  - Hook: "macOS forces mouse + trackpad to share scroll direction. I built a CLI fix."
  - 3-5 tweets: problem → solution → tech stack → GitHub link
  - Visuals: terminal demo GIF, comparison table screenshot
- [ ] **Products repo update** — `dongzhenye/products`:
  - Add reverse-scroll-cli entry with tagline, tech stack, status
  - Link to GitHub, blog post, Homebrew tap

### Community Outreach
- [ ] **Reddit engagement** — r/macOS, r/mac:
  - Target threads: "separate mouse trackpad scroll", "natural scrolling mouse"
  - Comment template: authentic, non-spammy, emphasize CLI differentiator
  - 4 high-traffic threads identified (2023-2025)
- [ ] **Apple Discussions / StackExchange** — answer existing questions with solution
- [ ] **Hacker News** — "Show HN" post (after blog + Reddit validation)
- [ ] **Product Hunt** — optional launch (if traction is good)

### Feedback Loop
- [ ] **Collect feedback** — GitHub issues, Reddit comments, X replies
- [ ] **Bug fixes** — address edge cases discovered by early users
- [ ] **Usage analytics** — track GitHub stars, cask installs (if tap has metrics)

## v0.4.0 — Homebrew-core Submission (P1)

**Goal:** Official distribution via `brew install reverse-scroll-cli`.

- [ ] **Homebrew-core PR** — submit cask to homebrew/homebrew-cask
- [ ] **Address review feedback** — cask style, naming, audit compliance
- [ ] **Merge & announce** — update README, post to Reddit/HN/X

## Future Enhancements (P2)

- [ ] **Alternate detection for Logitech mice** — fallback heuristic when `isContinuous` is wrong
- [ ] **Horizontal scroll reversal** — optional flag for tilt wheels
- [ ] **Notarization** — Apple Developer ID signing for Gatekeeper
- [ ] **Per-app exceptions** — config file to disable reversal in specific apps (e.g., games)
- [ ] **Telemetry opt-in** — anonymous usage stats (device types, macOS versions)

---

## Priority Rationale

**Phase 1 (Distribution):** Can't test or share without Homebrew tap + release artifact.

**Phase 2 (README):** First impression for users. Must be polished before public launch.

**Phase 3 (Open Source):** GitHub best practices. Important but not blocking distribution.

**Phase 4 (Quality):** Final validation before going public.

---

## Open Source Checklist Details

### README Enhancements

**Badges to add:**
```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![GitHub stars](https://img.shields.io/github/stars/dongzhenye/reverse-scroll-cli.svg)](https://github.com/dongzhenye/reverse-scroll-cli/stargazers)
```

**Why CLI? section:**
> All existing scroll reversal tools (Scroll Reverser, Mos, LinearMouse) are GUI applications with menu bar icons and preferences windows. If you just want mouse scroll reversed without configuration or visual clutter, this is the simplest option.

**Comparison table:**
| Tool | Type | Config | Size | Our Differentiator |
|------|------|--------|------|-------------------|
| reverse-scroll-cli | CLI daemon | Zero | 150KB | Install and forget |
| Scroll Reverser | Menu bar app | Preferences window | ~5MB | Established, feature-rich |
| LinearMouse | Preferences app | Full GUI | ~10MB | Per-device customization |
| Mos | Menu bar app | Per-app settings | ~8MB | Smooth scrolling |

**Troubleshooting section:**
- Permission not granted → System Settings path
- Conflicting tools detected → how to check/remove
- Natural scrolling OFF warning → why it matters

### GitHub Topics

Add these for discoverability:
- `macos`
- `scroll`
- `mouse`
- `trackpad`
- `cli`
- `swift`
- `homebrew`
- `accessibility`

### Issue Templates

**Bug Report:**
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior.

**Expected behavior**
What you expected to happen.

**Environment:**
- macOS version: [e.g., 14.2]
- Mouse model: [e.g., Logitech MX Master 3]
- Installation method: [brew cask / manual]

**Logs:**
Run `reverse-scroll-cli --verbose` and paste output.
```

**Feature Request:**
```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.
```

### SECURITY.md

```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please email dongzhenye@gmail.com.

Do not open a public issue for security vulnerabilities.

We will respond within 48 hours and work with you to address the issue.
```

---

## Content Strategy

### Blog Post Outline

**Title:** "Building a Zero-Config macOS Scroll Reverser in 200 Lines of Swift"

**Sections:**
1. **The Problem** — macOS ties mouse + trackpad scroll direction together
2. **Why CLI?** — Existing tools (Scroll Reverser, Mos) all have GUIs. Gap in market for "install and forget"
3. **Architecture** — CGEvent tap, `isContinuous` detection, `.app` bundle for stable permissions
4. **The Delta Ordering Bug** — macOS recalculates PointDelta/FixedPtDelta when DeltaAxis1 is set → must read all before writing
5. **Comparison** — vs Scroll Reverser (menu bar), vs LinearMouse (heavy), vs Logi Options+ (bloated)
6. **Lessons** — Swift for system tools, Homebrew cask distribution, Claude Code for PR review
7. **Try It** — `brew install --cask reverse-scroll-cli`

**Target platforms:** Dev.to (cross-post to Medium), personal blog, Hacker News "Show HN"

### X Thread Template

**Tweet 1 (Hook):**
> macOS forces your mouse and trackpad to share the same scroll direction.
> 
> Natural scrolling feels right on a trackpad, but wrong with a mouse wheel.
> 
> I built a CLI tool to fix this. Zero config, no GUI, just works.
> 
> 🧵 [1/4]

**Tweet 2 (Problem):**
> Existing solutions (Scroll Reverser, Mos, LinearMouse) all add menu bar icons and preferences windows.
> 
> I wanted something invisible. Install once, forget forever.
> 
> So I built reverse-scroll-cli: a 200-line Swift daemon that runs in the background.

**Tweet 3 (Tech):**
> How it works:
> • CGEvent tap intercepts scroll events
> • `isContinuous` field distinguishes mouse (discrete) from trackpad (continuous)
> • Negates mouse scroll delta, passes trackpad through
> • Packaged as .app bundle for stable Accessibility permission

**Tweet 4 (CTA):**
> Try it:
> ```
> brew install --cask reverse-scroll-cli
> ```
> 
> MIT licensed, open source.
> GitHub: [link]
> 
> If you've been frustrated by this macOS limitation, give it a shot. 🚀

**Visuals:**
- GIF: terminal showing `--foreground` mode + mouse scroll demo
- Screenshot: comparison table (reverse-scroll-cli vs competitors)

### Products Repo Entry

**File:** `dongzhenye/products/reverse-scroll-cli.md`

```markdown
# reverse-scroll-cli

**Tagline:** Reverse mouse scroll on macOS. Lightweight CLI, no GUI.

**Status:** v0.1.0 — MVP shipped (2026-03-02)

**Tech Stack:** Swift, CoreGraphics, Homebrew Cask

**Links:**
- GitHub: https://github.com/dongzhenye/reverse-scroll-cli
- Blog: [link after published]
- Install: `brew install --cask reverse-scroll-cli`

**Problem:** macOS forces mouse and trackpad to share scroll direction. Users want natural scrolling on trackpad, traditional on mouse.

**Solution:** Zero-config CLI daemon. Intercepts mouse scroll events via CGEvent tap, reverses direction, leaves trackpad untouched.

**Differentiator:** All existing tools (Scroll Reverser, Mos, LinearMouse) have GUIs. This is the first CLI-only option.

**Metrics:**
- GitHub stars: [track]
- Homebrew installs: [track if tap has metrics]
```

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
