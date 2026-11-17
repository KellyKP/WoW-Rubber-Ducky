-- Rubber Ducky: the menu behind our line in the minimap's AddOns list.
-- Features add themselves with Menu:Add, so the journal can join later:
--
--   ns.Menu:Add{ text = "Journal", order = 20, onClick = fn,
--                disabled = function() return not ns.db.journalEnabled end }
--
-- Drawn by hand: the game's dropdown menus can cause "action blocked" errors.

local _, ns = ...
local Menu = { items = {} }
ns.Menu = Menu

local ROW_H, WIDTH, PAD = 22, 170, 8
local menu, rows, closedAt = nil, {}, 0

function Menu:Add(item)
    self.items[#self.items + 1] = item
    table.sort(self.items, function(a, b) return (a.order or 50) < (b.order or 50) end)
    if menu and menu:IsShown() then Menu:Paint() end
end

local function Build()
    menu = CreateFrame("Frame", "RubberDuckyMenu", UIParent, "BackdropTemplate")
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    menu:Hide()
    tinsert(UISpecialFrames, "RubberDuckyMenu")

    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD + 2, -PAD - 2)
    title:SetText("|T" .. ns.DUCK .. ":16:16|t  Rubber Ducky")
    menu.title = title

    -- a click anywhere else closes it
    pcall(menu.RegisterEvent, menu, "GLOBAL_MOUSE_DOWN")
    menu:SetScript("OnEvent", function()
        if menu:IsShown() and not menu:IsMouseOver() then
            menu:Hide()
            closedAt = GetTime()
        end
    end)
end

local function Row(i)
    if rows[i] then return rows[i] end
    local b = CreateFrame("Button", nil, menu)
    b:SetHeight(ROW_H)
    b:SetPoint("TOPLEFT", PAD, -PAD - 24 - (i - 1) * ROW_H)
    b:SetPoint("RIGHT", menu, "RIGHT", -PAD, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.text:SetPoint("LEFT", 8, 0)
    b.text:SetJustifyH("LEFT")
    b.note = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.note:SetPoint("RIGHT", -4, 0)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0, 0.12)
    b:SetScript("OnClick", function(self)
        menu:Hide()
        if self.item and self.item.onClick then C_Timer.After(0, self.item.onClick) end
    end)
    rows[i] = b
    return b
end

function Menu:Paint()
    for _, b in ipairs(rows) do b:Hide() end
    for i, item in ipairs(self.items) do
        local b = Row(i)
        b.item = item
        b.text:SetText(type(item.text) == "function" and item.text() or item.text)
        local off = item.disabled and item.disabled()
        b.text:SetTextColor(off and 0.5 or 1, off and 0.5 or 1, off and 0.5 or 1)
        b.note:SetText(off and "off" or "")
        b:Show()
    end
    menu:SetSize(WIDTH, PAD * 2 + 24 + #self.items * ROW_H)
end

function Menu:Show(anchor)
    if not menu then Build() end
    self:Paint()
    menu:ClearAllPoints()
    if anchor and anchor.x then
        menu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", anchor.x - 4, anchor.y)
    else
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        menu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x / s - 8, y / s + 8)
    end
    menu:Show()
end

function Menu:Toggle(anchor)
    if menu and menu:IsShown() then menu:Hide() return end
    -- the click that just closed it (GLOBAL_MOUSE_DOWN) shouldn't reopen it
    if GetTime() - closedAt < 0.3 then return end
    self:Show(anchor)
end

-- The two items we have today. Settings stays at the bottom.
Menu:Add{
    text = "Fishing log", order = 10,
    disabled = function() return not (ns.db and ns.db.logEnabled) end,
    onClick = function() if ns.Log then ns.Log:Toggle(true) end end,
}
Menu:Add{
    text = "Settings", order = 100,
    onClick = function() if ns.Options then ns.Options:Open() end end,
}

-- Our line in the minimap's AddOns list. Registered here rather than in the
-- TOC so the name shows in plain white like everyone else's (the TOC title is
-- gold, for the AddOns window).
local hovered -- the list's button under the mouse, to open the menu beside it
local function Tip(btn)
    hovered = btn
    if not GameTooltip then return end
    GameTooltip:SetOwner(btn or UIParent, "ANCHOR_LEFT")
    GameTooltip:SetText("Rubber Ducky")
    GameTooltip:AddLine("Click for the Rubber Ducky menu.", 1, 1, 1)
    GameTooltip:Show()
end

-- the list's buttons get reused, so pin the menu to where it was, not to it
local function Spot(btn)
    if not (btn and btn.GetLeft and btn:GetLeft()) then return nil end
    local s = btn:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return { x = btn:GetLeft() * s, y = btn:GetTop() * s }
end

function Menu.Register()
    local list = AddonCompartmentFrame
    if not (list and list.RegisterAddon) then return end
    list:RegisterAddon({
        text = "Rubber Ducky",
        icon = ns.DUCK,
        notCheckable = true,
        func = function() Menu:Toggle(Spot(hovered)) end,
        funcOnEnter = Tip,
        funcOnLeave = function() if GameTooltip then GameTooltip:Hide() end end,
    })
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    Menu.Register()
end)
