# Gargul History

A companion addon for [Gargul](https://www.curseforge.com/wow/addons/gargul) that tracks and displays a persistent history of all loot awarded through Gargul in World of Warcraft TBC Anniversary.

## Features

- **Automatic Loot Tracking** - Listens for Gargul's loot award events and records every item awarded, including the item name, item ID, recipient, and timestamp.
- **Minimap Button** - A minimap icon provides quick access to the history window. Hover it to see the current entry count.
- **Sortable History Window** - A resizable, movable window displays all recorded awards in a three-column table:
  - **Date** - When the item was awarded
  - **Player** - Who received the item
  - **Item** - The item that was awarded (displayed with its quality color)

  Click any column header to sort ascending/descending.
- **Item Tooltips** - Hover any row to see the full item tooltip.
- **Export** - Export your full history as **JSON** or **CSV**. Toggle between formats in the export window, then select all and copy the data for use in external tools, spreadsheets, or websites.
- **Clear History** - Remove all recorded entries with a confirmation prompt.

## Requirements

- World of Warcraft TBC Anniversary (Interface 20505)
- [Gargul](https://www.curseforge.com/wow/addons/gargul) addon installed and enabled

## Installation

1. Copy the `Gargul_History` folder into your WoW AddOns directory:
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/Gargul_History/
   ```
2. Restart or reload WoW.
3. Gargul History will appear in your addon list and load automatically alongside Gargul.

If you cloned this repository, you can use the deploy script:
```bash
npm run deploy
# or
bash deploy.sh
```

## Usage

1. **Viewing History** - Click the Gargul History minimap icon (book icon) to open the history window.
2. **Sorting** - Click the **Date**, **Player**, or **Item** column headers to sort. Click again to reverse the sort order. An arrow indicator shows the current sort direction.
3. **Exporting** - Click the **Export** button at the bottom of the history window. A new window will appear with format toggle buttons for **JSON** and **CSV**. Select your preferred format, then press `Ctrl+A` to select all and `Ctrl+C` to copy.
4. **Clearing** - Click the **Clear History** button to remove all entries. You will be asked to confirm before anything is deleted.

## Export Formats

### JSON

```json
[
  {
    "date": "2026-03-13 20:15:00",
    "awardedTo": "Playername",
    "item": {
      "name": "Thunderfury, Blessed Blade of the Windseeker",
      "id": "19019"
    }
  }
]
```

### CSV

```csv
Date,Player,Item,ItemID
2026-03-13 20:15:00,Playername,"Thunderfury, Blessed Blade of the Windseeker",19019
```

## Data Storage

History is stored in the `GargulHistoryDB` SavedVariable, which persists across sessions and reloads. The minimap button position is also saved.
