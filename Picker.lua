-- Rubber Ducky: bobber icon picker (/ducky icons, or Choose Bobber).
--
-- Every bobber in a grid that scrolls past four rows: the ones you always have,
-- then Mrrl's (bought with Shiny Fishbones) and the ones you earn from Ducky's
-- Challenges, locked until they're yours. Underneath, on parchment, the one you've got and a line of its lore.

local _, ns = ...
local Picker = {}
ns.Picker = Picker

local COLS, CELL, GAP, ROWS = 8, 56, 8, 4
local HEAD = 30 -- the "Earned from challenges" line between the two sets

local win, cells, preview, previewName, lore, scroll

local function IconPath(i)
    return ns.BobberArt(ns.Bobber.MARKERS[i][1])
end

-- the challenge that earns a bobber
local function Challenge(id)
    for _, d in ipairs(ns.Challenges and ns.Challenges.DEFS or {}) do
        if d.id == id then return d end
    end
end

local function Refresh()
    if not win then return end
    local B = ns.Bobber
    local style = ns.db.markerStyle or 1
    -- the one you've got is parchment with a blue gem on its corner; ones still
    -- to find are dim, with a lock
    for i, cell in ipairs(cells) do
        local have = B.Unlocked(i)
        cell.art:SetArt(i == style and "tile_parch" or "tile_navy")
        cell.selected:SetShown(i == style)
        cell.icon:SetDesaturated(not have)
        cell.icon:SetAlpha(have and 1 or 0.45)
        cell.lock:SetShown(not have)
    end
    if style >= 1 and style <= #B.MARKERS then
        preview:SetTexture(IconPath(style))
        previewName:SetText(B.MARKERS[style][2])
        lore:SetText(B.LORE[B.MARKERS[style][1]] or "")
    else
        preview:SetTexture(ns.DUCK)
        previewName:SetText("A different one every cast")
        lore:SetText("Picked from the bobbers you've found, fresh each time you cast.")
    end
end

local function Choose(value)
    ns.db.markerStyle = value
    ns.db.markerEnabled = true -- picking a bobber means you want to see it
    if ns.Bobber.RefreshMarker then ns.Bobber:RefreshMarker() end
    if ns.Options and ns.Options.RefreshOverview then ns.Options.RefreshOverview() end
    Refresh()
end

