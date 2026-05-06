-- LevelSync_UI.lua
-- Visual style matches LichborneTracker: dark navy blue + gold trim.

local LS = _G["LevelSync"]
if not LS then return end

-- ─── Style constants (matching LichborneTracker exactly) ─────────────────────

local GOLD       = "|cffd4af37"
local GOLD2      = "|cffC69B3A"
local ENDC       = "|r"
local FONT       = "Fonts\\FRIZQT__.TTF"

-- Main panel
local BG_R,  BG_G,  BG_B,  BG_A  = 0.04, 0.06, 0.12, 0.98
local BDR_R, BDR_G, BDR_B, BDR_A = 0.78, 0.61, 0.23, 1.00

-- Account cells (slightly lighter blue, blue border)
local CBG_R,  CBG_G,  CBG_B,  CBG_A  = 0.08, 0.10, 0.18, 1.00
local CBDR_R, CBDR_G, CBDR_B, CBDR_A = 0.25, 0.35, 0.55, 0.80

local BD_MAIN = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left=2, right=2, top=2, bottom=2 },
}
local BD_CELL = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 6,
    insets = { left=1, right=1, top=1, bottom=1 },
}

-- ─── Layout constants ────────────────────────────────────────────────────────

local PANEL_W    = 784
local CELL_W     = 248    -- (784 - 2*14 side margins - 2*6 gaps) / 3 = 248
local CELL_H     = 169    -- account row + sep + col-header + sep + 10 rows*12px + padding
local SLOT_COUNT = 10     -- max chars per account cell
local ROW_H      = 12
local GRID_COLS  = 3
local GRID_ROWS  = 2
local CELL_GAP   = 6
local MARGIN     = 14
local GRID_TOP   = -52    -- y from panel TOPLEFT
local HDR_H      = 0      -- account name is now inside the cell
local HDR_GAP    = 0

-- Derived: where does the grid end?
local GRID_END   = GRID_TOP - GRID_ROWS * (HDR_H + HDR_GAP + CELL_H) - (GRID_ROWS - 1) * CELL_GAP

-- Commands: each entry has a command line (both prefixes) and a description line.
-- Format: cmd = shown in gold, desc = shown in light gray.
-- Both .levelsync and /lsync work as the prefix for every command.
-- sub = the part after the prefix (shared by both .levelsync and /lsync)
local CMDS = {
    { sub = "setkey <key>",              desc = "Set your account security key" },
    { sub = "addaccount <acct> [key]",   desc = "Link all characters from another account" },
    { sub = "addchar <name> [key]",      desc = "Link a single character into your group" },
    { sub = "removeaccount <acct>",      desc = "Remove all characters of an account" },
    { sub = "removeaccount # <acct#>",  desc = "Remove an account by its group number" },
    { sub = "removechar <name>",         desc = "Remove one character from your group" },
    { sub = "removeall",                 desc = "Disband your sync group" },
    { sub = "disbandaccount",            desc = "Disband all groups tied to your account" },
    { sub = "listaccount <acct> [key]",  desc = "List all characters on an account" },
    { sub = "status",                    desc = "Show full group summary and all members" },
    { sub = "level on|off",              desc = "Toggle level synchronization for the group" },
    { sub = "IP on|off",                 desc = "Toggle progression (IP tier) sync for the group" },
}
-- 2 columns (6 left, 5 right). Each entry = 2 lines: .levelsync cmd + description.
local CMD_ENTRY_H  = 32   -- 14px cmd + 14px desc + 4px gap
local CMD_COLS     = 2
local CMD_COL_W    = (PANEL_W - MARGIN * 2) / CMD_COLS  -- 306px each
local CMD_COL_SPLIT = 6   -- entries 1-6 in left col, 7-11 in right col
-- Panel height
PANEL_H = 680

-- ─── Tier short display strings ─────────────────────────────────────────────

