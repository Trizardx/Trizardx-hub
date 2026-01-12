local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local DIRECTIONAL_ENABLED = true
local LINES_ENABLED = true

local LINE_DISTANCE = 30

local COLORS = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(60, 255, 60),
    Color3.fromRGB(60, 160, 255),
    Color3.fromRGB(255, 255, 60),
    Color3.fromRGB(255, 60, 255),
    Color3.fromRGB(255, 160, 60),
}

local tracked = {}
local colorIndex = 1

local function nextColor()
    local c = COLORS[colorIndex]
    colorIndex += 1
    if colorIndex > #COLORS then
        colorIndex = 1
    end
    return c
end

local function isEnemy(player)
    if not LocalPlayer.Team or not player.Team then
        return player ~= LocalPlayer
    end
    return player.Team ~= LocalPlayer.Team
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.P then
        DIRECTIONAL_ENABLED = not DIRECTIONAL_ENABLED
    elseif input.KeyCode == Enum.KeyCode.L then
        LINES_ENABLED = not LINES_ENABLED
        for _, data in pairs(tracked) do
            if data.beam then
                data.beam.Enabled = LINES_ENABLED
            end
        end
    end
end)

local wasOnGround = true
local locked = false
local storedLook

RunService.RenderStepped:Connect(function()
    if not DIRECTIONAL_ENABLED then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    local onGround = hum.FloorMaterial ~= Enum.Material.Air

    if onGround then
        wasOnGround = true
        locked = false

        local camLook = Camera.CFrame.LookVector
        local look = Vector3.new(camLook.X, 0, camLook.Z)
        if look.Magnitude > 0.05 then
            storedLook = look.Unit
        end
        return
    end

    if wasOnGround and not locked then
        wasOnGround = false
        locked = true

        if storedLook then
            root.CFrame = CFrame.lookAt(
                root.Position,
                root.Position + storedLook
            )
        end
    end
end)

local function clearPlayer(player)
    local data = tracked[player]
    if data then
        if data.beam then data.beam:Destroy() end
        if data.a0 then data.a0:Destroy() end
        if data.a1 then data.a1:Destroy() end
        tracked[player] = nil
    end
end

local function setupPlayer(player)
    if player == LocalPlayer then return end

    local function onCharacter(char)
        clearPlayer(player)
        if not isEnemy(player) then return end

        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        local a0 = Instance.new("Attachment", root)
        local a1 = Instance.new("Attachment", root)

        local beam = Instance.new("Beam")
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.FaceCamera = true
        beam.LightEmission = 1
        beam.Width0 = 0.35
        beam.Width1 = 0.2
        beam.Color = ColorSequence.new(nextColor())
        beam.Enabled = LINES_ENABLED
        beam.Parent = root

        tracked[player] = {
            root = root,
            a0 = a0,
            a1 = a1,
            beam = beam
        }
    end

    if player.Character then
        onCharacter(player.Character)
    end

    player.CharacterAdded:Connect(onCharacter)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    clearPlayer(player)
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        clearPlayer(p)
        setupPlayer(p)
    end
end)

RunService.RenderStepped:Connect(function()
    if not LINES_ENABLED then return end

    for player, data in pairs(tracked) do
        if not isEnemy(player) then
            clearPlayer(player)
        else
            local root = data.root
            if root and root.Parent then
                data.a1.WorldPosition =
                    root.Position + (root.CFrame.LookVector * LINE_DISTANCE)
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end
