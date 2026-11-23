--[[
    Novex Hub - Kazakh Tower Script
    Roblox | Delta (mobile) | WindUI
    One file. Sections, in order:
      setup, services, theme, config, state, helpers, loader, WindUI load,
      persistence, movement, teleport runs, emotes, tools, players, game,
      floating windows, main window, unload.
    RightShift toggles the main window.
]]

local env = (getgenv and getgenv()) or _G
if env.KT_HUB_UNLOAD then pcall(env.KT_HUB_UNLOAD) end

local WindUI -- assigned once the library has loaded

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- ================= THEME =================
local HUB_TITLE = "Novex Hub - Kazakh Tower Script 🇰🇿"
local PURPLE = Color3.fromRGB(168, 85, 255)
local CYAN = Color3.fromRGB(0, 240, 255)
local BLACK = Color3.new(0, 0, 0)
local PANEL = Color3.fromRGB(8, 8, 11)
local BTN = Color3.fromRGB(18, 18, 24)
local BTN_ON = Color3.fromRGB(38, 18, 62)
local TEXT = Color3.fromRGB(235, 235, 245)
local MUTED = Color3.fromRGB(140, 140, 160)
local RED = Color3.fromRGB(255, 70, 110)
local NEON_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0, PURPLE),
    ColorSequenceKeypoint.new(0.5, CYAN),
    ColorSequenceKeypoint.new(1, PURPLE),
})
local EMOTE_ACCENT = {PURPLE, CYAN, PURPLE, CYAN}

-- ================= CONFIG: YOUR SPOTS =================
local SLAPS = {
    Vector3.new(26.42, 5.62, -86.31),
    Vector3.new(-140.18, 197.02, -72.45),
    Vector3.new(47.42, 27.81, -258.40),
    Vector3.new(396.83, 701.57, 50.94),
}
local CARPET = Vector3.new(413.35, 701.57, 50.62)
local AFK_COINS = Vector3.new(382.71, 702.53, 27.65)

-- ================= CONFIG: EMOTES =================
local R6_CATEGORIES = {
    {"Dances & Movement", {
        {"Moving Dance", 429703734}, {"Spin Dance", 429730430}, {"Spin Dance 2", 186934910},
        {"Spinner", 188632011}, {"Moon Dance", 45834924}, {"Moon Dance 2", 27789359},
        {"Moonwalk", 30196114}, {"Twirl", 144465399}, {"Jumping Jacks", 429681631},
        {"Barrel Roll", 136801964}, {"Backflip", 144427269}, {"Front Flip", 147842537},
        {"Hero Jump", 184574340},
    }},
    {"Glitch, Cursed & Limb Effects", {
        {"Glitch Levitate", 313762630}, {"Clone Illusion", 215384594}, {"Floating Head", 121572214},
        {"Head Throw", 35154961}, {"Head Juggle", 147527133}, {"Arm Detach", 33169583},
        {"Insane", 33796059}, {"Mega Insane", 184574340}, {"Insane Arms", 27432691},
        {"Arm Turbine", 259438880},
    }},
    {"Poses, Sitting & Floor", {
        {"Float Sit", 179224234}, {"Meditation", 144462739}, {"Chill", 144431365},
        {"Ninja Rest", 144514206}, {"Crouch", 182724289}, {"Floor Crawl", 282574440},
        {"Snake", 148175580}, {"Dino Walk", 204328711}, {"Faint", 181526230},
        {"Floor Faint", 181525546}, {"Scared", 180612465}, {"Bow Down", 204292303},
        {"Dab", 183412246}, {"Handstand", 144466905}, {"Splits", 144429224}, {"Pushups", 144396364},
    }},
    {"Combat, Action & Misc", {
        {"Full Punch", 204062532}, {"Punch", 28159255}, {"Uppercut", 28160593},
        {"Kick Box", 33686061}, {"Full Swing", 218504594}, {"Sword Slam", 204295235},
        {"Sword Slice", 35978879}, {"Chop", 33169596}, {"Fly", 90825039}, {"Fly 2", 90828653},
        {"Beatbox", 45504977}, {"Horn Blow", 32729592}, {"Drink", 29517689},
    }},
}
local CHIPS = {{"All", 0}, {"Dance", 1}, {"Glitch", 2}, {"Pose", 3}, {"Fight", 4}}

-- ================= STATE =================
local alive = true
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local S = {
    busy = false, abort = false, stay = 0.7, grabRadius = 25,
    speed = nil, jump = nil, noclip = false, infJump = false,
    god = false, climb = false, antiAfk = true,
    flyWanted = false, respawnCF = nil,
    antiVoid = false, voidY = -100, safeCF = nil,
    autoSlaps = false, autoGap = 20,
    esp = false, espNames = false,
}
local afk = {on = false, home = nil, extreme = true, returnOnOff = true, grabbing = true}
local selected = nil
local keepTools = {}
local custom = {}
local ui = {}
local Window
local boxGui, boxName, boxImg, boxInput
local emoteGui, posGui, flyGui
local neonGrads = {}
local hubOpen = true

-- ================= HELPERS: BASICS =================
local function guiParent(g)
    local ok = pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
