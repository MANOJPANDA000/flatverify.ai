# Flatverify Phase 1 area checks

The Flutter entry point now opens `AreaCheckApp` without an account gate. The existing scanner and old reports remain accessible through explicit secondary routes. Existing user edits and report formats were retained.

## Implemented

- Four-step calculator, feet/inches, decimal feet, metres, centimetres, direct area, quantities and mixed units.
- Eight separate categories, optional wall methods, editable advertised values, separate loading bases, efficiency and configurable comparison thresholds.
- Local guest draft and saved checks in `flatverify_area_checks_v1`, independent of account/session storage. Space edits persist after Save space; main form edits persist as entered.
- Room edit, duplicate, reorder, confirmed deletion, presets that ask for real measurements, named rectangular segments, optional site photos.
- Saved check open/edit, rename, duplicate, comparison, PDF export and confirmed deletion/clear.
- Learn topics, converter, five-item navigation and mobile action area.
- Bundled-font PDF reports with calculation inputs, category bars, assumptions and disclaimer.

## Remaining later-phase work

- The existing OCR scanner remains a separate workflow; confirmed scanner values are not automatically imported into the new calculator. Its legacy calculations/report labels have not been migrated.
- Native PWA, state-specific official RERA directory, cloud backup, multilingual reports and professional services are not implemented in this change.
- Irregular rooms use separately named rectangular segments rather than nested room shapes.
- Site photos are stored with area checks; PDF reports contain notes and measurements, not photos.
- Previous-version reports use their existing storage and account rules; clearing new area checks does not erase old account data.

## Verification

`flutter analyze --no-pub`

`flutter test --no-pub test/area_check_test.dart`

The new test covers independent formula expectations, round-trip persistence, validation and a 360px guest workflow. Existing Flutter tests are also run for regressions.

## September 2026 interface refresh

The active area-check experience now uses reusable surfaces, icon tiles, badges, hints, progress steps and a drawn floor-plan illustration in `lib/area_check/check_ui.dart`.

- Dashboard: navy feature card, four task cards, current draft, recent report, converter and learning entry.
- Calculator: grouped form sections, configuration chips, numbered progress, reachable room-add action, room action menus and persistent bottom actions.
- Results: prominent usable/carpet summary, labelled category chart, visible assumptions and comparison cards.
- Saved: property cards, area summaries, export action, and menus for rename, duplicate and deletion.
- Learn: searchable explanations, expandable topics and an introductory area guide.
- Layout: bottom navigation on phones and a sidebar on desktop. Text can wrap and cards grow with larger text settings.

The refresh preserves calculation formulas, local storage keys and report data. The scanner and previous-version report routes remain available. Shared theme changes also apply to those routes.

Responsive checks cover 320 px at 130% text scale, 390 px, and 1100 px. Review images are generated in `build/ui-refresh/` by `test/area_check_design_test.dart`.
