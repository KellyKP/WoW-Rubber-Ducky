-- Rubber Ducky: "What's new" window. Keep in step with CHANGELOG.md.

local _, ns = ...
local Changelog = {}
ns.Changelog = Changelog

Changelog.entries = {
    { "0.22.0", {
        "|cffffd100New|r",
        "Pole swap shows a splash with its own sound: \"Nice Day for Fishin'\" and \"It's Adventure Time!\". Both can be turned off on the overview page.",
        "New commands: /ducky swap toggles, /ducky swap 1 puts on your pole and /ducky swap 2 your weapon. They replace /ducky pole.",
        "Share settings: copy your settings as text and paste someone else's, from the overview page.",
        "A \"What's new\" button on the overview page shows this changelog in game.",
        "Chat messages are friendlier and carry the duck icon.",
        "|cffffd100Fixes|r",
        "Pole swap remembers your weapon and pole separately for each character.",
        "The swap splash only shows once your gear has actually changed, so it always matches, and a quick double press no longer undoes a swap.",
        "Swapping in combat, or without your weapon or pole in your bags, now says why instead of failing quietly.",
        "Picking a bobber turns the bobber icon on, in case it was off, and shows it on the bobber right away.",
        "/ducky in combat now opens the settings once combat ends.",
        "The Ducky Pole macro is no longer rewritten while the Macros window is open.",
    } },
    { "0.21.0", {
        "First release.",
    } },
}

local win

local function Text()
    local out = {}
    for _, e in ipairs(Changelog.entries) do
        out[#out + 1] = "|cffffd100" .. e[1] .. "|r"
        for _, line in ipairs(e[2]) do
            -- a coloured line is a sub-heading (e.g. Fixes), not a bullet
            out[#out + 1] = line:find("^|c") and ("  " .. line) or ("  •  " .. line)
        end
        out[#out + 1] = " "
    end
    return table.concat(out, "\n")
end

local function Build()
    win = CreateFrame("Frame", "RubberDuckyChangelog", UIParent, "BackdropTemplate")
    win:SetSize(520, 380)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true); win:EnableMouse(true); win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    tinsert(UISpecialFrames, "RubberDuckyChangelog")

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|TInterface\\AddOns\\RubberDucky\\Media\\bobber_duck:18:18|t  What's new")
    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -44)
    scroll:SetPoint("BOTTOMRIGHT", -36, 18)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(460, 10)
    scroll:SetScrollChild(body)
    local text = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT")
    text:SetWidth(460)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    win.text, win.body = text, body
end

function Changelog:Show()
    if not win then Build() end
    win.text:SetText(Text())
    win.body:SetHeight((win.text:GetStringHeight() or 0) + 10)
    win:Show()
end