local function Build()
    local UI = ns.UI
    local B = ns.Bobber
    local count = #B.MARKERS
    -- yours from the start; Mrrl's shelf, cheapest first; earned from challenges
    local free, shelf, earned = {}, {}, {}
    for i, m in ipairs(B.MARKERS) do
        if m.earn then earned[#earned + 1] = i
        elseif m.price then shelf[#shelf + 1] = i
        else free[#free + 1] = i end
    end
    table.sort(shelf, function(a, b)
        local pa, pb = B.MARKERS[a].price, B.MARKERS[b].price
        if pa ~= pb then return pa < pb end
        return a < b
    end)
    local gridW = COLS * CELL + (COLS - 1) * GAP
    local viewH = ROWS * CELL + (ROWS - 1) * GAP + 8
    local FOOT = 118

    -- our navy frame, smaller, with its title on a plaque on the top edge
    local fs = 0.55
    local side = 46 * fs + 10
    win = ns.SettingsWindow.Chrome("RubberDuckyIconPicker", nil, { title = "Choose your bobber", frame = fs,
        width = gridW + side * 2 + 42, -- room for the scroll bar height = viewH + FOOT + 44 * fs + 22 + 46 * fs + 30, scale = 1,
        strata = "FULLSCREEN_DIALOG" })
    local L, T = win.inner[1], win.inner[2]

    -- the grid scrolls once there's more than four rows
    scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", L + 6, -T)
    scroll:SetSize(gridW + 4, viewH)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(gridW + 4)
    scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local v = (self:GetVerticalScroll() or 0) - delta * (CELL + GAP)
        self:SetVerticalScroll(math.max(0, math.min(v, self:GetVerticalScrollRange() or 0)))
    end)
    UI.SlimScrollBar(scroll, win)
    Picker.scroll = scroll

    cells = {}
    Picker.cells = cells
    local function Cell(i, x, y)
        local b = CreateFrame("Button", nil, child)
        b:SetSize(CELL, CELL)
        b:SetPoint("TOPLEFT", x, -y)
        b.art = UI.Stretch(b, "tile_navy", "BACKGROUND", CELL / 154 * 0.9)

        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 9, -9); icon:SetPoint("BOTTOMRIGHT", -9, 9)
        icon:SetTexture(IconPath(i))
        b.icon = icon
        local lock = b:CreateTexture(nil, "OVERLAY")
        lock:SetSize(22, 22)
        lock:SetPoint("BOTTOMRIGHT", -3, 3)
        lock:SetAtlas("Forge-Lock") -- the game's little padlock
        if not lock:GetAtlas() then lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon") end
        b.lock = lock

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 6, -6); hl:SetPoint("BOTTOMRIGHT", -6, 6)
        hl:SetColorTexture(1, 1, 1, 0.15)

        local sel = b:CreateTexture(nil, "OVERLAY")
        UI.Gem(sel, "blue")
        sel:SetSize(18, 18)
        sel:SetPoint("CENTER", b, "TOPRIGHT", -4, -4)
        sel:Hide()
        b.selected = sel

        b:SetScript("OnClick", function()
            if not B.Unlocked(i) then
                -- one of Mrrl's: go and have a look at it
                if B.MARKERS[i].price and ns.Shop then win:Hide(); ns.Shop:Show("bobber", B.MARKERS[i][1]); return end
                UI.Sound("off"); return
            end
            UI.Sound("on"); Choose(i)
        end)
        b:SetScript("OnEnter", function(self)
            local m = B.MARKERS[i]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(m[2])
            if B.Unlocked(i) then
                local note, logo = m[3], m[4]
                if note and logo then note = note .. " |T" .. ns.MEDIA .. "Logos\\" .. logo .. ":14:14|t" end
                if note then GameTooltip:AddLine(note, 1, 0.82, 0.5) end
                if B.LORE[m[1]] then GameTooltip:AddLine(B.LORE[m[1]], 1, 1, 1, true) end
            elseif m.price then
                local F = ns.Flair
                GameTooltip:AddLine("On Mrrl's shelf for " .. (F and F.Bones(m.price) or m.price) .. ".", 1, 1, 1)
                GameTooltip:AddLine("Click to visit Mrrl's Doohicky Emporium.", 0.4, 0.8, 1)
            else
                -- what earns it; a hidden challenge stays a secret
                local d = Challenge(m.earn)
                if d and not d.hidden then
                    GameTooltip:AddLine("Earned from Ducky's Challenges:", 0.7, 0.7, 0.7)
                    GameTooltip:AddLine(d.name, 1, 0.82, 0)
                    GameTooltip:AddLine(d.goal, 1, 1, 1, true)
                else
                    GameTooltip:AddLine("Earned from a secret challenge. Keep fishing!", 0.7, 0.7, 0.7, true)
                end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cells[i] = b
    end
    local y = 2
    for n, i in ipairs(free) do
        Cell(i, ((n - 1) % COLS) * (CELL + GAP) + 2, y + math.floor((n - 1) / COLS) * (CELL + GAP))
    end
    y = y + math.ceil(#free / COLS) * (CELL + GAP)
    local function Section(title, list)
        if #list == 0 then return end
        local head = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        head:SetPoint("TOPLEFT", 4, -(y + 6))
        head:SetText(title)
        y = y + HEAD
        for n, i in ipairs(list) do
            Cell(i, ((n - 1) % COLS) * (CELL + GAP) + 2, y + math.floor((n - 1) / COLS) * (CELL + GAP))
        end
        y = y + math.ceil(#list / COLS) * (CELL + GAP)
    end
    Section("From Mrrl's Doohicky Emporium", shelf)
    Section("Earned from Ducky's Challenges", earned)
    child:SetHeight(y)

    -- underneath, on parchment: the one you've got, its lore, and Done
    local foot = CreateFrame("Frame", nil, win)
    foot:SetPoint("TOPLEFT", L, -(T + viewH + 12))
    foot:SetSize(gridW + 30, FOOT)
    UI.Stretch(foot, "tile_parch", "BACKGROUND", 0.75)
    local tile = UI.IconTile(foot, 78, nil, false)
    tile:SetPoint("LEFT", 18, 0)
    preview = tile.icon

    previewName = foot:CreateFontString(nil, "OVERLAY", UI.FONT.large)
    previewName:SetPoint("TOPLEFT", tile, "TOPRIGHT", 14, -8)
    previewName:SetPoint("RIGHT", foot, "RIGHT", -176, 0)
    previewName:SetJustifyH("LEFT"); previewName:SetWordWrap(false)
    lore = foot:CreateFontString(nil, "OVERLAY", UI.FONT.ink)
    lore:SetPoint("TOPLEFT", previewName, "BOTTOMLEFT", 0, -6)
    lore:SetPoint("RIGHT", foot, "RIGHT", -176, 0)
    lore:SetJustifyH("LEFT"); lore:SetJustifyV("TOP")
    lore:SetHeight(50)
    local done = UI.Button(foot, "Done", 140, function() win:Hide() end, { height = 44 })
    done:SetPoint("TOPRIGHT", -16, -14)
    -- more bobbers at Mrrl's
    local visit = UI.Button(foot, "Visit Mrrl", 140, function()
        win:Hide()
        if ns.Shop then ns.Shop:Show("bobber") end
    end, { height = 44 })
    visit:SetPoint("TOP", done, "BOTTOM", 0, -2)
    Picker.visit = visit

    win:SetScript("OnShow", Refresh)
    -- a controller: the D-pad picks, A chooses, B closes
    Picker.pad = ns.Pad.Attach(win, { roots = function() return { win } end,
        badges = function(nav) if win.close then nav:Badge(win.close, "PAD2", "TOPLEFT", 2, -2, 22) end end })
end

-- open with the bobber you've got in view
local function ScrollToCurrent()
    local style = ns.db.markerStyle or 1
    local cell = cells and cells[style]
    if cell and ns.Pad and ns.Pad.IntoView then ns.Pad.IntoView(cell) end
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
    if scroll then scroll:SetVerticalScroll(0) end
    if C_Timer then C_Timer.After(0, ScrollToCurrent) end
end

function Picker:Toggle()
    if win and win:IsShown() then win:Hide() else self:Show() end
end

function Picker:Refresh() Refresh() end
