-- CAR CONTROL HUB | KEY SYSTEM V1

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- CONFIG
local VALID_KEY = "CAR-FURY-2026-X9K7"

-- Ссылка на основной скрипт
local MAIN_URL =
    "https://raw.githubusercontent.com/Grimmtrollinfeeble/car-control-hub/main/main.lua"

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CarHubLicense"
gui.ResetOnSpawn = false
gui.DisplayOrder = 99999
gui.Parent = player:WaitForChild("PlayerGui")

local old = gui.Parent:FindFirstChild("CarHubLicense")
if old and old ~= gui then
    old:Destroy()
end

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,radius)
    c.Parent = obj
end

local frame = create("Frame", {
    Size = UDim2.fromOffset(420,330),
    Position = UDim2.new(0.5,-210,0.5,-165),
    BackgroundColor3 = Color3.fromRGB(18,20,32),
    BorderSizePixel = 0,
    Active = true
},gui)
corner(frame,15)

create("UIStroke", {
    Color = Color3.fromRGB(140,100,255),
    Thickness = 2
},frame)

create("TextLabel", {
    Size = UDim2.new(1,0,0,45),
    Position = UDim2.fromOffset(0,12),
    BackgroundTransparency = 1,
    Text = "CAR CONTROL HUB",
    TextColor3 = Color3.fromRGB(240,240,255),
    TextSize = 21,
    Font = Enum.Font.GothamBold
},frame)

create("TextLabel", {
    Size = UDim2.new(1,0,0,25),
    Position = UDim2.fromOffset(0,58),
    BackgroundTransparency = 1,
    Text = "PREMIUM LICENSE ACTIVATION",
    TextColor3 = Color3.fromRGB(160,140,220),
    TextSize = 12,
    Font = Enum.Font.Gotham
},frame)

local input = create("TextBox", {
    Size = UDim2.new(1,-40,0,44),
    Position = UDim2.fromOffset(20,105),
    BackgroundColor3 = Color3.fromRGB(35,38,55),
    Text = "",
    PlaceholderText = "ENTER LICENSE KEY",
    TextColor3 = Color3.new(1,1,1),
    PlaceholderColor3 = Color3.fromRGB(140,140,155),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ClearTextOnFocus = false
},frame)
corner(input,8)

local button = create("TextButton", {
    Size = UDim2.new(1,-40,0,43),
    Position = UDim2.fromOffset(20,163),
    BackgroundColor3 = Color3.fromRGB(120,75,240),
    Text = "ACTIVATE",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 15,
    Font = Enum.Font.GothamBold
},frame)
corner(button,8)

local status = create("TextLabel", {
    Size = UDim2.new(1,-20,0,35),
    Position = UDim2.fromOffset(10,220),
    BackgroundTransparency = 1,
    Text = "ENTER YOUR KEY TO CONTINUE",
    TextColor3 = Color3.fromRGB(160,160,175),
    TextSize = 12,
    Font = Enum.Font.Gotham
},frame)

local keyLink = create("TextBox", {
    Size = UDim2.new(1,-40,0,48),
    Position = UDim2.fromOffset(20,265),
    BackgroundTransparency = 1,
    Text = "Получить ключ: https://t.me/+4HLYTFJzkd80OGIy",
    TextEditable = false,
    ClearTextOnFocus = false,
    TextWrapped = true,
    TextColor3 = Color3.fromRGB(180,155,255),
    TextSize = 14,
    Font = Enum.Font.Gotham
},frame)

local busy = false

local function activate()
    if busy then return end

    local entered = input.Text:match("^%s*(.-)%s*$")

    if entered ~= VALID_KEY then
        status.Text = "INVALID LICENSE KEY"
        status.TextColor3 = Color3.fromRGB(255,90,100)
        return
    end

    busy = true
    button.Text = "LOADING..."

    status.Text = "KEY ACCEPTED"
    status.TextColor3 = Color3.fromRGB(70,230,140)

    local ok, err = pcall(function()
        local source = game:HttpGet(MAIN_URL)
        local scriptFunction, compileErr = loadstring(source)

        if not scriptFunction then
            error(compileErr)
        end

        scriptFunction()
    end)

    if ok then
        gui:Destroy()
    else
        busy = false
        button.Text = "ACTIVATE"
        status.Text = "LOAD FAILED - CHECK CONSOLE"
        status.TextColor3 = Color3.fromRGB(255,90,100)
        warn("[CarHub] " .. tostring(err))
    end
end

button.MouseButton1Click:Connect(activate)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        activate()
    end
end)

print("CAR CONTROL LICENSE SYSTEM READY")

