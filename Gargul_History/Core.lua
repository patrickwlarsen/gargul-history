local ADDON_NAME = "Gargul_History"

-- Saved variable (initialized on load)
GargulHistoryDB = GargulHistoryDB or {}

local GH = CreateFrame("Frame", "GargulHistoryFrame")
_G.GargulHistory = GH

GH.history = {}
GH.minimapButtonDB = {}

-- Wait for our addon to load, then hook into Gargul
GH:RegisterEvent("ADDON_LOADED")
GH:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= ADDON_NAME then
        return
    end

    GH:UnregisterEvent("ADDON_LOADED")

    -- Initialize saved variables
    GargulHistoryDB.history = GargulHistoryDB.history or {}
    GargulHistoryDB.minimap = GargulHistoryDB.minimap or {}
    GH.history = GargulHistoryDB.history
    GH.minimapButtonDB = GargulHistoryDB.minimap

    -- Get reference to Gargul
    local GL = _G.Gargul
    if not GL then
        print("|cffff0000[Gargul History]|r Gargul not found. Make sure Gargul is installed and enabled.")
        return
    end

    GH.GL = GL

    -- Set up minimap button
    GH:InitMinimapButton()

    -- Listen for item awards from Gargul
    GL.Events:register("GargulHistoryItemAwarded", "GL.ITEM_AWARDED", function(_, AwardEntry)
        GH:OnItemAwarded(AwardEntry)
    end)

    print("|cff967FD2[Gargul History]|r Loaded. Click the minimap icon to view loot history.")
end)

--- Called when Gargul fires GL.ITEM_AWARDED
function GH:OnItemAwarded(AwardEntry)
    if not AwardEntry then
        return
    end

    -- Extract item name from the item link
    local itemName = AwardEntry.itemLink and AwardEntry.itemLink:match("%[(.-)%]") or "Unknown"

    -- Strip realm from player name for cleaner display
    local awardedTo = AwardEntry.awardedTo or "Unknown"
    local dashPos = awardedTo:find("-")
    if dashPos then
        awardedTo = awardedTo:sub(1, dashPos - 1)
    end

    local entry = {
        date = date("%Y-%m-%d %H:%M:%S", AwardEntry.timestamp or time()),
        awardedTo = awardedTo,
        item = {
            name = itemName,
            id = tostring(AwardEntry.itemID or 0),
        },
        -- Keep the full item link for tooltip display
        itemLink = AwardEntry.itemLink,
        timestamp = AwardEntry.timestamp or time(),
    }

    table.insert(self.history, entry)

    -- Update the UI if it's open
    if GH.HistoryUI and GH.HistoryUI.IsOpen then
        GH.HistoryUI:Refresh()
    end
end

--- Initialize the minimap button using LibDBIcon from Gargul's bundled libs
function GH:InitMinimapButton()
    local LibDataBroker = LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LibDataBroker or not LibDBIcon then
        print("|cffff0000[Gargul History]|r Could not load minimap button libraries.")
        return
    end

    local broker = LibDataBroker:NewDataObject("GargulHistory", {
        type = "data source",
        text = "Gargul History",
        icon = "Interface/Icons/INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if GH.HistoryUI then
                    GH.HistoryUI:Toggle()
                end
            elseif button == "RightButton" then
                -- Right click to clear history (with confirmation)
                if GH.HistoryUI then
                    GH.HistoryUI:Toggle()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff967FD2Gargul History|r")
            tooltip:AddLine("|cffffffffLeft-click:|r Open history window")
            tooltip:AddLine("|cffffffffEntries:|r " .. #GH.history)
        end,
    })

    LibDBIcon:Register("GargulHistory", broker, self.minimapButtonDB)
end
