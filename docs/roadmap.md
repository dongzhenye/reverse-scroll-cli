# reverse-scroll-cli — Development Roadmap

> **Conventions** — Phases (letters) track investment milestones; releases (SemVer) track code contracts. They're decoupled: only code-changing phases produce a `git tag`. Each phase is a single flat checklist; if scope feels too big, insert a new phase rather than adding sub-sections.

## Phase A — MVP ✅ (released as v0.1.0)

- [x] Swift CLI daemon with CGEvent tap
- [x] `isContinuous` mouse detection
- [x] `.app` bundle with `LSUIElement=true`
- [x] Homebrew cask formula
- [x] LaunchAgent auto-registration via cask postflight
- [x] `--version` flag
- [x] Help/status output when run with no args
- [x] README with install instructions

## Phase B — Quality Refactor & Public Release ✅ (released as v0.2.0, 2026-04-15)

[Release](https://github.com/dongzhenye/reverse-scroll-cli/releases/tag/v0.2.0)

- [x] SwiftPM migration + module split (main.swift → 8 focused files)
- [x] Single-source version string (build-time injection)
- [x] Replace `pgrep` with `launchctl print` for daemon status
- [x] Conflict detection via bundleIdentifier (locale-safe; fixed wrong Mos ID)
- [x] Migrate Cask from `launchctl load/unload` to `bootstrap/bootout`
- [x] Unified `die()` error helper
- [x] Pure-helper unit tests (conflict detection, version)
- [x] Sync `product.md` + `architecture.md` to refactored code
- [x] Apple Developer Program enrollment ($99)
- [x] Developer ID Application signing + hardened runtime + secure timestamp
- [x] Notarization via `xcrun notarytool --keychain-profile`
- [x] `dongzhenye/homebrew-tap` Cask updated to v0.2.0
- [x] GitHub Release v0.2.0 + real sha256 in Cask
- [x] GitHub Actions CI (routes through `make build` / `make test` for Makefile drift coverage)

## Phase C — Visual Infrastructure ✅ (released as v0.3.0, 2026-04-16)

[Release](https://github.com/dongzhenye/reverse-scroll-cli/releases/tag/v0.3.0)

**Goal:** Project's public-facing surface no longer looks amateur. Prerequisite for content + outreach phases.

- [x] **AppIcon.icns** — 1024×1024 PNG → `Resources/AppIcon.icns`; Makefile bundle step copies to `.app/Contents/Resources/`, `Info.plist` adds `CFBundleIconFile`. Generated 2026-04-15 via Nano Banana Pro (Gemini 3 Pro Image) on z-macmini → squircle + opposing arrows; source PNG kept at `Resources/AppIcon.png`.
- [x] **GitHub homepage 装修** — description + 8 topics set; homepage URL points to `reverse-scroll-cli.dongzhenye.com` (Cloudflare redirect rule → repo); 1280×640 social preview composed via PIL and uploaded via repo Settings; README hero composites AppIcon above a `charmbracelet/freeze`-rendered shell session; pinned feedback issue [#4](https://github.com/dongzhenye/reverse-scroll-cli/issues/4).
- [x] **products repo entry** (`dongzhenye/products`) — `data/projects/reverse-scroll-cli.json` promoted to `stage: live`, `launchedAt: 2026-04-15`, description + website filled in.

## Phase D — Content Production ✅ (no release; **Completed**: 2026-04-17)

**Goal:** Produce the narrative artifacts that outreach links to.

- [x] **Blog post** (`dongzhenye/blog`) — "Building a Zero-Config macOS Scroll Reverser in ~230 Lines of Swift"; PM-voice draft landed at `blog/draft/2026-04-16-building-reverse-scroll-cli.md`. Companion post `2026-03-02-macos-scroll-direction-fix.md` trimmed and cross-linked. Published URLs TBD (batch publish later).
- [x] **X thread** (@dongzhenye) — 3-tweet thread (pain point → negative-space pitch → install) drafted at `x/drafts/2026-04-16-reverse-scroll-cli-launch.md`. Publish URL TBD.

## Phase E — Outreach & Measurement (no release)

**Goal:** Drive traffic + capture early-user signal. Measurement starts day 0.

- [ ] **Reddit outreach** — 4 identified threads in r/macOS / r/mac (2023-2025); authentic non-spammy comments emphasizing CLI differentiator. Targets + template in §Reddit Outreach Strategy below.
- [ ] **Apple Discussions / StackExchange** — answer existing questions with solution.
- [ ] **Hacker News "Show HN"** — post after blog + Reddit validation.
- [ ] **Product Hunt** — optional launch if traction is good.
- [ ] **Measurement baseline** — from day 0: GitHub stars trajectory, clones, PR/issue volume, `brew install --cask` analytics if tap exposes metrics. Evaluate Phase E ROI at close.
- [ ] **Feedback triage** — GitHub issues / Reddit comments / X replies; fix early-user edge cases; decide what bumps to a later phase.

## Phase F — Homebrew-core Submission (will release as v0.4.0)

**Goal:** Official distribution via `brew install reverse-scroll-cli`.

- [ ] **Homebrew-core PR** — submit cask to homebrew/homebrew-cask
- [ ] **Address review feedback** — cask style, naming, audit compliance
- [ ] **Merge & announce** — update README, post to Reddit/HN/X

## Phase G — Polish & Sedimentation (will release as v0.5.0; start when batchable)

**Goal:** Convert accumulated small-but-not-trivial fixes into a coherent release. Don't open until items batch up — small drive-by fixes go straight to commit, not to roadmap.

- [ ] **Project-level `CLAUDE.md`** — sediment Phase B learnings: module boundaries, build pipeline (SwiftPM + sed-based version injection), signing identity choice + Cask + tap layout, common pitfalls (TCC signature change, BRE/ERE, launchctl deprecations). Saves future-you (and AI agents) re-deriving on every revisit.
- [ ] `--help` text: surface `--daemon` as `(internal, used by LaunchAgent)` for transparency.
- [ ] Replace `codesign --deep` with explicit per-component sign (Apple is deprecating `--deep`; no-op risk now since we have no nested frameworks, but future-proof).
- [ ] Cask postflight: sed-rewrite LaunchAgent plist program path to use `#{appdir}` instead of hard-coded `/Applications/...` (only matters if user passes `brew install --cask --appdir=...`, but cheap to fix).

## Backlog (unphased)

Items recognized as worth doing but not yet promoted to a phase. Promote when scope + dependencies firm up.

- [ ] **Alternate detection for Logitech mice** — fallback heuristic when `isContinuous` is wrong.
- [ ] **Horizontal scroll reversal** — optional flag for tilt wheels.
- [ ] **Per-app exceptions** — config file to disable reversal in specific apps (e.g., games).

---

## Open Source Checklist Details

> All items below shipped in v0.1.x (README badges / sections / troubleshooting, SECURITY.md, issue & PR templates, GitHub topics). Kept as reference templates for future projects.

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
> - MIT licensed, ~230 lines of Swift
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
