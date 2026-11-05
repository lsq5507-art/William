# Little Paw — AGENTS.md

Short rules for coding agents. Prefer reading the code over this file when the code already answers.

## Commands
```bash
export PATH="/home/box/flutter/bin:$PATH"
cd /workspace/little-paw
flutter analyze    # target: No issues found
flutter test
flutter build web --release --base-href /   # Hosting → little-paw-prod.web.app
```

## Hosting / responsive (commander 2026-11-04)
- Deploy default: **only** `https://little-paw-prod.web.app/` (test domain). No custom-domain main entry without auth.
- New UI: desktop wide + mobile narrow browsers; no broken layout; touch and mouse reachable. Obvious PC break → fix next knife unless Must broken.

## Layout
- `lib/services/` — source of truth (SpaceStore, scripts, media)
- `lib/screens/` + `lib/widgets/` — thin UI
- `lib/theme/lp_theme.dart` — DS01 tokens (`LpTokens`)
- `test/` — behavior + defect regression

## Conventions
- Effective Dart + `flutter_lints`; no new ignore without reason comment
- User-visible copy via `lib/l10n/strings.dart` only
- Prefer Theme/`context.lpTokens` over hard-coded greys (`#8E8E8E` / `#DBDBDB` banned)
- Guest must remain playable; Auth parallel must not block local paths
- Do not rewrite World IA / Firebase project files / billing unless tasked

## Done means
Gates above green for the change surface; lean delivery under `/workspace/staff-system/outputs/开发/`.
Modes: load skill `staff-dev-modes` (FAST / STANDARD / ARCHITECT).
