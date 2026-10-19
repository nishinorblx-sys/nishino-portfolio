local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local State = require(script.Parent.CombatState)
local Movement = require(script.Parent.CombatMovementGuard)
local Config = require(script.Parent.CombatConfig)
local Resolver = require(script.Parent.CombatResolver)

local AbilityRunner = {}
local registry = {}
local active = {}
local cooldowns = {}
local requests = {}
local heartbeat

local function validNumber(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum
end

local function live(character)
    if not character or not character.Parent then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") or root.Anchored or humanoid.Sit then
        return nil
    end
    return humanoid, root
end

local function requiredWeapon(character, weaponId)
    if not weaponId then
        return true
    end
    local tool = character:FindFirstChildOfClass("Tool")
    return tool ~= nil and CollectionService:HasTag(tool, Config.WeaponTag) and tool:GetAttribute("CombatWeaponId") == weaponId
end

function AbilityRunner.Register(name, definition)
    assert(type(name) == "string" and #name > 0 and #name <= 40)
    assert(type(definition) == "table" and type(definition.Run) == "function")
    assert(validNumber(definition.Cooldown, 0, 180))
    assert(validNumber(definition.Duration, 0.1, 10))
    assert(validNumber(definition.Recovery, 0, 3))
    assert(validNumber(definition.Cost, 0, 100000))
    assert(definition.RequiredWeaponId == nil or type(definition.RequiredWeaponId) == "string")
    if definition.RequiredWeaponId then
        assert(Config.Weapons[definition.RequiredWeaponId] ~= nil)
    end
    if definition.Hit then
        local hit = definition.Hit
        assert(type(hit) == "table")
        assert(validNumber(hit.Damage, 0, 500))
        assert(validNumber(hit.PostureDamage, 0, 500))
        assert(validNumber(hit.Range, 0.1, 30))
        assert(validNumber(hit.ConeDot, -1, 1))
    end
    assert(registry[name] == nil, "Ability already registered")
    local copy = table.clone(definition)
    if definition.Hit then
        copy.Hit = table.freeze(table.clone(definition.Hit))
    end
    registry[name] = table.freeze(copy)
end

local function validContext(context)
    if not context.Active then
        return false
    end
    if context.Player.Character ~= context.Character then
        return false
    end
    local humanoid, root = live(context.Character)
    if not humanoid or (root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed and not Movement.IsImpulseAuthorized(context.Character, os.clock())) then
        return false
    end
    if not requiredWeapon(context.Character, context.Definition.RequiredWeaponId) then
        return false
    end
    local now = os.clock()
    if not State.IsAbilityCurrent(context.Character, context.Token, now) then
        return false
    end
    return State.UpdateMovement(context.Character, now)
end

local function finish(context, completed, reason)
    if not context.Active then
        return
    end
    context.Active = false
    if active[context.Player] == context then
        active[context.Player] = nil
    end
    for _, connection in ipairs(context.Connections) do
        connection:Disconnect()
    end
    table.clear(context.Connections)
    for thread in pairs(context.Tasks) do
        if coroutine.status(thread) == "suspended" then
            pcall(task.cancel, thread)
        end
    end
    table.clear(context.Tasks)
    for index = #context.Cleanup, 1, -1 do
        local ok, err = pcall(context.Cleanup[index], completed, reason)
        if not ok then
            warn("Ability cleanup failed:", err)
        end
    end
    table.clear(context.Cleanup)
    State.EndAbility(context.Character, context.Token, os.clock(), context.Definition.Recovery)
    if not context.Committed then
        State.RefundEssence(context.Character, context.Definition.Cost)
    end
end

local Context = {}
Context.__index = Context

function Context:IsCurrent()
    return validContext(self) and os.clock() <= self.Deadline
end

function Context:Commit()
    if self.Committed then
        return false
    end
    if not self:IsCurrent() then
        return false
    end
    self.Committed = true
    local playerCooldowns = cooldowns[self.Player]
    playerCooldowns[self.Name] = os.clock() + self.Definition.Cooldown
    return true
end

function Context:OnCleanup(callback)
    assert(type(callback) == "function")
    if not self.Active then
        pcall(callback, false, "Already finished")
        return
    end
    self.Cleanup[#self.Cleanup + 1] = callback
end

function Context:Connect(signal, callback)
    assert(type(callback) == "function")
    if not self.Active then
        return nil
    end
    local connection = signal:Connect(function(...)
        if not self:IsCurrent() then
            return
        end
        local ok, err = pcall(callback, self, ...)
        if not ok then
            warn("Ability event callback failed:", err)
            self:Cancel("Callback error")
        end
    end)
    self.Connections[#self.Connections + 1] = connection
    return connection
end

function Context:After(delaySeconds, callback)
    assert(validNumber(delaySeconds, 0, self.Definition.Duration))
    assert(type(callback) == "function")
    if not self.Active then
        return
    end
    local thread
    thread = task.delay(delaySeconds, function()
        self.Tasks[thread] = nil
        if not self:IsCurrent() then
            return
        end
        local ok, err = pcall(callback, self)
        if not ok then
            warn("Ability delayed callback failed:", err)
            self:Cancel("Callback error")
        end
    end)
    self.Tasks[thread] = true
end

function Context:OpenHitWindow(duration)
    if not self.Committed or not self:IsCurrent() or not validNumber(duration, 0.05, 0.5) then
        return false
    end
    return State.OpenAbilityWindow(self.Character, self.Token, os.clock(), duration)
end

function Context:Hit(target)
    if not self.Committed or not self:IsCurrent() or not self.Definition.Hit or not State.IsActive(self.Character, os.clock()) then
        return "Invalid", 0
    end
    if typeof(target) ~= "Instance" or not target:IsA("Model") or target == self.Character then
        return "Invalid", 0
    end
    local attackerRoot = self.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    if not attackerRoot or not attackerRoot:IsA("BasePart") or not targetRoot or not targetRoot:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return "Invalid", 0
    end
    local hit = self.Definition.Hit
    local offset = targetRoot.Position - attackerRoot.Position
    local distance = offset.Magnitude
    if distance > hit.Range or distance < 0.05 or attackerRoot.CFrame.LookVector:Dot(offset.Unit) < hit.ConeDot then
        return "OutOfRange", 0
    end
    if self.HitTargets[target] then
        return "Duplicate", 0
    end
    local raycast = RaycastParams.new()
    raycast.FilterType = Enum.RaycastFilterType.Exclude
    raycast.FilterDescendantsInstances = { self.Character }
    raycast.IgnoreWater = true
    local result = Workspace:Raycast(attackerRoot.Position, offset, raycast)
    if result and not result.Instance:IsDescendantOf(target) then
        return "Obstructed", 0
    end
    local outcome, dealt = Resolver.Apply(self.Character, target, attackerRoot, targetRoot, humanoid, hit, os.clock())
    if outcome ~= "Forbidden" and outcome ~= "Invalid" then
        self.HitTargets[target] = true
    end
    return outcome, dealt
end

function Context:Complete()
    if not self.Committed then
        self:Cancel("No commit")
        return false
    end
    if not self:IsCurrent() then
        self:Cancel("Interrupted")
        return false
    end
    finish(self, true, "Completed")
    return true
end

function Context:Cancel(reason)
    finish(self, false, reason or "Cancelled")
end

local function poll()
    for _, context in pairs(active) do
        if not context:IsCurrent() then
            context:Cancel("Interrupted")
        end
    end
    if next(active) == nil and heartbeat then
        heartbeat:Disconnect()
        heartbeat = nil
    end
end

function AbilityRunner.Execute(player, name)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return false, "Invalid player"
    end
    if type(name) ~= "string" or #name > 40 then
        return false, "Invalid ability"
    end
    local definition = registry[name]
    if not definition then
        return false, "Unknown ability"
    end
    local now = os.clock()
    if now - (requests[player] or -math.huge) < 0.075 then
        return false, "Rate limited"
    end
    requests[player] = now
    local character = player.Character
    local humanoid = live(character)
    if not humanoid or not requiredWeapon(character, definition.RequiredWeaponId) then
        return false, "Unavailable"
    end
    local playerCooldowns = cooldowns[player]
    if not playerCooldowns then
        playerCooldowns = {}
        cooldowns[player] = playerCooldowns
    end
    if now < (playerCooldowns[name] or 0) then
        return false, "Cooldown"
    end
    if active[player] then
        return false, "Already executing"
    end
    local token, reason = State.BeginAbility(character, definition.Duration, definition.Cost, now)
    if not token then
        return false, reason
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not State.UpdateMovement(character, now) then
        State.EndAbility(character, token, now, 0)
        State.RefundEssence(character, definition.Cost)
        return false, "Movement invalid"
    end
    local context = setmetatable({
        Player = player,
        Character = character,
        Name = name,
        Definition = definition,
        Token = token,
        Deadline = now + definition.Duration,
        Active = true,
        Committed = false,
        Cleanup = {},
        Connections = {},
        Tasks = {},
        HitTargets = {},
    }, Context)
    active[player] = context
    context.Connections[#context.Connections + 1] = humanoid.Died:Connect(function()
        context:Cancel("Died")
    end)
    context.Connections[#context.Connections + 1] = player.CharacterRemoving:Connect(function(removed)
        if removed == character then
            context:Cancel("Respawn")
        end
    end)
    for _, attribute in ipairs({ "Stunned", "Knocked", "Dodging", "Blocking" }) do
        context.Connections[#context.Connections + 1] = character:GetAttributeChangedSignal(attribute):Connect(function()
            if not context:IsCurrent() then
                context:Cancel("Status changed")
            end
        end)
    end
    if not heartbeat then
        heartbeat = RunService.Heartbeat:Connect(poll)
    end
    local ok, err = pcall(definition.Run, context)
    if not ok then
        warn("Ability initialization failed:", name, err)
        context:Cancel("Initialization error")
        return false, "Execution failed"
    end
    if not context.Committed then
        context:Cancel("No commit")
        return false, "Activation not committed"
    end
    return true, context
end

function AbilityRunner.Cancel(player, reason)
    local context = active[player]
    if context then
        context:Cancel(reason)
    end
end

function AbilityRunner.GetRemaining(player, name)
    local playerCooldowns = cooldowns[player]
    return math.max(0, ((playerCooldowns and playerCooldowns[name]) or 0) - os.clock())
end

Players.PlayerRemoving:Connect(function(player)
    AbilityRunner.Cancel(player, "Player left")
    cooldowns[player] = nil
    requests[player] = nil
end)

return AbilityRunner