local TIER_SHORT = {
    [0]  = "None",
    [1]  = "1 - Molten Core",
    [2]  = "2 - Onyxia",
    [3]  = "3 - Blackwing Lair",
    [4]  = "4 - Pre-Ahn'Qiraj",
    [5]  = "5 - AQ War Effort",
    [6]  = "6 - Ahn'Qiraj",
    [7]  = "7 - Naxxramas",
    [8]  = "8 - Pre-TBC",
    [9]  = "9 - Kara/Gruul/Mag",
    [10] = "10 - SSC/TK",
    [11] = "11 - Hyjal/Black Temple",
    [12] = "12 - Zul'Aman",
    [13] = "13 - Sunwell",
    [14] = "14 - Naxx/EoE",
    [15] = "15 - Ulduar",
    [16] = "16 - Trial of the Crusader",
    [17] = "17 - Icecrown Citadel",
    [18] = "18 - Ruby Sanctum",
}

-- ─── Tier text colors (hues match the Gear Tracker T0–T17 palette) ──────────

local TIER_COLORS = {
    [0]  = {0.50, 0.50, 0.50},  -- None          (gray)
    [1]  = {0.87, 0.55, 0.20},  -- Molten Core   (T1 amber)
    [2]  = {0.87, 0.55, 0.20},  -- Onyxia        (T1 amber)
    [3]  = {0.85, 0.25, 0.25},  -- BWL           (T2 red)
    [4]  = {0.30, 0.65, 0.30},  -- Pre-AQ        (T3 forest green)
    [5]  = {0.30, 0.50, 0.85},  -- AQ War Effort (T4 steel blue)
    [6]  = {0.65, 0.30, 0.85},  -- Ahn'Qiraj     (T5 purple)
    [7]  = {0.20, 0.72, 0.72},  -- Naxxramas 40  (T6 teal)
    [8]  = {0.75, 0.72, 0.25},  -- Pre-TBC       (T7 olive)
    [9]  = {0.80, 0.28, 0.50},  -- Kara/Gruul    (T8 maroon-pink)
    [10] = {0.55, 0.55, 0.70},  -- SSC / TK      (T9 slate)
    [11] = {1.00, 0.50, 0.15},  -- Hyjal / BT    (T10 orange)
    [12] = {0.22, 0.80, 0.55},  -- Zul'Aman      (T11 spring green)
    [13] = {0.30, 0.50, 1.00},  -- Sunwell       (T12 royal blue)
    [14] = {0.55, 0.78, 0.30},  -- Naxx/EoE/OS   (T13 lime green)
    [15] = {0.70, 0.50, 0.95},  -- Ulduar        (T14 lavender)
    [16] = {0.22, 0.75, 0.70},  -- ToC           (T15 cyan-teal)
    [17] = {0.90, 0.20, 0.30},  -- ICC           (T16 crimson)
    [18] = {0.35, 0.80, 0.35},  -- Ruby Sanctum  (T17 emerald)
}

-- ─── Helper: colored hex string → r,g,b floats ───────────────────────────────

local function hexRGB(hex)
    if not hex then return 1, 1, 1 end
    return tonumber(hex:sub(1,2),16)/255,
           tonumber(hex:sub(3,4),16)/255,
           tonumber(hex:sub(5,6),16)/255
end

-- Strip "N - " prefix from tier strings like "17 - Icecrown Citadel"
local function shortTier(s)
    if not s or s == "" or s == "None" then return "None" end
    return s:match("^%d+ %- (.+)") or s
end

-- ─── Main Panel ──────────────────────────────────────────────────────────────

local panel = CreateFrame("Frame", "LevelSyncMainFrame", UIParent)
panel:SetSize(PANEL_W, PANEL_H)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:SetClampedToScreen(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
panel:SetBackdrop(BD_MAIN)
panel:SetBackdropColor(BG_R, BG_G, BG_B, BG_A)
panel:SetBackdropBorderColor(BDR_R, BDR_G, BDR_B, BDR_A)
panel:Hide()

-- Register with UISpecialFrames so ESC closes it
tinsert(UISpecialFrames, "LevelSyncMainFrame")

-- ─── Title bar ───────────────────────────────────────────────────────────────


local titleFS = panel:CreateFontString(nil, "OVERLAY")
titleFS:SetFont(FONT, 13, "OUTLINE")
titleFS:SetPoint("TOP", panel, "TOP", 0, -12)
titleFS:SetText(GOLD.."LevelSync - v1.0"..ENDC)

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

-- ─── Status line ─────────────────────────────────────────────────────────────

-- Gold separator line helper
local function goldLine(yAbs)
    local t = panel:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  panel, "TOPLEFT",  MARGIN, yAbs)
    t:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -MARGIN, yAbs)
    t:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)
    return t
