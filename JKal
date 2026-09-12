-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DrawingLib = rawget(_G, "Drawing")

local function GetGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local oldUI = CoreGui:FindFirstChild("NurHub_Pulse_UI")
if oldUI then oldUI:Destroy() end

-- ==================== SETTINGS ====================
local Settings = {
    -- Players
    Player_ESP = false,
    Player_Nick = false,
    Player_Dist = false,
    Player_3DBox = false,

    -- Vehicles & AA
    Vehicle_ESP = false,
    Vehicle_Name = false,
    Vehicle_Speed = false,
    Vehicle_Dist = false,
    Vehicle_3DBox = false,
    Vehicle_Color = Color3.fromRGB(255, 204, 0),

    -- Drones
    Drone_ESP = false,
    Drone_Name = false,
    Drone_Dist = false,
    Drone_3DBox = false,
    Drone_Color = Color3.fromRGB(180, 50, 255),

    -- Missiles
    Missile_ESP = false,
    Missile_Name = false,
    Missile_Dist = false,
    Missile_3DBox = false,
    Missile_Color = Color3.fromRGB(255, 100, 0),

    -- World
    Tracers = false,
    TracerOrigin = "Bottom",
    Fullbright = false,
    NoFog = false,

    -- Combat
    Operator_Aimbot = false,
    Defender_Aimbot = false,

    Draw_FOV = false,
    FOV_Radius = 120,

    AccentColor = Color3.fromRGB(255, 204, 0),
    Color_Defender = Color3.fromRGB(30, 144, 255),
    Color_Civilian = Color3.fromRGB(50, 205, 50),
    Color_Operator = Color3.fromRGB(255, 50, 50),
}

local OrigFogEnd = Lighting.FogEnd
local OrigBrightness = Lighting.Brightness
local OrigGlobalShadows = Lighting.GlobalShadows

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NurHub_Pulse_UI"
ScreenGui.Parent = GetGuiParent()
ScreenGui.ResetOnSpawn = false

-- Toggle Button
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Name = "OpenButton"
ToggleBtn.Size = UDim2.new(0, 110, 0, 36)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleBtn.BackgroundTransparency = 0.25
ToggleBtn.Text = ""
ToggleBtn.Active = true
ToggleBtn.Draggable = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Transparency = 0.4

local BtnLogo = Instance.new("Frame", ToggleBtn)
BtnLogo.Size = UDim2.new(0, 22, 0, 22)
BtnLogo.Position = UDim2.new(0, 7, 0.5, -11)
BtnLogo.BackgroundColor3 = Settings.AccentColor
Instance.new("UICorner", BtnLogo).CornerRadius = UDim.new(0, 3)

local BtnLogoText = Instance.new("TextLabel", BtnLogo)
BtnLogoText.Size = UDim2.new(1, 0, 1, 0)
BtnLogoText.Text = "NH"
BtnLogoText.TextColor3 = Color3.fromRGB(0, 0, 0)
BtnLogoText.Font = Enum.Font.SourceSansBold
BtnLogoText.TextSize = 13
BtnLogoText.BackgroundTransparency = 1

local BtnText = Instance.new("TextLabel", ToggleBtn)
BtnText.Position = UDim2.new(0, 34, 0, 0)
BtnText.Size = UDim2.new(1, -34, 1, 0)
BtnText.Text = "NurHub"
BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnText.Font = Enum.Font.SourceSans
BtnText.TextSize = 15
BtnText.TextXAlignment = Enum.TextXAlignment.Left
BtnText.BackgroundTransparency = 1

-- FOV Circle
local FOVCircle = nil
if DrawingLib and DrawingLib.new then
    pcall(function()
        FOVCircle = DrawingLib.new("Circle")
        FOVCircle.Color = Settings.AccentColor
        FOVCircle.Thickness = 1.5
        FOVCircle.Filled = false
        FOVCircle.Transparency = 0.8
        FOVCircle.Visible = false
    end)
