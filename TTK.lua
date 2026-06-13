if game:GetService("CoreGui"):FindFirstChild("MeriadaVisualsV20") then
    game:GetService("CoreGui").MeriadaVisualsV20:Destroy()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Состояния функций
local BoxEnabled = false
local TracersEnabled = false
local NamesEnabled = false
local HealthEnabled = false
local HeadDotEnabled = false
local CrosshairEnabled = true -- По умолчанию включен
local LockWeaponAim = false   -- НОВАЯ ФУНКЦИЯ ДЛЯ ВЫРАВНИВАНИЯ СТВОЛА
local EnemyOnly = false

-- Моды мира
local NoShadows = false
local NoFog = false
local FullbrightEnabled = false

-- Цветовая схема
local COLOR_BOX      = Color3.fromRGB(255, 50, 50)
local COLOR_HP       = Color3.fromRGB(0, 255, 100)
local COLOR_HP_BG    = Color3.fromRGB(40, 40, 40)
local COLOR_HEAD     = Color3.fromRGB(0, 220, 255)
local COLOR_TRACER   = Color3.fromRGB(255, 255, 255)
local COLOR_OUTLINE  = Color3.fromRGB(0, 0, 0)

-- Хранилища объектов
local Storage_Squares        = {}
local Storage_SquaresOutline = {}
local Storage_HPBars         = {}
local Storage_HPBarsBG       = {}
local Storage_Tracers        = {}
local Storage_Texts          = {}
local Storage_Dots           = {}

local CrossHair_H = Drawing.new("Line")
local CrossHair_V = Drawing.new("Line")

local defaultShadows = Lighting.GlobalShadows
local defaultFogStart = Lighting.FogStart
local defaultFogEnd = Lighting.FogEnd
local defaultAmbient = Lighting.Ambient
local defaultOutdoor = Lighting.OutdoorAmbient
local defaultBrightness = Lighting.Brightness
local defaultClock = Lighting.ClockTime

-- ================= ИНТЕРФЕЙС УПРАВЛЕНИЯ (Высота: 390) =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeriadaVisualsV20"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 390)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 1
Frame.Parent = ScreenGui

local function CreateButton(text, yPos, colorMode)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 24)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    if colorMode == "world" then
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    elseif colorMode == "filter" then
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    elseif colorMode == "weapon" then
        btn.BackgroundColor3 = Color3.fromRGB(100, 50, 0) -- Отдельный цвет для оружия
    else
        btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = Frame
    return btn
end

local BoxBtn        = CreateButton("2D BOX + OUTLINE: OFF", 10)
local TracersBtn    = CreateButton("TRACERS: OFF", 38)
local NamesBtn      = CreateButton("NAMES: OFF", 66)
local HealthBtn     = CreateButton("HEALTH (BAR/TXT): OFF", 94)
local HeadDotBtn    = CreateButton("HEAD DOT: OFF", 122)
local CrossBtn      = CreateButton("CUSTOM CROSSHAIR: ON", 150)
local LockWeaponBtn = CreateButton("LOCK WEAPON AIM: OFF", 178, "weapon") -- НАШ ТУМБЛЕР
local EnemyOnlyBtn  = CreateButton("ENEMY ONLY: OFF", 210, "filter")

local ShadowsBtn    = CreateButton("NO SHADOWS: OFF", 245, "world")
local FogBtn        = CreateButton("NO FOG: OFF", 273, "world")
local BrightBtn     = CreateButton("FULLBRIGHT: OFF", 301, "world")

local RemoveBtn     = CreateButton("Remove UI", 355)
RemoveBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)

-- ================= УПРАВЛЕНИЕ ТУМБЛЕРОВ =================
local function ToggleVisual(btn, state, onText, offText, isCustomColor)
    if not isCustomColor then
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    end
    btn.Text = state and onText or offText
end

BoxBtn.MouseButton1Click:Connect(function() BoxEnabled = not BoxEnabled; ToggleVisual(BoxBtn, BoxEnabled, "2D BOX + OUTLINE: ON", "2D BOX + OUTLINE: OFF") end)
TracersBtn.MouseButton1Click:Connect(function() TracersEnabled = not TracersEnabled; ToggleVisual(TracersBtn, TracersEnabled, "TRACERS: ON", "TRACERS: OFF") end)
NamesBtn.MouseButton1Click:Connect(function() NamesEnabled = not NamesEnabled; ToggleVisual(NamesBtn, NamesEnabled, "NAMES: ON", "NAMES: OFF") end)
HealthBtn.MouseButton1Click:Connect(function() HealthEnabled = not HealthEnabled; ToggleVisual(HealthBtn, HealthEnabled, "HEALTH (BAR/TXT): ON", "HEALTH (BAR/TXT): OFF") end)
HeadDotBtn.MouseButton1Click:Connect(function() HeadDotEnabled = not HeadDotEnabled; ToggleVisual(HeadDotBtn, HeadDotEnabled, "HEAD DOT: ON", "HEAD DOT: OFF") end)

