local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local LOCK_KEY = Enum.KeyCode.E
local FOV_RADIUS = 200
local ESP_COLOR = Color3.fromRGB(255, 255, 255)
local AIMBOT_ENABLED = false
local AUTO_SHOOT = true
local killAllActive = false
local forceThirdPerson = false
local antiAimActive = false

local lockedTarget = nil
local espObjects = {}

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Color = ESP_COLOR
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Radius = FOV_RADIUS
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local targetLine = Drawing.new("Line")
targetLine.Visible = false
targetLine.Color = Color3.fromRGB(255,255,255)
targetLine.Thickness = 2

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local spinningImage = Instance.new("ImageLabel", ScreenGui)
spinningImage.Image = "rbxassetid://103453094686890"
spinningImage.Size = UDim2.new(0,150,0,150)
spinningImage.Position = UDim2.new(1,-160,0,10)
spinningImage.BackgroundTransparency = 1

-- Fonction pour détecter si le joueur est un ennemi
local function isEnemy(player)
    return player ~= LocalPlayer and player.Team ~= LocalPlayer.Team
end

local function isTargetTouchable(target)
    if not target or not target.Character then return false end
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    local origin = Camera.CFrame.Position
    local direction = (head.Position - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    if hitPart then
        local mat = hitPart.Material
        return mat == Enum.Material.Wood or mat == Enum.Material.Glass or mat == Enum.Material.Plastic or hitPart:IsDescendantOf(target.Character)
    end
    return true
end

local function getClosestTarget()
    local closest = nil
    local shortestDist = FOV_RADIUS
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) and player.Character and player.Character:FindFirstChild("Head") then
            local headPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(headPos.X, headPos.Y) - screenCenter).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

local function createESP(player)
    if espObjects[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = ESP_COLOR
    box.Thickness = 1
    box.Filled = false

    local nameText = Drawing.new("Text")
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = ESP_COLOR
    nameText.Visible = false

    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Thickness = 3

    local pingText = Drawing.new("Text")
    pingText.Size = 14
    pingText.Center = true
    pingText.Outline = true
    pingText.Color = ESP_COLOR
    pingText.Visible = false

    espObjects[player] = {Box = box, Name = nameText, HealthBar = healthBar, Ping = pingText}
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].Box:Remove()
        espObjects[player].Name:Remove()
        espObjects[player].HealthBar:Remove()
        espObjects[player].Ping:Remove()
        espObjects[player] = nil
    end
end

local function triggerBot(targetPlayer)
    if not AUTO_SHOOT or not targetPlayer or not targetPlayer.Character then return end
    local head = targetPlayer.Character:FindFirstChild("Head")
    if not head then return end
    local character = LocalPlayer.Character
    if not character then return end
    local weapon = character:FindFirstChildOfClass("Tool")
    if weapon then
        if weapon:FindFirstChild("RemoteEvent") then
            weapon.RemoteEvent:FireServer(head.Position)
        else
            weapon:Activate()
        end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        AIMBOT_ENABLED = true
        lockedTarget = getClosestTarget()
    elseif input.KeyCode == LOCK_KEY then
        lockedTarget = getClosestTarget()
    elseif input.KeyCode == Enum.KeyCode.L then
        antiAimActive = true
    elseif input.KeyCode == Enum.KeyCode.T then
        forceThirdPerson = not forceThirdPerson
    elseif input.KeyCode == Enum.KeyCode.Up then
        FOV_RADIUS = math.clamp(FOV_RADIUS + 20,50,600)
    elseif input.KeyCode == Enum.KeyCode.Down then
        FOV_RADIUS = math.clamp(FOV_RADIUS - 20,50,600)
    elseif input.KeyCode == Enum.KeyCode.H then
        killAllActive = not killAllActive
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        AIMBOT_ENABLED = false
        lockedTarget = nil
    elseif input.KeyCode == LOCK_KEY then
        lockedTarget = nil
    elseif input.KeyCode == Enum.KeyCode.L then
        antiAimActive = false
    end
end)

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Radius = FOV_RADIUS

    spinningImage.Rotation = (spinningImage.Rotation + 2) % 360

    if killAllActive then
        for _, target in pairs(Players:GetPlayers()) do
            if isEnemy(target) and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                local head = target.Character:FindFirstChild("Head")
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if head and hrp then
                    hrp.CFrame = CFrame.new(head.Position + Vector3.new(0,2,0))
                    triggerBot(target)
                    task.wait(0.1)
                end
            end
        end
    end

    local closestForLine = getClosestTarget()
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            createESP(player)
            local esp = espObjects[player]
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") then
                local rootPos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen then
                    local scale = 2000 / (rootPos.Z + 1)
                    esp.Box.Size = Vector2.new(30 * scale/50,50 * scale/50)
                    esp.Box.Position = Vector2.new(rootPos.X - esp.Box.Size.X/2, rootPos.Y - esp.Box.Size.Y/2)
                    esp.Box.Color = isTargetTouchable(player) and Color3.fromRGB(148,0,211) or ESP_COLOR
                    esp.Box.Visible = true

                    local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude) or 0
                    esp.Name.Text = player.Name .. " [" .. math.floor(dist) .. "]"
                    esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - esp.Box.Size.Y/2 - 15)
                    esp.Name.Visible = true

                    local healthPercent = math.clamp(char.Humanoid.Health / char.Humanoid.MaxHealth,0,1)
                    esp.HealthBar.From = Vector2.new(rootPos.X - esp.Box.Size.X/2 -5, rootPos.Y + esp.Box.Size.Y/2)
                    esp.HealthBar.To = Vector2.new(rootPos.X - esp.Box.Size.X/2 -5, rootPos.Y + esp.Box.Size.Y/2 - esp.Box.Size.Y*healthPercent)
                    esp.HealthBar.Color = Color3.fromRGB(255*(1-healthPercent),255*healthPercent,0)
                    esp.HealthBar.Visible = true

                    local pingValue = player:FindFirstChild("NetworkPing") and player.NetworkPing.Value or math.random(20,100)
                    esp.Ping.Text = tostring(math.floor(pingValue)) .. "ms"
                    esp.Ping.Position = Vector2.new(rootPos.X, rootPos.Y + esp.Box.Size.Y/2 + 10)
                    esp.Ping.Visible = true

                    if AIMBOT_ENABLED and lockedTarget == player then
                        local headPos,_ = Camera:WorldToViewportPoint(char.Head.Position)
                        local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                        local dist = (Vector2.new(headPos.X, headPos.Y) - screenCenter).Magnitude
                        if dist <= FOV_RADIUS then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, char.Head.Position)
                            triggerBot(player)
                            if char.Humanoid.Health <= 0 then
                                lockedTarget = getClosestTarget()
                            end
                        end
                    end
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.HealthBar.Visible = false
                    esp.Ping.Visible = false
                end
            else
                removeESP(player)
            end
        else
            removeESP(player)
        end
    end

    if closestForLine and closestForLine.Character and closestForLine.Character:FindFirstChild("Head") then
        local headPos, onScreen = Camera:WorldToViewportPoint(closestForLine.Character.Head.Position)
        if onScreen then
            local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            targetLine.From = screenCenter
            targetLine.To = Vector2.new(headPos.X, headPos.Y)
            targetLine.Visible = true
        else
            targetLine.Visible = false
        end
    else
        targetLine.Visible = false
    end

    if forceThirdPerson and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local offset = Vector3.new(0,5,10)
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
    end

    if antiAimActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0,math.rad(20),0)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent ~= LocalPlayer.Character then
                obj.Color = Color3.fromRGB(0,0,0)
            end
        end
    end
end)
