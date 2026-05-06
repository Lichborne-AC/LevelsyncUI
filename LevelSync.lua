-- LevelSync.lua — core logic
-- Communicates with mod-levelsync via WoW chat commands and CHAT_MSG_SYSTEM events.

local ADDON_NAME = "LevelSync"

-- Shared namespace; LevelSync_UI.lua accesses this via _G["LevelSync"]
local LS = {}
_G["LevelSync"] = LS

-- ─── Class & tier lookup tables ──────────────────────────────────────────────

LS.CLASS_COLORS = {
    ["Warrior"]      = "C79C6E",
    ["Paladin"]      = "F58CBA",
    ["Hunter"]       = "ABD473",
    ["Rogue"]        = "FFF569",
    ["Priest"]       = "FFFFFF",
    ["Death Knight"] = "C41F3B",
    ["Shaman"]       = "0070DE",
    ["Mage"]         = "69CCF0",
    ["Warlock"]      = "9482C9",
    ["Druid"]        = "FF7D0A",
}

LS.TIER_NAMES = {
    [0]  = "None",
    [1]  = "Molten Core",
    [2]  = "Onyxia",
    [3]  = "Blackwing Lair",
    [4]  = "Pre-AQ",
    [5]  = "AQ War Effort",
    [6]  = "Ahn'Qiraj",
    [7]  = "Naxxramas 40",
    [8]  = "Pre-TBC",
    [9]  = "Karazhan / Gruul / Magtheridon",
    [10] = "Serpentshrine Cavern / Tempest Keep",
    [11] = "Hyjal Summit / Black Temple",
    [12] = "Zul'Aman",
    [13] = "Sunwell Plateau",
    [14] = "Naxxramas / Eye of Eternity / Obsidian Sanctum",
    [15] = "Ulduar",
    [16] = "Trial of the Crusader",
    [17] = "Icecrown Citadel",
    [18] = "Ruby Sanctum",
}

-- ─── Parsed group data (written by CommitStatus, read by UI) ─────────────────

LS.data = {
    inGroup        = false,
    groupId        = nil,
    accountsCur    = 0,
    accountsMax    = 0,
    totalChars     = 0,
    levelSync      = false,
    ipSync         = false,
    ipSyncDisabled = false,
    members        = {},  -- {accountId, name, level, class, tierStr}
}

-- ─── Command sender ───────────────────────────────────────────────────────────

local function SendCmd(cmd)
    if InCombatLockdown() then
        print("|cffff4444[LevelSync]|r Cannot send commands while in combat.")
        return
    end
    local box = ChatFrame1EditBox
    if not box:IsVisible() then
        ChatFrame_OpenChat("", ChatFrame1)
    end
    box:SetText(".levelsync " .. cmd)
    ChatEdit_SendText(box, false)
    box:Hide()
end

LS.SendCmd = SendCmd


-- ─── Multi-line status state machine ─────────────────────────────────────────
-- Captures ALL CHAT_MSG_SYSTEM lines while sm.active is true, then commits
-- 300ms after the last line (reset on each new arrival via OnUpdate timer).

local COMMIT_DELAY = 0.3

local sm = {
    active = false,
    lines  = {},
}

local commitRemaining = 0
local commitFrame = CreateFrame("Frame")
commitFrame:Hide()

local function ArmCommitTimer()
    commitRemaining = COMMIT_DELAY
    commitFrame:Show()
end

local function CommitStatus()
    sm.active = false
    local d = LS.data

    d.inGroup     = false
    d.groupId     = nil
    d.accountsCur = 0
    d.accountsMax = 0
    d.totalChars  = 0
    d.levelSync   = false
    d.ipSync      = false
    d.members     = {}

    local curAccount = nil

    for _, line in ipairs(sm.lines) do
        -- Group header: "[LevelSync] Sync Group #N"
        local gid = line:match("Sync Group #(%d+)")
        if gid then
            d.inGroup = true
            d.groupId = tonumber(gid)
        end

        -- "  Accounts: X/Y"
        local cur, max = line:match("Accounts: (%d+)/(%d+)")
        if cur then
            d.accountsCur = tonumber(cur)
            d.accountsMax = tonumber(max)
        end

        -- "  Total Characters: N"
        local tc = line:match("Total Characters: (%d+)")
        if tc then d.totalChars = tonumber(tc) end

        -- "  Level sync: ON|OFF"
        local ls = line:match("Level sync: (%u+)")
        if ls then d.levelSync = (ls == "ON") end

        -- "  Progression sync: ON|OFF"
        local ps = line:match("Progression sync: (%u+)")
        if ps then d.ipSync = (ps == "ON") end

        -- "  Account N: Characters: X" — extract account ID
        local accId = line:match("Account (%d+):")
        if accId then curAccount = tonumber(accId) end

        -- "    Name (lvl X) (Class) IP Tier: ..."
        -- After color stripping, 4-space indent
        local name, lvl, cls, tierStr =
            line:match("^%s+(.-)%s+%(lvl (%d+)%)%s+%((.-)%)%s+IP Tier: (.+)$")
        if name and curAccount then
            local tierNum = 0
            if tierStr and tierStr ~= "None" then
                tierNum = tonumber(tierStr:match("^(%d+)")) or 0
            end
            table.insert(d.members, {
                accountId = curAccount,
                name      = name,
                level     = tonumber(lvl),
                class     = cls,
                tierStr   = tierStr,
                tierNum   = tierNum,
            })
        end
    end

    sm.lines = {}

    if LS.UI_OnDataRefresh then LS.UI_OnDataRefresh() end