end
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end
local function isPress(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end
local function root()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function tp(pos)
    local r = root()
    if not r then return false end
    r.CFrame = CFrame.new(pos)
    r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    return true
end
local function notify(title, content)
    pcall(function() WindUI:Notify({Title = title, Content = content, Duration = 3}) end)
end
local function safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            warn("[Novex Hub] " .. tostring(err))
            notify("Error", tostring(err):sub(1, 90))
        end
    end
end
local function syncUI(name, state)
    local t = ui[name]
    if t then pcall(function() t:Set(state) end) end
end

-- ================= HELPERS: NEON STYLE =================
-- Every neon gradient is registered here; one loop rotates them all.
local function neon(obj, thickness, transparency)
    local s = mk("UIStroke", {
        Color = PURPLE, Thickness = thickness or 1.5, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
    local g = mk("UIGradient", {Color = NEON_SEQ}, s)
    neonGrads[#neonGrads + 1] = g
    return s
end

local spinAngle = 0
bind(RunService.RenderStepped, function(dt)
    spinAngle = (spinAngle + dt * 90) % 360
    local live = {}
    for _, g in ipairs(neonGrads) do
        if g.Parent then
            g.Rotation = spinAngle
            live[#live + 1] = g
        end
    end
    neonGrads = live
end)

-- Small black button with a thin accent outline.
local function chip(b, accent)
    b.BackgroundColor3 = BTN
    b.BorderSizePixel = 0
    b.TextColor3 = TEXT
    b.Font = Enum.Font.GothamMedium
    corner(b, 8)
    mk("UIStroke", {
        Color = accent or PURPLE, Thickness = 1, Transparency = 0.35,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, b)
    return b
end
local function setOn(b, on)
    b.BackgroundColor3 = on and BTN_ON or BTN
    b.TextColor3 = on and CYAN or TEXT
end

local function makeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Black floating window with a neon purple/cyan outline and a gradient title bar.
local function windowFrame(parent, size, pos, title)
    local frame = mk("Frame", {Size = size, Position = pos, BackgroundColor3 = PANEL, BorderSizePixel = 0}, parent)
    corner(frame, 12)
    neon(frame, 1.5)
    local bar = mk("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = BLACK, BorderSizePixel = 0}, frame)
    corner(bar, 12)
    local label = mk("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
        Text = title, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bar)
    mk("UIGradient", {Color = NEON_SEQ}, label)
    local x = mk("TextButton", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1,
        Text = "✕", TextColor3 = RED, Font = Enum.Font.GothamBold, TextSize = 13,
    }, bar)
    x.MouseButton1Click:Connect(function() parent.Enabled = false end)
    makeDraggable(bar, frame)
    return frame, bar
end

-- ================= HELPERS: TOOLS =================
local function giveTool(name, onTap)
    local bp = lp:FindFirstChildOfClass("Backpack")
    if not bp then return end
    local old = bp:FindFirstChild(name) or (lp.Character and lp.Character:FindFirstChild(name))
    if old then old:Destroy() end
    local t = Instance.new("Tool")
    t.Name = name
    t.ToolTip = name
    t.RequiresHandle = false
    t.CanBeDropped = false
    t.Activated:Connect(function() pcall(onTap, mouse) end)
    t.Parent = bp
    keepTools[name] = onTap
end
local function removeKeptTools()
    for name in pairs(keepTools) do
        local bp = lp:FindFirstChildOfClass("Backpack")
        local t = (bp and bp:FindFirstChild(name)) or (lp.Character and lp.Character:FindFirstChild(name))
        if t then t:Destroy() end
    end
    keepTools = {}
end

-- ================= LOADER =================
local function buildLoader()
    local g = Instance.new("ScreenGui")
    g.Name = "NovexLoader"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = 10000
    guiParent(g)

    local bg = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0}, g)
    local card = mk("Frame", {
        Size = UDim2.fromOffset(340, 170), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(6, 6, 10), BorderSizePixel = 0,
    }, bg)
    corner(card, 16)
    neon(card, 2)
    local title = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 42), Position = UDim2.fromOffset(10, 22), BackgroundTransparency = 1,
        Text = "Novex Hub", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 34,
    }, card)
    mk("UIGradient", {Color = NEON_SEQ}, title)
    local sub = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 66), BackgroundTransparency = 1,
        Text = "Kazakh Tower Script 🇰🇿", TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 15,
    }, card)
    local track = mk("Frame", {
        Size = UDim2.new(1, -40, 0, 6), Position = UDim2.fromOffset(20, 108),
        BackgroundColor3 = Color3.fromRGB(24, 24, 32), BorderSizePixel = 0,
    }, card)
    corner(track, 3)
    local fill = mk("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
    corner(fill, 3)
    mk("UIGradient", {Color = NEON_SEQ}, fill)
    local status = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 124), BackgroundTransparency = 1,
        Text = "Starting...", TextColor3 = MUTED, Font = Enum.Font.Gotham, TextSize = 12,
    }, card)
    return {gui = g, bg = bg, card = card, title = title, sub = sub, track = track, fill = fill, status = status}
end

local loader = buildLoader()
local function loaderStep(text, pct)
    if not loader.gui.Parent then return end
    loader.status.Text = text
    TweenService:Create(loader.fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(pct, 1)}):Play()
end
local function loaderFinish()
    loaderStep("Ready", 1)
    task.wait(0.4)
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad)
    local stroke = loader.card:FindFirstChildOfClass("UIStroke")
    TweenService:Create(loader.bg, info, {BackgroundTransparency = 1}):Play()
    TweenService:Create(loader.card, info, {BackgroundTransparency = 1}):Play()
    if stroke then TweenService:Create(stroke, info, {Transparency = 1}):Play() end
    TweenService:Create(loader.title, info, {TextTransparency = 1}):Play()
    TweenService:Create(loader.sub, info, {TextTransparency = 1}):Play()
    TweenService:Create(loader.status, info, {TextTransparency = 1}):Play()
    TweenService:Create(loader.track, info, {BackgroundTransparency = 1}):Play()
    TweenService:Create(loader.fill, info, {BackgroundTransparency = 1}):Play()
    task.delay(0.6, function() pcall(function() loader.gui:Destroy() end) end)
end
local function loaderFail(text)
    loader.status.Text = text
    loader.status.TextColor3 = RED
    task.delay(2.5, function() pcall(function() loader.gui:Destroy() end) end)
end

-- ================= WINDUI LOAD =================
loaderStep("Fetching WindUI", 0.2)
local okUI, lib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not okUI or type(lib) ~= "table" then
    warn("[Novex Hub] WindUI failed to load: " .. tostring(lib))
    loaderFail("WindUI failed to load")
    return
end
WindUI = lib
loaderStep("Preparing systems", 0.5)

-- ================= PERSISTENCE: SAVED SPOTS =================
local SAVE_DIR, SAVE_FILE = "KazakhHub", "KazakhHub/spots.json"
local function saveSpots()
    if not (writefile and makefolder) then return end
    pcall(function()
        if isfolder and not isfolder(SAVE_DIR) then makefolder(SAVE_DIR) end
        writefile(SAVE_FILE, HttpService:JSONEncode(custom))
    end)
end
local function loadSpots()
    if not (readfile and isfile) then return end
    pcall(function()
        if isfile(SAVE_FILE) then
            local d = HttpService:JSONDecode(readfile(SAVE_FILE))
            if type(d) == "table" then custom = d end
        end
    end)
end
loadSpots()

-- ================= GRAB =================
local function grab(radius)
    local r = root()
    if not r then return end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character}
    params.MaxParts = 250
    for _, part in ipairs(workspace:GetPartBoundsInRadius(r.Position, radius, params)) do
        if firetouchinterest and part:FindFirstChildWhichIsA("TouchTransmitter") then
            firetouchinterest(r, part, 0)
            firetouchinterest(r, part, 1)
        end
        if fireproximityprompt then
            local pp = part:FindFirstChildWhichIsA("ProximityPrompt")
            if pp then
                pp.HoldDuration = 0
                pcall(fireproximityprompt, pp)
            end
        end
        if fireclickdetector then
            local cd = part:FindFirstChildWhichIsA("ClickDetector")
            if cd then pcall(fireclickdetector, cd) end
        end
    end
end

-- ================= MOVEMENT: FLY =================
local function newFlyer(getBase, platformStand)
    local f = {on = false, speed = 60, up = false, down = false}
    local bv, bg, conn
    function f.stop()
        f.on = false
        if conn then conn:Disconnect(); conn = nil end
        if bv then bv:Destroy(); bv = nil end
        if bg then bg:Destroy(); bg = nil end
        if platformStand then
            local h = humanoid()
            if h then h.PlatformStand = false end
        end
    end
    function f.start()
        f.stop()
        local base = getBase()
        if not base then return false end
        f.on = true
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = base
        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P = 9e4
        bg.CFrame = base.CFrame
        bg.Parent = base
        if platformStand then
            local h = humanoid()
            if h then h.PlatformStand = true end
        end
        local cur = Vector3.new(0, 0, 0)
        conn = RunService.RenderStepped:Connect(function()
            local hh, b = humanoid(), getBase()
            if not hh or not b or not bv or hh.Health <= 0 or b ~= bv.Parent then
                f.stop()
                return
            end
            local cam = workspace.CurrentCamera
            local m = cam.CFrame:VectorToObjectSpace(hh.MoveDirection)
            local dir = cam.CFrame.LookVector * -m.Z + cam.CFrame.RightVector * m.X
            if f.up then dir = dir + Vector3.new(0, 1, 0) end
            if f.down then dir = dir - Vector3.new(0, 1, 0) end
            cur = cur:Lerp(dir * f.speed, 0.2)
            bv.Velocity = cur
            bg.CFrame = cam.CFrame
        end)
        return true
    end
    return f
end

