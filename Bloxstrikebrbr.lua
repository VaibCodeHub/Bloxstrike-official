-- T-F BloxStrike | Delta Mobile | ESP + Silent Aim v2
if getgenv().TF_Loaded then getgenv().TF_Loaded:Destroy() end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    ESP = true,
    SilentAim = true,
    FOV = 150,
    TargetPart = "HumanoidRootPart",
    TeamCheck = false,
}

local ESPObjects = {}

-- ========== ESP ==========
local function clearESP(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        ESPObjects[plr] = nil
    end
end

local function applyESP(plr)
    if plr == LocalPlayer then return end
    if ESPObjects[plr] then return end
    local char = plr.Character
    if not char then return end
    ESPObjects[plr] = {}
    
    local hl = Instance.new("Highlight")
    hl.Name = "TF_ESP_HL"
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(255, 60, 60)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = char
    table.insert(ESPObjects[plr], hl)
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local bg = Instance.new("BillboardGui")
        bg.Name = "TF_ESP_BG"
        bg.Adornee = root
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Parent = root
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Text = plr.Name
        label.Parent = bg
        table.insert(ESPObjects[plr], bg)
    end
end

local function onCharacterAdded(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.ESP then applyESP(plr) end
    end)
    if Config.ESP then applyESP(plr) end
end

for _, plr in ipairs(Players:GetPlayers()) do onCharacterAdded(plr) end
Players.PlayerAdded:Connect(function(plr)
    onCharacterAdded(plr)
    plr.CharacterRemoving:Connect(function() clearESP(plr) end)
end)
Players.PlayerRemoving:Connect(clearESP)

-- ========== Silent Aim ==========
local function getClosestTarget()
    local camera = Workspace.CurrentCamera
    local center = camera.ViewportSize / 2
    local best, bestDist = nil, Config.FOV
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Config.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(Config.TargetPart)
        if not part then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = part
        end
    end
    return best
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if Config.SilentAim and checkcaller() == false then
        if self:IsA("Mouse") and (key == "Hit" or key == "Target") then
            local target = getClosestTarget()
            if target then
                if key == "Hit" then return target.CFrame end
                return target
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- ========== Menu ==========
local gui = Instance.new("ScreenGui")
gui.Name = "TF_Menu"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function makeBtn(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 42)
    btn.Position = UDim2.new(0, 20, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = gui
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local espBtn = makeBtn("ESP: ON", 20, function()
    Config.ESP = not Config.ESP
    espBtn.Text = "ESP: " .. (Config.ESP and "ON" or "OFF")
    if Config.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do applyESP(plr) end
    else
        for plr, _ in pairs(ESPObjects) do clearESP(plr) end
    end
end)

local aimBtn = makeBtn("Silent Aim: ON", 72, function()
    Config.SilentAim = not Config.SilentAim
    aimBtn.Text = "Silent Aim: " .. (Config.SilentAim and "ON" or "OFF")
end)

print("[T-F] BloxStrike v2 loaded. Silent Aim now hooks Mouse.Hit/Target.")
