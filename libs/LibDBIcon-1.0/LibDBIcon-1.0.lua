assert(LibStub, "LibDBIcon-1.0 requires LibStub")

local MAJOR, MINOR = "LibDBIcon-1.0", 37
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.objects    = lib.objects    or {}  -- [name] = {button, db, ldb}
lib.notCreated = lib.notCreated or {}  -- [name] = {ldb, db}  (waiting for PLAYER_LOGIN)

-- ─── position math ──────────────────────────────────────────────────────────

local function updatePosition(button, db)
	local angle  = math.rad(db.minimapPos or 225)
	local radius = db.radius or 80
	button:SetPoint("CENTER", Minimap, "CENTER",
		math.cos(angle) * radius,
		math.sin(angle) * radius)
end

-- ─── drag ───────────────────────────────────────────────────────────────────

local function onDragStart(self)
	self:LockHighlight()
	self:SetScript("OnUpdate", function(btn)
		local mx, my   = Minimap:GetCenter()
		local px, py   = GetCursorPosition()
		local eff      = UIParent:GetScale()
		px = px / eff
		py = py / eff
		local obj      = lib.objects[btn._lsName]
		if obj then
			obj.db.minimapPos = math.deg(math.atan2(py - my, px - mx)) % 360
			updatePosition(btn, obj.db)
		end
	end)
end

local function onDragStop(self)
	self:UnlockHighlight()
	self:SetScript("OnUpdate", nil)
end

-- ─── button construction ─────────────────────────────────────────────────────

local function createButton(name, ldb, db)
	local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
	button:SetFrameStrata("MEDIUM")
	button:SetWidth(31)
	button:SetHeight(31)
	button:SetFrameLevel(8)
	button:RegisterForClicks("anyUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetWidth(53)
	overlay:SetHeight(53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetWidth(20)
	background:SetHeight(20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("TOPLEFT", 7, -5)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetWidth(17)
	icon:SetHeight(17)
	icon:SetTexture(ldb.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint("TOPLEFT", 7, -6)
	button._icon = icon

	button._lsName = name

	button:SetScript("OnClick", function(self, btn)
		if ldb.OnClick then ldb.OnClick(self, btn) end
	end)

	button:SetScript("OnEnter", function(self)
		if ldb.OnTooltipShow then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:ClearLines()
			ldb.OnTooltipShow(GameTooltip)
			GameTooltip:Show()
		elseif ldb.OnEnter then
			ldb.OnEnter(self)
		end
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		if ldb.OnLeave then ldb.OnLeave(self) end
	end)

	button:SetScript("OnDragStart", onDragStart)
	button:SetScript("OnDragStop",  onDragStop)

	updatePosition(button, db)

	if db.hide then
		button:Hide()
	else
		button:Show()
	end

	return button
end

-- ─── public API ──────────────────────────────────────────────────────────────

function lib:Register(name, ldb, db)
	if self.objects[name] then
		error(("LibDBIcon: %q is already registered."):format(name), 2)
	end

	db = db or {}
	db.minimapPos = db.minimapPos or 225
	db.radius     = db.radius or 80
	if db.hide == nil then db.hide = false end

	if not IsLoggedIn() then
		self.notCreated[name] = { ldb = ldb, db = db }
	else
		local button = createButton(name, ldb, db)
		self.objects[name] = { button = button, db = db, ldb = ldb }
	end
end

function lib:Hide(name)
	local obj = self.objects[name]
	if obj then
		obj.db.hide = true
		obj.button:Hide()
	elseif self.notCreated[name] then
		self.notCreated[name].db.hide = true
	end
end

function lib:Show(name)
	local obj = self.objects[name]
	if obj then
		obj.db.hide = false
		obj.button:Show()
	elseif self.notCreated[name] then
		self.notCreated[name].db.hide = false
	end
end

function lib:IsRegistered(name)
	return self.objects[name] ~= nil or self.notCreated[name] ~= nil
end

-- ─── deferred creation on PLAYER_LOGIN ──────────────────────────────────────

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	for name, data in pairs(lib.notCreated) do
		local button = createButton(name, data.ldb, data.db)
		lib.objects[name] = { button = button, db = data.db, ldb = data.ldb }
	end
	wipe(lib.notCreated)
end)
