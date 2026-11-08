-- CAR CONTROL V3 | XENO
-- RIGHT SHIFT = SHOW / HIDE MENU

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if env.CarControlCleanup then
    pcall(env.CarControlCleanup)
end

local cfg = {
    Speed = 130,
    Turn = 3.0,
    FloorHeight = 0,

    Boost = true,
    Steering = true,
    Fly = false,
    Rage = false,
    GhostFloor = false,

    RageSpeed = 240,
    RageDelay = 0.9,
    Acceleration = 9
}

local connections = {}
local gyro
local floor
local rageIndex = 0
local nextRage = 0
local rageUntil = 0

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function make(class, properties, parent)
    local obj = Instance.new(class)
    for key, value in pairs(properties) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, obj)
end

local function destroyGyro()
    if gyro then
        gyro:Destroy()
        gyro = nil
    end
end

local function getParts()
    local character = player.Character
    if not character then return end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    if not humanoid then return end

    local seat = humanoid.SeatPart
    local body = character:FindFirstChild("HumanoidRootPart")

    if seat and seat:IsA("VehicleSeat") then
        return seat, seat.AssemblyRootPart or seat
    end

    return nil, body
end

do
    local _, root = getParts()
    if root then
        cfg.FloorHeight = math.floor(root.Position.Y - 3)
    end
end

-- INVISIBLE FLOOR

floor = Instance.new("Part")
floor.Name = "LocalGhostFloor"
floor.Size = Vector3.new(600, 2, 600)
floor.Anchored = true
floor.CanCollide = true
floor.CanTouch = false
floor.CanQuery = false
floor.Transparency = 1
floor.CastShadow = false

-- GUI

local gui = make("ScreenGui", {
    Name = "CarControlV3",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999
}, player:WaitForChild("PlayerGui"))

local BG = Color3.fromRGB(18, 20, 31)
local PANEL = Color3.fromRGB(34, 37, 53)
local PURPLE = Color3.fromRGB(139, 92, 246)
local WHITE = Color3.fromRGB(245, 245, 255)
local GRAY = Color3.fromRGB(150, 154, 174)
local GREEN = Color3.fromRGB(38, 170, 110)
local RED = Color3.fromRGB(165, 58, 75)

local frame = make("Frame", {
    Size = UDim2.fromOffset(340, 540),
    Position = UDim2.new(1, -355, 0.5, -270),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    Active = true
}, gui)
round(frame, 15)

make("UIStroke", {
    Color = PURPLE,
    Transparency = 0.35,
    Thickness = 1.4
}, frame)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1,
    Active = true
}, frame)

