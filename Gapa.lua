-- NurHub - FPS Flick Ultimate (Delta Edition, no Drawing)
-- Жёлтый акцент, кастомная кнопка NurHub с анимацией
-- ВНИМАНИЕ: Использование читов может привести к блокировке аккаунта.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ================== ЦВЕТА NURHUB ==================
local NURHUB_YELLOW = Color3.fromRGB(255, 199, 44)   -- основной жёлтый
local NURHUB_DARK   = Color3.fromRGB(20, 20, 22)     -- тёмный фон
local NURHUB_ACCENT = Color3.fromRGB(255, 220, 90)   -- светлый акцент

-- ================== ПЕРЕМЕННЫЕ ==================
local aimbotEnabled = false
local autoShootEnabled = false
local shootDelay = 0.15
local lastShootTime = 0
local fovEnabled = false
local fovSize = 150
local wallCheckEnabled = true

local espEnabled = false
local chamsEnabled = false
local tracersEnabled = false
local rainbowEnabled = false

local espColor = Color3.fromRGB(255, 0, 0)
local chamsColor = Color3.fromRGB(255, 0, 0)
local tracerColor = Color3.fromRGB(255, 255, 255)

local espObjects = {}
local chamsObjects = {}
local tracerObjects = {}

local godModeEnabled = false
local wallbangEnabled = false
local hue = 0

-- ================== КАСТОМНАЯ КНОПКА NURHUB ==================
local nurGui = Instance.new("ScreenGui")
nurGui.Name = "NurHubUI"
nurGui.IgnoreGuiInset = true
nurGui.ResetOnSpawn = false
nurGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
nurGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

-- Кнопка-логотип (двигается, светится, пульсирует)
local nurButton = Instance.new("TextButton")
nurButton.Name = "NurHubButton"
nurButton.Size = UDim2.fromOffset(180, 60)
nurButton.Position = UDim2.fromOffset(30, 120)
nurButton.BackgroundColor3 = NURHUB_DARK
nurButton.BorderSizePixel = 0
nurButton.Text = ""
nurButton.AutoButtonColor = false
nurButton.Active = true
nurButton.Draggable = false -- тащим вручную, чтобы не конфликтовать
nurButton.Parent = nurGui

local nurCorner = Instance.new("UICorner")
nurCorner.CornerRadius = UDim.new(0, 10)
nurCorner.Parent = nurButton

local nurStroke = Instance.new("UIStroke")
nurStroke.Color = NURHUB_YELLOW
nurStroke.Thickness = 2
nurStroke.Transparency = 0.3
nurStroke.Parent = nurButton

local nurGradient = Instance.new("UIGradient")
nurGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, NURHUB_DARK),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 40))
}
nurGradient.Rotation = 45
nurGradient.Parent = nurButton

-- Иконка NH (жёлтый квадрат с NH)
local nhIcon = Instance.new("Frame")
nhIcon.Size = UDim2.fromOffset(44, 44)
nhIcon.Position = UDim2.fromOffset(8, 8)
nhIcon.BackgroundColor3 = NURHUB_YELLOW
nhIcon.BorderSizePixel = 0
nhIcon.Parent = nurButton

local nhIconCorner = Instance.new("UICorner")
nhIconCorner.CornerRadius = UDim.new(0, 8)
nhIconCorner.Parent = nhIcon

local nhText = Instance.new("TextLabel")
nhText.Size = UDim2.fromScale(1, 1)
nhText.BackgroundTransparency = 1
nhText.Text = "NH"
nhText.Font = Enum.Font.GothamBlack
nhText.TextSize = 20
nhText.TextColor3 = NURHUB_DARK
nhText.Parent = nhIcon

-- Название NurHub
local nurTitle = Instance.new("TextLabel")
nurTitle.Size = UDim2.new(1, -60, 1, 0)
nurTitle.Position = UDim2.fromOffset(56, 0)
nurTitle.BackgroundTransparency = 1
nurTitle.Text = "NurHub"
nurTitle.Font = Enum.Font.GothamBold
nurTitle.TextSize = 22
nurTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
nurTitle.TextXAlignment = Enum.TextXAlignment.Left
nurTitle.Parent = nurButton

local nurSubtitle = Instance.new("TextLabel")
nurSubtitle.Size = UDim2.new(1, -60, 1, 0)
nurSubtitle.Position = UDim2.fromOffset(58, 28)
nurSubtitle.BackgroundTransparency = 1
nurSubtitle.Text = "FPS Flick Ultimate"
nurSubtitle.Font = Enum.Font.Gotham
nurSubtitle.TextSize = 10
nurSubtitle.TextColor3 = NURHUB_YELLOW
nurSubtitle.TextXAlignment = Enum.TextXAlignment.Left
nurSubtitle.Parent = nurButton