end

-- OnUpdate script set here so CommitStatus is in scope for the closure
commitFrame:SetScript("OnUpdate", function(self, elapsed)
    commitRemaining = commitRemaining - elapsed
    if commitRemaining <= 0 then
        self:Hide()
        if sm.active then CommitStatus() end
    end
end)

-- ─── CHAT_MSG_SYSTEM listener ─────────────────────────────────────────────────

local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_SYSTEM")
listener:SetScript("OnEvent", function(self, event, msg)
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    -- ── While collecting status block, capture ALL system messages ──
    -- Many status lines (Accounts, Level sync, member rows) have no [LevelSync] prefix.
    if sm.active then
        table.insert(sm.lines, clean)
        ArmCommitTimer()
        return
    end

    -- Outside a status block, only act on [LevelSync] messages
    if not clean:find("%[LevelSync%]") then return end

    -- ── No group — wipe all data ──
    if clean:find("Sync group disbanded") or clean:find("You are not in a sync group") then
        LS.data.inGroup     = false
        LS.data.groupId     = nil
        LS.data.accountsCur = 0
        LS.data.accountsMax = 0
        LS.data.totalChars  = 0
        LS.data.levelSync   = false
        LS.data.ipSync      = false
        LS.data.members     = {}
        if LS.UI_OnDataRefresh then LS.UI_OnDataRefresh() end
        return
    end

    -- ── Status block start ──
    if clean:find("Sync Group #") then
        sm.active = true
        sm.lines  = { clean }
        ArmCommitTimer()
        return
    end

end)

-- ─── Status output filter ────────────────────────────────────────────────────
-- Suppresses the status block from appearing in the chat frame.
-- Our event listener still captures every line for parsing — it just won't print.

local function LevelSyncStatusFilter(_, _, msg)
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    if sm.active then
        -- Untagged lines are pure status data (Accounts:, character rows, etc.) — suppress
        if not clean:find("%[LevelSync%]") then return true end
        -- Known status header lines that carry [LevelSync] — suppress
        if clean:find("Sync Group #") or clean:find("Group members") then return true end
        -- Any other [LevelSync] message (confirmations, errors) — let through
        return
    end

    -- Catch the trigger line before sm.active is set (in case chat frame fires first)
    if clean:find("%[LevelSync%]") and clean:find("Sync Group #") then
        return true
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LevelSyncStatusFilter)

-- ─── Slash commands ───────────────────────────────────────────────────────────

SLASH_LEVELSYNC1 = "/lsync"
SLASH_LEVELSYNC2 = "/levelsync"
SlashCmdList["LEVELSYNC"] = function(msg)
    msg = msg:match("^%s*(.-)%s*$")
    if msg == "" then
        if LS.TogglePanel then LS.TogglePanel() end
    else
        SendCmd(msg)
    end
end

-- ─── Minimap icon (LibDBIcon) — registered on ADDON_LOADED ───────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    LevelSyncDB = LevelSyncDB or {}
    LevelSyncDB.minimap = LevelSyncDB.minimap or { hide = false }

    local LDB  = LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub("LibDBIcon-1.0", true)

    if LDB and Icon then
        local ldb = LDB:NewDataObject("LevelSync", {
            type  = "launcher",
            icon  = "Interface\\Icons\\inv_misc_groupneedmore",
            label = "LevelSync",
            OnClick = function(_, btn)
                if btn == "LeftButton" then
                    if LS.TogglePanel then LS.TogglePanel() end
                end
            end,
            OnTooltipShow = function(tip)
                tip:AddLine("|cffd4af37LevelSync|r")
                tip:AddLine("|cffaaaaaaLeft-click|r to open/close", 1, 1, 1)
                tip:AddLine("|cffaaaaaaRight-drag|r to reposition", 1, 1, 1)
            end,
        })
        Icon:Register("LevelSync", ldb, LevelSyncDB.minimap)
    else
        print("|cffff4444[LevelSync]|r Warning: minimap libraries not loaded.")
    end
end)
