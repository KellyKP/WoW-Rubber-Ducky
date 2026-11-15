-- Rubber Ducky: sound focus. While fishing, SFX up and music, ambience and
-- dialog down, with fades both ways. All effects share one SFX channel, so
-- your own splash can't be isolated from other players' sounds.

local _, ns = ...
local Sound = {}
ns.Sound = Sound

local SCALED  = { "Sound_MusicVolume", "Sound_AmbienceVolume", "Sound_DialogVolume" }
local VOLUMES = { "Sound_SFXVolume", "Sound_MusicVolume", "Sound_AmbienceVolume", "Sound_DialogVolume" }
local EXTRAS  = { "Sound_EnableEmoteSounds", "Sound_EnablePetSounds", "Sound_EnableErrorSpeech" }

local function Get(cvar) return ns.Safe(GetCVar, cvar) end

-- our recent writes, so another addon changing the same volumes can be spotted
local recent = {}
local WATCHED = { Sound_SFXVolume = true, Sound_MusicVolume = true, Sound_AmbienceVolume = true, Sound_DialogVolume = true }

local function Set(cvar, value)
    if WATCHED[cvar] then
        local list = recent[cvar] or {}
        list[#list + 1] = tonumber(value)
        if #list > 12 then table.remove(list, 1) end
        recent[cvar] = list
    end
    return ns.Safe(SetCVar, cvar, value)
end

local warned = false
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("CVAR_UPDATE")
watcher:SetScript("OnEvent", function(_, _, cvar, value)
    if not WATCHED[cvar] or not (ns.db and ns.db.savedSound) then return end
    local v = tonumber(value)
    if not v then return end
    for _, mine in ipairs(recent[cvar] or {}) do
        if mine and math.abs(mine - v) < 0.002 then return end
    end
    if ns.Probe then ns.Probe:Mark(("another addon set %s to %s"):format(cvar, tostring(value))) end
    if not warned then
        warned = true
        ns.Print("another addon changed |cffffd100%s|r to %s while Rubber Ducky's sound focus was on. Two addons adjusting the same volumes will fight (jumps in volume, settings not coming back right). Turn off the sound option in one of them, or Rubber Ducky's with /ducky focus.", cvar, tostring(value))
    end
end)

-------------------------------------------------------------------------------
-- Fader
-------------------------------------------------------------------------------

local fader = CreateFrame("Frame")
fader:Hide()
local fade -- { from, to, start, duration, onDone }
local STEP = 1 / 30
local acc = 0

local function Smooth(t) return t * t * (3 - 2 * t) end

local function FinishFade()
    local f = fade
    fade = nil
    fader:Hide()
    if not f then return end
    for cvar, v in pairs(f.to) do Set(cvar, string.format("%.3f", v)) end
    if f.onDone then f.onDone() end
end

fader:SetScript("OnUpdate", function(_, elapsed)
    if not fade then fader:Hide() return end
    acc = acc + elapsed
    if acc < STEP then return end
    acc = 0
    local t = (GetTime() - fade.start) / fade.duration
    if t >= 1 then FinishFade() return end
    local k = Smooth(t)
    for cvar, to in pairs(fade.to) do
        local from = fade.from[cvar] or to
        Set(cvar, string.format("%.3f", from + (to - from) * k))
    end
end)

-- A new fade starts from wherever the current one is.
local function FadeTo(targets, duration, onDone)
    if fade then
        local old = fade
        fade = nil
        -- an interrupted fade's onDone is dropped on purpose
        old.onDone = nil
    end
    local from = {}
    for cvar in pairs(targets) do from[cvar] = tonumber(Get(cvar)) end
    if not duration or duration <= 0 then
        fade = { from = from, to = targets, start = GetTime(), duration = 1, onDone = onDone }
        FinishFade()
        return
    end
    fade = { from = from, to = targets, start = GetTime(), duration = duration, onDone = onDone }
    acc = STEP
    fader:Show()
end

-------------------------------------------------------------------------------
-- Saved settings
-------------------------------------------------------------------------------
-- lastSet = our fishing value, baseline = your real value. A cvar still at our
-- fishing value (a lost restore) uses the baseline, so the mumble never stacks.

local function Remember(saved, cvar)
    if saved[cvar] ~= nil then return end
    local db = ns.db
    db.lastSet = db.lastSet or {}
    db.baseline = db.baseline or {}
    local v = Get(cvar)
    if v == nil then return end
    local last = db.lastSet[cvar]
    if last ~= nil and db.baseline[cvar] ~= nil and math.abs((tonumber(v) or -1) - (tonumber(last) or -2)) < 0.002 then
        v = db.baseline[cvar]
    else
        db.baseline[cvar] = v
    end
    saved[cvar] = v
end

-------------------------------------------------------------------------------

function Sound:Apply()
    local db = ns.db
    if not db.focusEnabled then return end

    -- already holding your originals (recast mid fade-out): keep them
    local saved = db.savedSound
    if not saved then
        saved = {}
        Remember(saved, "Sound_SFXVolume")
        Remember(saved, "Sound_EnableSFX")
        for _, cvar in ipairs(SCALED) do Remember(saved, cvar) end
        if db.quietExtras then for _, cvar in ipairs(EXTRAS) do Remember(saved, cvar) end end
        if db.soundInBG then Remember(saved, "Sound_EnableSoundWhenGameIsInBG") end
        db.savedSound = saved -- for crash recovery
    end

    local targets = { Sound_SFXVolume = db.sfxLevel }
    for _, cvar in ipairs(SCALED) do
        local orig = tonumber(saved[cvar])
        if orig then targets[cvar] = orig * db.mumbleLevel end
    end
    db.lastSet = {}
    for cvar, v in pairs(targets) do db.lastSet[cvar] = string.format("%.3f", v) end

    Set("Sound_EnableSFX", "1")
    if db.quietExtras then for _, cvar in ipairs(EXTRAS) do if saved[cvar] then Set(cvar, "0") end end end
    if db.soundInBG and saved.Sound_EnableSoundWhenGameIsInBG then Set("Sound_EnableSoundWhenGameIsInBG", "1") end

    FadeTo(targets, db.fadeIn or 1)
end

-- duration: nil = fade-out setting, 0 = instant
function Sound:Restore(duration)
    local saved = ns.db and ns.db.savedSound
    if not saved then return end
    if duration == nil then duration = ns.db.fadeOut or 2.5 end

    local targets = {}
    for _, cvar in ipairs(VOLUMES) do
        if saved[cvar] ~= nil then targets[cvar] = tonumber(saved[cvar]) end
    end

    FadeTo(targets, duration, function()
        -- exact saved values, not the rounded fade value
        for cvar, value in pairs(saved) do Set(cvar, value) end
        ns.db.savedSound = nil
        ns.db.lastSet = {}
        for cvar, value in pairs(saved) do
            local now = Get(cvar)
            if now ~= value and tonumber(now) ~= tonumber(value) then
                if ns.Probe then ns.Probe:Mark(("restore of %s didn't stick: wanted %s, got %s"):format(cvar, value, tostring(now))) end
            end
        end
    end)
end

function Sound:RecoverFromCrash()
    if ns.db.savedSound then
        self:Restore(0)
        ns.Print("restored your sound settings from an interrupted fishing session.")
    end
end