-- Пульсация свечения
task.spawn(function()
    while nurButton.Parent do
        local tween1 = TweenService:Create(nurStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Transparency = 0.05, Thickness = 3})
        tween1:Play()
        task.wait(1.2)
        local tween2 = TweenService:Create(nurStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Transparency = 0.5, Thickness = 2})
        tween2:Play()
        task.wait(1.2)
    end
end)

-- Hover-эффект
nurButton.MouseEnter:Connect(function()
    TweenService:Create(nurButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
    TweenService:Create(nhIcon, TweenInfo.new(0.2), {BackgroundColor3 = NURHUB_ACCENT}):Play()
end)
nurButton.MouseLeave:Connect(function()
    TweenService:Create(nurButton, TweenInfo.new(0.2), {BackgroundColor3 = NURHUB_DARK}):Play()
    TweenService:Create(nhIcon, TweenInfo.new(0.2), {BackgroundColor3 = NURHUB_YELLOW}):Play()
end)

-- ================== ПЕРЕТАСКИВАНИЕ КНОПКИ ==================
local dragging = false
local dragStart, startPos

nurButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        -- Отличаем drag от click через маленькую задержку / движение
        dragging = true
        dragStart = input.Position
        startPos = nurButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
            nurButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ================== FOV КРУГ (ScreenGui) ==================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "NurFOV"
fovGui.IgnoreGuiInset = true
fovGui.ResetOnSpawn = false
fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fovGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local fovCircleFrame = Instance.new("Frame")
fovCircleFrame.BackgroundTransparency = 1
fovCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircleFrame.Visible = false
fovCircleFrame.Parent = fovGui

local fovCircleStroke = Instance.new("UIStroke")
fovCircleStroke.Color = NURHUB_YELLOW
fovCircleStroke.Thickness = 2
fovCircleStroke.Parent = fovCircleFrame

local fovCircleCorner = Instance.new("UICorner")
fovCircleCorner.CornerRadius = UDim.new(1, 0)
fovCircleCorner.Parent = fovCircleFrame

local function updateFOVCircle()
    local vs = Camera.ViewportSize
    fovCircleFrame.Size = UDim2.fromOffset(fovSize * 2, fovSize * 2)
    fovCircleFrame.Position = UDim2.fromOffset(vs.X / 2, vs.Y / 2 + 36)
    fovCircleFrame.Visible = fovEnabled and aimbotEnabled
end

-- ================== ESP ==================
local function createESP(player)
    if not player.Character then return end
    if espObjects[player] and espObjects[player].billboard then
        espObjects[player].billboard:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NurESP"
    billboard.Adornee = player.Character:FindFirstChild("HumanoidRootPart")
    billboard.Size = UDim2.fromOffset(60, 100)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = player.Character

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromScale(1, 1)
    frame.Visible = false
    frame.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Color = espColor
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, -0.18, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = player.Name
    nameLabel.Visible = false
    nameLabel.Parent = billboard

    espObjects[player] = espObjects[player] or {}
    espObjects[player].billboard = billboard
    espObjects[player].frame = frame
    espObjects[player].stroke = stroke
    espObjects[player].nameLabel = nameLabel

    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        if espObjects[player] and espObjects[player].billboard then
            espObjects[player].billboard.Adornee = char:FindFirstChild("HumanoidRootPart")
        end
    end)
end

local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
        espObjects[player] = nil
    end
end

-- ================== TRACERS ==================
local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "NurTracers"
tracerGui.IgnoreGuiInset = true
tracerGui.ResetOnSpawn = false
tracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tracerGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local function createTracer(player)
    if tracerObjects[player] and tracerObjects[player].line then
        tracerObjects[player].line:Destroy()
    end
    local line = Instance.new("Frame")
    line.BackgroundColor3 = tracerColor
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Visible = false
    line.ZIndex = 5
    line.Parent = tracerGui
    tracerObjects[player] = { line = line }
end

local function removeTracer(player)
    if tracerObjects[player] then
        if tracerObjects[player].line then tracerObjects[player].line:Destroy() end
        tracerObjects[player] = nil
    end
end

-- ================== AIMBOT ==================
local function isPlayerVisible(targetPart)
    if not wallCheckEnabled then return true end
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = targetPart.Position - rayOrigin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then return result.Instance:IsDescendantOf(targetPart.Parent) end
    return true
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = fovEnabled and fovSize or math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild("Head")
                or player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 and isPlayerVisible(targetPart) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