end

goldLine(-38)

-- ─── 3×2 Account cell grid ───────────────────────────────────────────────────

local cells = {}  -- cells[1..6] = { frame, hdrFS, rows[1..10] }

for idx = 1, 6 do
    local col = (idx - 1) % GRID_COLS
    local row = math.floor((idx - 1) / GRID_COLS)

    local xOff     = MARGIN + col * (CELL_W + CELL_GAP)
    local groupTop = GRID_TOP - row * (CELL_H + CELL_GAP)

    -- Cell frame (full height, account name lives inside)
    local cell = CreateFrame("Frame", nil, panel)
    cell:SetSize(CELL_W, CELL_H)
    cell:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff, groupTop)
    cell:SetBackdrop(BD_CELL)
    cell:SetBackdropColor(CBG_R, CBG_G, CBG_B, CBG_A)
    cell:SetBackdropBorderColor(CBDR_R, CBDR_G, CBDR_B, CBDR_A)

    -- Account name row (inside cell)
    local hdrFS = cell:CreateFontString(nil, "OVERLAY")
    hdrFS:SetFont(FONT, 10, "OUTLINE")
    hdrFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -3)
    hdrFS:SetWidth(CELL_W - 4)
    hdrFS:SetJustifyH("CENTER")
    hdrFS:SetTextColor(BDR_R, BDR_G, BDR_B)
    hdrFS:SetText("— empty —")

    -- Separator under account name
    local acctSep = cell:CreateTexture(nil, "ARTWORK")
    acctSep:SetHeight(1)
    acctSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -16)
    acctSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -16)
    acctSep:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)

    -- Column headers: LvL | Character | Tier
    local colLvlFS = cell:CreateFontString(nil, "OVERLAY")
    colLvlFS:SetFont(FONT, 9, "OUTLINE")
    colLvlFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -22)
    colLvlFS:SetWidth(20)
    colLvlFS:SetJustifyH("CENTER")
    colLvlFS:SetTextColor(BDR_R, BDR_G, BDR_B)
    colLvlFS:SetText("LvL")

    local colCharFS = cell:CreateFontString(nil, "OVERLAY")
    colCharFS:SetFont(FONT, 9, "OUTLINE")
    colCharFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 25, -22)
    colCharFS:SetWidth(84)
    colCharFS:SetJustifyH("LEFT")
    colCharFS:SetTextColor(BDR_R, BDR_G, BDR_B)
    colCharFS:SetText("Character")

    local colTierFS = cell:CreateFontString(nil, "OVERLAY")
    colTierFS:SetFont(FONT, 9, "OUTLINE")
    colTierFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 112, -22)
    colTierFS:SetWidth(114)
    colTierFS:SetJustifyH("LEFT")
    colTierFS:SetTextColor(BDR_R, BDR_G, BDR_B)
    colTierFS:SetText("Tier")

    -- Separator under column headers
    local hdrSep = cell:CreateTexture(nil, "ARTWORK")
    hdrSep:SetHeight(1)
    hdrSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -37)
    hdrSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -37)
    hdrSep:SetTexture(CBDR_R, CBDR_G, CBDR_B, 0.7)

    -- 10 character slots
    local rows = {}
    for r = 1, SLOT_COUNT do
        local yRow = -(39 + (r - 1) * ROW_H)

        local lvlFS = cell:CreateFontString(nil, "OVERLAY")
        lvlFS:SetFont(FONT, 9, "OUTLINE")
        lvlFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
        lvlFS:SetWidth(20)
        lvlFS:SetJustifyH("CENTER")
        lvlFS:SetText("")

        local nameFS = cell:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont(FONT, 9, "OUTLINE")
        nameFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 25, yRow)
        nameFS:SetWidth(84)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetText("")

        local tierFS = cell:CreateFontString(nil, "OVERLAY")
        tierFS:SetFont(FONT, 9, "OUTLINE")
        tierFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 112, yRow)
        tierFS:SetWidth(114)
        tierFS:SetJustifyH("LEFT")
        tierFS:SetText("")

        -- Row highlight texture
        local highlight = cell:CreateTexture(nil, "ARTWORK")
        highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
        highlight:SetSize(CELL_W - 6, ROW_H - 1)
        highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        highlight:SetVertexColor(0.78, 0.61, 0.23, 0.08)
        highlight:Hide()

        -- Transparent hover frame (full row width, behind removeBtn)
        local rowBtn = CreateFrame("Button", nil, cell)
        rowBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
        rowBtn:SetSize(CELL_W - 6, ROW_H)
        rowBtn:SetFrameLevel(cell:GetFrameLevel() + 1)
        rowBtn.active = false
        rowBtn:SetScript("OnEnter", function(self)
            if self.active then highlight:Show() end
        end)
        rowBtn:SetScript("OnLeave", function(self)
            highlight:Hide()
        end)

        -- Remove button (×) — sits above rowBtn
        local removeBtn = CreateFrame("Button", nil, cell)
        removeBtn:SetSize(16, ROW_H)
        removeBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", 230, yRow)
        removeBtn:SetFrameLevel(cell:GetFrameLevel() + 2)
        removeBtn.charName = ""
        local removeLbl = removeBtn:CreateFontString(nil, "OVERLAY")
        removeLbl:SetFont(FONT, 9, "OUTLINE")
        removeLbl:SetAllPoints(removeBtn)
        removeLbl:SetJustifyH("CENTER")
        removeLbl:SetTextColor(0.70, 0.20, 0.20)
        removeLbl:SetText("×")
        removeBtn.lbl = removeLbl
        removeBtn:SetScript("OnClick", function(self)
            if self.charName ~= "" then
                LS.SendCmd("removechar " .. self.charName)
            end
        end)
        removeBtn:SetScript("OnEnter", function(self)
            self.lbl:SetTextColor(1.0, 0.4, 0.4)
            if rowBtn.active then highlight:Show() end
        end)
        removeBtn:SetScript("OnLeave", function(self)
            self.lbl:SetTextColor(0.70, 0.20, 0.20)
            highlight:Hide()
        end)
        removeBtn:Hide()

        rows[r] = { nameFS = nameFS, lvlFS = lvlFS, tierFS = tierFS, removeBtn = removeBtn, rowBtn = rowBtn, highlight = highlight }
    end

    cells[idx] = { frame = cell, hdrFS = hdrFS, rows = rows }
