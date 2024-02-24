if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Nebula = {}
setmetatable(Nebula, {
    __index = function(self, key)
        if game:GetService(key) ~= nil then
            return game:GetService(key)
        end
    end
})

Nebula.LocalPlayer = Nebula.Players.LocalPlayer
Nebula.Camera = Nebula.Workspace.CurrentCamera
Nebula.Mouse = Nebula.LocalPlayer:GetMouse()
Nebula.F = {}
Nebula.L = {}

Nebula.__cache = {
    ["Root"] = {},
    ["Character"] = {},
    ["Humanoid"] = {}
}

function Nebula.F:Character(Player)
    Player = Player or Nebula.LocalPlayer
    if Nebula.__cache["Character"][Player.Name] then
        local Cache = Nebula.__cache["Character"][Player.Name]
        if Cache ~= nil and Cache.Parent ~= nil then
            return Nebula.__cache["Character"][Player.Name]
        end
    end

    local Character = Player.Character or Player.CharacterAdded:Wait()
    Nebula.__cache["Character"][Player.Name] = Character

    return Character
end

function Nebula.F:Root(Player)
    Player = Player or Nebula.LocalPlayer
    if Nebula.__cache["Root"][Player.Name] then
        local Cache = Nebula.__cache["Root"][Player.Name]
        if Cache ~= nil and Cache.Parent ~= nil then
            return Nebula.__cache["Root"][Player.Name]
        end
    end

    local Root = Nebula.F:Character(Player):WaitForChild("HumanoidRootPart", 1)
    Nebula.__cache["Root"][Player.Name] = Root

    return Root
end

function Nebula.F:Humanoid(Player)
    Player = Player or Nebula.LocalPlayer
    if Nebula.__cache["Humanoid"][Player.Name] then
        local Cache = Nebula.__cache["Humanoid"][Player.Name]
        if Cache ~= nil and Cache.Parent ~= nil then
            return Nebula.__cache["Humanoid"][Player.Name]
        end
    end

    local Root = Nebula.F:Character(Player):WaitForChild("Humanoid", 1)
    Nebula.__cache["Humanoid"][Player.Name] = Root

    return Root
end

Nebula.F.GetClosest = function(self, teamcheck, friendcheck, wallcheck, mode, fov, range, onscreencheck, maxparts)
    teamcheck = teamcheck or false
    friendcheck = friendcheck or false
    wallcheck = wallcheck or false
    mode = mode or "character"
    fov = fov or 200
    range = range or math.huge
    onscreencheck = onscreencheck or false

    local Closest, Lowest = nil, math.huge
    for i, v in pairs(Nebula.Players:GetPlayers()) do
        if v ~= Nebula.LocalPlayer then
            local CanContinue = true

            if teamcheck and Nebula.LocalPlayer.Team == v.Team then
                CanContinue = false
            end

            if friendcheck and Nebula.LocalPlayer:IsFriendsWith(v.UserId) and CanContinue then
                CanContinue = false
            end

            if wallcheck and CanContinue then
                local Character = Nebula.F:Character(v)
                local Character2 = Nebula.F:Character()
                local Head = Character:FindFirstChild("Head")

                local Obstructing = Nebula.Camera:GetPartsObscuringTarget(
                    {Nebula.Camera.CFrame.Position, Head.Position}, {Character, Character2})

                if Obstructing and #Obstructing > maxparts then
                    CanContinue = false
                end
            end

            if onscreencheck and CanContinue then
                local Character = Nebula.F:Character(v)
                local Head = Character:FindFirstChild("Head")
                local Vector, InViewport = Nebula.Camera:WorldToViewportPoint(Head.Position)

                if not InViewport then
                    CanContinue = false
                end
            end

            if CanContinue then
                pcall(function()
                    local Root = Nebula.F:Root(v)
                    local Humanoid = Nebula.F:Humanoid(v)

                    if Humanoid.Health ~= 0 then
                        if mode == "character" then
                            local Root2 = Nebula.F:Root()
                            local Mag = (Root.Position - Root2.Position).Magnitude

                            if Mag < Lowest and (Mag < range or Mag == range) then
                                Lowest = Mag
                                Closest = v
                            end
                        else
                            local Position, InViewport = Nebula.Camera:WorldToViewportPoint(Root.Position)
                            local Mouse = Vector2.new(Nebula.Mouse.X, Nebula.Mouse.Y + 36)
                            Position = Vector2.new(Position.X, Position.Y)
                            local Mag = (Position - Mouse).Magnitude

                            if Mag < Lowest and (Mag < fov or Mag == fov) then
                                Lowest = Mag
                                Closest = v
                            end
                        end
                    end
                end)
            end
        end
    end

    return Closest
end

function Nebula.L:CreateLoop(Function, StartCallback, EndCallback)
    local Loop = {}
    Loop.Loop = nil
    Loop.Enabled = false
    Loop.StartCallback = StartCallBack or function()
    end
    Loop.EndCallback = EndCallback or function()
    end
    Loop.Toggle = function(self)
        if self.Enabled and self.Loop then
            self.Loop:Disconnect()
            self.Loop = nil
            self.Enabled = false
            self.EndCallback()
        elseif not self.Enabled and not self.Loop then
            self.StartCallback()
            self.Enabled = true
            self.Loop = Nebula.RunService.RenderStepped:Connect(Function)
        end
    end

    return Loop
end