RunService:BindToRenderStep("NurAimbot", Enum.RenderPriority.Camera.Value - 1, function()
    if not aimbotEnabled then return end
    local target = getClosestPlayerInFOV()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, head.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.3)
        end
    end
end)

-- ================== AUTO SHOOT ==================
local function getTargetUnderCrosshair()
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = Camera.CFrame.LookVector * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player and player ~= LocalPlayer then
                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return player, result.Instance
                end
            end
        end
    end
    return nil
end

local function simulateClick()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

RunService.RenderStepped:Connect(function()
    if not autoShootEnabled then return end
    if tick() - lastShootTime < shootDelay then return end
    local target = getTargetUnderCrosshair()
    if target then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            simulateClick()
            lastShootTime = tick()
        end
    end
end)

-- ================== CHAMS ==================
local function applyChams(player)
    if not player.Character then return end
    if chamsObjects[player] then chamsObjects[player]:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.Name = "NurChams"
    highlight.Adornee = player.Character
    highlight.FillColor = chamsColor
    highlight.OutlineColor = chamsColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character
    chamsObjects[player] = highlight
end

local function removeChams(player)
    if chamsObjects[player] then
        chamsObjects[player]:Destroy()
        chamsObjects[player] = nil
    end
end

-- ================== ОБНОВЛЕНИЕ ВИЗУАЛОВ ==================
RunService.RenderStepped:Connect(function()
    updateFOVCircle()

    if rainbowEnabled then
        hue = (hue + 0.005) % 1
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        espColor = rainbowColor
        chamsColor = rainbowColor
        tracerColor = rainbowColor
    end

    for player, obj in pairs(espObjects) do
        if obj.billboard and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                obj.billboard.Adornee = root
                if espEnabled then
                    obj.frame.Visible = true
                    obj.nameLabel.Visible = true
                    obj.stroke.Color = espColor
                else
                    obj.frame.Visible = false
                    obj.nameLabel.Visible = false
                end
            else
                obj.frame.Visible = false
                obj.nameLabel.Visible = false
            end
        end
    end

    for player, highlight in pairs(chamsObjects) do
        if chamsEnabled then
            highlight.FillColor = chamsColor
            highlight.OutlineColor = chamsColor
            highlight.Enabled = true
        else
            highlight.Enabled = false
        end
    end

    local vs = Camera.ViewportSize
    local originX = vs.X / 2
    local originY = vs.Y + 36

    for player, obj in pairs(tracerObjects) do
        local line = obj.line
        if line then
            if player.Character and player.Character:FindFirstChild("Head") then
                local headPos = player.Character.Head.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                if onScreen and tracersEnabled then
                    local dx = screenPos.X - originX
                    local dy = screenPos.Y - originY
                    local length = math.sqrt(dx * dx + dy * dy)
                    local angle = math.deg(math.atan2(dy, dx))
                    line.Visible = true
                    line.BackgroundColor3 = tracerColor
                    line.Size = UDim2.fromOffset(length, 2)
                    line.Position = UDim2.fromOffset(originX, originY)
                    line.Rotation = angle
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end)

-- ================== GOD MODE ==================
local godConn = nil
local function applyGod(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = 9e9
        hum.Health = 9e9
    end
end

local function enableGodMode()
    if LocalPlayer.Character then applyGod(LocalPlayer.Character) end
    if godConn then godConn:Disconnect() end
    godConn = LocalPlayer.CharacterAdded:Connect(applyGod)
end

local function disableGodMode()
    if godConn then godConn:Disconnect() godConn = nil end
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end

-- ================== ИНИЦИАЛИЗАЦИЯ ==================
local function setupPlayer(player)
    if player == LocalPlayer then return end
    createESP(player)
    createTracer(player)
    if chamsEnabled then applyChams(player) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        createESP(player)
        if chamsEnabled then applyChams(player) end
    end)
end

for _, player in pairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    removeChams(player)
    removeESP(player)
    removeTracer(player)
end)

-- ================== СОЗДАНИЕ МЕНЮ RAYFIELD ==================
local Window = Rayfield:CreateWindow({
    Name = "NurHub",
    LoadingTitle = "NurHub",
    LoadingSubtitle = "FPS Flick Ultimate",
    ConfigurationSaving = {Enabled = true, FolderName = "NurHubConfig", FileName = "config"},
    KeySystem = false
})