local flyer = newFlyer(function() return root() end, true)
local carFlyer = newFlyer(function()
    local h = humanoid()
    local seat = h and h.SeatPart
    return seat and (seat.AssemblyRootPart or seat)
end, false)

flyGui = Instance.new("ScreenGui")
flyGui.Name = "NovexFlyPad"
flyGui.ResetOnSpawn = false
flyGui.Enabled = false
guiParent(flyGui)

local function setVert(key, v)
    flyer[key] = v
    carFlyer[key] = v
end
local function padButton(text, yOffset, key)
    local b = mk("TextButton", {
        Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -76, 0.5, yOffset),
        BackgroundColor3 = BTN, BackgroundTransparency = 0.1,
        Text = text, TextSize = 24, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
    }, flyGui)
    corner(b, 28)
    neon(b, 1.5)
    b.InputBegan:Connect(function(i) if isPress(i) then setVert(key, true) end end)
    b.InputEnded:Connect(function(i) if isPress(i) then setVert(key, false) end end)
end
padButton("▲", -66, "up")
padButton("▼", 10, "down")
bind(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.E then setVert("up", true)
    elseif i.KeyCode == Enum.KeyCode.Q then setVert("down", true) end
end)
bind(UIS.InputEnded, function(i)
    if i.KeyCode == Enum.KeyCode.E then setVert("up", false)
    elseif i.KeyCode == Enum.KeyCode.Q then setVert("down", false) end
end)

-- ================= MOVEMENT: TOGGLE SETTERS =================
local function setFly(state)
    if S.flyWanted == state then return end
    S.flyWanted = state
    flyGui.Enabled = state or carFlyer.on
    if state then flyer.start() else flyer.stop() end
    syncUI("fly", state)
end
local function setNoclip(state)
    if S.noclip == state then return end
    S.noclip = state
    syncUI("noclip", state)
end
local function setInfJump(state)
    if S.infJump == state then return end
    S.infJump = state
    syncUI("infjump", state)
end
local function setAfk(state)
    if afk.on == state then return end
    if state then
        local r = root()
        if not r then return end
        afk.home = r.CFrame
        afk.on = true
    else
        afk.on = false
        local r = root()
        if r and afk.home and afk.returnOnOff then
            r.CFrame = afk.home
            r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
    syncUI("coins", state)
end

-- ================= MOVEMENT: SKY WALK =================
local air = {on = false, part = nil, y = 0}
local function setAir(s)
    air.on = s
    if air.part then air.part:Destroy(); air.part = nil end
    if s then
        local r = root()
        if not r then air.on = false return end
        air.y = r.Position.Y - 3.5
        air.part = mk("Part", {
            Size = Vector3.new(10, 1, 10), Anchored = true, Transparency = 0.8,
            Material = Enum.Material.Neon, Color = CYAN,
        }, workspace)
    end
end

-- ================= MOVEMENT: MAIN LOOPS =================
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
local lastGrab, lastSafe = 0, 0

