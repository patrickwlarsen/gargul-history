# Changelog

## v1.1.0 - 2026-03-14

### Added
- CSV export format option alongside JSON.
- Format toggle buttons (JSON / CSV) in the export window.

## v1.0.0 - 2026-03-13

### Added
- Initial addon creation with TOC file for WoW TBC Anniversary (Interface 20505).
- Core event listener that hooks into Gargul's `GL.ITEM_AWARDED` event to capture loot awards.
- Persistent history storage via `GargulHistoryDB` SavedVariable.
- Minimap button using LibDBIcon and LibDataBroker (from Gargul's bundled libraries).
- History window with sortable columns: Date, Player, and Item.
- Alternating row colors and hover highlighting in the history list.
- Item tooltip display on row hover.
- Export button that opens a window with the full history serialized as JSON.
- Copy support in the export window (Ctrl+A to select, Ctrl+C to copy).
- Clear History button with confirmation dialog.
- Escape key support to close both the history and export windows.
- Resizable and movable history window with drag handle and resize grip.
- Deploy script to copy the addon to the WoW AddOns directory.

### Fixed
- Close (X) buttons not responding to clicks due to the title bar frame intercepting mouse events.
- Export window not displaying text due to EditBox width being set before layout.