CrosshairEnabled = true
CrossBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
CrossBtn.MouseButton1Click:Connect(function() 
    CrosshairEnabled = not CrosshairEnabled
    CrossBtn.BackgroundColor3 = CrosshairEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    ToggleVisual(CrossBtn, CrosshairEnabled, "CUSTOM CROSSHAIR: ON", "CUSTOM CROSSHAIR: OFF", true) 
end)

-- ХЕНДЛЕР СНАПА СТВОЛА (ЧЕРЕЗ ПАМЯТЬ ДВИЖКА)
LockWeaponBtn.MouseButton1Click:Connect(function()
    LockWeaponAim = not LockWeaponAim
    LockWeaponBtn.BackgroundColor3 = LockWeaponAim and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 50, 0)
    ToggleVisual(LockWeaponBtn, LockWeaponAim, "LOCK WEAPON AIM: ON", "LOCK WEAPON AIM: OFF", true)
    
    if LockWeaponAim then
        print("[!] Запуск сканирования конфигураций оружия в памяти...")
    end
end)

EnemyOnlyBtn.MouseButton1Click:Connect(function()
    EnemyOnly = not EnemyOnly
    EnemyOnlyBtn.BackgroundColor3 = EnemyOnly and Color3.fromRGB(0, 120, 150) or Color3.fromRGB(40, 40, 50)
    EnemyOnlyBtn.Text = EnemyOnly and "ENEMY ONLY: ON" or "ENEMY ONLY: OFF"
end)

ShadowsBtn.MouseButton1Click:Connect(function() NoShadows = not NoShadows; ToggleVisual(ShadowsBtn, NoShadows, "NO SHADOWS: ON", "NO SHADOWS: OFF", true); if not NoShadows then Lighting.GlobalShadows = defaultShadows end end)
FogBtn.MouseButton1Click:Connect(function() NoFog = not NoFog; ToggleVisual(FogBtn, NoFog, "NO FOG: ON", "NO FOG: OFF", true); if not NoFog then Lighting.FogStart = defaultFogStart; Lighting.FogEnd = defaultFogEnd end end)
BrightBtn.MouseButton1Click:Connect(function() FullbrightEnabled = not FullbrightEnabled; ToggleVisual(BrightBtn, FullbrightEnabled, "FULLBRIGHT: ON", "FULLBRIGHT: OFF", true); if not FullbrightEnabled then Lighting.Ambient = defaultAmbient; Lighting.OutdoorAmbient = defaultOutdoor; Lighting.Brightness = defaultBrightness; Lighting.ClockTime = defaultClock end end)

local function ClearAllVisuals()
    for p, v in pairs(Storage_Squares) do v:Remove() end
    for p, v in pairs(Storage_SquaresOutline) do v:Remove() end
    for p, v in pairs(Storage_HPBars) do v:Remove() end
    for p, v in pairs(Storage_HPBarsBG) do v:Remove() end
    for p, v in pairs(Storage_Tracers) do v:Remove() end
    for p, v in pairs(Storage_Texts) do v:Remove() end
    for p, v in pairs(Storage_Dots) do v:Remove() end
    CrossHair_H:Remove(); CrossHair_V:Remove()
    Lighting.GlobalShadows = defaultShadows; Lighting.FogStart = defaultFogStart; Lighting.FogEnd = defaultFogEnd
    Lighting.Ambient = defaultAmbient; Lighting.OutdoorAmbient = defaultOutdoor; Lighting.Brightness = defaultBrightness; Lighting.ClockTime = defaultClock
end

RemoveBtn.MouseButton1Click:Connect(function() ClearAllVisuals(); ScreenGui:Destroy() end)

local function GetVisualRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or character:FindFirstChild("Head") or character:FindFirstChildOfClass("BasePart")
end