make("TextLabel", {
    Size = UDim2.new(1, -65, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    BackgroundTransparency = 1,
    Text = "CAR CONTROL  V3",
    TextColor3 = WHITE,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local close = make("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -40, 0, 9),
    BackgroundColor3 = PANEL,
    Text = "X",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 14
}, header)
round(close, 8)

bind(close.MouseButton1Click, function()
    frame.Visible = false
end)

make("TextLabel", {
    Size = UDim2.new(1, -30, 0, 20),
    Position = UDim2.fromOffset(15, 50),
    BackgroundTransparency = 1,
    Text = "VEHICLE PHYSICS / MOVEMENT",
    TextColor3 = GRAY,
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

-- SLIDERS

local activeSlider = nil

local function createSlider(title, y, key, min, max)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -30, 0, 24),
        Position = UDim2.fromOffset(15, y),
        BackgroundTransparency = 1,
        TextColor3 = WHITE,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)

    local bar = make("Frame", {
        Size = UDim2.new(1, -30, 0, 10),
        Position = UDim2.fromOffset(15, y + 30),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
        Active = true
    }, frame)
    round(bar, 6)

    local fill = make("Frame", {
        BackgroundColor3 = PURPLE,
        BorderSizePixel = 0
    }, bar)
    round(fill, 6)

    local knob = make("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Active = true
    }, bar)
    round(knob, 9)

    local function set(value)
        value = math.floor(math.clamp(value, min, max))
        cfg[key] = value

        local alpha = (value - min) / (max - min)

        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        label.Text = title .. ": " .. tostring(value)
    end

    local function update(x)
        local width = math.max(bar.AbsoluteSize.X, 1)
        local alpha = math.clamp(
            (x - bar.AbsolutePosition.X) / width,
            0, 1
        )

        set(min + alpha * (max - min))
    end

    local function begin(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            activeSlider = update
            update(input.Position.X)
        end
    end

    bind(bar.InputBegan, begin)
    bind(knob.InputBegan, begin)

    set(cfg[key])
    return set
end

createSlider("MAX SPEED", 78, "Speed", 30, 300)
createSlider("STEERING POWER", 138, "Turn", 1, 8)

local setFloor = createSlider(
    "GHOST FLOOR HEIGHT",
    198,
    "FloorHeight",
    -100,
    1000
)

local function smallButton(text, x, action)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(85, 27),
        Position = UDim2.fromOffset(x, 247),
        BackgroundColor3 = PANEL,
        Text = text,
        TextColor3 = WHITE,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, frame)
    round(b, 7)
    bind(b.MouseButton1Click, action)
end

smallButton("- 5 HEIGHT", 15, function()
    setFloor(cfg.FloorHeight - 5)
end)

smallButton("+ 5 HEIGHT", 113, function()
    setFloor(cfg.FloorHeight + 5)
end)

-- TOGGLES

local function createToggle(title, y, key)
    make("TextLabel", {
        Size = UDim2.fromOffset(210, 34),
        Position = UDim2.fromOffset(15, y),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WHITE,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)

    local button = make("TextButton", {
        Size = UDim2.fromOffset(70, 29),
        Position = UDim2.new(1, -85, 0, y + 2),
        TextColor3 = WHITE,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0
    }, frame)
    round(button, 8)

    local function refresh()
        button.Text = cfg[key] and "ON" or "OFF"
        button.BackgroundColor3 = cfg[key] and GREEN or RED
    end

    bind(button.MouseButton1Click, function()
        cfg[key] = not cfg[key]

        if key == "Fly" and not cfg.Fly then
            destroyGyro()
        end

        if key == "Rage" then
            nextRage = 0
            rageUntil = 0
        end

        refresh()
    end)

    refresh()
end

createToggle("SPEEDHACK", 286, "Boost")
createToggle("SHARP STEERING", 326, "Steering")
createToggle("CAR FLY", 366, "Fly")
createToggle("RAGE MODE", 406, "Rage")
createToggle("GHOST FLOOR", 446, "GhostFloor")

local status = make("TextLabel", {
    Size = UDim2.new(1, -30, 0, 25),
    Position = UDim2.fromOffset(15, 498),
    BackgroundTransparency = 1,
    Text = "STATUS: READY",
    TextColor3 = GRAY,
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

-- DRAGGING

local dragging = false
local dragStart
local originalPosition

bind(header.InputBegan, function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        originalPosition = frame.Position
    end
end)

bind(UIS.InputChanged, function(input)
    if dragging and input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset + delta.X,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + delta.Y
        )
    end

    if activeSlider and (
        input.UserInputType ==
        Enum.UserInputType.MouseMovement
        or input.UserInputType ==
        Enum.UserInputType.Touch
    ) then
        activeSlider(input.Position.X)
    end
end)

bind(UIS.InputEnded, function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = false
        activeSlider = nil
    end
end)

bind(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end

    if input.KeyCode == Enum.KeyCode.PageUp then
        setFloor(cfg.FloorHeight + 5)
    elseif input.KeyCode == Enum.KeyCode.PageDown then
        setFloor(cfg.FloorHeight - 5)
    end
end)

-- INPUT HELPERS

local function getThrottle(seat)
    local t = seat.ThrottleFloat

    if UIS:IsKeyDown(Enum.KeyCode.W) then
        return 1
    elseif UIS:IsKeyDown(Enum.KeyCode.S) then
        return -1
    end

    return t
end

local function getSteer(seat)
    if UIS:IsKeyDown(Enum.KeyCode.D) then
        return 1
    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
        return -1
    end

    return seat.SteerFloat
end

local function flatForward(cf)
    local v = Vector3.new(
        cf.LookVector.X,
        0,
        cf.LookVector.Z
    )

    if v.Magnitude < 0.001 then
        return Vector3.new(0, 0, -1)
    end

    return v.Unit
end

-- FLY STABILIZER

local function ensureGyro(root)
    if gyro and gyro.Parent == root then
        return gyro
    end

    destroyGyro()

    gyro = Instance.new("BodyGyro")
    gyro.Name = "CarFlyStabilizer"
    gyro.MaxTorque = Vector3.new(5e6, 5e6, 5e6)
    gyro.P = 18000
    gyro.D = 1200
    gyro.CFrame = root.CFrame
    gyro.Parent = root

    return gyro
end

-- RAGE TARGETING

local function nextTarget()
    local targets = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local sameTeam =
                player.Team ~= nil
                and p.Team == player.Team
                and not player.Neutral
                and not p.Neutral

            local character = p.Character

            if character and not sameTeam then
                local hum =
                    character:FindFirstChildOfClass("Humanoid")

                local root =
                    character:FindFirstChild("HumanoidRootPart")

                if hum and hum.Health > 0 and root then
                    table.insert(targets, p)
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        return a.UserId < b.UserId
    end)

    if #targets == 0 then return nil end

    rageIndex = (rageIndex % #targets) + 1

    local target = targets[rageIndex]
    return target.Character.HumanoidRootPart
end

local function moveCar(seat, targetCF)
    local model = seat:FindFirstAncestorOfClass("Model")

    if model then
        local offset =
            seat.CFrame:ToObjectSpace(model:GetPivot())

        model:PivotTo(targetCF * offset)
    else
        seat.CFrame = targetCF
    end
end

local function performRage(seat, root)
    local enemy = nextTarget()
    if not enemy then
        status.Text = "RAGE: NO TARGETS"
        return
    end

    local direction = flatForward(enemy.CFrame)

    local destination =
        enemy.Position
        - direction * 15
        + Vector3.new(0, 3, 0)

    local face = CFrame.lookAt(
        destination,
        destination + direction,
        Vector3.yAxis
    )

    destroyGyro()
    moveCar(seat, face)

    root.AssemblyLinearVelocity =
        direction * cfg.RageSpeed
        + Vector3.new(0, 2, 0)

    root.AssemblyAngularVelocity = Vector3.zero

    rageUntil = os.clock() + 0.4

    status.Text = "RAGE: " .. enemy.Parent.Name
end

-- GHOST FLOOR

local function updateFloor(seat, root)
    if not cfg.GhostFloor or cfg.Rage or not root then
        if floor.Parent then
            floor.Parent = nil
        end
        return
    end

    if floor.Parent ~= workspace then
        floor.Parent = workspace
    end

    local current = floor.Position
    local wanted = Vector3.new(
        root.Position.X,
        cfg.FloorHeight - 1,
        root.Position.Z
    )

    if (Vector3.new(current.X, 0, current.Z)
        - Vector3.new(wanted.X, 0, wanted.Z)
    ).Magnitude > 100
        or math.abs(current.Y - wanted.Y) > 0.1 then

        floor.Position = wanted
    end

    local minY = cfg.FloorHeight + 3

    if root.Position.Y < minY then
        local delta = Vector3.new(
            0,
            minY - root.Position.Y,
            0
        )

        if seat then
            local model =
                seat:FindFirstAncestorOfClass("Model")

            if model then
                model:PivotTo(model:GetPivot() + delta)
            else
                root.CFrame = root.CFrame + delta
            end
        else
            root.CFrame = root.CFrame + delta
        end

        local vel = root.AssemblyLinearVelocity

        if vel.Y < 0 then
            root.AssemblyLinearVelocity = Vector3.new(
                vel.X, 0, vel.Z
            )
        end
    end
end

-- MAIN PHYSICS

local statusClock = 0

bind(RunService.Heartbeat, function(dt)
    local seat, root = getParts()

    updateFloor(seat, root)

    if not seat or not root then
        destroyGyro()
        statusClock = statusClock + dt

        if statusClock > 0.4 then
            status.Text = "STATUS: ENTER A VEHICLE"
            statusClock = 0
        end
        return
    end

    if root.Anchored then return end

    local now = os.clock()

    -- RAGE
    if cfg.Rage then
        if now >= nextRage then
            performRage(seat, root)
            nextRage = now + cfg.RageDelay
        end

        if now < rageUntil then
            return
        end
    end

    local throttle = getThrottle(seat)
    local steer = getSteer(seat)
    local forward = flatForward(seat.CFrame)

    local alpha = 1 - math.exp(
        -cfg.Acceleration * math.min(dt, 0.1)
    )

    -- FLIGHT
    if cfg.Fly and not cfg.Rage then
        local stabilizer = ensureGyro(root)

        local turnAngle = -steer * cfg.Turn * dt

        local newDirection =
            CFrame.fromAxisAngle(
                Vector3.yAxis,
                turnAngle
            ):VectorToWorldSpace(forward)

        stabilizer.CFrame = CFrame.lookAt(
            root.Position,
            root.Position + newDirection,
            Vector3.yAxis
        )

        local vertical = 0

        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            vertical = vertical + 1
        end

        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical = vertical - 1
        end

        local velocity =
            newDirection * cfg.Speed * throttle
            + Vector3.new(
                0,
                vertical * cfg.Speed * 0.65,
                0
            )

        root.AssemblyLinearVelocity = velocity

        statusClock = statusClock + dt

        if statusClock > 0.4 then
            status.Text = "STATUS: FLYING"
            statusClock = 0
        end

        return
    end

    destroyGyro()

    -- GROUND SPEED
    if cfg.Boost and math.abs(throttle) > 0.01 then
        local vel = root.AssemblyLinearVelocity

        local target =
            forward * cfg.Speed * throttle

        local horizontal = Vector3.new(
            vel.X, 0, vel.Z
        ):Lerp(target, alpha)

        root.AssemblyLinearVelocity = Vector3.new(
            horizontal.X,
            vel.Y,
            horizontal.Z
        )
    end

    -- SHARP STEERING
    if cfg.Steering then
        local angular = root.AssemblyAngularVelocity

        local reverse = throttle < 0 and -1 or 1
        local turn = -steer * cfg.Turn * reverse

        root.AssemblyAngularVelocity = Vector3.new(
            angular.X * 0.85,
            angular.Y + (turn - angular.Y) * alpha,
            angular.Z * 0.85
        )
    end

    statusClock = statusClock + dt

    if statusClock > 0.4 and not cfg.Rage then
        status.Text = "STATUS: VEHICLE CONNECTED"
        statusClock = 0
    end
end)

-- CLEANUP FOR RE-EXECUTION

env.CarControlCleanup = function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    destroyGyro()
    floor:Destroy()
    gui:Destroy()
    env.CarControlCleanup = nil
end

print("CAR CONTROL V3 LOADED")
print("RIGHT SHIFT = MENU")
print("SPACE / LEFT CTRL = FLY UP / DOWN")
print("PAGE UP / PAGE DOWN = FLOOR HEIGHT")

