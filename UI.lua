-- Rubber Ducky: settings page kit, drawn inside Blizzard's settings window.
--
--   local page = UI.NewPage{ title, subtitle, icon, toggleKey, onToggle }
--   local card = page:Card("While your line is out")
--   card:Toggle{ label, key, onChange }
--   card:Slider{ label, key, min, max, step, format, onChange }
--   card:Choice{ label, options = {{value, text}...}, key | get/set, onChange, tall }
--   card:Buttons{ {text, onClick}, ... }
--   card:Text("...")
--   page:Expander("Fine-tune position", card)   -- card shown on demand
--   page:Tool("Reset position", fn)             -- small buttons, top right
--   page:ResetTool{ apply, extra, positions }   -- reset icon: settings / positions menu
--
-- Changes run a frame later (UI.Later), outside Blizzard's code, to avoid taint.

local _, ns = ...
local UI = {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local PAD = 14
local LABEL_W = 180 -- label column for sliders and choices

function UI.Later(fn) C_Timer.After(0, fn) end

local function Backdrop(frame, bgAlpha, edgeR, edgeG, edgeB, edgeA)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(0, 0, 0, bgAlpha)
    frame:SetBackdropBorderColor(edgeR, edgeG, edgeB, edgeA)
end

-------------------------------------------------------------------------------
-- Card
-------------------------------------------------------------------------------

local Card = {}
Card.__index = Card

local function NewCard(page, title, plain)
    local f = CreateFrame("Frame", nil, page.content, "BackdropTemplate")
    if not plain then Backdrop(f, 0.35, 1, 1, 1, 0.10) end
    local c = setmetatable({ frame = f, page = page, y = -PAD + 4, rows = {}, controls = page.controls }, Card)
    if title then
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOPLEFT", PAD, c.y)
        t:SetText(title)
        c.y = c.y - 24
    end
    f:SetScript("OnSizeChanged", function(_, w)
        for _, row in ipairs(c.rows) do if row.Relayout then row:Relayout(w) end end
    end)
    return c
end

function Card:Height() return -self.y + PAD - 6 end

function Card:Advance(h) local y = self.y; self.y = self.y - h; return y end

function Card:Text(text, small)
    local fs = self.frame:CreateFontString(nil, "OVERLAY", small and "GameFontDisableSmall" or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    local y = self.y
    fs:SetPoint("TOPLEFT", PAD, y)
    local row = { fs = fs }
    function row:Relayout(w) fs:SetWidth(w - PAD * 2) end
    self.rows[#self.rows + 1] = row
    self:Advance(small and 18 or 20)
    return fs
end

-- remember which settings a page shows, for its Defaults button
local function Track(card, o) if o.key then card.page.keys[o.key] = true end end

function Card:Toggle(o)
    Track(self, o)
    local y = self:Advance(o.desc and 40 or 28)
    local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", PAD - 4, y + 2)
    local label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 4, o.desc and 7 or 0)
    label:SetText(o.label)
    if o.desc then
        local d = self.frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        d:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        d:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0) -- one line, truncated
        d:SetJustifyH("LEFT")
        d:SetWordWrap(false)
        d:SetText(o.desc)
    end
    cb:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        if o.set then o.set(on) else ns.db[o.key] = on end
        if o.onChange then UI.Later(function() o.onChange(on) end) end
        UI.Later(function() if self.page then self.page:Refresh() end end)
    end)
    cb.page = self.page
    local ctl = { Refresh = function() cb:SetChecked(o.get and o.get() or ns.db[o.key] and true or false) end }
    self.controls[#self.controls + 1] = ctl
    return cb
end

local function Round(v, step)
    return math.floor(v / step + 0.5) * step
end

function Card:Slider(o)
    Track(self, o)
    local y = self:Advance(34)
    local label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", PAD, y - 6)
    label:SetWidth(LABEL_W - 10); label:SetJustifyH("LEFT")
    label:SetText(o.label)

    local s = CreateFrame("Slider", nil, self.frame, "BackdropTemplate")
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(17)
    s:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    s:SetMinMaxValues(o.min, o.max)
    s:SetValueStep(o.step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetPoint("TOPLEFT", LABEL_W, y - 5)
    s:EnableMouseWheel(true)

    local value = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("LEFT", s, "RIGHT", 10, 0)
    value:SetWidth(86); value:SetJustifyH("LEFT")

    local refreshing = false
    local function Show(v) value:SetText(o.format and o.format(v) or tostring(v)) end
    s:SetScript("OnValueChanged", function(_, v)
        v = Round(v, o.step)
        Show(v)
        if refreshing then return end
        ns.db[o.key] = v
        if o.onChange then UI.Later(function() o.onChange(v) end) end
    end)
    s:SetScript("OnMouseWheel", function(self, d)
        self:SetValue(math.max(o.min, math.min(o.max, self:GetValue() + d * o.step)))
    end)
    s:SetScript("OnMouseUp", function() UI.Later(function() self.page:Refresh() end) end)

    local row = {}
    function row:Relayout(w) s:SetWidth(math.max(80, w - LABEL_W - 110)) end
    self.rows[#self.rows + 1] = row
    self.controls[#self.controls + 1] = { Refresh = function()
        refreshing = true
        local v = ns.db[o.key] or o.min
        s:SetValue(v); Show(v)
        refreshing = false
    end }
    return s
end

-- A row of buttons, one picked
function Card:Choice(o)
    Track(self, o)
    local h = o.tall and 52 or 30
    local y = self:Advance(h + 6)
    local x0 = PAD
    if o.label then
        local label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", PAD, y - (h / 2) + 6)
        label:SetWidth(LABEL_W - 10); label:SetJustifyH("LEFT")
        label:SetText(o.label)
        x0 = LABEL_W
    end
    local buttons = {}
    local function Current()
        if o.get then return o.get() end
        return ns.db[o.key]
    end
    local function Paint()
        local cur = Current()
        if type(o.options) == "function" then -- labels can change
            local fresh = o.options()
            for i, b in ipairs(buttons) do
                if fresh[i] then
                    b.text:SetText(fresh[i][2])
                    if b.subText then b.subText:SetText(fresh[i][3] or "") end
                end
            end
        end
        for _, b in ipairs(buttons) do
            local on = (b.value == cur)
            if on then
                b:SetBackdropColor(GOLD[1], GOLD[2], GOLD[3], 0.18)
                b:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
                b.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            else
                b:SetBackdropColor(0, 0, 0, 0.3)
                b:SetBackdropBorderColor(1, 1, 1, 0.15)
                b.text:SetTextColor(0.9, 0.9, 0.9)
            end
        end
    end
    local options = type(o.options) == "function" and o.options() or o.options
    for i, opt in ipairs(options) do
        local b = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
        b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        b:SetHeight(h)
        b.value = opt[1]
        b.text = b:CreateFontString(nil, "OVERLAY", o.tall and "GameFontHighlight" or "GameFontHighlightSmall")
        b.text:SetPoint("CENTER", 0, opt[3] and 7 or 0)
        b.text:SetText(opt[2])
        if opt[3] then
            b.subText = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            b.subText:SetPoint("TOP", b.text, "BOTTOM", 0, -3)
            b.subText:SetText(opt[3])
        end
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
        b:SetScript("OnClick", function()
            if o.set then o.set(b.value) else ns.db[o.key] = b.value end
            Paint()
            if o.onChange then UI.Later(function() o.onChange(b.value) end) end
            UI.Later(function() self.page:Refresh() end)
        end)
        buttons[i] = b
    end
    local row = {}
    function row:Relayout(w)
        local gap = 6
        local n = #buttons
        local bw = (w - x0 - PAD - gap * (n - 1)) / n
        if o.maxWidth then bw = math.min(bw, o.maxWidth) end
        for i, b in ipairs(buttons) do
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", x0 + (i - 1) * (bw + gap), y)
            b:SetWidth(bw)
        end
    end
    self.rows[#self.rows + 1] = row
    self.controls[#self.controls + 1] = { Refresh = Paint, buttons = buttons }
    return buttons
end

function Card:Buttons(list)
    local y = self:Advance(32)
    local x = PAD
    local made = {}
    for _, item in ipairs(list) do
        local b = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        b:SetSize(item.width or 150, 24)
        b:SetText(item[1])
        b:SetPoint("TOPLEFT", x, y)
        b:SetScript("OnClick", function() UI.Later(item[2]) end)
        x = x + (item.width or 150) + 8
        made[#made + 1] = b
    end
    return made
end

-------------------------------------------------------------------------------
-- Page
-------------------------------------------------------------------------------

local Page = {}
Page.__index = Page

function UI.NewPage(o)
    local f = CreateFrame("Frame")
    f:Hide()
    -- called by the settings window on canvas pages
    f.OnCommit = function() end
    f.OnDefault = function() end
    f.OnRefresh = function() end

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(620, 400)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, w) content:SetWidth(w) end)

    local p = setmetatable({ frame = f, content = content, controls = {}, cards = {}, refreshers = {},
        keys = {}, tools = {}, toggleKey = o.toggleKey }, Page)

    -- header: icon, title, subtitle, main switch
    local iconFrame = CreateFrame("Frame", nil, content)
    iconFrame:SetSize(48, 48)
    iconFrame:SetPoint("TOPLEFT", 12, -8)
    local ring = iconFrame:CreateTexture(nil, "BACKGROUND")
    ring:SetAllPoints(); ring:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexture(o.icon)
    if o.crop ~= false then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    if iconFrame.CreateMaskTexture then
        local mask = iconFrame:CreateMaskTexture()
        mask:SetAllPoints()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        icon:AddMaskTexture(mask); ring:AddMaskTexture(mask)
    end
    p.icon = icon

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 12, -4)
    title:SetText(o.title)
    local sub = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText(o.subtitle or "")
    p.subtitle = sub

    if o.toggleKey then
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(28, 28)
        cb:SetPoint("TOPRIGHT", -40, -16)
        p.toggleButton = cb
        local l = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb:SetScript("OnClick", function(self)
            ns.db[o.toggleKey] = self:GetChecked() and true or false
            if o.onToggle then UI.Later(function() o.onToggle(ns.db[o.toggleKey]) end) end
            UI.Later(function() p:Refresh() end)
        end)
        p.controls[#p.controls + 1] = { Refresh = function()
            local on = ns.db[o.toggleKey] and true or false
            cb:SetChecked(on)
            l:SetText(on and "On" or "Off")
        end }
    end

    p.top = -68
    f:SetScript("OnShow", function() p:Refresh() end)
    return p
end

-- top-right tools sit in a row level with the on/off switch, to its left
function Page:PlaceTool(b)
    local prev = self.tools[#self.tools]
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -6, 0)
    elseif self.toggleButton then b:SetPoint("RIGHT", self.toggleButton, "LEFT", -12, 0)
    else b:SetPoint("RIGHT", self.content, "TOPRIGHT", -14, -30) end
end

-- small buttons in the top right
function Page:Tool(text, fn)
    local b = CreateFrame("Button", nil, self.content, "UIPanelButtonTemplate")
    b:SetHeight(22)
    b:SetText(text)
    b:SetWidth(math.max(80, (b:GetFontString() and b:GetFontString():GetStringWidth() or 60) + 28))
    self:PlaceTool(b)
    b:SetScript("OnClick", function() UI.Later(function() fn(b) end) end)
    self.tools[#self.tools + 1] = b
    return b
end

-- A little popup menu under a button. items: { text, onClick, confirm }.
-- confirm items ask "Sure?" first and stay open for the second click.
local popup
function UI.Popup(anchor, items)
    if not popup then
        popup = CreateFrame("Frame", "RubberDuckyPopup", UIParent, "BackdropTemplate")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetToplevel(true)
        popup:EnableMouse(true)
        popup:SetClampedToScreen(true)
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        popup.rows = {}
        pcall(popup.RegisterEvent, popup, "GLOBAL_MOUSE_DOWN")
        popup:SetScript("OnEvent", function()
            if popup:IsShown() and not popup:IsMouseOver() and not (popup.anchor and popup.anchor:IsMouseOver()) then
                popup:Hide()
            end
        end)
        popup:Hide()
        tinsert(UISpecialFrames, "RubberDuckyPopup")
    end
    if popup:IsShown() and popup.anchor == anchor then popup:Hide() return end
    popup.anchor = anchor
    for _, r in ipairs(popup.rows) do r:Hide() end
    local width = 160
    for i, item in ipairs(items) do
        local r = popup.rows[i]
        if not r then
            r = CreateFrame("Button", nil, popup)
            r:SetHeight(22)
            r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            r.text:SetPoint("LEFT", 8, 0)
            local hl = r:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0, 0.12)
            popup.rows[i] = r
        end
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 22)
        r:SetPoint("RIGHT", popup, "RIGHT", -6, 0)
        r.text:SetText(item[1])
        r.text:SetTextColor(1, 1, 1)
        local armed = false
        r:SetScript("OnClick", function()
            if item.confirm and not armed then
                armed = true
                r.text:SetText("Sure? Click again")
                r.text:SetTextColor(1, 0.5, 0.25)
                return
            end
            popup:Hide()
            UI.Later(item[2])
        end)
        r:Show()
        width = math.max(width, (r.text:GetStringWidth() or 0) + 40)
    end
    popup:SetSize(width, 12 + #items * 22)
    popup:ClearAllPoints()
    popup:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
    popup:Show()
end

-- The reset icon, top right. Its menu puts this page's settings back to the
-- defaults (all but the page's on/off switch), and offers any position resets.
-- o: { apply = fn after settings change, extra = { keys set by hand-made
-- controls }, positions = { { "Reset log position", fn }, ... } }
function Page:ResetTool(o)
    o = o or {}
    for _, k in ipairs(o.extra or {}) do self.keys[k] = true end
    local b = CreateFrame("Button", nil, self.content)
    b:SetSize(26, 26)
    self:PlaceTool(b)
    b:SetNormalTexture("Interface\\Buttons\\UI-RotationLeft-Button-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-RotationLeft-Button-Down")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", function()
        GameTooltip:SetOwner(b, "ANCHOR_LEFT")
        GameTooltip:SetText("Reset")
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function ResetSettings()
        for k in pairs(self.keys) do
            if k ~= self.toggleKey and ns.defaults[k] ~= nil then ns.db[k] = ns.defaults[k] end
        end
        if o.apply then o.apply() end
        self:Refresh()
    end
    b:SetScript("OnClick", function()
        local items = { { "Reset settings", ResetSettings, confirm = true } }
        for _, pos in ipairs(o.positions or {}) do items[#items + 1] = pos end
        UI.Popup(b, items)
    end)
    self.tools[#self.tools + 1] = b
    return b
end

function Page:Card(title, plain)
    local c = NewCard(self, title, plain)
    self.cards[#self.cards + 1] = c
    return c
end

-- "Fine-tune" line that shows or hides a card
function Page:Expander(text, card)
    local line = self:Card(nil, true)
    local b = CreateFrame("Button", nil, line.frame)
    b:SetHeight(20)
    b:SetPoint("TOPLEFT", 6, -2)
    b:SetPoint("TOPRIGHT", -6, -2)
    local plus = b:CreateTexture(nil, "ARTWORK")
    plus:SetSize(14, 14)
    plus:SetPoint("LEFT", 4, 0)
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", plus, "RIGHT", 6, 0)
    t:SetText(text)
    line.y = -24
    card.hidden = true
    local function Paint()
        plus:SetTexture(card.hidden and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    end
    b:SetScript("OnClick", function()
        card.hidden = not card.hidden
        Paint()
        self:Layout()
    end)
    Paint()
    table.remove(self.cards)
    for i, c in ipairs(self.cards) do
        if c == card then table.insert(self.cards, i, line) break end
    end
    return line
end

function Page:Layout()
    local y = self.top
    for _, c in ipairs(self.cards) do
        local f = c.frame
        f:ClearAllPoints()
        if c.hidden then
            f:Hide()
        else
            f:Show()
            f:SetPoint("TOPLEFT", self.content, "TOPLEFT", 12, y)
            f:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -12, y)
            f:SetHeight(c:Height())
            y = y - c:Height() - 10
        end
    end
    self.content:SetHeight(-y + 12)
end

function Page:OnRefresh(fn) self.refreshers[#self.refreshers + 1] = fn end

function Page:Refresh()
    if not ns.db then return end
    for _, ctl in ipairs(self.controls) do ctl.Refresh() end
    for _, fn in ipairs(self.refreshers) do fn(self) end
    self:Layout()
end
