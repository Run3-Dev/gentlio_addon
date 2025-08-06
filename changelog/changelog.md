# Changelog

All notable changes to this project will be documented in this file.

## [0.2.8] – 2025-08-06
### Added
- Internationalization (I18N) support with language auto-detection via `GetLocale()`.
- English (`enUS`) and German (`deDE`) translations included.
- All user-facing strings now routed through a central translation function (`GentlI18N.T`).
- English is used as fallback if no translation is found.

## [0.2.5] – 2025-07-20
### Added
- Persistent storage of local player ratings in SavedVariables (`GentlPendingRatings`).
- Various bugfixes.
- Preparation for upcoming desktop syncing tool.

## [0.2.0] – 2025-07-13
### Added
- Character interaction log: automatically stores all group members with name, realm, class, level, and timestamp.
- `/gentl` command: opens character overview UI showing the last 3 days of group encounters.
- Rating display: shows score meaning, date, and list of tags, merged from external and local ratings.
- "Add Rating" button: opens a form with multi-select checkboxes for tags (positive and negative).
- Each tag carries a weight (0–5), average becomes the stored score.
- Ratings are saved immediately and shown in the UI.
- Visual & UX improvements: dark theme, faction/class icons, color-coded scores.

### Changed
- Tooltip now shows race and class on hover (for planned future use).

## [0.1.1] – 2025-07-10
### Added
- Tooltip integration using Blizzard's `TooltipDataProcessor` API (Retail-only).
- Displays rating summary in two-column layout via `AddDoubleLine`.
- Shows number of ratings and fallback message if none are available.
- Visual separation via colored `Gentl.IO` label in tooltip.
- Technical switch from `GameTooltip:HookScript` to `Enum.TooltipDataType.Unit`.
- Safe list access (`ensureList`) to avoid nil errors.

### Changed
- Fully compatible with WoW Retail versions from Shadowlands onward.

## [0.1.0] – 2025-07-01
### Added
- Basic addon structure.
- Initial tooltip display of the Gentl.IO score on player hover.
- Private chat notification when a group member already has a rating.