bind(RunService.Heartbeat, function()
    local h, r = humanoid(), root()
    if not h or not r then return end

    if S.speed then h.WalkSpeed = S.speed end
    if S.jump then h.UseJumpPower = true; h.JumpPower = S.jump end
    if S.god then
        pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
        if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end
    if air.on and air.part then
        air.part.CFrame = CFrame.new(r.Position.X, air.y, r.Position.Z)
    end
    if S.climb and h.MoveDirection.Magnitude > 0 then
        wallParams.FilterDescendantsInstances = {lp.Character}
        if workspace:Raycast(r.Position, h.MoveDirection * 3, wallParams) then
            local v = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(v.X, 45, v.Z)
        end
    end

    if afk.on then
        if afk.extreme or (r.Position - AFK_COINS).Magnitude > 3 then
            r.CFrame = CFrame.new(AFK_COINS)
            r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if afk.grabbing and os.clock() - lastGrab > 0.15 then
            lastGrab = os.clock()
            pcall(grab, 20)
        end
    end

    if S.antiVoid then
        if os.clock() - lastSafe > 0.5 and h.FloorMaterial ~= Enum.Material.Air and r.Position.Y > S.voidY + 10 then
            lastSafe = os.clock()
            S.safeCF = r.CFrame
        end
        if r.Position.Y < S.voidY and S.safeCF then
            r.CFrame = S.safeCF
            r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

bind(RunService.Stepped, function()
    if S.noclip and lp.Character then
        for _, p in ipairs(lp.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)
bind(UIS.JumpRequest, function()
    local h = humanoid()
    if S.infJump and h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
bind(lp.Idled, function()
    if S.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ================= TELEPORT RUNS =================
local function visit(list, returnHome)
    if S.busy then notify("Teleport", "a run is already going, tap Stop run first") return end
    local r = root()
    if not r then return end
    S.busy, S.abort = true, false
    local home = r.CFrame
    for _, pos in ipairs(list) do
        if S.abort or not alive then break end
        tp(pos)
        task.wait(S.stay)
        pcall(grab, S.grabRadius)
        task.wait(0.15)
    end
    if returnHome then
        local r2 = root()
        if r2 then
            r2.CFrame = home
            r2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
    S.busy = false
end

local function getCarpet()
    tp(CARPET)
    task.wait(0.3)
    pcall(grab, S.grabRadius)
    notify("Carpet", "teleported, staying there")
end

local function customList()
    local out = {}
    for _, e in ipairs(custom) do out[#out + 1] = Vector3.new(e.x, e.y, e.z) end
    return out
end

task.spawn(function()
    while alive do
        task.wait(1)
        if S.autoSlaps and not S.busy and not afk.on then
            visit(SLAPS, true)
            local waited = 0
            while alive and S.autoSlaps and waited < S.autoGap do
                task.wait(1)
                waited = waited + 1
            end
        end
    end
end)

-- ================= EMOTES: CORE =================
local track, copied, emoteSpeed, loopEmotes, typedId = nil, {}, 1, true, ""

local function stopEmote()
    if track then pcall(function() track:Stop(); track:Destroy() end); track = nil end
    for _, t in ipairs(copied) do pcall(function() t:Stop() end) end
    copied = {}
end

local function loadTrack(id)
    local h = humanoid()
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = h
    end
    local a = Instance.new("Animation")
    local s = tostring(id)
    a.AnimationId = s:find("://") and s or ("rbxassetid://" .. s)
    local ok, t = pcall(function() return animator:LoadAnimation(a) end)
    if ok then return t end
end

local function playEmote(id, name)
    stopEmote()
    local t = loadTrack(id)
    if not t then notify("Emote", "couldn't load " .. tostring(name or id)) return end
    track = t
    t.Priority = Enum.AnimationPriority.Action4
    t.Looped = loopEmotes
    t:Play()
    t:AdjustSpeed(emoteSpeed)
    task.delay(0.6, function()
        if track == t and t.Length == 0 then
            notify("Emote", tostring(name or id) .. " didn't load (dead ID or blocked)")
        end
    end)
end

local function randomEmote()
    local all = {}
    for _, cat in ipairs(R6_CATEGORIES) do
        for _, e in ipairs(cat[2]) do all[#all + 1] = e end
    end
    local e = all[math.random(1, #all)]
    playEmote(e[2], e[1])
end

-- ================= TOOLS: HAND TOOLS =================
local function aim(m)
    local t, pos = m.Target, m.Hit and m.Hit.Position
    if not t then
        local cam = workspace.CurrentCamera
        local loc = UIS:GetMouseLocation()
        local ray = cam:ViewportPointToRay(loc.X, loc.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {lp.Character}
        local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if res then t, pos = res.Instance, res.Position end
    end
    return t, pos
end

local function clickTeleport(m)
    local _, pos = aim(m)
    local r = root()
    if r and pos then
        r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

local function deleteTap(m)
    local t, _ = aim(m)
    if not t then return end
    if lp.Character and t:IsDescendantOf(lp.Character) then return end
    if Players:GetPlayerFromCharacter(t:FindFirstAncestorOfClass("Model")) then return end
    t:Destroy()
end

-- ================= PLAYERS =================
local function others()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then t[#t + 1] = p end
    end
    table.sort(t, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return t
end

local function setSelected(plr, fromTyping)
    selected = plr
    if boxName then
        boxName.Text = plr and (plr.DisplayName .. "\n@" .. plr.Name) or "nobody selected"
    end
    if boxInput and not fromTyping then boxInput.Text = plr and plr.Name or "" end
    if boxImg then
        if plr then
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and selected == plr and boxImg then boxImg.Image = img end
            end)
        else
            boxImg.Image = ""
        end
    end
end

local function findPlayer(q)
    q = (q or ""):lower()
    if q == "" then return end
    local prefix, contains
    for _, p in ipairs(others()) do
        local n, d = p.Name:lower(), p.DisplayName:lower()
        if n == q or d == q then return p end
        if not prefix and (n:sub(1, #q) == q or d:sub(1, #q) == q) then prefix = p end
        if not contains and (n:find(q, 1, true) or d:find(q, 1, true)) then contains = p end
    end
    return prefix or contains
end

local function cyclePlayer(dir)
    local list = others()
    if #list == 0 then notify("Players", "nobody else is here") return end
    local idx = 0
    for i, p in ipairs(list) do
        if p == selected then idx = i break end
    end
    if idx == 0 then
        idx = dir > 0 and 1 or #list
    else
        idx = ((idx - 1 + dir) % #list) + 1
    end
    setSelected(list[idx])
end

local function playerAt(t, pos)
    local cur = t
    while cur and cur ~= workspace do
        if cur:IsA("Model") then
            local p = Players:GetPlayerFromCharacter(cur)
            if p and p ~= lp then return p end
        end
        cur = cur.Parent
    end
    if pos then
        local best, bd = nil, 10
        for _, p in ipairs(others()) do
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - pos).Magnitude
                if d < bd then best, bd = p, d end
            end
        end
        return best
    end
end

local function pickFromMouse(m)
    local t, pos = aim(m)
    local p = playerAt(t, pos)
    if p then
        setSelected(p)
        notify("Selected", p.DisplayName .. " (@" .. p.Name .. ")")
    else
        notify("Select", "tap on or right next to a player")
    end
end

bind(Players.PlayerRemoving, function(p)
    if selected == p then setSelected(nil) end
end)

local function targetRoot()
    if not selected then notify("Player", "select someone first") return end
    local c = selected.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then notify("Player", selected.Name .. " has no character right now") end
    return r
end

local spectating = false
local function setSpectate(state)
    spectating = state
    local cam = workspace.CurrentCamera
    if state then
        if not selected then notify("Spectate", "select someone first") spectating = false return end
        task.spawn(function()
            while spectating and alive and selected do
                local h = selected.Character and selected.Character:FindFirstChildOfClass("Humanoid")
                if h then cam.CameraSubject = h end
                task.wait(0.3)
            end
        end)
    else
        local h = humanoid()
        if h then cam.CameraSubject = h end
    end
end

local function gotoPlayer()
    local tr, r = targetRoot(), root()
    if tr and r then
        r.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

local function gotoEveryone()
    if S.busy then notify("Teleport", "a run is already going") return end
    local r = root()
    if not r then return end
    S.busy, S.abort = true, false
    local home = r.CFrame
    for _, p in ipairs(others()) do
        if S.abort or not alive then break end
        local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        local rr = root()
        if not rr then break end
        if tr then
            rr.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
            task.wait(1)
        end
    end
    local r2 = root()
    if r2 then
        r2.CFrame = home
        r2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    S.busy = false
end

local attachConn
local function stopAttach()
    if attachConn then attachConn:Disconnect(); attachConn = nil end
    local h = humanoid()
    if h then h.Sit = false end
end
local function startAttach(mode)
    stopAttach()
    if not selected then notify("Player", "select someone first") return end
    local offsets = {
        head = CFrame.new(0, 2.6, 0),
        back = CFrame.new(0, 0, 1.6),
        hug = CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0),
    }
    local h = humanoid()
    if mode == "head" and h then h.Sit = true end
    attachConn = RunService.Heartbeat:Connect(function()
        local r = root()
        local tr = selected and selected.Character and selected.Character:FindFirstChild("HumanoidRootPart")
        if not r or not tr then stopAttach() return end
        r.CFrame = tr.CFrame * offsets[mode]
        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
end

local function copyAnimation()
    if not selected then notify("Copy animation", "select someone first") return end
    local th = selected.Character and selected.Character:FindFirstChildOfClass("Humanoid")
    local ta = th and th:FindFirstChildOfClass("Animator")
    if not ta then notify("Copy animation", "nothing to copy") return end
    stopEmote()
    local n = 0
    for _, t in ipairs(ta:GetPlayingAnimationTracks()) do
        local id = t.Animation and t.Animation.AnimationId
        if id and id ~= "" and t.Priority ~= Enum.AnimationPriority.Core
            and t.Priority.Value >= Enum.AnimationPriority.Action.Value then
            local mine = loadTrack(id)
            if mine then
                mine.Priority = Enum.AnimationPriority.Action4
                mine.Looped = true
                mine:Play()
                copied[#copied + 1] = mine
                n = n + 1
            end
        end
    end
    notify("Copy animation", n > 0 and ("copied " .. n .. " animation(s)") or "they aren't playing an emote right now")
end

local spinConn
local function setSpin(s)
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if s then
        spinConn = RunService.Heartbeat:Connect(function(dt)
            local r = root()
            if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(720) * dt, 0) end
        end)
    end
end
local function setLie(s)
    local r, h = root(), humanoid()
    if not r or not h then return end
    if s then
        h.PlatformStand = true
        r.CFrame = r.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
    else
        h.PlatformStand = false
        r.CFrame = CFrame.new(r.Position + Vector3.new(0, 3, 0))
    end
end
local function setStatue(s)
    local r = root()
    if r then r.Anchored = s end
end

-- ================= GAME: ESP, WORLD, LOOT, MUSIC, SERVERS =================
task.spawn(function()
    while alive do
        task.wait(1)
        for _, p in ipairs(others()) do
            local c = p.Character
            if c then
                local hl = c:FindFirstChild("KT_ESP")
                if S.esp and not hl then
                    mk("Highlight", {
                        Name = "KT_ESP", FillTransparency = 0.6, FillColor = PURPLE,
                        OutlineColor = CYAN, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                    }, c)
                elseif not S.esp and hl then
                    hl:Destroy()
                end
                local head, bb = c:FindFirstChild("Head"), c:FindFirstChild("KT_NAME")
                if S.espNames and head and not bb then
                    bb = mk("BillboardGui", {
                        Name = "KT_NAME", Adornee = head, Size = UDim2.fromOffset(160, 24),
                        StudsOffset = Vector3.new(0, 2.2, 0), AlwaysOnTop = true,
                    }, c)
                    mk("TextLabel", {
                        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                        Text = p.DisplayName .. " (@" .. p.Name .. ")", TextColor3 = Color3.new(1, 1, 1),
                        TextStrokeTransparency = 0, TextStrokeColor3 = PURPLE,
                        Font = Enum.Font.GothamBold, TextSize = 13,
                    }, bb)
                elseif not S.espNames and bb then
                    bb:Destroy()
                end
            end
        end
    end
end)

local function clearEsp()
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            local a, b = c:FindFirstChild("KT_ESP"), c:FindFirstChild("KT_NAME")
            if a then a:Destroy() end
            if b then b:Destroy() end
        end
    end
end

local function setXray(s)
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and not Players:GetPlayerFromCharacter(d:FindFirstAncestorOfClass("Model")) then
            d.LocalTransparencyModifier = s and 0.7 or 0
            n = n + 1
            if n % 400 == 0 then task.wait() end
        end
    end
end

local function setFullbright(s)
    if s then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 2; Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    end
end

local function setPotato(s)
    pcall(function()
        settings().Rendering.QualityLevel = s and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    end)
    Lighting.GlobalShadows = not s
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then e.Enabled = not s end
    end
end

local function pickTools(teleport)
    local r = root()
    if not r then return end
    local home = r.CFrame
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Tool") and not Players:GetPlayerFromCharacter(d.Parent) then
            local handle = d:FindFirstChild("Handle")
            if handle then
                if teleport then
                    r = root()
                    if not r then break end
                    r.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.25)
                end
                if firetouchinterest then
                    firetouchinterest(r, handle, 0)
                    firetouchinterest(r, handle, 1)
                end
                n = n + 1
            end
        end
    end
    if teleport then
        local r2 = root()
        if r2 then r2.CFrame = home end
    end
    notify("Tools", "tried " .. n .. " tool(s)")
end

local function pickNearestTool()
    local r = root()
    if not r then return end
    local best, bd
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Tool") and not Players:GetPlayerFromCharacter(d.Parent) then
            local handle = d:FindFirstChild("Handle")
            if handle then
                local dist = (handle.Position - r.Position).Magnitude
                if not bd or dist < bd then best, bd = handle, dist end
            end
        end
    end
    if best and firetouchinterest then
        firetouchinterest(r, best, 0)
        firetouchinterest(r, best, 1)
        notify("Tools", string.format("nearest tool is %.0f studs away", bd))
    else
        notify("Tools", "no tool found")
    end
end

local localSound, musicVol, musicId = nil, 1, ""
local function playMusic()
    local id = musicId:match("%d+")
    if not id then notify("Music", "type an audio ID first") return end
    if localSound then localSound:Destroy() end
    localSound = mk("Sound", {SoundId = "rbxassetid://" .. id, Volume = musicVol, Looped = true}, SoundService)
    localSound:Play()
end
local function stopMusic()
    if localSound then localSound:Destroy(); localSound = nil end
end

local function copySoundIds()
    local out, seen = {}, {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Sound") and d.IsPlaying and d.SoundId ~= "" then
            local id = d.SoundId:match("%d+")
            local owner, cur = "world", d.Parent
            while cur and cur ~= workspace do
                local p = Players:GetPlayerFromCharacter(cur)
                if p then owner = p.Name break end
                cur = cur.Parent
            end
            local key = owner .. tostring(id or d.SoundId)
            if id and not seen[key] then
                seen[key] = true
                out[#out + 1] = owner .. ": " .. id
            end
        end
    end
    if #out == 0 then notify("Music IDs", "nothing is playing") return end
    if setclipboard then setclipboard(table.concat(out, "\n")) end
    notify("Music IDs", #out .. " ID(s) copied")
end

local function serverHop()
    notify("Server", "searching for another server...")
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok or not data or not data.data then notify("Server", "couldn't read the server list") return end
    for _, s in ipairs(data.data) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
            return
        end
    end
    notify("Server", "no other open server found")
end

-- ================= FLOATING WINDOW: PLAYER BOX =================
local function openBox()
    if boxGui then boxGui.Enabled = not boxGui.Enabled return end
    boxGui = Instance.new("ScreenGui")
    boxGui.Name = "NovexPlayerBox"
    boxGui.ResetOnSpawn = false
    guiParent(boxGui)

    local frame = windowFrame(boxGui, UDim2.fromOffset(250, 280), UDim2.new(0, 12, 0.28, 0), "PLAYER BOX")

    boxImg = mk("ImageLabel", {
        Size = UDim2.fromOffset(72, 72), Position = UDim2.fromOffset(8, 36),
        BackgroundColor3 = BTN, BorderSizePixel = 0, Image = "",
    }, frame)
    corner(boxImg, 10)
    neon(boxImg, 1.5)

    boxInput = mk("TextBox", {
        Size = UDim2.fromOffset(118, 28), Position = UDim2.fromOffset(88, 36),
        BackgroundColor3 = BTN, PlaceholderText = "type 2-3 letters", Text = "",
        PlaceholderColor3 = MUTED, ClearTextOnFocus = false,
        TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 12, BorderSizePixel = 0,
    }, frame)
    corner(boxInput, 8)
    mk("UIStroke", {Color = CYAN, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, boxInput)

    local hand = mk("TextButton", {
        Size = UDim2.fromOffset(32, 28), Position = UDim2.fromOffset(210, 36),
        BackgroundColor3 = BTN, Text = "✋", TextSize = 16, BorderSizePixel = 0,
    }, frame)
    corner(hand, 8)
    mk("UIStroke", {Color = CYAN, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, hand)

    boxName = mk("TextLabel", {
        Size = UDim2.new(1, -96, 0, 44), Position = UDim2.fromOffset(88, 68),
        BackgroundTransparency = 1, Text = "nobody selected", TextWrapped = true,
        TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, frame)

    local scroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -116), Position = UDim2.fromOffset(4, 112),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = PURPLE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, frame)
    mk("UIGridLayout", {
        CellSize = UDim2.fromOffset(76, 28), CellPadding = UDim2.fromOffset(4, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)

    local order = 0
    local function action(text, fn)
        order = order + 1
        local b = mk("TextButton", {
            Text = text, TextColor3 = TEXT, Font = Enum.Font.GothamMedium,
            TextScaled = true, BorderSizePixel = 0, LayoutOrder = order,
        }, scroll)
        chip(b)
        mk("UITextSizeConstraint", {MaxTextSize = 12, MinTextSize = 7}, b)
        mk("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)}, b)
        b.MouseButton1Click:Connect(safe(fn))
        return b
    end
    local function switch(text, fn)
        local on = false
        local b
        b = action(text, function()
            on = not on
            local ok = fn(on)
            if ok == false then on = false end
            setOn(b, on)
        end)
        return b
    end

    action("< Prev", function() cyclePlayer(-1) end)
    action("Next >", function() cyclePlayer(1) end)
    action("Clear", function() setSelected(nil) end)
    switch("Spectate", function(s) setSpectate(s); return (not s) or spectating end)
    action("Go to", gotoPlayer)
    action("Go to all", function() task.spawn(gotoEveryone) end)
    action("Copy anim", copyAnimation)
    action("Sit on head", function() startAttach("head") end)
    action("Bag / back", function() startAttach("back") end)
    action("Hug", function() startAttach("hug") end)
    action("Stop attach", stopAttach)
    action("Stop run", function() S.abort = true end)
    action("Copy name", function()
        if selected and setclipboard then setclipboard(selected.Name) notify("Copied", selected.Name) end
    end)
    switch("Spin", setSpin)
    switch("Lie down", setLie)
    switch("Statue", setStatue)

    boxInput:GetPropertyChangedSignal("Text"):Connect(function()
        if boxInput.Text == "" then
            if selected then setSelected(nil, true) end
            return
        end
        local p = findPlayer(boxInput.Text)
        if p and p ~= selected then setSelected(p, true) end
    end)
    hand.MouseButton1Click:Connect(function()
        giveTool("Select Player", pickFromMouse)
        notify("Hand", "'Select Player' tool added. Equip it and tap a player.")
    end)

    if selected then setSelected(selected) end
end

-- ================= FLOATING WINDOW: EMOTE MENU =================
local function openEmoteMenu()
    if emoteGui then emoteGui.Enabled = not emoteGui.Enabled return end
    emoteGui = Instance.new("ScreenGui")
    emoteGui.Name = "NovexEmoteMenu"
    emoteGui.ResetOnSpawn = false
    guiParent(emoteGui)

    local frame = windowFrame(emoteGui, UDim2.fromOffset(238, 300), UDim2.new(1, -252, 0.12, 0), "EMOTES")

    local function smallButton(text, x, w, y, fn)
        local b = mk("TextButton", {
            Size = UDim2.fromOffset(w, 22), Position = UDim2.fromOffset(x, y),
            Text = text, TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 12, BorderSizePixel = 0,
        }, frame)
        chip(b)
        b.MouseButton1Click:Connect(safe(fn))
        return b
    end

    smallButton("Stop", 4, 56, 30, stopEmote)
    local loopB
    loopB = smallButton("Loop: ON", 64, 74, 30, function()
        loopEmotes = not loopEmotes
        loopB.Text = loopEmotes and "Loop: ON" or "Loop: OFF"
        setOn(loopB, loopEmotes)
        if track then track.Looped = loopEmotes end
    end)
    setOn(loopB, loopEmotes)
    smallButton("Random", 142, 92, 30, randomEmote)

    local activeCat = 0
    local chipBtns = {}
    local rows = {}
    local search

    local function applyFilter()
        local q = search.Text:lower()
        for _, r in ipairs(rows) do
            local okCat = (activeCat == 0) or (r.ci == activeCat)
            local okQ = (q == "") or (r.name:find(q, 1, true) ~= nil)
            r.b.Visible = okCat and okQ
        end
        for ci, b in pairs(chipBtns) do
            setOn(b, ci == activeCat)
        end
    end

    for i, chipDef in ipairs(CHIPS) do
        local b = smallButton(chipDef[1], 4 + (i - 1) * 46, 43, 56, function()
            activeCat = chipDef[2]
            applyFilter()
        end)
        chipBtns[chipDef[2]] = b
    end

    search = mk("TextBox", {
        Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 82), BackgroundColor3 = BTN,
        PlaceholderText = "search...", Text = "", ClearTextOnFocus = false, TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = MUTED, Font = Enum.Font.Gotham, TextSize = 12, BorderSizePixel = 0,
    }, frame)
    corner(search, 8)
    mk("UIStroke", {Color = CYAN, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, search)

    local scroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -112), Position = UDim2.fromOffset(4, 108), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = PURPLE,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, frame)
    mk("UIGridLayout", {
        CellSize = UDim2.fromOffset(106, 26), CellPadding = UDim2.fromOffset(6, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)

    local n = 0
    for ci, cat in ipairs(R6_CATEGORIES) do
        for _, e in ipairs(cat[2]) do
            n = n + 1
            local b = mk("TextButton", {
                Text = e[1], TextColor3 = TEXT, Font = Enum.Font.GothamMedium,
                TextScaled = true, TextWrapped = true, BorderSizePixel = 0, LayoutOrder = n,
            }, scroll)
            chip(b, EMOTE_ACCENT[ci])
            mk("UITextSizeConstraint", {MaxTextSize = 11, MinTextSize = 6}, b)
            mk("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)}, b)
            b.MouseButton1Click:Connect(safe(function() playEmote(e[2], e[1]) end))
            rows[#rows + 1] = {b = b, name = e[1]:lower(), ci = ci}
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
    applyFilter()
end

-- ================= FLOATING WINDOW: POSITION HUD =================
local function openPosHud()
    if posGui then posGui.Enabled = not posGui.Enabled return end
    posGui = Instance.new("ScreenGui")
    posGui.Name = "NovexPosHud"
    posGui.ResetOnSpawn = false
    guiParent(posGui)

    local frame = windowFrame(posGui, UDim2.fromOffset(160, 116), UDim2.new(0.5, -80, 0.08, 0), "POSITION")
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -16, 0, 54), Position = UDim2.fromOffset(8, 32), BackgroundTransparency = 1,
        Text = "X ...\nY ...\nZ ...", TextColor3 = CYAN, Font = Enum.Font.Code,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, frame)
    local copyB = mk("TextButton", {
        Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 88),
        Text = "Copy X / Y / Z", TextColor3 = TEXT, Font = Enum.Font.GothamMedium,
        TextSize = 12, BorderSizePixel = 0,
    }, frame)
    chip(copyB)
    copyB.MouseButton1Click:Connect(safe(function()
        local r = root()
        if r and setclipboard then
            local p = r.Position
            setclipboard(string.format("X %.2f\nY %.2f\nZ %.2f", p.X, p.Y, p.Z))
            copyB.Text = "Copied!"
            task.delay(1, function() if copyB.Parent then copyB.Text = "Copy X / Y / Z" end end)
        end
    end))
    bind(RunService.RenderStepped, function()
        if not posGui or not posGui.Enabled then return end
        local r = root()
        if r then
            local p = r.Position
            lbl.Text = string.format("X %.2f\nY %.2f\nZ %.2f", p.X, p.Y, p.Z)
        end
    end)
end

-- ================= RESPAWN =================
bind(lp.CharacterAdded, function()
    flyer.stop(); carFlyer.stop(); stopAttach(); setSpin(false)
    track = nil; copied = {}
    air.on = false
    if air.part then air.part:Destroy(); air.part = nil end
    task.wait(1)
    if S.flyWanted then flyer.start() end
    if S.respawnCF then
        local r = root()
        if r then r.CFrame = S.respawnCF end
    end
    for name, fn in pairs(keepTools) do giveTool(name, fn) end
end)

-- ================= MAIN WINDOW =================
loaderStep("Building interface", 0.8)
Window = WindUI:CreateWindow({
    Title = HUB_TITLE,
    Icon = "zap",
    Author = "Novex Hub",
    Folder = "KazakhHub",
})

local function toggleHub()
    local ok = pcall(function() Window:Toggle() end)
    if not ok then
        pcall(function()
            if hubOpen then Window:Close() else Window:Open() end
        end)
    end
    hubOpen = not hubOpen
end
bind(UIS.InputBegan, function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then toggleHub() end
end)

-- Finds the main WindUI window by its title text and gives it the neon outline.
-- WindUI's internal names are not verified, so this searches at runtime and skips quietly if it misses.
local function findWindowRoot()
    local roots = {}
    pcall(function() if gethui then roots[#roots + 1] = gethui() end end)
    pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then roots[#roots + 1] = pg end
    for _, r in ipairs(roots) do
        for _, d in ipairs(r:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text:find("Novex Hub", 1, true)
                and not d:FindFirstAncestor("NovexLoader") then
                local node = d
                while node.Parent and not node.Parent:IsA("ScreenGui") do
                    node = node.Parent
                end
                if node:IsA("GuiObject") then return node end
            end
        end
    end
end

local function applyNeonWindow()
    local node
    for _ = 1, 25 do
        node = findWindowRoot()
        if node then break end
        task.wait(0.2)
    end
    if not node then
        warn("[Novex Hub] window frame not found, neon outline skipped")
        return
    end
    neon(node, 2)
    neon(node, 5, 0.6)
end
task.spawn(applyNeonWindow)

-- ---- TELEPORTS ----
local TP = Window:Tab({Title = "Teleports", Icon = "map-pin"})
TP:Button({Title = "Get all slaps (and come back)", Callback = safe(function() task.spawn(visit, SLAPS, true) end)})
for i, pos in ipairs(SLAPS) do
    TP:Button({Title = "Slap " .. i .. " only", Callback = safe(function() task.spawn(visit, {pos}, true) end)})
end
TP:Button({Title = "Get carpet (stay there)", Callback = safe(function() task.spawn(getCarpet) end)})
TP:Button({
    Title = "Slaps then carpet",
    Callback = safe(function()
        task.spawn(function()
            visit(SLAPS, false)
            if not S.abort then getCarpet() end
        end)
    end),
})
TP:Button({Title = "Stop run", Callback = safe(function() S.abort = true end)})
TP:Toggle({Title = "Auto loop slaps", Value = false, Callback = safe(function(v) S.autoSlaps = v end)})
TP:Slider({Title = "Seconds between auto loops", Value = {Min = 5, Max = 120, Default = 20}, Step = 5, Callback = safe(function(v) S.autoGap = v end)})
TP:Slider({Title = "Stay time per spot (s)", Value = {Min = 0.3, Max = 3, Default = 0.7}, Step = 0.1, Callback = safe(function(v) S.stay = v end)})
TP:Slider({Title = "Grab radius", Value = {Min = 10, Max = 60, Default = 25}, Step = 5, Callback = safe(function(v) S.grabRadius = v end)})

local spotNum = ""
TP:Button({
    Title = "Save my position as custom spot",
    Callback = safe(function()
        local r = root()
        if not r then return end
        local p = r.Position
        custom[#custom + 1] = {x = p.X, y = p.Y, z = p.Z}
        saveSpots()
        notify("Spots", "saved spot #" .. #custom)
    end),
})
TP:Button({Title = "Run all custom spots (and come back)", Callback = safe(function() task.spawn(visit, customList(), true) end)})
TP:Input({Title = "Go to custom spot number", Placeholder = "1, 2, 3...", Callback = safe(function(t) spotNum = t end)})
TP:Button({
    Title = "Go to that spot",
    Callback = safe(function()
        local e = custom[tonumber(spotNum) or 0]
        if e then tp(Vector3.new(e.x, e.y, e.z)) else notify("Spots", "no spot with that number") end
    end),
})
TP:Button({
    Title = "Copy custom spots",
    Callback = safe(function()
        if #custom == 0 then notify("Spots", "none saved yet") return end
        local out = {}
        for i, e in ipairs(custom) do
            out[#out + 1] = string.format("Spot %d\nX %.2f\nY %.2f\nZ %.2f", i, e.x, e.y, e.z)
        end
        if setclipboard then setclipboard(table.concat(out, "\n\n")) end
        notify("Spots", #custom .. " spot(s) copied")
    end),
})
TP:Button({
    Title = "Clear custom spots",
    Callback = safe(function()
        custom = {}
        saveSpots()
        notify("Spots", "cleared")
    end),
})

-- ---- COINS ----
local CN = Window:Tab({Title = "Infinite Coins", Icon = "coins"})
ui.coins = CN:Toggle({Title = "Infinite coins (AFK)", Value = false, Callback = safe(setAfk)})
CN:Toggle({Title = "Extreme lock (snap every frame)", Value = true, Callback = safe(function(v) afk.extreme = v end)})
CN:Toggle({Title = "Auto grab nearby while there", Value = true, Callback = safe(function(v) afk.grabbing = v end)})
CN:Toggle({Title = "Return to old spot when turned off", Value = true, Callback = safe(function(v) afk.returnOnOff = v end)})
CN:Button({Title = "Go to coin spot once", Callback = safe(function() tp(AFK_COINS) end)})

-- ---- MOVEMENT ----
local MV = Window:Tab({Title = "Movement", Icon = "plane"})
ui.fly = MV:Toggle({Title = "Fly", Value = false, Callback = safe(setFly)})
MV:Slider({Title = "Fly speed", Value = {Min = 10, Max = 400, Default = 60}, Step = 5, Callback = safe(function(v) flyer.speed = v end)})
MV:Input({Title = "Speed (1 - 999999)", Placeholder = "type a number", Callback = safe(function(t)
    local n = tonumber(t)
    if n then S.speed = math.clamp(n, 1, 999999) end
end)})
MV:Slider({Title = "Walk speed", Value = {Min = 16, Max = 300, Default = 16}, Step = 1, Callback = safe(function(v) S.speed = v end)})
MV:Input({Title = "Jump height (1 - 999999)", Placeholder = "type a number", Callback = safe(function(t)
    local n = tonumber(t)
    if n then S.jump = math.clamp(n, 1, 999999) end
end)})
MV:Slider({Title = "Jump power", Value = {Min = 50, Max = 400, Default = 50}, Step = 5, Callback = safe(function(v) S.jump = v end)})
ui.infjump = MV:Toggle({Title = "Infinite jump", Value = false, Callback = safe(setInfJump)})
ui.noclip = MV:Toggle({Title = "Walk through walls (noclip)", Value = false, Callback = safe(setNoclip)})
MV:Toggle({Title = "Walk on the sky", Value = false, Callback = safe(setAir)})
MV:Button({Title = "Sky platform up", Callback = safe(function() air.y = air.y + 5 end)})
MV:Button({Title = "Sky platform down", Callback = safe(function() air.y = air.y - 5 end)})
MV:Toggle({Title = "Walk on walls (climb)", Value = false, Callback = safe(function(v) S.climb = v end)})
MV:Toggle({Title = "Anti-void (return if you fall)", Value = false, Callback = safe(function(v) S.antiVoid = v end)})
MV:Slider({Title = "Void height (Y)", Value = {Min = -500, Max = 0, Default = -100}, Step = 10, Callback = safe(function(v) S.voidY = v end)})
MV:Button({
    Title = "Click TP tool (tap to teleport)",
    Callback = safe(function()
        giveTool("Click TP", clickTeleport)
        notify("Click TP", "equip 'Click TP' and tap where you want to go")
    end),
})
MV:Button({
    Title = "Delete tool (hides objects for you)",
    Callback = safe(function()
        giveTool("Delete", deleteTap)
        notify("Delete", "equip 'Delete' and tap an object (only you see it vanish)")
    end),
})
MV:Button({
    Title = "Set my respawn place",
    Callback = safe(function()
        local r = root()
        if r then S.respawnCF = r.CFrame; notify("Respawn", "saved, you'll spawn here") end
    end),
})
MV:Button({Title = "Clear respawn place", Callback = safe(function() S.respawnCF = nil end)})
MV:Button({
    Title = "Reset speed, jump, fly, tools",
    Callback = safe(function()
        S.speed, S.jump = nil, nil
        setFly(false); carFlyer.stop(); flyGui.Enabled = false
        setAir(false); S.climb = false
        setNoclip(false); setInfJump(false)
        workspace.Gravity = 196.2
        local h = humanoid()
        if h then h.WalkSpeed = 16; h.JumpPower = 50 end
        removeKeptTools()
    end),
})

-- ---- PLAYERS ----
local PL = Window:Tab({Title = "Players", Icon = "users"})
PL:Button({Title = "Open player box", Callback = safe(openBox)})
PL:Button({
    Title = "Hand: get Select Player tool",
    Callback = safe(function()
        giveTool("Select Player", pickFromMouse)
        notify("Hand", "equip 'Select Player' and tap a player")
    end),
})

-- ---- GAME ----
local GM = Window:Tab({Title = "Game", Icon = "gamepad-2"})
GM:Toggle({Title = "See players (ESP)", Value = false, Callback = safe(function(v) S.esp = v; if not v and not S.espNames then clearEsp() end end)})
GM:Toggle({Title = "See player names", Value = false, Callback = safe(function(v) S.espNames = v; if not v and not S.esp then clearEsp() end end)})
GM:Toggle({Title = "X-ray (see through objects)", Value = false, Callback = safe(function(v) task.spawn(setXray, v) end)})
GM:Toggle({
    Title = "Immortal (client side only)",
    Value = false,
    Callback = safe(function(v)
        S.god = v
        if not v then
            local h = humanoid()
            if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end) end
        end
    end),
})
GM:Button({Title = "Day", Callback = safe(function() Lighting.ClockTime = 14 end)})
GM:Button({Title = "Night", Callback = safe(function() Lighting.ClockTime = 0 end)})
GM:Toggle({Title = "Graphics: fullbright", Value = false, Callback = safe(setFullbright)})
GM:Toggle({Title = "Graphics: potato (less lag)", Value = false, Callback = safe(setPotato)})
GM:Slider({Title = "Gravity", Value = {Min = 20, Max = 300, Default = 196}, Step = 2, Callback = safe(function(v) workspace.Gravity = v end)})
GM:Slider({Title = "Field of view", Value = {Min = 40, Max = 120, Default = 70}, Step = 1, Callback = safe(function(v) workspace.CurrentCamera.FieldOfView = v end)})
GM:Button({Title = "Pick up all tools", Callback = safe(function() task.spawn(pickTools, false) end)})
GM:Button({Title = "Pick up all tools (teleport to each)", Callback = safe(function() task.spawn(pickTools, true) end)})
GM:Button({Title = "Pick up nearest tool", Callback = safe(pickNearestTool)})
GM:Toggle({
    Title = "Fly the car (sit in a vehicle first)",
    Value = false,
    Callback = safe(function(v)
        if v then
            if carFlyer.start() then
                flyGui.Enabled = true
            else
                notify("Car", "sit in a vehicle seat first")
            end
        else
            carFlyer.stop()
            flyGui.Enabled = S.flyWanted
        end
    end),
})
GM:Slider({Title = "Car fly speed", Value = {Min = 20, Max = 400, Default = 80}, Step = 5, Callback = safe(function(v) carFlyer.speed = v end)})
GM:Input({Title = "Music (only you hear): audio ID", Placeholder = "paste an ID", Callback = safe(function(t) musicId = t end)})
GM:Slider({Title = "Music volume", Value = {Min = 0, Max = 5, Default = 1}, Step = 0.1, Callback = safe(function(v)
    musicVol = v
    if localSound then localSound.Volume = v end
end)})
GM:Button({Title = "Play music", Callback = safe(playMusic)})
GM:Button({Title = "Stop music", Callback = safe(stopMusic)})
GM:Button({Title = "Copy IDs of music other players are playing", Callback = safe(copySoundIds)})

-- ---- EMOTES ----
local DN = Window:Tab({Title = "Emotes", Icon = "music"})
DN:Button({Title = "Open emote menu (small, draggable)", Callback = safe(openEmoteMenu)})
DN:Button({Title = "Random emote", Callback = safe(randomEmote)})
DN:Button({Title = "Stop emote", Callback = safe(stopEmote)})
DN:Toggle({Title = "Loop emotes", Value = true, Callback = safe(function(v) loopEmotes = v; if track then track.Looped = v end end)})
DN:Slider({Title = "Emote speed", Value = {Min = 0.2, Max = 4, Default = 1}, Step = 0.1, Callback = safe(function(v)
    emoteSpeed = v
    if track then track:AdjustSpeed(v) end
end)})
DN:Input({Title = "Custom animation ID", Placeholder = "paste an ID", Callback = safe(function(t) typedId = t end)})
DN:Button({
    Title = "Play typed ID",
    Callback = safe(function()
        local id = tonumber(typedId)
        if id then playEmote(id, id) else notify("Emote", "type a numeric ID first") end
    end),
})
DN:Button({
    Title = "Copy IDs of animations playing on me",
    Callback = safe(function()
        local h = humanoid()
        local animator = h and h:FindFirstChildOfClass("Animator")
        if not animator then return end
        local out = {}
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            out[#out + 1] = t.Animation and t.Animation.AnimationId or "?"
        end
        if setclipboard then setclipboard(table.concat(out, "\n")) end
        notify("Copied", #out .. " animation IDs")
    end),
})

-- ---- SERVER ----
local SV = Window:Tab({Title = "Server", Icon = "server"})
SV:Button({Title = "Change server", Callback = safe(function() task.spawn(serverHop) end)})
SV:Button({Title = "Rejoin this same server", Callback = safe(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)})
SV:Button({Title = "Rejoin (new server)", Callback = safe(function() TeleportService:Teleport(game.PlaceId, lp) end)})

-- ---- SETTINGS ----
local MS = Window:Tab({Title = "Settings", Icon = "settings"})
pcall(function()
    MS:Dropdown({
        Title = "Change color (theme)",
        Values = {"Dark", "Light", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet", "Amber", "Emerald"},
        Value = "Dark",
        Callback = function(opt) pcall(function() WindUI:SetTheme(opt) end) end,
    })
end)
MS:Toggle({Title = "Anti-AFK", Value = true, Callback = safe(function(v) S.antiAfk = v end)})
MS:Button({Title = "Position HUD (draggable)", Callback = safe(openPosHud)})
MS:Button({
    Title = "Copy my position (X / Y / Z)",
    Callback = safe(function()
        local r = root()
        if r and setclipboard then
            local p = r.Position
            setclipboard(string.format("X %.2f\nY %.2f\nZ %.2f", p.X, p.Y, p.Z))
            notify("Copied", string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
        end
    end),
})
MS:Button({Title = "Unload hub", Callback = safe(function() env.KT_HUB_UNLOAD() end)})

-- ================= UNLOAD =================
local function unload()
    alive = false
    S.autoSlaps = false
    S.esp, S.espNames, S.god, S.climb, S.antiVoid = false, false, false, false, false
    afk.on = false
    S.abort = true
    pcall(function() flyer.stop(); carFlyer.stop() end)
    pcall(stopAttach); pcall(setSpin, false); pcall(setSpectate, false)
    pcall(stopEmote); pcall(stopMusic); pcall(clearEsp); pcall(setAir, false)
    pcall(removeKeptTools)
    S.noclip, S.infJump = false, false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    neonGrads = {}
    for _, g in ipairs({boxGui, emoteGui, posGui, flyGui}) do
        if g then pcall(function() g:Destroy() end) end
    end
    pcall(function() loader.gui:Destroy() end)
    pcall(function() Window:Destroy() end)
    env.KT_HUB_UNLOAD = nil
end
env.KT_HUB_UNLOAD = unload

loaderFinish()
notify("Novex Hub", "Kazakh Tower Script loaded. RightShift toggles the menu.")
