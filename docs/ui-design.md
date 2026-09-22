# Interface design

The main Flutter screens were adapted from the approved Google AI Studio web
design. The older React reference and standalone app generator have been removed
from this branch; the current application is implemented in `lib/`.
Real saved reports, room names, measurements and confirmation state drive the UI;
the example account photo, dates and reports from the draft are not seeded data.

- Bundled Plus Jakarta Sans font, blueprint logo, navy-to-blue hero, pale backgrounds,
  rounded white panels, and shared account/unit controls.
- Dashboard, Calculator, Scan Blueprint, Saved Audits, and Settings navigation.
- Bottom navigation on phones; header navigation on wide screens. Drafts survive
  switching sections.
- Room entry and audit summaries stack on phones and use columns above 850 px.
- Saved-audit search, scan/manual filters, PDF actions, and two-report comparison.
- Persisted area-display preferences; existing measurements are not converted in storage.
- Compact photo previews, room progress, unit conversion and status cards.
- Fixed area summary, results jump, confirmation feedback and room deletion undo.
- Default credentials use email/password, with registration, verification and reset.
  Firebase configuration is still required. Paid SMS is disabled by default.

The existing calculation formulas, fixed-area overrides, OCR review rules, and
account storage model remain in use. The separate detailed RERA workflow is still
available from the calculator; this redesign does not reconcile its formulas with
the older calculator or complete its builder-comparison placeholders.

`test/studio_design_test.dart` checks navigation, unit changes without measurement
drift, saved-audit filtering/comparison, and layouts at 320, 390 and 1280 px.
It captures the main screens at phone and desktop widths under `build/design-review/`.
The screenshots use test reports only. Font licensing is in `assets/fonts/OFL.txt`.

## Illustration source

Asset: `assets/branding/floor_plan_hero.png`.
Generated using the built-in image generation tool from the approved draft.
Prompt:

> Extract and faithfully recreate ONLY the pale blue architectural floor plan illustration inside the LEFT phone in this reference as a standalone landscape 5:3 image asset for the actual app. No phone frame, interface, title, buttons or other screen content. Match the reference floorplan closely: top-down apartment plan with blue double-line walls, furniture outlines, small soft green plants, faint square blueprint grid on very pale #F6F7FB background, subtle blue fills/shadows. Plan occupies left 75 percent, on right the same handwritten blue words stacked 'Measure' 'Verify' 'Move forward' with small underline. Preserve airy delicate architectural illustration style. Exact flat front view; beautiful crisp light blueprint, not photorealistic, no new logo. This is the illustration asset replacing the previous simplified plan in a mobile app.

This image is decorative. It is not scanned or used in area calculations.