-- Скрываем логотип/текст Rayfield в углу меню и красим акцент в жёлтый
task.spawn(function()
    task.wait(0.6) -- даём Rayfield дорисовать UI

    local function recolorAll()
        -- Перекраска всех элементов Rayfield в жёлтый акцент
        local function processGui(root)
            for _, obj in pairs(root:GetDescendants()) do
                -- Скрыть "Rayfield" подпись
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    if obj.Text and (obj.Text == "Rayfield" or obj.Text:lower() == "rayfield") then
                        obj.Visible = false
                    end
                end
                -- Перекраска кнопок/акцентов
                if obj:IsA("Frame") or obj:IsA("TextButton") then
                    local bg = obj.BackgroundColor3
                    -- Ищем элементы с синим акцентом Rayfield (по умолчанию синий ~ Color3.fromRGB(0,140,255))
                    if math.abs(bg.B - bg.R) > 0.3 and bg.B > 0.6 then
                        obj.BackgroundColor3 = NURHUB_YELLOW
                    end
                end
                if obj:IsA("UIStroke") then
                    local c = obj.Color
                    if math.abs(c.B - c.R) > 0.3 and c.B > 0.6 then
                        obj.Color = NURHUB_YELLOW
                    end
                end
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local c = obj.TextColor3
                    if c and math.abs(c.B - c.R) > 0.3 and c.B > 0.6 then
                        obj.TextColor3 = NURHUB_YELLOW
                    end
                end
            end
        end

        local cg = game:GetService("CoreGui")
        for _, gui in pairs(cg:GetChildren()) do
            if gui.Name:lower():find("rayfield") then processGui(gui) end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in pairs(pg:GetChildren()) do
                if gui.Name:lower():find("rayfield") then processGui(gui) end
            end
        end
    end

    recolorAll()
    task.wait(1)
    recolorAll() -- второй проход на случай отложенной отрисовки
end)

-- ================== ПРИВЯЗКА КНОПКИ NURHUB К МЕНЮ ==================
-- Rayfield по умолчанию создаёт свою кнопку. Найдём её и спрячем, а наша кнопка будет открывать/закрывать меню.
local rayfieldHidden = false
local function hideDefaultToggle()
    local cg = game:GetService("CoreGui")
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local roots = {cg}
    if pg then table.insert(roots, pg) end
    for _, root in ipairs(roots) do
        for _, gui in pairs(root:GetChildren()) do
            if gui.Name:lower():find("rayfield") then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("ImageButton") or obj:IsA("TextButton") then
                        -- Стандартная кнопка Rayfield в углу — круглая иконка
                        if obj.Size and obj.Size.X.Offset > 0 and obj.Size.X.Offset < 60
                           and obj.AbsolutePosition.X < 100 and obj.AbsolutePosition.Y < 200 then
                            obj.Visible = false
                        end
                    end
                end
            end
        end
    end
end

task.spawn(function()
    for i = 1, 8 do
        hideDefaultToggle()
        task.wait(0.5)
    end
end)

-- Открытие меню по клику на кнопку NurHub
local menuVisible = true -- Rayfield по умолчанию открыто
nurButton.MouseButton1Click:Connect(function()
    -- Защита от ложного срабатывания при drag
    if dragging then return end

    -- Rayfield: переключаем видимость через перебор CoreGui
    local function toggleRayfield()
        local cg = game:GetService("CoreGui")
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local roots = {cg}
        if pg then table.insert(roots, pg) end
        for _, root in ipairs(roots) do
            for _, gui in pairs(root:GetChildren()) do
                if gui.Name:lower():find("rayfield") then
                    for _, obj in pairs(gui:GetDescendants()) do
                        if obj:IsA("Frame") and obj.Size.X.Offset > 300 then
                            -- Основное окно меню
                            obj.Visible = not obj.Visible
                        end
                    end
                end
            end
        end
    end

    toggleRayfield()

    -- Анимация нажатия
    local origSize = nurButton.Size
    TweenService:Create(nurButton, TweenInfo.new(0.08), {
        Size = UDim2.fromOffset(origSize.X.Offset - 8, origSize.Y.Offset - 4)
    }):Play()
    task.wait(0.08)
    TweenService:Create(nurButton, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = origSize
    }):Play()
end)