end

-- ─── Separator + Refresh button + status bar ─────────────────────────────────

goldLine(GRID_END - 8)

-- 5 equal slots across the panel (756px usable / 5 = 151px each)
-- Slot centers: 89, 240, 391, 542, 693
local statY = GRID_END - 22

local refreshBtn = CreateFrame("Button", nil, panel)
refreshBtn:SetSize(90, 22)
refreshBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 44, GRID_END - 17)  -- centered in slot 1
refreshBtn:SetBackdrop(BD_CELL)
refreshBtn:SetBackdropColor(0.10, 0.08, 0.02, 1)
refreshBtn:SetBackdropBorderColor(BDR_R, BDR_G, BDR_B, 1.0)

local refreshLbl = refreshBtn:CreateFontString(nil, "OVERLAY")
refreshLbl:SetFont(FONT, 10, "OUTLINE")
refreshLbl:SetAllPoints(refreshBtn)
refreshLbl:SetJustifyH("CENTER")
refreshLbl:SetText(GOLD.."Refresh"..ENDC)

refreshBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(1, 0.95, 0.5, 1)
end)
refreshBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(BDR_R, BDR_G, BDR_B, 1.0)
end)
refreshBtn:SetScript("OnClick", function()
    LS.SendCmd("status")
end)

-- Status displays — slots 2–5 (130px wide, CENTER justify; slot centers: 240, 391, 542, 693)
local accountsFS = panel:CreateFontString(nil, "OVERLAY")
accountsFS:SetFont(FONT, 10, "OUTLINE")
accountsFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 175, statY)    -- center 240
accountsFS:SetWidth(130)
accountsFS:SetJustifyH("CENTER")
accountsFS:SetTextColor(0.70, 0.75, 0.85)
accountsFS:SetText("Accounts: —")

