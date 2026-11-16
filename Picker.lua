-- Rubber Ducky: bobber icon picker (/ducky icons, or Choose Bobber).

local _, ns = ...
local Picker = {}
ns.Picker = Picker

local COLS, CELL, GAP, PAD = 6, 60, 8, 18
local MEDIA = "Interface\\AddOns\\RubberDucky\\Media\\bobber_"

local win, cells, preview, previewName, randomCheck

local function IconPath(i)
    return MEDIA .. ns.Bobber.MARKERS[i][1]
end

local function SyncSetting(value) end

local function Refresh()
    if not win then return end
    local style = ns.db.markerStyle or 1
    for i, cell in ipairs(cells) do
        cell.selected:SetShown(i == style)
    end
    randomCheck:SetChecked(style == 0)
    if style >= 1 and style <= #ns.Bobber.MARKERS then
        preview:SetTexture(IconPath(style))
        preview:SetDesaturated(false)
        previewName:SetText(ns.Bobber.MARKERS[style][2])
    else
        preview:SetTexture(IconPath(math.random(#ns.Bobber.MARKERS)))
        previewName:SetText("Random each cast")
    end
end

local function Choose(value)
    ns.db.markerStyle = value
    ns.db.markerEnabled = true -- picking a bobber means you want to see it
    SyncSetting(value)
    if ns.Bobber.RefreshMarker then ns.Bobber:RefreshMarker() end
    if ns.Options and ns.Options.RefreshOverview then ns.Options.RefreshOverview() end
    Refresh()
end

local function Build()
    local count = #ns.Bobber.MARKERS
    local rows = math.ceil(count / COLS)
    local gridW = COLS * CELL + (COLS - 1) * GAP
    local gridH = rows * CELL + (rows - 1) * GAP

    win = CreateFrame("Frame", "RubberDuckyIconPicker", UIParent, "BackdropTemplate")
    win:SetSize(gridW + PAD * 2, gridH + 150)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetMovable(true); win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    tinsert(UISpecialFrames, "RubberDuckyIconPicker")
    win:Hide()

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Choose your bobber icon")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    cells = {}
    for i = 1, count do
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        local b = CreateFrame("Button", nil, win)
        b:SetSize(CELL, CELL)
        b:SetPoint("TOPLEFT", PAD + col * (CELL + GAP), -46 - row * (CELL + GAP))

        local bg = b:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.06)

        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4); icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexture(IconPath(i))

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.15)

        local sel = b:CreateTexture(nil, "OVERLAY")
        sel:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        sel:SetBlendMode("ADD")
        sel:SetVertexColor(1, 0.82, 0.2)
        sel:SetPoint("CENTER")
        sel:SetSize(CELL * 1.75, CELL * 1.75)
        sel:Hide()
        b.selected = sel

        b:SetScript("OnClick", function() Choose(i) end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(ns.Bobber.MARKERS[i][2])
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cells[i] = b
    end

    local footerTop = -46 - gridH - 14
    preview = win:CreateTexture(nil, "ARTWORK")
    preview:SetSize(80, 80)
    preview:SetPoint("TOPLEFT", PAD, footerTop)

    previewName = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    previewName:SetPoint("LEFT", preview, "RIGHT", 12, 12)
    previewName:SetJustifyH("LEFT")

    randomCheck = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
    randomCheck:SetPoint("TOPLEFT", previewName, "BOTTOMLEFT", -4, -6)
    local rl = randomCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rl:SetPoint("LEFT", randomCheck, "RIGHT", 2, 0)
    rl:SetText("Random each cast")
    randomCheck:SetScript("OnClick", function(self)
        Choose(self:GetChecked() and 0 or 1)
    end)

    win:SetScript("OnShow", Refresh)
end

function Picker:Show()
    if not win then Build() end
    win:ClearAllPoints()
    if SettingsPanel and SettingsPanel:IsShown() then
        win:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 4, 0)
    else
        win:SetPoint("CENTER")
    end
    win:Show()
    Refresh()
end

function Picker:Toggle()
    if win and win:IsShown() then win:Hide() else self:Show() end
end

function Picker:Refresh() Refresh() end