end

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Settings.AccentColor
MainStroke.Transparency = 0.8

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Position = UDim2.new(0, 15, 0, 0)
HeaderTitle.Size = UDim2.new(0, 200, 1, 0)
HeaderTitle.Text = "NurHub <font color='#FFCC00'>v3.1</font>"
HeaderTitle.RichText = true
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.Font = Enum.Font.SourceSansBold
HeaderTitle.TextSize = 18
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Position = UDim2.new(1, -35, 0, 8)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Settings.AccentColor
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local function OpenMenu()
    MainFrame.Visible = true
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 580, 0, 380)
    }):Play()
end

local function CloseMenu()
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 580, 0, 0)
    })
    t.Completed:Connect(function() MainFrame.Visible = false end)
    t:Play()
end

CloseBtn.MouseButton1Click:Connect(CloseMenu)
ToggleBtn.MouseButton1Click:Connect(function()
    if MainFrame.Visible then CloseMenu() else OpenMenu() end
end)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.Size = UDim2.new(0, 130, 1, -55)
Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 5)

-- Pages
local ContainerArea = Instance.new("Frame", MainFrame)
ContainerArea.Position = UDim2.new(0, 150, 0, 45)
ContainerArea.Size = UDim2.new(1, -160, 1, -55)
ContainerArea.BackgroundTransparency = 1

local VisualsPage = Instance.new("ScrollingFrame", ContainerArea)
VisualsPage.Size = UDim2.new(1, 0, 1, 0)
VisualsPage.BackgroundTransparency = 1
VisualsPage.ScrollBarThickness = 3
VisualsPage.Visible = true
Instance.new("UIListLayout", VisualsPage).Padding = UDim.new(0, 8)

local CombatPage = Instance.new("ScrollingFrame", ContainerArea)
CombatPage.Size = UDim2.new(1, 0, 1, 0)
CombatPage.BackgroundTransparency = 1
CombatPage.ScrollBarThickness = 3
CombatPage.Visible = false
Instance.new("UIListLayout", CombatPage).Padding = UDim.new(0, 8)

local function CreateTab(name, pageFrame)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        VisualsPage.Visible = false
        CombatPage.Visible = false
        pageFrame.Visible = true
        for _, c in ipairs(Sidebar:GetChildren()) do
            if c:IsA("TextButton") then
                TweenService:Create(c, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(180, 180, 180)}):Play()
            end
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Settings.AccentColor, TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
    end)

    if name == "Visuals" then
        btn.BackgroundColor3 = Settings.AccentColor
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    end
end

CreateTab("Visuals", VisualsPage)
CreateTab("Combat", CombatPage)

-- UI Helpers
local function CreateSectionBlock(parent, title)
    local block = Instance.new("Frame", parent)
    block.Size = UDim2.new(1, -5, 0, 32)
    block.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    block.ClipsDescendants = true
    Instance.new("UICorner", block).CornerRadius = UDim.new(0, 6)

    local list = Instance.new("UIListLayout", block)
    list.Padding = UDim.new(0, 4)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local txt = Instance.new("TextLabel", block)
    txt.Size = UDim2.new(1, -10, 0, 28)
    txt.Text = "  " .. title
    txt.TextColor3 = Settings.AccentColor
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 14
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.BackgroundTransparency = 1

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        block.Size = UDim2.new(1, -5, 0, list.AbsoluteContentSize.Y + 6)
    end)
    return block
end