local totalCharsFS = panel:CreateFontString(nil, "OVERLAY")
totalCharsFS:SetFont(FONT, 10, "OUTLINE")
totalCharsFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 326, statY)  -- center 391
totalCharsFS:SetWidth(130)
totalCharsFS:SetJustifyH("CENTER")
totalCharsFS:SetTextColor(0.70, 0.75, 0.85)
totalCharsFS:SetText("Characters: —")

local levelSyncFS = panel:CreateFontString(nil, "OVERLAY")
levelSyncFS:SetFont(FONT, 10, "OUTLINE")
levelSyncFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 477, statY)   -- center 542
levelSyncFS:SetWidth(130)
levelSyncFS:SetJustifyH("CENTER")
levelSyncFS:SetTextColor(0.70, 0.75, 0.85)
levelSyncFS:SetText("Level Sync: —")

local ipSyncFS = panel:CreateFontString(nil, "OVERLAY")
ipSyncFS:SetFont(FONT, 10, "OUTLINE")
ipSyncFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 628, statY)      -- center 693
ipSyncFS:SetWidth(130)
ipSyncFS:SetJustifyH("CENTER")
ipSyncFS:SetTextColor(0.70, 0.75, 0.85)
ipSyncFS:SetText("IP Sync: —")

-- ─── Commands reference section ──────────────────────────────────────────────

local CMD_TOP = GRID_END - 48

goldLine(CMD_TOP)

local cmdHdr = panel:CreateFontString(nil, "OVERLAY")
cmdHdr:SetFont(FONT, 10, "OUTLINE")
cmdHdr:SetPoint("TOPLEFT", panel, "TOPLEFT", MARGIN, CMD_TOP - 6)
cmdHdr:SetText(GOLD2.."Commands"..ENDC)

goldLine(CMD_TOP - 18)

-- 2 columns (6 left, 5 right)
for i, entry in ipairs(CMDS) do
    local col    = (i <= CMD_COL_SPLIT) and 0 or 1
    local rowIdx = (i <= CMD_COL_SPLIT) and (i - 1) or (i - CMD_COL_SPLIT - 1)
    local xOff   = MARGIN + 2 + col * CMD_COL_W
    local yBase  = CMD_TOP - 26 - rowIdx * CMD_ENTRY_H

    local dot = panel:CreateFontString(nil, "OVERLAY")
    dot:SetFont(FONT, 11, "OUTLINE")
    dot:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff, yBase)
    dot:SetWidth(CMD_COL_W - 6)
    dot:SetJustifyH("LEFT")
    dot:SetTextColor(BDR_R, BDR_G, BDR_B)
    dot:SetText(".levelsync " .. entry.sub)

    local desc = panel:CreateFontString(nil, "OVERLAY")
    desc:SetFont(FONT, 11, "OUTLINE")
    desc:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff, yBase - 15)
    desc:SetWidth(CMD_COL_W - 6)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.70, 0.75, 0.85)
    desc:SetText(entry.desc)
end

-- ─── RebuildGrid — called by UI_OnDataRefresh ─────────────────────────────────