-- ================== ВКЛАДКИ МЕНЮ ==================
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
AimbotTab:CreateToggle({
    Name = "Включить Aimbot", CurrentValue = false, Flag = "AimbotToggle",
    Callback = function(value) aimbotEnabled = value updateFOVCircle() end
})
AimbotTab:CreateToggle({
    Name = "Auto Shoot (Авто-выстрел)", CurrentValue = false, Flag = "AutoShootToggle",
    Callback = function(value)
        autoShootEnabled = value
        if value then
            Rayfield:Notify({Title = "NurHub", Content = "Auto Shoot активирован!", Duration = 3, Image = 4483362458})
        end
    end
})
AimbotTab:CreateSlider({
    Name = "Задержка выстрела (сек)", Range = {0.05, 0.5}, Increment = 0.01,
    Suffix = " сек", CurrentValue = 0.15, Flag = "ShootDelaySlider",
    Callback = function(value) shootDelay = value end
})
AimbotTab:CreateToggle({
    Name = "Wall Check (не бить через стены)", CurrentValue = true, Flag = "WallCheckToggle",
    Callback = function(value) wallCheckEnabled = value end
})
AimbotTab:CreateToggle({
    Name = "Показывать FOV круг", CurrentValue = false, Flag = "FOVToggle",
    Callback = function(value) fovEnabled = value updateFOVCircle() end
})
AimbotTab:CreateSlider({
    Name = "Размер FOV", Range = {50, 500}, Increment = 10, Suffix = "px",
    CurrentValue = 150, Flag = "FOVSlider",
    Callback = function(value) fovSize = value updateFOVCircle() end
})

local VisualTab = Window:CreateTab("Визуал", 4483362458)
VisualTab:CreateToggle({
    Name = "ESP (Рамки)", CurrentValue = false, Flag = "ESPToggle",
    Callback = function(value) espEnabled = value end
})
VisualTab:CreateToggle({
    Name = "Chams (Подсветка тела сквозь стены)", CurrentValue = false, Flag = "ChamsToggle",
    Callback = function(value)
        chamsEnabled = value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if value then applyChams(player) else removeChams(player) end
            end
        end
    end
})
VisualTab:CreateToggle({
    Name = "Tracers (Линии до врагов)", CurrentValue = false, Flag = "TracersToggle",
    Callback = function(value) tracersEnabled = value end
})
VisualTab:CreateToggle({
    Name = "🌈 Режим Радуги (Rainbow)", CurrentValue = false, Flag = "RainbowToggle",
    Callback = function(value) rainbowEnabled = value end
})
VisualTab:CreateColorPicker({
    Name = "Цвет ESP", Color = espColor, Flag = "ESPColor",
    Callback = function(color) if not rainbowEnabled then espColor = color end end
})
VisualTab:CreateColorPicker({
    Name = "Цвет Chams", Color = chamsColor, Flag = "ChamsColor",
    Callback = function(color) if not rainbowEnabled then chamsColor = color end end
})
VisualTab:CreateColorPicker({
    Name = "Цвет Линий", Color = tracerColor, Flag = "TracerColor",
    Callback = function(color) if not rainbowEnabled then tracerColor = color end end
})

local CheatTab = Window:CreateTab("Читы", 4483362458)
CheatTab:CreateToggle({
    Name = "God Mode", CurrentValue = false, Flag = "GodToggle",
    Callback = function(value)
        godModeEnabled = value
        if value then enableGodMode() else disableGodMode() end
    end
})
CheatTab:CreateToggle({
    Name = "Стрельба через стены (Wallbang)", CurrentValue = false, Flag = "WallbangToggle",
    Callback = function(value) wallbangEnabled = value end
})

local SkinTab = Window:CreateTab("Скины", 4483362458)
local function applySkin(option)
    if not LocalPlayer.Character then return end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, part in pairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            if option == "Neon Red" then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(255, 0, 0)
            elseif option == "Neon Blue" then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(0, 50, 255)
            elseif option == "Gold" then
                part.Material = Enum.Material.Metal
                part.Color = Color3.fromRGB(255, 215, 0)
            elseif option == "Diamond" then
                part.Material = Enum.Material.Glass
                part.Color = Color3.fromRGB(200, 230, 255)
            elseif option == "Void" then
                part.Material = Enum.Material.ForceField
                part.Color = Color3.fromRGB(25, 0, 50)
            else
                part.Material = Enum.Material.Plastic
                part.Color = Color3.fromRGB(163, 162, 165)
            end
        end
    end
end
SkinTab:CreateDropdown({
    Name = "Выбрать скин (Локально)",
    Options = {"Default", "Neon Red", "Neon Blue", "Gold", "Diamond", "Void"},
    CurrentOption = "Default", Flag = "SkinDropdown",
    Callback = function(option) applySkin(option) end
})

Rayfield:Notify({
   Title = "NurHub загружен",
   Content = "FPS Flick Ultimate готов к работе!",
   Duration = 5,
   Image = 4483362458,
})

print("NurHub - FPS Flick Ultimate успешно запущен!")