-- ================= ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ =================
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    if not ScreenGui.Parent then ClearAllVisuals(); renderConnection:Disconnect(); return end

    -- Моды мира
    if NoShadows then Lighting.GlobalShadows = false end
    if NoFog then
        Lighting.FogStart = 999999; Lighting.FogEnd = 999999
        for _, obj in pairs(Lighting:GetChildren()) do if obj:IsA("Atmosphere") then obj.Density = 0 end end
    end
    if FullbrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3; Lighting.ClockTime = 14
    end

    -- УЛЬТИМАТИВНЫЙ ФИКС СВОБОДНОЙ КОЛЛИЗИИ (LOCK WEAPON AIM)
    if LockWeaponAim then
        -- 1. Метод жесткой очистки конфигов в памяти (getgc)
        -- Перебираем все таблицы в сборщике мусора Луау, ищем настройки пушек
        local success, gc = pcall(getgc)
        if success and type(gc) == "table" then
            for _, t in pairs(gc) do
                if type(t) == "table" then
                    -- Если находим ключи дедзоны или покачивания ствола — намертво обнуляем их
                    if t.DeadZone or t.Deadzone or t.Sway or t.WeaponSway or t.AimDeadzone or t.FreeAim then
                        t.DeadZone = 0
                        t.Deadzone = 0
                        t.Sway = 0
                        t.AimDeadzone = 0
                        t.FreeAim = false
                        t.FreeAimRadius = 0
                    end
                end
            end
        end

        -- 2. Метод силового выравнивания Viewmodel в Workspace
        -- Ищем кастомные модели в камере или персонаже (MercPOV / Вьюмодель)
        local viewmodel = Camera:FindFirstChildOfClass("Model") or workspace:FindFirstChild("MercPOV")
        if viewmodel and viewmodel:IsA("Model") and viewmodel.PrimaryPart then
            -- Насильно убираем локальное смещение поворота пушки, синхронизируя её с CFrame камеры
            local currentCF = viewmodel:GetPrimaryPartCFrame()
            local targetRotation = Camera.CFrame.Rotation
            viewmodel:SetPrimaryPartCFrame(CFrame.new(currentCF.Position) * targetRotation)
        end
    end

    -- Рендер прицела
    if CrosshairEnabled then
        local camCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local cs = 6
        CrossHair_H.From = Vector2.new(camCenter.X - cs, camCenter.Y); CrossHair_H.To = Vector2.new(camCenter.X + cs, camCenter.Y); CrossHair_H.Color = Color3.fromRGB(0, 255, 255); CrossHair_H.Thickness = 1.5; CrossHair_H.Visible = true
        CrossHair_V.From = Vector2.new(camCenter.X, camCenter.Y - cs); CrossHair_V.To = Vector2.new(camCenter.X, camCenter.Y + cs); CrossHair_V.Color = Color3.fromRGB(0, 255, 255); CrossHair_V.Thickness = 1.5; CrossHair_V.Visible = true
    else
        CrossHair_H.Visible = false; CrossHair_V.Visible = false
    end

    -- Мусоросборник
    for p, v in pairs(Storage_Squares) do if not p or p.Parent == nil then v:Remove(); Storage_Squares[p] = nil end end
    for p, v in pairs(Storage_SquaresOutline) do if not p or p.Parent == nil then v:Remove(); Storage_SquaresOutline[p] = nil end end
    for p, v in pairs(Storage_HPBars) do if not p or p.Parent == nil then v:Remove(); Storage_HPBars[p] = nil end end
    for p, v in pairs(Storage_HPBarsBG) do if not p or p.Parent == nil then v:Remove(); Storage_HPBarsBG[p] = nil end end
    for p, v in pairs(Storage_Tracers) do if not p or p.Parent == nil then v:Remove(); Storage_Tracers[p] = nil end end
    for p, v in pairs(Storage_Texts) do if not p or p.Parent == nil then v:Remove(); Storage_Texts[p] = nil end end
    for p, v in pairs(Storage_Dots) do if not p or p.Parent == nil then v:Remove(); Storage_Dots[p] = nil end end

    local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

    -- Стандартный цикл отрисовки 2D ESP
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local root = GetVisualRoot(char)
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head") or root

            local isAlive = true
            if humanoid and humanoid.Health <= 0 then isAlive = false end
            if EnemyOnly and player.Team == LocalPlayer.Team then isAlive = false end

            if root and isAlive then
                local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.3, 0))
                    local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.8, 0))
                    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
                    local boxWidth = boxHeight / 1.6
                    local boxX = rootPos.X - (boxWidth / 2)
                    local boxY = topPos.Y

                    if BoxEnabled then
                        if not Storage_SquaresOutline[player] then local sqO = Drawing.new("Square"); sqO.Thickness = 2.5; sqO.Filled = false; sqO.Color = COLOR_OUTLINE; Storage_SquaresOutline[player] = sqO end
                        Storage_SquaresOutline[player].Position = Vector2.new(boxX, boxY); Storage_SquaresOutline[player].Size = Vector2.new(boxWidth, boxHeight); Storage_SquaresOutline[player].Visible = true
                        if not Storage_Squares[player] then local sq = Drawing.new("Square"); sq.Thickness = 1; sq.Filled = false; sq.Color = COLOR_BOX; Storage_Squares[player] = sq end
                        Storage_Squares[player].Position = Vector2.new(boxX, boxY); Storage_Squares[player].Size = Vector2.new(boxWidth, boxHeight); Storage_Squares[player].Visible = true
                    else
                        if Storage_Squares[player] then Storage_Squares[player].Visible = false end
                        if Storage_SquaresOutline[player] then Storage_SquaresOutline[player].Visible = false end
                    end

                    if HealthEnabled and humanoid then
                        local barX = boxX - 5
                        if not Storage_HPBarsBG[player] then local bgBar = Drawing.new("Line"); bgBar.Thickness = 2; bgBar.Color = COLOR_HP_BG; Storage_HPBarsBG[player] = bgBar end
                        Storage_HPBarsBG[player].From = Vector2.new(barX, bottomPos.Y); Storage_HPBarsBG[player].To = Vector2.new(barX, boxY); Storage_HPBarsBG[player].Visible = true
                        if not Storage_HPBars[player] then local bar = Drawing.new("Line"); bar.Thickness = 2; bar.Color = COLOR_HP; Storage_HPBars[player] = bar end
                        local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local barHeight = boxHeight * hpPercent
                        Storage_HPBars[player].From = Vector2.new(barX, bottomPos.Y); Storage_HPBars[player].To = Vector2.new(barX, bottomPos.Y - barHeight); Storage_HPBars[player].Visible = true
                    else
                        if Storage_HPBars[player] then Storage_HPBars[player].Visible = false end
                        if Storage_HPBarsBG[player] then Storage_HPBarsBG[player].Visible = false end
                    end

                    if NamesEnabled or (HealthEnabled and humanoid) then
                        if not Storage_Texts[player] then local txt = Drawing.new("Text"); txt.Size = 12; txt.Center = true; txt.Outline = true; Storage_Texts[player] = txt end
                        local infoStr = ""
                        if NamesEnabled then infoStr = infoStr .. player.Name end
                        if HealthEnabled and humanoid then infoStr = infoStr .. (NamesEnabled and " ["..math.floor(humanoid.Health).." HP]" or math.floor(humanoid.Health).." HP") end
                        Storage_Texts[player].Text = infoStr; Storage_Texts[player].Position = Vector2.new(rootPos.X, boxY - 14); Storage_Texts[player].Color = COLOR_HP; Storage_Texts[player].Visible = true
                    else
                        if Storage_Texts[player] then Storage_Texts[player].Visible = false end
                    end

                    if HeadDotEnabled and head then
                        local headScreen, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                        if headOnScreen then
                            if not Storage_Dots[player] then local dot = Drawing.new("Circle"); dot.Radius = 3; dot.Filled = true; dot.Color = COLOR_HEAD; Storage_Dots[player] = dot end
                            Storage_Dots[player].Position = Vector2.new(headScreen.X, headScreen.Y); Storage_Dots[player].Visible = true
                        else
                            if Storage_Dots[player] then Storage_Dots[player].Visible = false end
                        end
                    else
                        if Storage_Dots[player] then Storage_Dots[player].Visible = false end
                    end

                    if TracersEnabled then
                        if not Storage_Tracers[player] then local tr = Drawing.new("Line"); tr.Thickness = 1; tr.Color = COLOR_TRACER; tr.From = screenCenterBottom; Storage_Tracers[player] = tr end
                        Storage_Tracers[player].To = Vector2.new(rootPos.X, bottomPos.Y); Storage_Tracers[player].Visible = true
                    else
                        if Storage_Tracers[player] then Storage_Tracers[player].Visible = false end
                    end
                else
                    if Storage_Squares[player] then Storage_Squares[player].Visible = false end
                    if Storage_SquaresOutline[player] then Storage_SquaresOutline[player].Visible = false end
                    if Storage_HPBars[player] then Storage_HPBars[player].Visible = false end
                    if Storage_HPBarsBG[player] then Storage_HPBarsBG[player].Visible = false end
                    if Storage_Tracers[player] then Storage_Tracers[player].Visible = false end
                    if Storage_Texts[player] then Storage_Texts[player].Visible = false end
                    if Storage_Dots[player] then Storage_Dots[player].Visible = false end
                end
            else
                if Storage_Squares[player] then Storage_Squares[player].Visible = false end
                if Storage_SquaresOutline[player] then Storage_SquaresOutline[player].Visible = false end
                if Storage_HPBars[player] then Storage_HPBars[player].Visible = false end
                if Storage_HPBarsBG[player] then Storage_HPBarsBG[player].Visible = false end
                if Storage_Tracers[player] then Storage_Tracers[player].Visible = false end
                if Storage_Texts[player] then Storage_Texts[player].Visible = false end
                if Storage_Dots[player] then Storage_Dots[player].Visible = false end
            end
        end
    end
end)

print("[+] MERIADA COMBINE V2.0 STABLY LOADED")