getgenv().Settings = {
    Aimbot = {
        Enabled = false,
        Range = 1000,
        FOV = 200,
        ClosestMethod = "cursor",
        WallCheck = false,
        FriendCheck = false,
        TeamCheck = false,
        OnScreenCheck = false,
        MaxParts = 4,
        UseFOV = false,
        FOVCircle = nil,
        AimingMethod = "snap",
        SmoothSpeed = 400,
        MagPrediction = false,
        AimAt = "Head",
        ShowLockOn = false,
        Tracer = nil,
        Tweens = {},
        Offset = {
            X = 0,
            Y = 0
        }
    },
    TriggerBot = {
        Enabled = false,
        WallCheck = false,
        FriendCheck = false,
        TeamCheck = false,
        Delay = 0,
        RandomDelay = false,
        RandomCap = 1,
        RandomMin = 0
    }
}

local Holding = false
Nebula.UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

Nebula.UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

local function CreateFOV()
    local Circle = Drawing.new("Circle")
    Circle.Radius = Settings.Aimbot.FOV
    Circle.Thickness = 1
    Circle.NumSides = 32
    Circle.Color = Color3.fromRGB(255, 255, 255)
    Settings.Aimbot.FOVCircle = Circle
end

local function DestroyFOV()
    if Settings.Aimbot.FOVCircle then
        Settings.Aimbot.FOVCircle:Destroy()
        Settings.Aimbot.FOVCircle = nil
    end
end

local function UpdateFOV()
    if not Settings.Aimbot.UseFOV then
        if Settings.Aimbot.FOVCircle then
            DestroyFOV()
            return
        end
    end
    if not Settings.Aimbot.FOVCircle then
        CreateFOV()
    end

    local Circle = Settings.Aimbot.FOVCircle
    Circle.Position = Vector2.new(Nebula.Mouse.X, Nebula.Mouse.Y + 36)
    Circle.Radius = Settings.Aimbot.FOV

    if Settings.Aimbot.ShowLockOn then
        if not Settings.Aimbot.Tracer then
            Settings.Aimbot.Tracer = Drawing.new("Line")
            Settings.Aimbot.Tracer = Color3.fromRGB(255, 255, 255)
        end

        local Closest = Nebula.F:GetClosest(Settings.Aimbot.TeamCheck, Settings.Aimbot.FriendCheck,
            Settings.Aimbot.WallCheck, Settings.Aimbot.ClosestMethod, Settings.Aimbot.FOV, Settings.Aimbot.Range,
            Settings.Aimbot.OnScreenCheck)

        Nebula.ESP:UpdateTracer(Settings.Aimbot.Tracer, Vector2.new(Nebula.Mouse.X, Nebula.Mouse.Y + 36), Closest)
    end
end

local function CleanUp(KeepTracer)
    for i, v in pairs(Settings.Aimbot.Tweens) do
        v:Cancel()
        v:Destroy()
        v = nil
    end

    if Settings.Aimbot.Tracer and not KeepTracer then
        Settings.Aimbot.Tracer:Destroy()
    end
end

local function Aimbot()
    if not Settings.Aimbot.Enabled then
        return
    end

    local Closest = Nebula.F:GetClosest(Settings.Aimbot.TeamCheck, Settings.Aimbot.FriendCheck,
        Settings.Aimbot.WallCheck, Settings.Aimbot.ClosestMethod, Settings.Aimbot.FOV, Settings.Aimbot.Range,
        Settings.Aimbot.OnScreenCheck, Settings.Aimbot.MaxParts)

    if Closest then
        if Holding then
            local Target = Closest.Character:FindFirstChild(Settings.Aimbot.AimAt)
            local AimAt = Target.Position

            if Settings.Aimbot.MagPrediction then
                AimAt = AimAt + Target.Velocity / (Nebula.F:Root().Position - Target.Position).Magnitude
            end

            AimAt = AimAt + Vector3.new(Settings.Aimbot.Offset.X, Settings.Aimbot.Offset.Y, 0)

            if Settings.Aimbot.AimingMethod:lower():match("snap") then
                Nebula.Camera.CFrame = CFrame.new(Nebula.Camera.CFrame.Position, AimAt)
            else
                local Delay = (Nebula.Camera.CFrame.Position - AimAt).Magnitude
                local Tween = Nebula.Tween:Create(Nebula.Camera, TweenInfo.new(Delay / Settings.Aimbot.SmoothSpeed), {
                    CFrame = CFrame.new(Nebula.Camera.CFrame.Position, AimAt)
                })

                Tween:Play()
                table.insert(Tween, Settings.Aimbot.Tweens)
            end
        else
            CleanUp(true)
        end
    else
        CleanUp(false)
    end
end

local function TriggerBot()
    if not Settings.TriggerBot.Enabled then
        return
    end

    local Closest = Nebula.F:GetClosest(Settings.TriggerBot.TeamCheck, Settings.TriggerBot.FriendCheck,
        Settings.TriggerBot.WallCheck, "cursor", 100, 1000, true)

    if Closest then
        local Target = Nebula.Mouse.Target
        if Target:IsDescendantOf(Closest.Character) then
            task.wait((Settings.TriggerBot.RandomDelay and
                          math.random(Settings.TriggerBot.RandomMin, Settings.TriggerBot.RandomCap) or
                          Settings.TriggerBot.Delay))
            if Target:IsDescendantOf(Closest.Character) then
                mouse1click()
            end
        end
    end
end

local TriggerBotLoop = Nebula.L:CreateLoop(TriggerBot)
local AimbotLoop = Nebula.L:CreateLoop(Aimbot, function()
end, CleanUp)
local FOVLoop = Nebula.L:CreateLoop(UpdateFOV, CreateFOV, DestroyFOV)

FOVLoop:Toggle()
AimbotLoop:Toggle()
TriggerBotLoop:Toggle()

return {Settings = Settings, Nebula = Nebula}