-- Accordion block
local function CreateAccordionBlock(parent, title, defaultState, onToggle, buildSub)
    local block = Instance.new("Frame", parent)
    block.Size = UDim2.new(1, -5, 0, 32)
    block.BackgroundTransparency = 1

    local mainBtn = Instance.new("TextButton", block)
    mainBtn.Size = UDim2.new(0.82, 0, 0, 32)
    mainBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    mainBtn.Text = (defaultState and "  [X] " or "  [  ] ") .. title
    mainBtn.TextColor3 = defaultState and Settings.AccentColor or Color3.fromRGB(200, 200, 200)
    mainBtn.Font = Enum.Font.SourceSansBold
    mainBtn.TextSize = 14
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)

    local arrowBtn = Instance.new("TextButton", block)
    arrowBtn.Position = UDim2.new(0.84, 0, 0, 0)
    arrowBtn.Size = UDim2.new(0.16, 0, 0, 32)
    arrowBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    arrowBtn.Text = "[ > ]"
    arrowBtn.TextColor3 = Settings.AccentColor
    arrowBtn.Font = Enum.Font.SourceSansBold
    arrowBtn.TextSize = 12
    Instance.new("UICorner", arrowBtn).CornerRadius = UDim.new(0, 6)

    local drop = Instance.new("Frame", parent)
    drop.Size = UDim2.new(1, -5, 0, 0)
    drop.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    drop.Visible = false
    drop.ClipsDescendants = true
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0, 6)

    local dropLayout = Instance.new("UIListLayout", drop)
    dropLayout.Padding = UDim.new(0, 4)
    dropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local state = defaultState
    mainBtn.MouseButton1Click:Connect(function()
        state = not state
        mainBtn.Text = (state and "  [X] " or "  [  ] ") .. title
        mainBtn.TextColor3 = state and Settings.AccentColor or Color3.fromRGB(200, 200, 200)
        onToggle(state)
    end)

    local open = false
    arrowBtn.MouseButton1Click:Connect(function()
        open = not open
        arrowBtn.Text = open and "[ v ]" or "[ > ]"
        drop.Visible = true
        local contentHeight = dropLayout.AbsoluteContentSize.Y
        local targetHeight = open and (contentHeight > 0 and contentHeight + 8 or 35) or 0
        TweenService:Create(drop, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = UDim2.new(1, -5, 0, targetHeight)
        }):Play()
        if not open then
            task.delay(0.25, function() if not open then drop.Visible = false end end)
        end
    end)

    -- Пересчёт высоты при изменении содержимого
    dropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if open then
            TweenService:Create(drop, TweenInfo.new(0.2), {
                Size = UDim2.new(1, -5, 0, dropLayout.AbsoluteContentSize.Y + 8)
            }):Play()
        end
    end)

    buildSub(drop)
end

local function AddSubToggle(parent, text, defaultState, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.94, 0, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    btn.Text = (defaultState and "  [X] " or "  [  ] ") .. text
    btn.TextColor3 = defaultState and Settings.AccentColor or Color3.fromRGB(170, 170, 170)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local st = defaultState
    btn.MouseButton1Click:Connect(function()
        st = not st
        btn.Text = (st and "  [X] " or "  [  ] ") .. text
        btn.TextColor3 = st and Settings.AccentColor or Color3.fromRGB(170, 170, 170)
        callback(st)
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.94, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 5, 0, 2)
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0.9, 0, 0, 6)
    bar.Position = UDim2.new(0.05, 0, 0.7, 0)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Settings.AccentColor
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        lbl.Text = text .. ": " .. val
        callback(val)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
end

-- ==================== COLOR PICKER ====================
-- Пресеты цветов
local ColorPresets = {
    {name = "Red",      color = Color3.fromRGB(255, 50, 50)},
    {name = "Green",    color = Color3.fromRGB(50, 205, 50)},
    {name = "Blue",     color = Color3.fromRGB(30, 144, 255)},
    {name = "Yellow",   color = Color3.fromRGB(255, 204, 0)},
    {name = "Purple",   color = Color3.fromRGB(180, 50, 255)},
    {name = "Orange",   color = Color3.fromRGB(255, 100, 0)},
    {name = "Pink",     color = Color3.fromRGB(255, 105, 180)},
    {name = "Cyan",     color = Color3.fromRGB(0, 255, 255)},
    {name = "White",    color = Color3.fromRGB(255, 255, 255)},
    {name = "Black",    color = Color3.fromRGB(0, 0, 0)},
}

