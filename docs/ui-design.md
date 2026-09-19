# Interface design

The Home and Verify screens implement the approved blue-and-white visual draft.
Real saved reports, room names, measurements and confirmation state drive the UI;
the example account photo, dates and reports from the draft are not seeded data.

- Shared compact brand header and account action.
- Blueprint hero, scan/manual actions and recent reports.
- Persistent bottom navigation when entering Verify from Home.
- Compact photo previews, room progress, unit conversion and status cards.
- Fixed area summary, results jump, confirmation feedback and room deletion undo.
- Default credentials use email/password, with registration, verification and reset.
  Firebase configuration is still required. Paid SMS is disabled by default.

## Illustration source

Asset: `assets/branding/floor_plan_hero.png`.
Generated using the built-in image generation tool from the approved draft.
Prompt:

> Extract and faithfully recreate ONLY the pale blue architectural floor plan illustration inside the LEFT phone in this reference as a standalone landscape 5:3 image asset for the actual app. No phone frame, interface, title, buttons or other screen content. Match the reference floorplan closely: top-down apartment plan with blue double-line walls, furniture outlines, small soft green plants, faint square blueprint grid on very pale #F6F7FB background, subtle blue fills/shadows. Plan occupies left 75 percent, on right the same handwritten blue words stacked 'Measure' 'Verify' 'Move forward' with small underline. Preserve airy delicate architectural illustration style. Exact flat front view; beautiful crisp light blueprint, not photorealistic, no new logo. This is the illustration asset replacing the previous simplified plan in a mobile app.

This image is decorative. It is not scanned or used in area calculations.
