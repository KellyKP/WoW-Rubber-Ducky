-- Rubber Ducky: debug console. Status messages land here instead of chat;
-- the window shows while debug mode is on.

local _, ns = ...
local Console = {}
ns.Console = Console

local MAX = 500
local win, feed, copyWin

-- colour codes stripped, for copying
local function PlainText()
    local out = {}
    for i, line in ipairs(ns.consoleLines) do
        out[i] = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
    end
    return table.concat(out, "\n")
end

local function ShowCopy()
    if not copyWin then
        copyWin = CreateFrame("Frame", "RubberDuckyConsoleCopy", UIParent, "BackdropTemplate")
        copyWin:SetSize(560, 360)
        copyWin:SetPoint("CENTER")
        copyWin:SetFrameStrata("DIALOG")
        copyWin:SetMovable(true); copyWin:EnableMouse(true)
        copyWin:RegisterForDrag("LeftButton")
        copyWin:SetScript("OnDragStart", copyWin.StartMoving)
        copyWin:SetScript("OnDragStop", copyWin.StopMovingOrSizing)
        copyWin:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        tinsert(UISpecialFrames, "RubberDuckyConsoleCopy")
        local t = copyWin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", 0, -14)
        t:SetText("Rubber Ducky console  (Ctrl+A, Ctrl+C to copy)")
        local close = CreateFrame("Button", nil, copyWin, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        local scroll = CreateFrame("ScrollFrame", nil, copyWin, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -36)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(500)
        edit:SetScript("OnEscapePressed", function() copyWin:Hide() end)
        scroll:SetScrollChild(edit)
        copyWin.edit = edit
    end
    copyWin.edit:SetText(PlainText())
    copyWin:Show()
    copyWin.edit:SetFocus()
    copyWin.edit:HighlightText()
end
Console.ShowCopy = ShowCopy

local function Build()
    win = CreateFrame("Frame", "RubberDuckyConsole", UIParent, "BackdropTemplate")
    win:SetSize(500, 220)
    win:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 40, 260)
    win:SetFrameStrata("MEDIUM")
    win:SetMovable(true); win:EnableMouse(true); win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        ns.db.consolePos = { point, rel, x, y }
    end)
    win:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    win:SetBackdropColor(0.03, 0.05, 0.08, 0.88)
    win:SetBackdropBorderColor(0.3, 0.55, 0.7, 0.9)
    win:Hide()

    local pos = ns.db.consolePos
    if pos then
        win:ClearAllPoints()
        win:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cffffd100Rubber Ducky|r console  |cff888888(debug mode)|r")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() win:Hide() end)

    local function SmallButton(text, anchorTo, onClick)
        local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
        b:SetSize(58, 18)
        b:SetText(text)
        b:SetNormalFontObject("GameFontNormalSmall")
        b:SetHighlightFontObject("GameFontHighlightSmall")
        if anchorTo then b:SetPoint("RIGHT", anchorTo, "LEFT", -4, 0) else b:SetPoint("TOPRIGHT", -26, -5) end
        b:SetScript("OnClick", onClick)
        return b
    end
    local clear = SmallButton("Clear", nil, function() wipe(ns.consoleLines); feed:Clear() end)
    local log = SmallButton("Rec. log", clear, function() if ns.Probe then ns.Probe:ShowLog() end end)
    local status = SmallButton("Status", log, function() if ns.OneKey then ns.OneKey:Status() end end)
    SmallButton("Copy", status, ShowCopy)

    feed = CreateFrame("ScrollingMessageFrame", nil, win)
    feed:SetPoint("TOPLEFT", 10, -28)
    feed:SetPoint("BOTTOMRIGHT", -10, 8)
    feed:SetFontObject(GameFontHighlightSmall)
    feed:SetJustifyH("LEFT")
    feed:SetFading(false)
    feed:SetMaxLines(MAX)
    feed:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_BOTTOM or "BOTTOM")
    feed:EnableMouseWheel(true)
    feed:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    for _, line in ipairs(ns.consoleLines) do feed:AddMessage(line) end
end

function Console:Add(line)
    if feed then feed:AddMessage(line) end
end

function Console:Show()
    if not win then Build() end
    win:Show()
end

function Console:Hide()
    if win then win:Hide() end
end

function Console:Toggle()
    if win and win:IsShown() then win:Hide() else self:Show() end
end

function Console:Apply()
    if ns.db.debugMode then self:Show() else self:Hide() end
end