local function AddColorPicker(parent, text, initialColor, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.94, 0, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 5, 0, 2)
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local grid = Instance.new("Frame", frame)
    grid.Size = UDim2.new(1, -10, 0, 42)
    grid.Position = UDim2.new(0, 5, 0, 22)
    grid.BackgroundTransparency = 1

    local gridLayout = Instance.new("UIGridLayout", grid)
    gridLayout.CellSize = UDim2.new(0, 22, 0, 22)
    gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local currentColor = initialColor

    for i, preset in ipairs(ColorPresets) do
        local swatch = Instance.new("TextButton", grid)
        swatch.Size = UDim2.new(0, 22, 0, 22)
        swatch.BackgroundColor3 = preset.color
        swatch.Text = ""
        swatch.LayoutOrder = i
        Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)

        local stroke = Instance.new("UIStroke", swatch)
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.7
        stroke.Thickness = 2

        -- Подсветка выбранного цвета
        if preset.color == initialColor then
            stroke.Transparency = 0
            stroke.Color = Settings.AccentColor
        end

        swatch.MouseButton1Click:Connect(function()
            currentColor = preset.color
            callback(preset.color)
            for _, c in ipairs(grid:GetChildren()) do
                if c:IsA("TextButton") then
                    local s = c:FindFirstChildOfClass("UIStroke")
                    if s then
                        s.Transparency = 0.7
                        s.Color = Color3.fromRGB(255, 255, 255)
                    end
                end
            end
            stroke.Transparency = 0
            stroke.Color = Settings.AccentColor
        end)
    end
end

-- ==================== VISUALS PAGE ====================
-- PLAYER ESP
CreateAccordionBlock(VisualsPage, "Player ESP", Settings.Player_ESP,
    function(v) Settings.Player_ESP = v end,
    function(sub)
        AddSubToggle(sub, "Show Nickname", Settings.Player_Nick, function(v) Settings.Player_Nick = v end)
        AddSubToggle(sub, "Show Distance", Settings.Player_Dist, function(v) Settings.Player_Dist = v end)
        AddSubToggle(sub, "3D Box Frame", Settings.Player_3DBox, function(v) Settings.Player_3DBox = v end)
    end
)

-- VEHICLE / AA ESP
CreateAccordionBlock(VisualsPage, "Vehicles & AA ESP", Settings.Vehicle_ESP,
    function(v) Settings.Vehicle_ESP = v end,
    function(sub)
        AddSubToggle(sub, "Show Name", Settings.Vehicle_Name, function(v) Settings.Vehicle_Name = v end)
        AddSubToggle(sub, "Show Speed (km/h)", Settings.Vehicle_Speed, function(v) Settings.Vehicle_Speed = v end)
        AddSubToggle(sub, "Show Distance", Settings.Vehicle_Dist, function(v) Settings.Vehicle_Dist = v end)
        AddSubToggle(sub, "3D Box Frame", Settings.Vehicle_3DBox, function(v) Settings.Vehicle_3DBox = v end)
        AddColorPicker(sub, "Vehicle Color", Settings.Vehicle_Color, function(c)
            Settings.Vehicle_Color = c
        end)
    end
)

-- DRONES ESP
CreateAccordionBlock(VisualsPage, "Drones ESP", Settings.Drone_ESP,
    function(v) Settings.Drone_ESP = v end,
    function(sub)
        AddSubToggle(sub, "Show Name", Settings.Drone_Name, function(v) Settings.Drone_Name = v end)
        AddSubToggle(sub, "Show Distance", Settings.Drone_Dist, function(v) Settings.Drone_Dist = v end)
        AddSubToggle(sub, "3D Box Frame", Settings.Drone_3DBox, function(v) Settings.Drone_3DBox = v end)
        AddColorPicker(sub, "Drone Color", Settings.Drone_Color, function(c)
            Settings.Drone_Color = c
        end)
    end
)

-- MISSILES ESP
CreateAccordionBlock(VisualsPage, "Missiles ESP", Settings.Missile_ESP,
    function(v) Settings.Missile_ESP = v end,
    function(sub)
        AddSubToggle(sub, "Show Name", Settings.Missile_Name, function(v) Settings.Missile_Name = v end)
        AddSubToggle(sub, "Show Distance", Settings.Missile_Dist, function(v) Settings.Missile_Dist = v end)
        AddSubToggle(sub, "3D Box Frame", Settings.Missile_3DBox, function(v) Settings.Missile_3DBox = v end)
        AddColorPicker(sub, "Missile Color", Settings.Missile_Color, function(c)
            Settings.Missile_Color = c
        end)
    end
)

