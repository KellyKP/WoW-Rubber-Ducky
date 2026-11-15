-- Rubber Ducky: fishing camera. Zoom and ActionCam tilt while fishing, restored
-- after. Approach from Improved Forever (MIT). ActionCam's interact focus
-- doesn't count the soft-targeted bobber in Forever, so it isn't used.

local _, ns = ...
local Cam = {}
ns.Camera = Cam

local CENTERED = "CameraKeepCharacterCentered" -- gamepad mode sets it; it cancels ActionCam
local CVARS = {
    "test_cameraDynamicPitch", "test_cameraDynamicPitchBaseFovPad", "test_cameraOverShoulder",
}

local function GetC(name)
    local get = C_CVar and C_CVar.GetCVar or GetCVar
    local ok, v = pcall(get, name)
    return ok and v or nil
end

local function SetC(name, value)
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    if set and value ~= nil then pcall(set, name, tostring(value)) end
end

local function Zoom()
    local ok, z = pcall(GetCameraZoom)
    return ok and type(z) == "number" and z or nil
end

local function ZoomTo(target)
    local now = Zoom()
    if not (now and target) then return end
    if now > target + 0.1 then pcall(CameraZoomIn, now - target)
    elseif now < target - 0.1 then pcall(CameraZoomOut, target - now) end
end

function Cam:Apply()
    local db = ns.db
    if not db.cameraEnabled then return end

    if not db.savedCamera then
        local saved = { zoom = Zoom(), cvars = {} }
        for _, name in ipairs(CVARS) do saved.cvars[name] = GetC(name) end
        saved.centered = GetC(CENTERED)
        db.savedCamera = saved -- for crash recovery
    end

    if C_CVar and C_CVar.SetTempCVar then pcall(C_CVar.SetTempCVar, CENTERED, "0") end

    SetC("test_cameraDynamicPitch", 1)
    SetC("test_cameraDynamicPitchBaseFovPad", db.cameraTilt or 0.15)
    SetC("test_cameraOverShoulder", db.cameraShoulder or 0)

    ZoomTo(db.cameraZoom or 4)
end

function Cam:Reapply()
    if ns.sessionActive and ns.db.savedCamera then self:Apply() end
end

function Cam:Restore(zoomBack)
    local saved = ns.db and ns.db.savedCamera
    if not saved then return end
    for name, value in pairs(saved.cvars or {}) do SetC(name, value) end
    if saved.centered ~= nil and C_CVar and C_CVar.SetTempCVar then
        local ok, pad = pcall(C_CVar.GetCVarBool or GetCVarBool, "GamePadEnable")
        if ok and pad then
            pcall(C_CVar.SetTempCVar, CENTERED, saved.centered)
        elseif C_CVar.RemoveTempCVar then
            pcall(C_CVar.RemoveTempCVar, CENTERED)
        end
    end
    if zoomBack ~= false then ZoomTo(saved.zoom) end
    ns.db.savedCamera = nil
end

function Cam:RecoverFromCrash()
    if ns.db.savedCamera then
        self:Restore(true)
        ns.Print("put your camera back from an interrupted fishing session.")
    end
end