local function RebuildGrid()
    local d       = LS.data
    local myName  = UnitName("player") or ""

    -- Status bar
    if d.inGroup then
        accountsFS:SetText("Accounts: " .. d.accountsCur .. "/" .. d.accountsMax)
        totalCharsFS:SetText("Characters: " .. d.totalChars)
        local lsOn = d.levelSync
        levelSyncFS:SetText("Level Sync: " .. (lsOn and "|cff44dd44ON|r" or "|cffdd4444OFF|r"))
        local ipOn = d.ipSync
        ipSyncFS:SetText("IP Sync: "     .. (ipOn and "|cff44dd44ON|r" or "|cffdd4444OFF|r"))
    else
        accountsFS:SetText("Accounts: —")
        totalCharsFS:SetText("Characters: —")
        levelSyncFS:SetText("Level Sync: —")
        ipSyncFS:SetText("IP Sync: —")
    end

    -- Group members by accountId, preserving order of first appearance
    local accountOrder = {}
    local accountMap   = {}  -- accountId → {members}
    for _, m in ipairs(d.members) do
        if not accountMap[m.accountId] then
            table.insert(accountOrder, m.accountId)
            accountMap[m.accountId] = {}
        end
        table.insert(accountMap[m.accountId], m)
    end

    for cellIdx = 1, 6 do
        local cell   = cells[cellIdx]
        local accId  = accountOrder[cellIdx]

        if not accId then
            -- Empty cell
            cell.hdrFS:SetTextColor(0.35, 0.35, 0.50)
            cell.hdrFS:SetText("— empty —")
            cell.frame:SetBackdropBorderColor(CBDR_R, CBDR_G, CBDR_B, CBDR_A)
            for r = 1, SLOT_COUNT do
                cell.rows[r].nameFS:SetText("")
                cell.rows[r].lvlFS:SetText("")
                cell.rows[r].tierFS:SetText("")
                cell.rows[r].removeBtn.charName = ""
                cell.rows[r].removeBtn:Hide()
                cell.rows[r].rowBtn.active = false
                cell.rows[r].highlight:Hide()
            end
        else
            cell.hdrFS:SetTextColor(BDR_R, BDR_G, BDR_B)
            cell.hdrFS:SetText("Account " .. accId)
            cell.frame:SetBackdropBorderColor(BDR_R * 0.7, BDR_G * 0.7, BDR_B * 0.7, 0.9)

            local members = accountMap[accId]
            for r = 1, SLOT_COUNT do
                local m = members[r]
                if m then
                    local cr, cg, cb = hexRGB(LS.CLASS_COLORS[m.class])
                    if m.name == myName then
                        cell.rows[r].nameFS:SetTextColor(1.00, 0.90, 0.30)
                    else
                        cell.rows[r].nameFS:SetTextColor(cr, cg, cb)
                    end
                    cell.rows[r].nameFS:SetText(m.name)
                    cell.rows[r].lvlFS:SetTextColor(0.83, 0.69, 0.22)
                    cell.rows[r].lvlFS:SetText(tostring(m.level))
                    local tc = TIER_COLORS[m.tierNum] or TIER_COLORS[0]
                    cell.rows[r].tierFS:SetTextColor(tc[1], tc[2], tc[3])
                    cell.rows[r].tierFS:SetText(TIER_SHORT[m.tierNum] or "None")
                    cell.rows[r].removeBtn.charName = m.name
                    cell.rows[r].removeBtn:Show()
                    cell.rows[r].rowBtn.active = true
                else
                    cell.rows[r].nameFS:SetText("")
                    cell.rows[r].lvlFS:SetText("")
                    cell.rows[r].tierFS:SetText("")
                    cell.rows[r].removeBtn.charName = ""
                    cell.rows[r].removeBtn:Hide()
                    cell.rows[r].rowBtn.active = false
                    cell.rows[r].highlight:Hide()
                end
            end
        end
    end
end

-- ─── Public callbacks (called from LevelSync.lua) ────────────────────────────

function LS.UI_OnDataRefresh()
    RebuildGrid()
end

function LS.UI_OnIPSyncDisabled()
    LS.data.ipSyncDisabled = true
    RebuildGrid()
end

function LS.UI_OnNotification(msg)
    local text = msg:match("%[LevelSync%]%s*(.+)") or msg
    print("|cffd4af37[LevelSync]|r " .. text)
end

-- ─── Toggle (slash command + minimap icon) ───────────────────────────────────

function LS.TogglePanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
        RebuildGrid()
        LS.SendCmd("status")
    end
end
