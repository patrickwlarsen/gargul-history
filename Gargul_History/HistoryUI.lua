local GH = _G.GargulHistory

---@class HistoryUI
local HistoryUI = {
    IsOpen = false,
    Window = nil,
    ScrollFrame = nil,
    ItemHolder = nil,
    Rows = {},
    sortField = "date",  -- "date", "player", "item"
    sortAscending = false, -- newest first by default
    exportFormat = "JSON", -- "JSON" or "CSV"
}

GH.HistoryUI = HistoryUI

--[[ CONSTANTS ]]
local WINDOW_WIDTH = 500
local WINDOW_HEIGHT = 450
local ROW_HEIGHT = 20
local HEADER_HEIGHT = 24
local FONT_SIZE = 12
local FONT = "Fonts\\FRIZQT__.TTF"

local COLOR_HEADER_BG = { 0.15, 0.15, 0.15, 0.9 }
local COLOR_ROW_EVEN = { 0.12, 0.12, 0.12, 0.8 }
local COLOR_ROW_ODD = { 0.18, 0.18, 0.18, 0.8 }
local COLOR_ROW_HOVER = { 0.3, 0.3, 0.5, 0.5 }
local COLOR_BORDER = { 0.4, 0.4, 0.4, 1 }
local COLOR_TITLE = { 0.59, 0.5, 0.82, 1 } -- Gargul purple

--- Toggle the history window
function HistoryUI:Toggle()
    if self.IsOpen then
        self:Close()
    else
        self:Open()
    end
end

--- Open the history window
function HistoryUI:Open()
    if not self.Window then
        self:Build()
    end

    self:Refresh()
    self.Window:Show()
    self.IsOpen = true
end

--- Close the history window
function HistoryUI:Close()
    if self.Window then
        self.Window:Hide()
    end
    self.IsOpen = false
end