-- TRACERS
CreateAccordionBlock(VisualsPage, "Tracers (Lines)", Settings.Tracers,
    function(v) Settings.Tracers = v end,
    function(sub)
        AddSubToggle(sub, "Origin: Top of Screen", Settings.TracerOrigin == "Top", function(v)
            Settings.TracerOrigin = v and "Top" or "Bottom"
        end)
    end
)

local WorldBlock = CreateSectionBlock(VisualsPage, "World Settings")
AddSubToggle(WorldBlock, "Fullbright", Settings.Fullbright, function(v) Settings.Fullbright = v end)
AddSubToggle(WorldBlock, "No Fog", Settings.NoFog, function(v) Settings.NoFog = v end)

-- ==================== COMBAT PAGE ====================
local OperatorBlock = CreateSectionBlock(CombatPage, "Operator Aimbot (Target: Players)")
AddSubToggle(OperatorBlock, "Enable Operator Aimbot", Settings.Operator_Aimbot, function(v) Settings.Operator_Aimbot = v end)

local DefenderBlock = CreateSectionBlock(CombatPage, "Defender Aimbot (Target: Missiles/Drones)")
AddSubToggle(DefenderBlock, "Enable Defender Aimbot", Settings.Defender_Aimbot, function(v) Settings.Defender_Aimbot = v end)

local FOVBlock = CreateSectionBlock(CombatPage, "FOV Settings")
AddSubToggle(FOVBlock, "Show FOV Circle", Settings.Draw_FOV, function(v) Settings.Draw_FOV = v end)
AddSlider(FOVBlock, "FOV Radius", 30, 400, Settings.FOV_Radius, function(val) Settings.FOV_Radius = val end)

-- ==================== CORE LOGIC ====================
local Cache = {}
local Camera = Workspace.CurrentCamera
local ESP3DParent = Workspace

local function GetOrCreateESP(instance, targetPart, sizeVec)
    if Cache[instance] then
        local data = Cache[instance]
        if targetPart and data.Box.Adornee ~= targetPart then
            data.Box.Adornee = targetPart
            data.BB.Adornee = targetPart
        end
        if sizeVec then
            data.Size = sizeVec
        end
        return data
    end

    local box = Instance.new("SelectionBox")
    box.Name = "NH_3DBox"
    box.LineThickness = 0.1
    box.Adornee = targetPart
    box.Parent = ESP3DParent

    local bb = Instance.new("BillboardGui")
    bb.Name = "NH_Billboard"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = targetPart
    bb.Parent = ScreenGui

    local txt = Instance.new("TextLabel", bb)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 14
    txt.TextStrokeTransparency = 0.2

    local line = nil
    if DrawingLib and DrawingLib.new then
        pcall(function()
            line = DrawingLib.new("Line")
            line.Thickness = 1.5
            line.Visible = false
        end)
    end

    local data = { Box = box, BB = bb, Text = txt, Line = line, Size = sizeVec or Vector3.new(4, 5, 4) }
    Cache[instance] = data
    return data
end

local function GetRoleColor(player)
    local teamName = player.Team and player.Team.Name:lower() or ""
    local roleAttr = player:GetAttribute("Role")
    local roleStr = type(roleAttr) == "string" and roleAttr:lower() or ""

    if teamName:find("defender") or teamName:find("защитник") or roleStr:find("защитник") then
        return Settings.Color_Defender, "Defender"
    elseif teamName:find("operator") or teamName:find("оператор") or roleStr:find("оператор") then
        return Settings.Color_Operator, "Operator"
    else
        return Settings.Color_Civilian, "Civilian"
    end
end

local function GetScreenPos(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function GetMainPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

-- Классификация объектов
local function ClassifyObject(obj)
    local name = obj.Name:lower()
    local isMissile = name:find("missile") or name:find("rocket") or name:find("shahed") or name:find("ракет")
    local isDrone = name:find("drone") or name:find("uav") or name:find("quadcopter") or name:find("дрон") or name:find("бпла")
    local isVehicle = obj:FindFirstChildOfClass("VehicleSeat") or name:find("pantsir") or name:find("car") or name:find("truck") or name:find("aa") or name:find("пво") or name:find("танк") or name:find("tank")

    if isMissile then return "missile" end
    if isDrone then return "drone" end
    if isVehicle then return "vehicle" end
    return nil
end

-- Размер 3D-бокса по габаритам объекта
local function GetBoxSize(obj)
    if obj:IsA("Model") then
        local ok, size = pcall(function() return obj:GetExtentsSize() end)
        if ok and size then
            return size + Vector3.new(1, 1, 1)
        end
    elseif obj:IsA("BasePart") then
        return obj.Size + Vector3.new(0.5, 0.5, 0.5)
    end
    return Vector3.new(6, 6, 6)
end

-- Кэш объектов мира
local CachedObjects = {}
local function UpdateObjectCache()
    if not (Settings.Vehicle_ESP or Settings.Drone_ESP or Settings.Missile_ESP or Settings.Defender_Aimbot) then
        table.clear(CachedObjects)
        return
    end

    table.clear(CachedObjects)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local cls = ClassifyObject(obj)
            if cls then
                table.insert(CachedObjects, obj)
            else
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Model") or child:IsA("BasePart") then
                        if ClassifyObject(child) then
                            table.insert(CachedObjects, child)
                        end
                    end
                end
            end        end
    end
end

task.spawn(function()
    while true do
        UpdateObjectCache()
        task.wait(1.5)
    end
end)

local function GetClosestTargetInFOV(mode)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDistance = nil, Settings.FOV_Radius

    if mode == "Operator" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local screenPos, onScreen = GetScreenPos(hrp.Position)
                    if onScreen then
                        local dist = (screenPos - center).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closest = hrp
                        end
                    end
                end
            end
        end
    elseif mode == "Defender" then
        for _, obj in ipairs(CachedObjects) do
            local cls = ClassifyObject(obj)
            if cls == "missile" or cls == "drone" then
                local part = GetMainPart(obj)
                if part then
                    local screenPos, onScreen = GetScreenPos(part.Position)
                    if onScreen then
                        local dist = (screenPos - center).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closest = part
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Применение размера 3D-бокса (через SizeHandleAdornment не работает с SelectionBox,
-- поэтому используем BoxHandleAdornment в связке)
local function ApplyBoxSize(data, sizeVec, color)
    -- SelectionBox всегда плотно облегает Adornee, поэтому для управления размером
    -- используем BoxHandleAdornment, который можно масштабировать
    if not data.BoxHandle then
        local bha = Instance.new("BoxHandleAdornment")
        bha.Name = "NH_BoxHandle"
        bha.AlwaysOnTop = true
        bha.ZIndex = 10
        bha.Transparency = 0.6
        bha.Adornee = data.Box.Adornee
        bha.Parent = ESP3DParent
        data.BoxHandle = bha
    end
    data.BoxHandle.Size = sizeVec
    data.BoxHandle.Color3 = color
    data.BoxHandle.Adornee = data.Box.Adornee
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    if Camera.ViewportSize.X < 1 or Camera.ViewportSize.Y < 1 then return end

    if FOVCircle then
        FOVCircle.Visible = Settings.Draw_FOV
        FOVCircle.Radius = Settings.FOV_Radius
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = OrigBrightness
        Lighting.GlobalShadows = OrigGlobalShadows
    end

    if Settings.NoFog then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = OrigFogEnd
    end

    -- Очистка мёртвого кэша
    local toRemove = {}
    for inst, data in pairs(Cache) do
        if not inst or not inst.Parent then
            if data.Box then data.Box:Destroy() end
            if data.BB then data.BB:Destroy() end
            if data.BoxHandle then data.BoxHandle:Destroy() end
            if data.Line then
                pcall(function() data.Line.Visible = false end)
                pcall(function() data.Line:Remove() end)
                data.Line = nil
            end
            table.insert(toRemove, inst)
        else
            data.Box.Visible = false
            if data.BoxHandle then data.BoxHandle.Visible = false end
            data.BB.Enabled = false
            if data.Line then data.Line.Visible = false end
        end
    end
    for _, inst in ipairs(toRemove) do
        Cache[inst] = nil
    end

    -- 1. Players ESP
    if Settings.Player_ESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local esp = GetOrCreateESP(char, hrp)
                    local color, roleName = GetRoleColor(player)

                    esp.Box.Visible = Settings.Player_3DBox
                    esp.Box.Color3 = color

                    esp.BB.Enabled = true
                    esp.Text.TextColor3 = color

                    local str = ""
                    if Settings.Player_Nick then
                        str = str .. player.Name .. " [" .. roleName .. "]\n"
                    else
                        str = str .. "[" .. roleName .. "]\n"
                    end
                    if Settings.Player_Dist and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                        str = str .. dist .. "m"
                    end
                    esp.Text.Text = str

                    if Settings.Tracers and esp.Line then
                        local screenPos, onScreen = GetScreenPos(hrp.Position)
                        if onScreen then
                            esp.Line.Visible = true
                            esp.Line.Color = color
                            esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Settings.TracerOrigin == "Top" and 0 or Camera.ViewportSize.Y)
                            esp.Line.To = screenPos
                        end
                    end
                end
            end
        end
    end

    -- 2. Vehicles / Drones / Missiles ESP
    if Settings.Vehicle_ESP or Settings.Drone_ESP or Settings.Missile_ESP then
        for _, obj in ipairs(CachedObjects) do
            if obj and obj.Parent then
                local cls = ClassifyObject(obj)
                if cls then
                    local enabled = (cls == "vehicle" and Settings.Vehicle_ESP)
                                 or (cls == "drone" and Settings.Drone_ESP)
                                 or (cls == "missile" and Settings.Missile_ESP)

                    if enabled then
                        local primaryPart = GetMainPart(obj)
                        if primaryPart then
                            local esp = GetOrCreateESP(obj, primaryPart)

                            local color, showName, showDist, show3D, showSpeed
                            if cls == "vehicle" then
                                color = Settings.Vehicle_Color
                                showName = Settings.Vehicle_Name
                                showDist = Settings.Vehicle_Dist
                                show3D = Settings.Vehicle_3DBox
                                showSpeed = Settings.Vehicle_Speed
                            elseif cls == "drone" then
                                color = Settings.Drone_Color
                                showName = Settings.Drone_Name
                                showDist = Settings.Drone_Dist
                                show3D = Settings.Drone_3DBox
                                showSpeed = false
                            else
                                color = Settings.Missile_Color
                                showName = Settings.Missile_Name
                                showDist = Settings.Missile_Dist
                                show3D = Settings.Missile_3DBox
                                showSpeed = false
                            end

                            esp.Box.Visible = show3D
                            esp.Box.Color3 = color

                            -- Применяем 3D-бокс правильного размера
                            if show3D then
                                local sizeVec = GetBoxSize(obj)
                                ApplyBoxSize(esp, sizeVec, color)
                                if esp.BoxHandle then esp.BoxHandle.Visible = true end
                            else
                                if esp.BoxHandle then esp.BoxHandle.Visible = false end
                            end

                            esp.BB.Enabled = true
                            esp.Text.TextColor3 = color

                            local str = ""
                            if showName then
                                str = str .. obj.Name .. "\n"
                            end
                            if showSpeed and primaryPart then
                                local speed = math.floor(primaryPart.AssemblyLinearVelocity.Magnitude * 3.6)
                                str = str .. "Speed: " .. speed .. " km/h\n"
                            end
                            if showDist and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - primaryPart.Position).Magnitude)
                                str = str .. dist .. "m"
                            end
                            if str == "" then
                                str = cls:upper()
                            end
                            esp.Text.Text = str

                            if Settings.Tracers and esp.Line then
                                local screenPos, onScreen = GetScreenPos(primaryPart.Position)
                                if onScreen then
                                    esp.Line.Visible = true
                                    esp.Line.Color = color
                                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Settings.TracerOrigin == "Top" and 0 or Camera.ViewportSize.Y)
                                    esp.Line.To = screenPos
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. Aimbot
    local target = nil
    if Settings.Operator_Aimbot then
        target = GetClosestTargetInFOV("Operator")
    elseif Settings.Defender_Aimbot then
        target = GetClosestTargetInFOV("Defender")
    end

    if target and (target.Position - Camera.CFrame.Position).Magnitude > 0.1 then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end)