--- Build the main window
function HistoryUI:Build()
    -- Main window frame
    local Window = CreateFrame("Frame", "GargulHistoryWindow", UIParent, "BackdropTemplate")
    Window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    Window:SetPoint("CENTER")
    Window:SetMovable(true)
    Window:EnableMouse(true)
    Window:SetResizable(true)
    Window:SetClampedToScreen(true)
    Window:SetFrameStrata("HIGH")
    Window:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    Window:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    Window:SetBackdropBorderColor(unpack(COLOR_BORDER))

    -- Resizing
    if Window.SetResizeBounds then
        Window:SetResizeBounds(400, 250, 800, 800)
    elseif Window.SetMinResize then
        Window:SetMinResize(400, 250)
        Window:SetMaxResize(800, 800)
    end

    -- Title bar drag
    local TitleBar = CreateFrame("Frame", nil, Window)
    TitleBar:SetPoint("TOPLEFT", 0, 0)
    TitleBar:SetPoint("TOPRIGHT", 0, 0)
    TitleBar:SetHeight(28)
    TitleBar:EnableMouse(true)
    TitleBar:RegisterForDrag("LeftButton")
    TitleBar:SetScript("OnDragStart", function() Window:StartMoving() end)
    TitleBar:SetScript("OnDragStop", function() Window:StopMovingOrSizing() end)

    -- Title text
    local Title = TitleBar:CreateFontString(nil, "OVERLAY")
    Title:SetFont(FONT, 14, "OUTLINE")
    Title:SetPoint("LEFT", TitleBar, "LEFT", 12, 0)
    Title:SetTextColor(unpack(COLOR_TITLE))
    Title:SetText("Gargul History")

    -- Entry count
    local EntryCount = TitleBar:CreateFontString(nil, "OVERLAY", nil, 7)
    EntryCount:SetFont(FONT, 11)
    EntryCount:SetPoint("RIGHT", TitleBar, "RIGHT", -36, 0)
    EntryCount:SetTextColor(0.7, 0.7, 0.7, 1)
    self.EntryCount = EntryCount

    -- Close button (parented to TitleBar so it stays above it for clicks)
    local CloseButton = CreateFrame("Button", nil, TitleBar, "UIPanelCloseButton")
    CloseButton:SetPoint("TOPRIGHT", Window, "TOPRIGHT", -2, -2)
    CloseButton:HookScript("OnClick", function() HistoryUI:Close() end)

    -- Resize grip
    local ResizeGrip = CreateFrame("Button", nil, Window)
    ResizeGrip:SetSize(16, 16)
    ResizeGrip:SetPoint("BOTTOMRIGHT", -4, 4)
    ResizeGrip:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
    ResizeGrip:SetHighlightTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Highlight")
    ResizeGrip:SetPushedTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Down")
    ResizeGrip:SetScript("OnMouseDown", function() Window:StartSizing("BOTTOMRIGHT") end)
    ResizeGrip:SetScript("OnMouseUp", function()
        Window:StopMovingOrSizing()
        HistoryUI:Refresh()
    end)

    -- Column headers
    local HeaderFrame = CreateFrame("Frame", nil, Window, "BackdropTemplate")
    HeaderFrame:SetPoint("TOPLEFT", Window, "TOPLEFT", 8, -30)
    HeaderFrame:SetPoint("TOPRIGHT", Window, "TOPRIGHT", -8, -30)
    HeaderFrame:SetHeight(HEADER_HEIGHT)
    HeaderFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    })
    HeaderFrame:SetBackdropColor(unpack(COLOR_HEADER_BG))
    self.HeaderFrame = HeaderFrame

    -- Create column headers (Date, Player, Item)
    self:CreateColumnHeaders(HeaderFrame)

    -- Scroll frame for the item rows
    local ScrollFrame = CreateFrame("ScrollFrame", "GargulHistoryScrollFrame", Window, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", HeaderFrame, "BOTTOMLEFT", 0, -2)
    ScrollFrame:SetPoint("BOTTOMRIGHT", Window, "BOTTOMRIGHT", -28, 36)
    self.ScrollFrame = ScrollFrame

    local ItemHolder = CreateFrame("Frame", nil, ScrollFrame)
    ItemHolder:SetSize(ScrollFrame:GetWidth(), 1)
    ScrollFrame:SetScrollChild(ItemHolder)
    self.ItemHolder = ItemHolder

    -- Clear history button
    local ClearButton = CreateFrame("Button", nil, Window, "UIPanelButtonTemplate")
    ClearButton:SetSize(100, 22)
    ClearButton:SetPoint("BOTTOMLEFT", Window, "BOTTOMLEFT", 10, 8)
    ClearButton:SetText("Clear History")
    ClearButton:SetScript("OnClick", function()
        StaticPopup_Show("GARGUL_HISTORY_CLEAR_CONFIRM")
    end)

    -- Export button
    local ExportButton = CreateFrame("Button", nil, Window, "UIPanelButtonTemplate")
    ExportButton:SetSize(80, 22)
    ExportButton:SetPoint("LEFT", ClearButton, "RIGHT", 4, 0)
    ExportButton:SetText("Export")
    ExportButton:SetScript("OnClick", function()
        HistoryUI:ShowExportWindow()
    end)

    -- Register the confirmation dialog
    StaticPopupDialogs["GARGUL_HISTORY_CLEAR_CONFIRM"] = {
        text = "Are you sure you want to clear all Gargul History entries? This cannot be undone.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            wipe(GH.history)
            HistoryUI:Refresh()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    Window:Hide()
    self.Window = Window

    -- Close with Escape
    tinsert(UISpecialFrames, "GargulHistoryWindow")
end

--- Create sortable column headers
function HistoryUI:CreateColumnHeaders(parent)
    local columns = {
        { field = "date",   label = "Date",   relWidth = 0.30 },
        { field = "player", label = "Player",  relWidth = 0.25 },
        { field = "item",   label = "Item",    relWidth = 0.45 },
    }

    local prevButton
    for i, col in ipairs(columns) do
        local Button = CreateFrame("Button", nil, parent)
        if i == 1 then
            Button:SetPoint("LEFT", parent, "LEFT", 4, 0)
        else
            Button:SetPoint("LEFT", prevButton, "RIGHT", 0, 0)
        end
        Button:SetHeight(HEADER_HEIGHT)

        -- We'll set width dynamically during refresh
        col.button = Button

        local Label = Button:CreateFontString(nil, "OVERLAY")
        Label:SetFont(FONT, FONT_SIZE, "OUTLINE")
        Label:SetPoint("LEFT", 4, 0)
        Label:SetTextColor(1, 0.82, 0)
        col.label_fs = Label

        -- Sort arrow indicator
        local Arrow = Button:CreateFontString(nil, "OVERLAY")
        Arrow:SetFont(FONT, FONT_SIZE, "OUTLINE")
        Arrow:SetPoint("LEFT", Label, "RIGHT", 4, 0)
        Arrow:SetTextColor(1, 0.82, 0)
        col.arrow = Arrow

        Button:SetScript("OnClick", function()
            if self.sortField == col.field then
                self.sortAscending = not self.sortAscending
            else
                self.sortField = col.field
                self.sortAscending = true
            end
            self:Refresh()
        end)

        Button:SetScript("OnEnter", function(btn)
            btn.highlight = btn.highlight or btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetColorTexture(1, 1, 1, 0.1)
        end)

        prevButton = Button
        columns[i] = col
    end

    self.columns = columns
end

--- Update column header labels with sort indicators
function HistoryUI:UpdateHeaders()
    if not self.columns then return end

    local contentWidth = self.HeaderFrame:GetWidth() - 8

    for _, col in ipairs(self.columns) do
        col.button:SetWidth(contentWidth * col.relWidth)

        local arrow = ""
        if self.sortField == col.field then
            arrow = self.sortAscending and " \226\150\178" or " \226\150\188"
        end
        col.label_fs:SetText(col.label)
        col.arrow:SetText(arrow)
    end
end

--- Get sorted history data
function HistoryUI:GetSortedHistory()
    local sorted = {}
    for i, entry in ipairs(GH.history) do
        sorted[i] = entry
    end

    local field = self.sortField
    local asc = self.sortAscending

    table.sort(sorted, function(a, b)
        local valA, valB

        if field == "date" then
            valA = a.timestamp or 0
            valB = b.timestamp or 0
        elseif field == "player" then
            valA = (a.awardedTo or ""):lower()
            valB = (b.awardedTo or ""):lower()
        elseif field == "item" then
            valA = (a.item and a.item.name or ""):lower()
            valB = (b.item and b.item.name or ""):lower()
        end

        if asc then
            return valA < valB
        else
            return valA > valB
        end
    end)

    return sorted
end

--- Refresh the displayed rows
function HistoryUI:Refresh()
    if not self.ItemHolder then return end

    -- Clear existing rows
    for _, row in ipairs(self.Rows) do
        row:Hide()
    end

    self:UpdateHeaders()

    local sortedHistory = self:GetSortedHistory()
    local contentWidth = self.HeaderFrame:GetWidth() - 8
    local colWidths = {}
    for i, col in ipairs(self.columns) do
        colWidths[i] = contentWidth * col.relWidth
    end

    -- Update entry count
    self.EntryCount:SetText(#sortedHistory .. " entries")

    -- Set holder height
    self.ItemHolder:SetHeight(math.max(1, #sortedHistory * ROW_HEIGHT))
    self.ItemHolder:SetWidth(self.ScrollFrame:GetWidth())

    for i, entry in ipairs(sortedHistory) do
        local row = self.Rows[i]

        if not row then
            row = CreateFrame("Frame", nil, self.ItemHolder, "BackdropTemplate")
            row:SetHeight(ROW_HEIGHT)
            row:EnableMouse(true)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()

            row.dateText = row:CreateFontString(nil, "OVERLAY")
            row.dateText:SetFont(FONT, FONT_SIZE - 1)
            row.dateText:SetJustifyH("LEFT")

            row.playerText = row:CreateFontString(nil, "OVERLAY")
            row.playerText:SetFont(FONT, FONT_SIZE)
            row.playerText:SetJustifyH("LEFT")

            row.itemText = row:CreateFontString(nil, "OVERLAY")
            row.itemText:SetFont(FONT, FONT_SIZE)
            row.itemText:SetJustifyH("LEFT")

            -- Hover highlight
            row:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(unpack(COLOR_ROW_HOVER))
                -- Show item tooltip if we have an item link
                if self.itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(self.itemLink)
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                local color = (self.rowIndex % 2 == 0) and COLOR_ROW_EVEN or COLOR_ROW_ODD
                self.bg:SetColorTexture(unpack(color))
                GameTooltip:Hide()
            end)

            self.Rows[i] = row
        end

        -- Position and size
        row:SetPoint("TOPLEFT", self.ItemHolder, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", self.ItemHolder, "RIGHT", 0, 0)

        -- Alternating row colors
        row.rowIndex = i
        local bgColor = (i % 2 == 0) and COLOR_ROW_EVEN or COLOR_ROW_ODD
        row.bg:SetColorTexture(unpack(bgColor))

        -- Date column
        row.dateText:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.dateText:SetWidth(colWidths[1] - 12)
        row.dateText:SetText(entry.date or "")
        row.dateText:SetTextColor(0.7, 0.7, 0.7, 1)

        -- Player column
        row.playerText:SetPoint("LEFT", row, "LEFT", colWidths[1] + 4, 0)
        row.playerText:SetWidth(colWidths[2] - 8)
        row.playerText:SetText(entry.awardedTo or "")
        row.playerText:SetTextColor(0.8, 0.9, 1, 1)

        -- Item column - use item link color if available
        row.itemText:SetPoint("LEFT", row, "LEFT", colWidths[1] + colWidths[2] + 4, 0)
        row.itemText:SetWidth(colWidths[3] - 8)
        if entry.itemLink then
            row.itemText:SetText(entry.itemLink)
        else
            row.itemText:SetText(entry.item and entry.item.name or "Unknown")
            row.itemText:SetTextColor(1, 1, 1, 1)
        end

        row.itemLink = entry.itemLink
        row:Show()
    end

    -- Hide extra rows
    for i = #sortedHistory + 1, #self.Rows do
        self.Rows[i]:Hide()
    end
end

--- Serialize history to JSON string
function HistoryUI:HistoryToJSON()
    local parts = {}
    for _, entry in ipairs(GH.history) do
        local itemName = (entry.item and entry.item.name or "Unknown"):gsub('"', '\\"')
        local itemId = entry.item and entry.item.id or "0"
        local awardedTo = (entry.awardedTo or "Unknown"):gsub('"', '\\"')
        local entryDate = (entry.date or ""):gsub('"', '\\"')

        table.insert(parts, string.format(
            '{"date":"%s","awardedTo":"%s","item":{"name":"%s","id":"%s"}}',
            entryDate, awardedTo, itemName, itemId
        ))
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

--- Show the export window with copyable text (JSON or CSV)
function HistoryUI:ShowExportWindow()
    -- Reuse existing window if it exists
    if self.ExportWindow then
        self.ExportWindow:Show()
        self:UpdateExportText()
        return
    end

    local Window = CreateFrame("Frame", "GargulHistoryExportWindow", UIParent, "BackdropTemplate")
    Window:SetSize(500, 350)
    Window:SetPoint("CENTER")
    Window:SetMovable(true)
    Window:EnableMouse(true)
    Window:SetClampedToScreen(true)
    Window:SetFrameStrata("DIALOG")
    Window:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    Window:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    Window:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Title bar drag
    local TitleBar = CreateFrame("Frame", nil, Window)
    TitleBar:SetPoint("TOPLEFT", 0, 0)
    TitleBar:SetPoint("TOPRIGHT", 0, 0)
    TitleBar:SetHeight(28)
    TitleBar:EnableMouse(true)
    TitleBar:RegisterForDrag("LeftButton")
    TitleBar:SetScript("OnDragStart", function() Window:StartMoving() end)
    TitleBar:SetScript("OnDragStop", function() Window:StopMovingOrSizing() end)

    -- Title
    local Title = TitleBar:CreateFontString(nil, "OVERLAY")
    Title:SetFont(FONT, 14, "OUTLINE")
    Title:SetPoint("LEFT", TitleBar, "LEFT", 12, 0)
    Title:SetTextColor(unpack(COLOR_TITLE))
    Title:SetText("Export History")

    -- Close button (parented to TitleBar so it stays above it for clicks)
    local CloseButton = CreateFrame("Button", nil, TitleBar, "UIPanelCloseButton")
    CloseButton:SetPoint("TOPRIGHT", Window, "TOPRIGHT", -2, -2)
    CloseButton:HookScript("OnClick", function() Window:Hide() end)

    -- Format selector row
    local FormatLabel = Window:CreateFontString(nil, "OVERLAY")
    FormatLabel:SetFont(FONT, 11)
    FormatLabel:SetPoint("TOPLEFT", Window, "TOPLEFT", 12, -32)
    FormatLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    FormatLabel:SetText("Format:")

    -- Format toggle buttons
    local formats = { "JSON", "CSV" }
    local formatButtons = {}
    local prevBtn
    for i, fmt in ipairs(formats) do
        local btn = CreateFrame("Button", nil, Window, "BackdropTemplate")
        btn:SetSize(50, 20)
        if i == 1 then
            btn:SetPoint("LEFT", FormatLabel, "RIGHT", 8, 0)
        else
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 4, 0)
        end
        btn:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT, 11, "OUTLINE")
        label:SetPoint("CENTER")
        label:SetText(fmt)
        btn.label = label
        btn.format = fmt

        btn:SetScript("OnClick", function()
            self.exportFormat = fmt
            self:UpdateFormatButtons()
            self:UpdateExportText()
        end)

        formatButtons[i] = btn
        prevBtn = btn
    end
    self.formatButtons = formatButtons

    -- Hint
    local Hint = Window:CreateFontString(nil, "OVERLAY")
    Hint:SetFont(FONT, 11)
    Hint:SetPoint("LEFT", prevBtn, "RIGHT", 16, 0)
    Hint:SetTextColor(0.5, 0.5, 0.5, 1)
    Hint:SetText("Ctrl+A to select all, Ctrl+C to copy")

    -- Scroll frame for the edit box
    local ScrollFrame = CreateFrame("ScrollFrame", "GargulHistoryExportScrollFrame", Window, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", Window, "TOPLEFT", 12, -56)
    ScrollFrame:SetPoint("BOTTOMRIGHT", Window, "BOTTOMRIGHT", -32, 12)

    -- Edit box (read-only multi-line text)
    local EditBox = CreateFrame("EditBox", "GargulHistoryExportEditBox", ScrollFrame)
    EditBox:SetMultiLine(true)
    EditBox:SetAutoFocus(true)
    EditBox:SetFontObject(ChatFontNormal)
    EditBox:SetTextColor(1, 1, 1, 1)
    EditBox:SetScript("OnEscapePressed", function() Window:Hide() end)
    ScrollFrame:SetScrollChild(EditBox)

    -- Size the EditBox to match the scroll frame after layout
    ScrollFrame:SetScript("OnSizeChanged", function(sf)
        EditBox:SetWidth(sf:GetWidth())
    end)

    self.ExportWindow = Window
    self.ExportEditBox = EditBox
    self.ExportScrollFrame = ScrollFrame

    tinsert(UISpecialFrames, "GargulHistoryExportWindow")

    self:UpdateFormatButtons()
    self:UpdateExportText()
end

--- Update format button visual states
function HistoryUI:UpdateFormatButtons()
    if not self.formatButtons then return end
    for _, btn in ipairs(self.formatButtons) do
        if btn.format == self.exportFormat then
            btn:SetBackdropColor(0.3, 0.3, 0.6, 0.9)
            btn:SetBackdropBorderColor(0.59, 0.5, 0.82, 1)
            btn.label:SetTextColor(1, 1, 1, 1)
        else
            btn:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            btn.label:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end
end

--- Escape a value for CSV (wrap in quotes if it contains commas, quotes, or newlines)
local function csvEscape(value)
    value = tostring(value)
    if value:find('[,"\n]') then
        return '"' .. value:gsub('"', '""') .. '"'
    end
    return value
end

--- Serialize history to CSV string
function HistoryUI:HistoryToCSV()
    local lines = { "Date,Player,Item,ItemID" }
    for _, entry in ipairs(GH.history) do
        local itemName = entry.item and entry.item.name or "Unknown"
        local itemId = entry.item and entry.item.id or "0"
        local awardedTo = entry.awardedTo or "Unknown"
        local entryDate = entry.date or ""

        table.insert(lines, string.format("%s,%s,%s,%s",
            csvEscape(entryDate),
            csvEscape(awardedTo),
            csvEscape(itemName),
            csvEscape(itemId)
        ))
    end
    return table.concat(lines, "\n")
end

--- Update the export text content
function HistoryUI:UpdateExportText()
    if not self.ExportEditBox then return end
    local text
    if self.exportFormat == "CSV" then
        text = self:HistoryToCSV()
    else
        text = self:HistoryToJSON()
    end
    self.ExportEditBox:SetText(text)
    -- Defer highlight/focus to next frame so layout is complete
    C_Timer.After(0, function()
        if self.ExportScrollFrame then
            self.ExportEditBox:SetWidth(self.ExportScrollFrame:GetWidth())
        end
        self.ExportEditBox:HighlightText()
        self.ExportEditBox:SetFocus()
    end)
end
