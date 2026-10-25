-- ==========================================
-- [ 통합 ] Linoria Hub v3 Premium | 크로스헤어 간격/스핀/애니메이션 + 우측 정확한 내 대미지 힛로그 (블럭 현상 제거본)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local playerScripts = Player.PlayerScripts
local controllers = playerScripts.Controllers
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Remove duplicate GUIs
for _, v in pairs(PlayerGui:GetChildren()) do
    if v.Name == "LuminousPureHub" or v.Name == "HoNyang💩FOV" or v.Name == "VoidSpamGui" or v.Name == "HoNyangMeleeHub" or v.Name == "HoNyangRageUI" or v.Name == "HoNyangSilentFOV" or v.Name == "HoNyangCustomUI" then
        v:Destroy()
    end
end

-- 내가 최근에 공격했는지 체크하는 변수 및 헬스 트래킹
local lastAttackTime = 0
local playerHealths = {}

local function trackPlayerHealth(plr)
    if plr == Player then return end
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            playerHealths[plr] = hum.Health
            hum.HealthChanged:Connect(function(newHp)
                local oldHp = playerHealths[plr] or newHp
                local diff = oldHp - newHp
                if diff > 0 and getgenv().HitLogEnabled and (tick() - lastAttackTime < 0.3) then
                    addHitLog(plr.Name, math.floor(diff))
                end
                playerHealths[plr] = newHp
            end)
        end
    end
    plr.CharacterAdded:Connect(onChar)
    if plr.Character then onChar(plr.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do trackPlayerHealth(p) end
Players.PlayerAdded:Connect(trackPlayerHealth)

-- Spawn protection tracker (for invincibility skip)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        player:SetAttribute("SpawnTime", tick())
    end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        player:SetAttribute("SpawnTime", tick())
    end)
    if player.Character then
        player:SetAttribute("SpawnTime", tick())
    end
end

-- 1. Load Linoria Library
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Honyang Hub v3 Premium | Mobile Compatible - Elite Edition',
    Center = true,
    AutoShow = true,
})

-- 2. Integrate existing skin changer and logic
local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end

local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
local DataController = require(controllers:WaitForChild("PlayerDataController", 10))

local equipped, favorites = {}, {}
local constructingWeapon, viewingProfile = nil, nil
local lastUsedWeapon = nil

local function cloneCosmetic(name, cosmeticType, options)
    local base = CosmeticLibrary.Cosmetics[name]
    if not base then return nil end
    local data = {}
    for key, value in pairs(base) do data[key] = value end
    data.Name = name
    data.Type = data.Type or cosmeticType
    data.Seed = data.Seed or math.random(1, 1000000)
    if EnumLibrary then
        local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
        if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
    end
    if options then
        if options.inverted ~= nil then data.Inverted = options.inverted end
        if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
    end
    return data
end

local saveFile = "unlockall/config.json"
local function saveConfig()
    if not writefile then return end
    pcall(function()
        local config = {equipped = {}, favorites = favorites}
        for weapon, cosmetics in pairs(equipped) do
            config.equipped[weapon] = {}
            for cosmeticType, cosmeticData in pairs(cosmetics) do
                if cosmeticData and cosmeticData.Name then
                    config.equipped[weapon][cosmeticType] = {
                        name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                    }
                end
            end
        end
        makefolder("unlockall")
        writefile(saveFile, HttpService:JSONEncode(config))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(saveFile) then return end
    pcall(function()
        local config = HttpService:JSONDecode(readfile(saveFile))
        if config.equipped then
            for weapon, cosmetics in pairs(config.equipped) do
                equipped[weapon] = {}
                for cosmeticType, cosmeticData in pairs(cosmetics) do
                    local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                    if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                end
            end
        end
        favorites = config.favorites or {}
    end)
end

local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic then
        local cType = cosmetic.Type
        if cType == "Skin" or cType == "Charm" or cType == "Dance" or cType == "Emote" or cType == "Wrap" or cType == "Wrapping" or name:lower():find("charm") or name:lower():find("dance") or name:lower():find("emote") or name:lower():find("wrap") then
            return true
        end
    end
    return originalOwnsCosmetic(self, inventory, name, weapon)
end

CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

local originalGet = DataController.Get
DataController.Get = function(self, key)
    local data = originalGet(self, key)
    if key == "CosmeticInventory" then
        local proxy = {}
        if data then for k, v in pairs(data) do 
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            if cosmetic then proxy[k] = v end
        end end
        return setmetatable(proxy, {__index = function(t, k)
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            if cosmetic then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = data and table.clone(data) or {}
        for weapon, favs in pairs(favorites) do
            result[weapon] = result[weapon] or {}
            for name, isFav in pairs(favs) do 
                result[weapon][name] = isFav
            end
        end
        return result
    end
    return data
end

local originalGetWeaponData = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = originalGetWeaponData(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    if equipped[weaponName] then
        for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do 
            merged[cosmeticType] = cosmeticData
        end
    end
    return merged
end

local FighterController
pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

if hookmetamethod then
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local dataRemotes = remotes and remotes:FindFirstChild("Data")
    local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
    local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
    local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
    local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
    local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
        local args = {...}
        
        if useItemRemote and self == useItemRemote then
            lastAttackTime = tick()
            local objectID = args[1]
            if FighterController then
                pcall(function()
                    local fighter = FighterController:GetFighter(Player)
                    if fighter and fighter.Items then
                        for _, item in pairs(fighter.Items) do
                            if item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name break end
                        end
                    end
                end)
            end
        end
        
        if self == equipRemote then
            local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
            
            if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                local inventory = originalGet(DataController, "CosmeticInventory")
                if inventory and rawget(inventory, cosmeticName) then 
                    return oldNamecall(self, ...) 
                end
            end
            
            if cosmeticType == "Dance" or cosmeticType == "Emote" or (cosmeticName and (cosmeticName:lower():find("dance") or cosmeticName:lower():find("emote"))) then
                equipped.Dances = equipped.Dances or {}
                if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                    equipped.Dances[cosmeticType] = nil
                else
                    local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                    if cloned then equipped.Dances[cosmeticType] = cloned end
                end
                task.defer(function()
                    pcall(function() DataController.CurrentData:Replicate("CosmeticInventory") end)
                    task.wait(0.1)
                    saveConfig()
                end)
                return
            end
            
            equipped[weaponName] = equipped[weaponName] or {}
            if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                equipped[weaponName][cosmeticType] = nil
                if not next(equipped[weaponName]) then equipped[weaponName] = nil end
            else
                local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                if cloned then equipped[weaponName][cosmeticType] = cloned end
            end
            
            task.defer(function()
                pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                task.wait(0.1)
                saveConfig()
            end)
            return
        end
        
        if self == favoriteRemote then
            local wName, cName, isFav = args[1], args[2], args[3]
            local cosmetic = CosmeticLibrary.Cosmetics[cName]
            if cosmetic then
                favorites[wName] = favorites[wName] or {}
                favorites[wName][cName] = isFav or nil
                saveConfig()
                task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
            end
            return
        end
        
        return oldNamecall(self, ...)
    end)
end

local ClientItem
pcall(function() ClientItem = require(playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

if ClientItem and ClientItem._CreateViewModel then
    local originalCreateViewModel = ClientItem._CreateViewModel
    ClientItem._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
        constructingWeapon = (weaponPlayer == Player) and weaponName or nil
        
        if weaponPlayer == Player and equipped[weaponName] and viewmodelRef then
            local dataKey = self:ToEnum("Data")
            local targetTable = viewmodelRef[dataKey] or viewmodelRef.Data
            
            if targetTable then
                if equipped[weaponName].Skin then
                    targetTable[self:ToEnum("Skin") or "Skin"] = equipped[weaponName].Skin
                    targetTable[self:ToEnum("Name") or "Name"] = equipped[weaponName].Skin.Name
                end
                if equipped[weaponName].Charm then
                    targetTable[self:ToEnum("Charm") or "Charm"] = equipped[weaponName].Charm
                end
                if equipped[weaponName].Wrap then
                    targetTable[self:ToEnum("Wrap") or "Wrap"] = equipped[weaponName].Wrap
                end
            end
        end
        
        local result = originalCreateViewModel(self, viewmodelRef)
        constructingWeapon = nil
        return result
    end
end

local viewModelModule = playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if viewModelModule then
    local ClientViewModel = require(viewModelModule)
    
    if ClientViewModel.GetCharm then
        local originalGetCharmFunc = ClientViewModel.GetCharm
        ClientViewModel.GetCharm = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and weaponPlayer == Player and equipped[weaponName] and equipped[weaponName].Charm then
                return equipped[weaponName].Charm
            end
            return originalGetCharmFunc(self)
        end
    end
    
    if ClientViewModel.GetWrap then
        local originalGetWrapFunc = ClientViewModel.GetWrap
        ClientViewModel.GetWrap = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and weaponPlayer == Player and equipped[weaponName] and equipped[weaponName].Wrap then
                return equipped[weaponName].Wrap
            end
            return originalGetWrapFunc(self)
        end
    end

    local originalNew = ClientViewModel.new
    ClientViewModel.new = function(replicatedData, clientItem)
        local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = constructingWeapon or clientItem.Name
        if weaponPlayer == Player and equipped[weaponName] then
            local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
            local dataKey = ReplicatedClass:ToEnum("Data")
            replicatedData[dataKey] = replicatedData[dataKey] or {}
            
            local cosmetics = equipped[weaponName]
            if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
            if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
            if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
        end
        
        local result = originalNew(replicatedData, clientItem)
        
        if weaponPlayer == Player and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
            result:_UpdateWrap()
            task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
        end
        return result
    end
end

ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
    if not weaponData then return nil end
    local weaponName = weaponData.Name
    local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == Player and equipped[weaponName] and equipped[weaponName].Skin)
    if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
        local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
        if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
    end
    return nil
end

local EmoteController
pcall(function() 
    EmoteController = require(controllers:WaitForChild("EmoteController", 10))
    if EmoteController and EmoteController.GetEmotes then
        local originalGetEmotes = EmoteController.GetEmotes
        EmoteController.GetEmotes = function(self)
            local emotes = originalGetEmotes(self)
            for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then
                    if not emotes[name] then
                        emotes[name] = { Name = name, Type = cosmetic.Type, ObjectID = cosmetic.ObjectID, Enum = cosmetic.Enum }
                    end
                end
            end
            return emotes
        end
    end
end)

pcall(function()
    local ViewProfile = require(playerScripts.Modules.Pages.ViewProfile)
    if ViewProfile and ViewProfile.Fetch then
        local originalFetch = ViewProfile.Fetch
        ViewProfile.Fetch = function(self, targetPlayer)
            viewingProfile = targetPlayer
            return originalFetch(self, targetPlayer)
        end
    end
end)

loadConfig()

-- ============================================================================
-- DEVICE SPOOFER
-- ============================================================================
getgenv().DeviceSpooferEnabled = getgenv().DeviceSpooferEnabled or false
getgenv().SpoofedDeviceMode = getgenv().SpoofedDeviceMode or "MouseKeyboard"

local function normalizeDeviceMode(mode)
    if not mode then return "MouseKeyboard" end
    local m = tostring(mode):lower():gsub("%s+", "")
    if m == "vr" then return "VR" end
    if m == "touch" or m == "mobile" then return "Touch" end
    if m == "gamepad" or m == "controller" or m == "console" then return "Gamepad" end
    if m == "mousekeyboard" or m == "keyboard" or m == "pc" or m == "desktop" then return "MouseKeyboard" end
    return "MouseKeyboard"
end

local function getSetControlsRemote()
    local ok, remote = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local replication = remotes and remotes:FindFirstChild("Replication")
        local fighter = replication and replication:FindFirstChild("Fighter")
        return fighter and fighter:FindFirstChild("SetControls")
    end)
    return ok and remote or nil
end

local function fireDeviceSetControls(mode)
    mode = normalizeDeviceMode(mode or getgenv().SpoofedDeviceMode)
    getgenv().SpoofedDeviceMode = mode
    local remote = getSetControlsRemote()
    if not remote then return false end
    local ok, err = pcall(function()
        remote:FireServer(mode)
    end)
    if not ok then return false end
    return true
end

task.spawn(function()
    local lastMode = nil
    while true do
        task.wait(2.5)
        if getgenv().DeviceSpooferEnabled then
            local mode = normalizeDeviceMode(getgenv().SpoofedDeviceMode)
            if mode ~= lastMode or true then
                fireDeviceSetControls(mode)
                lastMode = mode
            end
        end
    end
end)

Player.CharacterAdded:Connect(function()
    if getgenv().DeviceSpooferEnabled then
        task.wait(1)
        fireDeviceSetControls(getgenv().SpoofedDeviceMode)
    end
end)

-- ============================================================================
-- HIT SOUND SYSTEM
-- ============================================================================
getgenv().HitSoundEnabled = getgenv().HitSoundEnabled ~= false and true or true
getgenv().SelectedHitSound = getgenv().SelectedHitSound or "rust hs"
getgenv().HitSoundVolume = getgenv().HitSoundVolume or 1.0
getgenv().HitSoundPitch = getgenv().HitSoundPitch or 1.0
local _lastHitSoundAt = 0

local hitSoundList = {
    ["rust hs"]       = "rbxassetid://4764109000",
    ["neverlose"]     = "rbxassetid://97643101798871",
    ["sparkle"]       = "rbxassetid://110241936966089",
    ["minecraft hit"] = "rbxassetid://8766809464",
    ["bonk"]          = "rbxassetid://5766898159",
    ["osu"]           = "rbxassetid://7149255551",
    ["among us"]      = "rbxassetid://5700183626",
    ["bruh"]          = "rbxassetid://4578740568",
    ["vine"]          = "rbxassetid://5332680810",
    ["gamesense"]     = "rbxassetid://4817809188",
}

local function playHitSound()
    if not getgenv().HitSoundEnabled then return end
    local now = tick()
    if now - _lastHitSoundAt < 0.05 then return end
    _lastHitSoundAt = now
    local soundId = hitSoundList[getgenv().SelectedHitSound] or hitSoundList["rust hs"]
    if not soundId or soundId == "" then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.Name = "CustomHitSound"
        sound.SoundId = soundId
        sound.Volume = math.clamp(tonumber(getgenv().HitSoundVolume) or 1, 0, 2)
        sound.PlaybackSpeed = math.clamp(tonumber(getgenv().HitSoundPitch) or 1, 0.1, 2)
        sound.Looped = false
        sound.PlayOnRemove = false
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        pcall(function() game:GetService("Debris"):AddItem(sound, 4) end)
    end)
end

task.spawn(function()
    local function hookViewModel(vm)
        if not vm or vm:GetAttribute("HSHooked") then return end
        pcall(function() vm:SetAttribute("HSHooked", true) end)
        vm.ChildAdded:Connect(function(child)
            if not getgenv().HitSoundEnabled then return end
            if child:IsA("Sound") and child.SoundId ~= "rbxassetid://16537449730" then
                pcall(function()
                    local sid = hitSoundList[getgenv().SelectedHitSound] or hitSoundList["rust hs"]
                    child.SoundId = sid
                    child.PlaybackSpeed = math.clamp(tonumber(getgenv().HitSoundPitch) or 1, 0.1, 2)
                    child.Volume = 0
                    local s = Instance.new("Sound")
                    s.SoundId = sid
                    s.PlaybackSpeed = math.clamp(tonumber(getgenv().HitSoundPitch) or 1, 0.1, 2)
                    s.Volume = math.clamp(tonumber(getgenv().HitSoundVolume) or 1, 0, 2)
                    s.Parent = game:GetService("SoundService")
                    s:Play()
                    pcall(function() game:GetService("Debris"):AddItem(s, 4) end)
                end)
            end
        end)
    end

    pcall(function()
        local path = Player.PlayerScripts:FindFirstChild("Modules")
            and Player.PlayerScripts.Modules:FindFirstChild("ClientReplicatedClasses")
            and Player.PlayerScripts.Modules.ClientReplicatedClasses:FindFirstChild("ClientFighter")
            and Player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter:FindFirstChild("ClientItem")
            and Player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
        if path then
            hookViewModel(path)
            path.ChildAdded:Connect(function(ch)
                if ch:IsA("Model") or ch:IsA("Folder") then hookViewModel(ch) end
            end)
        end
    end)
end)

local _origAddHitLog = nil
task.defer(function()
    if type(addHitLog) == "function" then
        local orig = addHitLog
        addHitLog = function(targetName, damage)
            orig(targetName, damage)
            if damage and damage > 0 then pcall(playHitSound) end
        end
    end
end)

-- 3. Linoria Library Tabs and Groupboxes setup
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder('MobileScriptHub')
SaveManager:SetFolder('MobileScriptHub/game')

local Tabs = {
    Legit = Window:AddTab('Legit'),
    Rage = Window:AddTab('Ragebot'),
    Visuals = Window:AddTab('Visuals'),
    Move = Window:AddTab('Move'),
    Teleport = Window:AddTab('Teleport'),
    Emotes = Window:AddTab('Emotes'),
    Skybox = Window:AddTab('Skybox'),
    Spoofer = Window:AddTab('Device Spoofer'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local LegitGroup = Tabs.Legit:AddLeftGroupbox('Combat & Aimbot')
local SilentAimGroup = Tabs.Legit:AddLeftGroupbox('Silent Aim')
local AntiAimGroup = Tabs.Legit:AddRightGroupbox('Anti-Aim')

local VoidSpamGroup = Tabs.Rage:AddLeftGroupbox('Void Spam & Orbit')
local WeaponGroup = Tabs.Rage:AddRightGroupbox('Weapon & Rage Config')

local VisualsGroup = Tabs.Visuals:AddLeftGroupbox('ESP & Map')
local CustomVisGroup = Tabs.Visuals:AddRightGroupbox('Visual Customization')
local MoveGroup = Tabs.Move:AddLeftGroupbox('Movement')
local TeleportGroup = Tabs.Teleport:AddLeftGroupbox('Teleport Options')
local EmotesGroup = Tabs.Emotes:AddLeftGroupbox('Emote Options')
local SkyboxGroup = Tabs.Skybox:AddLeftGroupbox('Skybox Options')

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
local SpooferGroup = Tabs.Spoofer:AddLeftGroupbox('Device Spoofer')
local SpooferInfoGroup = Tabs.Spoofer:AddRightGroupbox('Info')
local HitSoundGroup = Tabs.Visuals:AddLeftGroupbox('Hit Sound')

-- FOV GUIs
local FOV = 150
local FOVGui = Instance.new("ScreenGui", PlayerGui)
FOVGui.Name = "HoNyang💩FOV"
FOVGui.ResetOnSpawn = false

local FOVFrame = Instance.new("Frame", FOVGui)
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, -25)
FOVFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false

local UICorner = Instance.new("UICorner", FOVFrame)
UICorner.CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVFrame)
FOVStroke.Thickness = 1
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
local FOVGradient = Instance.new("UIGradient", FOVFrame)
FOVGradient.Rotation = 45

local silentAimFovRadius = 150
local SilentFOVGui = Instance.new("ScreenGui", PlayerGui)
SilentFOVGui.Name = "HoNyangSilentFOV"
SilentFOVGui.ResetOnSpawn = false

local SilentFOVFrame = Instance.new("Frame", SilentFOVGui)
SilentFOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
SilentFOVFrame.Position = UDim2.new(0.5, 0, 0.5, -25)
SilentFOVFrame.Size = UDim2.new(0, silentAimFovRadius * 2, 0, silentAimFovRadius * 2)
SilentFOVFrame.BackgroundTransparency = 1
SilentFOVFrame.Visible = false

local SilentUICorner = Instance.new("UICorner", SilentFOVFrame)
SilentUICorner.CornerRadius = UDim.new(1, 0)
local SilentFOVStroke = Instance.new("UIStroke", SilentFOVFrame)
SilentFOVStroke.Thickness = 1
SilentFOVStroke.Color = Color3.fromRGB(0, 255, 255)
local SilentFOVGradient = Instance.new("UIGradient", SilentFOVFrame)
SilentFOVGradient.Rotation = 45

-- Custom Crosshair & UI Elements (v3 Premium Style)
local CustomUIGui = Instance.new("ScreenGui", PlayerGui)
CustomUIGui.Name = "HoNyangCustomUI"
CustomUIGui.ResetOnSpawn = false

local CustomCrosshairContainer = Instance.new("Frame", CustomUIGui)
CustomCrosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
CustomCrosshairContainer.Position = UDim2.new(0.5, 0, 0.5, -25)
CustomCrosshairContainer.Size = UDim2.new(0, 100, 0, 100)
CustomCrosshairContainer.BackgroundTransparency = 1
CustomCrosshairContainer.Visible = false

local ccLines = {
    {Name = "Left", Size = UDim2.new(0, 10, 0, 2), BasePos = -15},
    {Name = "Right", Size = UDim2.new(0, 10, 0, 2), BasePos = 5},
    {Name = "Up", Size = UDim2.new(0, 2, 0, 10), BasePos = -15},
    {Name = "Down", Size = UDim2.new(0, 2, 0, 10), BasePos = 5}
}

local ccFrames = {}
local ccData = {}

for i, info in ipairs(ccLines) do
    local line = Instance.new("Frame", CustomCrosshairContainer)
    line.Size = info.Size
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    table.insert(ccFrames, line)
    table.insert(ccData, info)
end

getgenv().CrosshairGap = 5
getgenv().CrosshairSize = 10
local function updateCrosshairLayout()
    local gap = getgenv().CrosshairGap or 5
    local sz = getgenv().CrosshairSize or 10
    
    ccFrames[1].Size = UDim2.new(0, sz, 0, 2)
    ccFrames[1].Position = UDim2.new(0.5, -gap - sz, 0.5, -1)
    
    ccFrames[2].Size = UDim2.new(0, sz, 0, 2)
    ccFrames[2].Position = UDim2.new(0.5, gap, 0.5, -1)
    
    ccFrames[3].Size = UDim2.new(0, 2, 0, sz)
    ccFrames[3].Position = UDim2.new(0.5, -1, 0.5, -gap - sz)
    
    ccFrames[4].Size = UDim2.new(0, 2, 0, sz)
    ccFrames[4].Position = UDim2.new(0.5, -1, 0.5, gap)
end
updateCrosshairLayout()

local RageTextLabel = Instance.new("TextLabel", CustomUIGui)
RageTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
RageTextLabel.Position = UDim2.new(0.5, 0, 0.5, 35)
RageTextLabel.Size = UDim2.new(0, 200, 0, 25)
RageTextLabel.BackgroundTransparency = 1
RageTextLabel.Text = "ragebot.honyang v3"
RageTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RageTextLabel.TextStrokeTransparency = 0
RageTextLabel.Font = Enum.Font.GothamBold
RageTextLabel.TextSize = 13
RageTextLabel.TextXAlignment = Enum.TextXAlignment.Center
RageTextLabel.Visible = false

local HitLogContainer = Instance.new("Frame", CustomUIGui)
HitLogContainer.AnchorPoint = Vector2.new(1, 0.5)
HitLogContainer.Position = UDim2.new(0.98, 0, 0.4, 0)
HitLogContainer.Size = UDim2.new(0, 300, 0, 200)
HitLogContainer.BackgroundTransparency = 1
HitLogContainer.Visible = false

local HitLogList = Instance.new("UIListLayout", HitLogContainer)
HitLogList.SortOrder = Enum.SortOrder.LayoutOrder
HitLogList.VerticalAlignment = Enum.VerticalAlignment.Bottom
HitLogList.HorizontalAlignment = Enum.HorizontalAlignment.Right
HitLogList.Padding = UDim.new(0, 4)

function addHitLog(targetName, damage)
    if not getgenv().HitLogEnabled then return end
    if not damage or damage <= 0 then return end
    
    local msg = string.format("[honyang.ragebot] %s - %d", targetName, damage)
    local lbl = Instance.new("TextLabel", HitLogContainer)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = msg
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Right
    
    pcall(playHitSound)
    
    task.spawn(function()
        task.wait(3.5)
        if lbl then lbl:Destroy() end
    end)
end

local ccAngle = 0
local animTimer = 0
RunService.RenderStepped:Connect(function(dt)
    if not getgenv().CustomCrosshairEnabled then return end
    
    if getgenv().CrosshairSpinEnabled then
        ccAngle = (ccAngle + ((getgenv().CrosshairSpinSpeed or 2) * dt * 50)) % 360
        CustomCrosshairContainer.Rotation = ccAngle
    else
        CustomCrosshairContainer.Rotation = 0
    end

    if getgenv().CrosshairPulseEnabled then
        animTimer = animTimer + (dt * (getgenv().CrosshairPulseSpeed or 3))
        local pulseOffset = math.sin(animTimer) * (getgenv().CrosshairPulseIntensity or 5)
        local baseGap = getgenv().CrosshairGap or 5
        local sz = getgenv().CrosshairSize or 10
        local dynamicGap = math.max(1, baseGap + pulseOffset)
        
        ccFrames[1].Size = UDim2.new(0, sz, 0, 2)
        ccFrames[1].Position = UDim2.new(0.5, -dynamicGap - sz, 0.5, -1)
        ccFrames[2].Size = UDim2.new(0, sz, 0, 2)
        ccFrames[2].Position = UDim2.new(0.5, dynamicGap, 0.5, -1)
        ccFrames[3].Size = UDim2.new(0, 2, 0, sz)
        ccFrames[3].Position = UDim2.new(0.5, -1, 0.5, -dynamicGap - sz)
        ccFrames[4].Size = UDim2.new(0, 2, 0, sz)
        ccFrames[4].Position = UDim2.new(0.5, -1, 0.5, dynamicGap)
    end
end)

-- Legit Groupbox
LegitGroup:AddToggle('AimbotToggle', {
    Text = 'Aimbot (Players & NPCs)',
    Default = false,
    Callback = function(Value)
        getgenv().AimbotEnabled = Value
        FOVFrame.Visible = Value and (getgenv().FOVShowEnabled or false)
    end
})

LegitGroup:AddToggle('WallCheckToggle', {
    Text = 'Wall Check',
    Default = false,
    Callback = function(Value)
        getgenv().WallCheckEnabled = Value
    end
})

LegitGroup:AddSlider('FOVSizeSlider', {
    Text = 'FOV Size',
    Default = 150,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        FOV = Value
        FOVFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
    end
})

LegitGroup:AddToggle('FOVShowToggle', {
    Text = 'Show FOV Circle',
    Default = false,
    Callback = function(Value)
        getgenv().FOVShowEnabled = Value
        FOVFrame.Visible = Value and (getgenv().AimbotEnabled or false)
    end
})

LegitGroup:AddLabel('FOV Color'):AddColorPicker('FOVColorPicker', {
    Default = Color3.fromRGB(255, 140, 0),
    Callback = function(Value)
        FOVStroke.Color = Value
        local h, s, v = Value:ToHSV()
        local darkerColor = Color3.fromHSV(h, math.clamp(s + 0.1, 0, 1), math.clamp(v * 0.7, 0, 1))
        local lighterColor = Color3.fromHSV(h, math.clamp(s - 0.1, 0, 1), math.clamp(v * 1.2, 0, 1))
        FOVGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, darkerColor),
            ColorSequenceKeypoint.new(0.5, Value),
            ColorSequenceKeypoint.new(1, lighterColor)
        })
    end
})

LegitGroup:AddToggle('FOVFillToggle', {
    Text = 'FOV Filled',
    Default = false,
    Callback = function(Value)
        getgenv().FOVFillEnabled = Value
        if Value then
            FOVFrame.BackgroundTransparency = getgenv().FOVFillTransparency or 0.5
        else
            FOVFrame.BackgroundTransparency = 1
        end
    end
})

LegitGroup:AddSlider('FOVFillTransparencySlider', {
    Text = 'Fill Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().FOVFillTransparency = Value
        if getgenv().FOVFillEnabled then
            FOVFrame.BackgroundTransparency = Value
        end
    end
})

LegitGroup:AddSlider('FOVStrokeTransparencySlider', {
    Text = 'Stroke Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        FOVStroke.Transparency = Value
    end
})

LegitGroup:AddToggle('FOVSpinToggle', {
    Text = 'FOV Spin',
    Default = false,
    Callback = function(Value)
        getgenv().FOVSpinEnabled = Value
    end
})

LegitGroup:AddSlider('FOVSpinSpeedSlider', {
    Text = 'FOV Spin Speed',
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        getgenv().FOVSpinSpeed = Value
    end
})

-- Orbit & New Void Spam (Attack Spam to Nearest Target)
getgenv().OrbitEnabled = getgenv().OrbitEnabled or false
getgenv().OrbitRange = getgenv().OrbitRange or 12
getgenv().OrbitDelay = getgenv().OrbitDelay or 0.03
getgenv().OrbitHeight = getgenv().OrbitHeight or 0

getgenv().VoidSpamEnabled = getgenv().VoidSpamEnabled or false
getgenv().VoidSpamAttackLimit = getgenv().VoidSpamAttackLimit or 2
getgenv().VoidSpamSpeed = getgenv().VoidSpamSpeed or 0.1

local orbitAnchorPos = nil
local orbitAngle = 0
local orbitOrigCF = nil
local orbitOrigVel = nil

local function restoreOrbitDesync()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not orbitOrigCF then return end
    hrp.CFrame = orbitOrigCF
    if orbitOrigVel then
        pcall(function() hrp.AssemblyLinearVelocity = orbitOrigVel end)
        pcall(function() hrp.Velocity = orbitOrigVel end)
    end
    orbitOrigCF = nil
    orbitOrigVel = nil
end

pcall(function()
    RunService:BindToRenderStep("honyangOrbitRestore", Enum.RenderPriority.Last.Value, restoreOrbitDesync)
end)
RunService.RenderStepped:Connect(function()
    if orbitOrigCF then restoreOrbitDesync() end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().OrbitEnabled then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and not orbitAnchorPos then
                orbitAnchorPos = hrp.Position
                orbitAngle = 0
            end
        else
            orbitAnchorPos = nil
            orbitAngle = 0
        end
    end
end)

task.spawn(function()
    while true do
        local delay = math.clamp(tonumber(getgenv().OrbitDelay) or 0.03, 0.01, 1)
        task.wait(delay)
        if not getgenv().OrbitEnabled then continue end
        pcall(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if not orbitAnchorPos then
                orbitAnchorPos = hrp.Position
                orbitAngle = 0
            end
            orbitOrigCF = hrp.CFrame
            orbitOrigVel = hrp.AssemblyLinearVelocity or hrp.Velocity

            local range = math.clamp(tonumber(getgenv().OrbitRange) or 12, 1, 200)
            local height = tonumber(getgenv().OrbitHeight) or 0
            orbitAngle = (orbitAngle + 45) % 360
            local rad = math.rad(orbitAngle)
            local ox = math.cos(rad) * range
            local oz = math.sin(rad) * range
            local targetPos = Vector3.new(
                orbitAnchorPos.X + ox,
                orbitAnchorPos.Y + height,
                orbitAnchorPos.Z + oz
            )
            local rotOnly = orbitOrigCF - orbitOrigCF.Position
            hrp.CFrame = CFrame.new(targetPos) * rotOnly
        end)
    end
end)

-- New Void Spam (Attack Spam: 2 seconds / 2 attacks alternation between Head 2 studs above & Back 2 studs behind target)
task.spawn(function()
    local toggleState = false
    local lastToggleTime = 0
    while true do
        local speed = math.clamp(tonumber(getgenv().VoidSpamSpeed) or 0.1, 0.01, 2.0)
        task.wait(speed)
        if not getgenv().VoidSpamEnabled or getgenv().OrbitEnabled then continue end
        
        pcall(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            -- Find closest alive enemy / target recognized by ragebot (using players proximity)
            local closestTargetRoot = nil
            local minD = math.huge
            local myPos = hrp.Position
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local pChar = p.Character
                    local pHum = pChar:FindFirstChildOfClass("Humanoid")
                    local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                    if pHum and pHum.Health > 0 and pRoot then
                        local d = (myPos - pRoot.Position).Magnitude
                        if d < minD then
                            minD = d
                            closestTargetRoot = pRoot
                        end
                    end
                end
            end
            
            if closestTargetRoot then
                local maxAttacks = tonumber(getgenv().VoidSpamAttackLimit) or 2
                if tick() - lastToggleTime >= maxAttacks then
                    lastToggleTime = tick()
                    toggleState = not toggleState
                end
                
                local targetCF
                if toggleState then
                    -- 머리 위 2 스터드
                    targetCF = closestTargetRoot.CFrame + Vector3.new(0, 2, 0)
                else
                    -- 머리 뒤 2 스터드
                    targetCF = closestTargetRoot.CFrame * CFrame.new(0, 0, 2)
                end
                
                local origCF = hrp.CFrame
                hrp.CFrame = targetCF
                task.wait(speed / 2)
                hrp.CFrame = origCF
            end
        end)
    end
end)

VoidSpamGroup:AddToggle('OrbitEnable', {
    Text = 'Orbit (Circle Desync)',
    Default = false,
    Callback = function(val)
        getgenv().OrbitEnabled = val
        if not val then
            orbitAnchorPos = nil
            orbitAngle = 0
        end
        if val then getgenv().VoidSpamEnabled = false end
    end
})

VoidSpamGroup:AddSlider('OrbitStudsSlider', {
    Text = 'Orbit Radius (Studs)',
    Default = 12,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Callback = function(val)
        getgenv().OrbitRange = val
    end
})

VoidSpamGroup:AddSlider('OrbitHeightSlider', {
    Text = 'Orbit Height Offset',
    Default = 0,
    Min = -20,
    Max = 50,
    Rounding = 0,
    Callback = function(val)
        getgenv().OrbitHeight = val
    end
})

VoidSpamGroup:AddSlider('OrbitDelaySlider', {
    Text = 'Orbit Delay',
    Default = 0.03,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(val)
        getgenv().OrbitDelay = tonumber(string.format("%.2f", val))
    end
})

VoidSpamGroup:AddToggle('VoidSpamEnable', {
    Text = 'Void Spam (Attack Teleport)',
    Default = false,
    Callback = function(val)
        getgenv().VoidSpamEnabled = val
        if val then
            getgenv().OrbitEnabled = false
            orbitAnchorPos = nil
        end
    end
})

VoidSpamGroup:AddSlider('VoidSpamAttackLimitSlider', {
    Text = 'Attack Limit (Max 2)',
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(val)
        getgenv().VoidSpamAttackLimit = val
    end
})

VoidSpamGroup:AddSlider('VoidSpamSpeedSlider', {
    Text = 'Void Speed (0.01 - 2)',
    Default = 0.1,
    Min = 0.01,
    Max = 2,
    Rounding = 2,
    Callback = function(val)
        getgenv().VoidSpamSpeed = tonumber(string.format("%.2f", val))
    end
})

-- Silent Aim Groupbox
SilentAimGroup:AddToggle('SilentAimToggle', {
    Text = 'Silent Aim Enabled',
    Default = false,
    Callback = function(Value)
        silentAimEnabled = Value
        SilentFOVFrame.Visible = Value and (silentAimShowEnabled or false)
    end
})

SilentAimGroup:AddToggle('SilentWallCheckToggle', {
    Text = 'Wall Check',
    Default = false,
    Callback = function(Value)
        silentWallCheck = Value
    end
})

SilentAimGroup:AddToggle('AllHeadToggle', {
    Text = 'Hitbox Head Priority',
    Default = false,
    Callback = function(Value)
        allHeadEnabled = Value
    end
})

SilentAimGroup:AddDropdown('SilentAimHitPartDropdown', {
    Values = { 'Head', 'HumanoidRootPart', 'Torso' },
    Default = 'Head',
    Multi = false,
    Text = 'Hit Part',
    Callback = function(Value)
        silentAimHitPart = Value
    end
})

SilentAimGroup:AddSlider('SilentFOVSizeSlider', {
    Text = 'FOV Size',
    Default = 150,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        silentAimFovRadius = Value
        SilentFOVFrame.Size = UDim2.new(0, silentAimFovRadius * 2, 0, silentAimFovRadius * 2)
    end
})

SilentAimGroup:AddToggle('SilentFOVShowToggle', {
    Text = 'Show FOV Circle',
    Default = false,
    Callback = function(Value)
        silentAimShowEnabled = Value
        SilentFOVFrame.Visible = Value and (silentAimEnabled or false)
    end
})

SilentAimGroup:AddLabel('FOV Color'):AddColorPicker('SilentFOVColorPicker', {
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(Value)
        SilentFOVStroke.Color = Value
        local h, s, v = Value:ToHSV()
        local darkerColor = Color3.fromHSV(h, math.clamp(s + 0.1, 0, 1), math.clamp(v * 0.7, 0, 1))
        local lighterColor = Color3.fromHSV(h, math.clamp(s - 0.1, 0, 1), math.clamp(v * 1.2, 0, 1))
        SilentFOVGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, darkerColor),
            ColorSequenceKeypoint.new(0.5, Value),
            ColorSequenceKeypoint.new(1, lighterColor)
        })
    end
})

SilentAimGroup:AddToggle('SilentFOVFillToggle', {
    Text = 'FOV Filled',
    Default = false,
    Callback = function(Value)
        silentAimFOVFillEnabled = Value
        if Value then
            SilentFOVFrame.BackgroundTransparency = silentAimFOVFillTransparency or 0.5
        else
            SilentFOVFrame.BackgroundTransparency = 1
        end
    end
})

SilentAimGroup:AddSlider('SilentFOVFillTransparencySlider', {
    Text = 'Fill Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        silentAimFOVFillTransparency = Value
        if silentAimFOVFillEnabled then
            SilentFOVFrame.BackgroundTransparency = Value
        end
    end
})

SilentAimGroup:AddSlider('SilentFOVStrokeTransparencySlider', {
    Text = 'Stroke Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        SilentFOVStroke.Transparency = Value
    end
})

SilentAimGroup:AddToggle('SilentFOVSpinToggle', {
    Text = 'FOV Spin',
    Default = false,
    Callback = function(Value)
        silentAimFOVSpinEnabled = Value
    end
})

SilentAimGroup:AddSlider('SilentFOVSpinSpeedSpeedSlider', {
    Text = 'FOV Spin Speed',
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        silentAimFOVSpinSpeed = Value
    end
})

local fovCurrentSpin = 0
local silentFovCurrentSpin = 0
RunService.RenderStepped:Connect(function(dt)
    if getgenv().FOVSpinEnabled and getgenv().FOVShowEnabled and getgenv().AimbotEnabled then
        fovCurrentSpin = fovCurrentSpin + ((getgenv().FOVSpinSpeed or 2) * dt * 50)
        FOVFrame.Rotation = fovCurrentSpin
    else
        FOVFrame.Rotation = 0
    end

    if silentAimFOVSpinEnabled and silentAimShowEnabled and silentAimEnabled then
        silentFovCurrentSpin = silentFovCurrentSpin + ((silentAimFOVSpinSpeed or 2) * dt * 50)
        SilentFOVFrame.Rotation = silentFovCurrentSpin
    else
        SilentFOVFrame.Rotation = 0
    end
end)

silentAimEnabled = false
silentWallCheck = false
allHeadEnabled = false
silentAimHitPart = "Head"
silentAimShowEnabled = false
silentAimFOVFillEnabled = false
silentAimFOVFillTransparency = 0.5
silentAimFOVSpinEnabled = false
silentAimFOVSpinSpeed = 2

local LocalPlayer = Players.LocalPlayer

local function is_teammate(player)
    local pTeam = player:GetAttribute("TeamID")
    local lTeam = LocalPlayer:GetAttribute("TeamID")
    if pTeam and lTeam then return pTeam == lTeam end
    return false
end

local function get_character_valid(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") or (tick() - (player:GetAttribute("SpawnTime") or 0) < 1.5) then return false end
    return true
end

local function get_hit_part(char, hitboxName)
    if not char then return nil end
    if allHeadEnabled then
        return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    end
    local partName = string.lower(tostring(hitboxName or "head"))
    if partName == "humanoidrootpart" then
        return char:FindFirstChild("HumanoidRootPart")
    elseif partName == "torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function has_line_of_sight(targetPart, myChar)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local dir = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, Camera }
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, dir, params)
    if not result then return true end
    local model = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    return model == targetPart:FindFirstAncestorOfClass("Model")
end

RunService.Heartbeat:Connect(function()
    silentAimTarget = nil
    local myChar = LocalPlayer.Character
    if (silentAimEnabled or ragebotOrKillAura or ragebotMagicBullet) and myChar then
        local closestDist = math.huge
        local mousePos = UserInputService:GetMouseLocation()
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not is_teammate(player) and get_character_valid(player) then
                local hitPart = get_hit_part(player.Character, (ragebotOrKillAura and "head" or silentAimHitPart))
                if hitPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        local maxFov = (ragebotOrKillAura or ragebotMagicBullet) and 99999 or silentAimFovRadius
                        
                        if screenDist <= maxFov and screenDist < closestDist then
                            if ragebotMagicBullet or (not silentWallCheck) or has_line_of_sight(hitPart, myChar) then
                                closestDist = screenDist
                                silentAimTarget = hitPart
                            end
                        end
                    end
                end
            end
        end
    end
end)

pcall(function()
    if FighterController and FighterController.LocalFighter and FighterController.LocalFighter.GetMouseLocation then
        local LocalFighter = FighterController.LocalFighter
        local oldMouseLoc = LocalFighter.GetMouseLocation
        
        LocalFighter.GetMouseLocation = newcclosure(function(...)
            if silentAimTarget and (silentAimEnabled or ragebotOrKillAura or ragebotMagicBullet) then
                local screenPos = Camera:WorldToScreenPoint(silentAimTarget.Position)
                return Vector2.new(screenPos.X, screenPos.Y)
            end
            return oldMouseLoc(...)
        end)
    end
end)

local originalWeaponValues = {}
LegitGroup:AddToggle('NoCDToggle', {
    Text = 'No Cooldown / Instant Fire',
    Default = false,
    Callback = function(Value)
        getgenv().RivalsNoCD = Value
        if Value then
            task.spawn(function()
                while getgenv().RivalsNoCD do
                    task.wait(2)
                    pcall(function()
                        for _, v in pairs(getgc(true)) do
                            if type(v) == "table" then
                                if rawget(v, "ShootCooldown") and not originalWeaponValues[v] then
                                    originalWeaponValues[v] = {Key = "ShootCooldown", Val = v.ShootCooldown}
                                end
                                if rawget(v, "FireRate") and not originalWeaponValues[v] then
                                    originalWeaponValues[v] = {Key = "FireRate", Val = v.FireRate}
                                end
                                if rawget(v, "Cooldown") and not originalWeaponValues[v] then
                                    originalWeaponValues[v] = {Key = "Cooldown", Val = v.Cooldown}
                                end

                                if rawget(v, "ShootCooldown") then v.ShootCooldown = 0 end
                                if rawget(v, "FireRate") then v.FireRate = 0 end
                                if rawget(v, "Cooldown") then v.Cooldown = 0 end
                            end
                        end
                    end)
                end
            end)
        else
            pcall(function()
                for tbl, info in pairs(originalWeaponValues) do
                    if type(tbl) == "table" and info and info.Key then
                        tbl[info.Key] = info.Val
                    end
                end
                table.clear(originalWeaponValues)
            end)
        end
    end
})

LegitGroup:AddToggle('FastMeleeToggle', {
    Text = 'Fast Melee',
    Default = false,
    Callback = function(Value)
        getgenv().FastMeleeEnabled = Value
    end
})

task.spawn(function()
    while true do
        task.wait(1.5)
        if getgenv().FastMeleeEnabled then
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        if rawget(v, "Cooldown") then v.Cooldown = 0 end
                        if rawget(v, "AttackCooldown") then v.AttackCooldown = 0 end
                        if rawget(v, "SwingCooldown") then v.SwingCooldown = 0 end
                        if rawget(v, "HitCooldown") then v.HitCooldown = 0 end
                        if rawget(v, "Delay") then v.Delay = 0 end
                    end
                end
                
                local char = Player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                            local animName = string.lower(track.Animation.AnimationId)
                            if animName:find("sword") or animName:find("melee") or animName:find("knife") or animName:find("slash") or animName:find("punch") or animName:find("attack") then
                                track:AdjustSpeed(8.0)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

local __repS = cloneref(game:GetService("ReplicatedStorage"))
local __plrs = cloneref(game:GetService("Players"))
local __runS = cloneref(game:GetService("RunService"))
local __ws = cloneref(game:GetService("Workspace"))
local __lplr = __plrs.LocalPlayer
local __util = require(__repS.Modules.Utility)
local __enum = require(__repS.Modules.EnumLibrary)
local __FighterController = require(__lplr.PlayerScripts.Controllers.FighterController)
local __SpectateController = require(__lplr.PlayerScripts.Controllers:WaitForChild("SpectateController"))

getgenv().Config = {
    Enabled = false,
    FireRate = 0.0005,
    WeaponSlot = "Melee",
    ForceEquip = true,
    AutoSwap = false
}

local __slots = { Primary = 1, Secondary = 2, Melee = 3, Swap = "Swap" }
local function __getSlotNumber() 
    local slot = getgenv().Config.WeaponSlot
    if slot == "Swap" then
        return math.random(1, 3)
    end
    return __slots[slot] or 3 
end

task.spawn(function()
    local localFighter = __FighterController.LocalFighter
    while not localFighter do
        task.wait(0.1)
        localFighter = __FighterController.LocalFighter
    end
    pcall(function() 
        if getgenv().Config.ForceEquip and getgenv().Config.WeaponSlot ~= "Swap" then
            localFighter:EquipItem(__getSlotNumber()) 
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(5)
        if not getgenv().Config.Enabled then continue end
        local localFighter = __FighterController.LocalFighter
        if localFighter then
            pcall(function() 
                if getgenv().Config.ForceEquip and getgenv().Config.WeaponSlot ~= "Swap" then
                    localFighter:EquipItem(__getSlotNumber()) 
                elseif getgenv().Config.AutoSwap or getgenv().Config.WeaponSlot == "Swap" then
                    localFighter:EquipItem(math.random(1, 3))
                end
            end)
        end
    end
end)

local __lastFire = 0
local __deflecting = {}
__plrs.PlayerRemoving:Connect(function(player) __deflecting[player] = nil end)

local function __updateDeflection()
    if not __FighterController or not __FighterController.Objects then return end
    for _, fighterObj in __FighterController.Objects do
        local player = fighterObj.Player
        if not player then continue end
        if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
            __deflecting[player] = false
            continue
        end
        local equipped = fighterObj.EquippedItem
        local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
        local isDeflecting = false
        if isKatana then
            isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
        end
        __deflecting[player] = isDeflecting
    end
end

local function __isEnemy(player)
    if player == __lplr then return false end
    local duel = __SpectateController.CurrentDuelSubject
    local localDueler = duel and duel:GetDueler(__lplr)
    local localTeam = localDueler and localDueler:Get("TeamID") or nil
    if localTeam and duel and duel.Duelers then
        for _, dueler in duel.Duelers do
            if dueler.Player == player then
                local team = dueler:Get("TeamID")
                return team ~= localTeam
            end
        end
    end
    local pTeam = player:GetAttribute("TeamID")
    local lTeam = __lplr:GetAttribute("TeamID")
    if pTeam and lTeam then return pTeam ~= lTeam end
    return true
end

local function __isInvincible(player, pChar)
    if not player or not pChar then return true end
    if pChar:FindFirstChildOfClass("ForceField") then return true end
    local st = player:GetAttribute("SpawnTime")
    if st and (tick() - st) < 1.5 then return true end
    local ok, inv = pcall(function() return player:GetAttribute("Invincible") or player:GetAttribute("IsInvincible") end)
    if ok and inv then return true end
    local hum = pChar:FindFirstChildWhichIsA("Humanoid")
    if hum then
        local ok2, s = pcall(function() return hum:GetState() end)
        if ok2 and s == Enum.HumanoidStateType.Dead then return true end
    end
    return false
end

local function __getClosestTarget()
    local char = __lplr.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    local closestPlayer, closestRoot, closestHead = nil, nil, nil
    local closestDist = 500
    for _, player in __plrs:GetPlayers() do
        if not __isEnemy(player) then continue end
        local pChar = player.Character
        if not pChar then continue end
        if __isInvincible(player, pChar) then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestPlayer = player
            closestRoot = pRoot
            closestHead = pHead
        end
    end
    return closestPlayer, closestRoot, closestHead
end

local lastToggleTime = 0
local togglePositionState = false

getgenv().HeadTeleportEnabled = getgenv().HeadTeleportEnabled or false
getgenv().BackTeleportEnabled = getgenv().BackTeleportEnabled or false
getgenv().HeadStuds = 5
getgenv().BackStuds = 3
getgenv().RageSpeed = 0.5

__runS.Heartbeat:Connect(function()
    if not getgenv().MeleeRageBotEnabled then return end
    __updateDeflection()
    local targetPlayer, targetRoot, targetHead = __getClosestTarget()
    local desyncCF = nil
    
    if targetRoot and targetHead then
        local speedLimit = math.clamp(getgenv().RageSpeed or 0.5, 0.01, 10.0)
        
        -- Multi-mode toggle calculation (Head / Back / Both alternating)
        local useHead = getgenv().HeadTeleportEnabled
        local useBack = getgenv().BackTeleportEnabled
        
        local currentOffset = Vector3.zero
        if useHead and useBack then
            if tick() - lastToggleTime >= speedLimit then
                lastToggleTime = tick()
                togglePositionState = not togglePositionState
            end
            if togglePositionState then
                currentOffset = Vector3.new(0, getgenv().HeadStuds, 0)
            else
                currentOffset = Vector3.new(0, 0, -getgenv().BackStuds)
            end
        elseif useHead then
            currentOffset = Vector3.new(0, getgenv().HeadStuds, 0)
        elseif useBack then
            currentOffset = Vector3.new(0, 0, -getgenv().BackStuds)
        end

        if useHead or useBack then
            local desyncPos = (targetRoot.CFrame * CFrame.new(currentOffset)).Position
            desyncCF = CFrame.new(desyncPos)
        end
    end

    if desyncCF and __lplr.Character then
        local myRoot = __lplr.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local oldCF = myRoot.CFrame
            local oldVel = myRoot.Velocity
            local oldRotVel = myRoot.RotVelocity
            myRoot.CFrame = desyncCF
            __runS:BindToRenderStep("__restore", 101, function()
                if myRoot then
                    myRoot.CFrame = oldCF
                    myRoot.Velocity = oldVel
                    myRoot.RotVelocity = oldRotVel
                end
                __runS:UnbindFromRenderStep("__restore")
            end)
        end
    end

    if not targetPlayer or not targetHead or not targetRoot then return end
    if targetPlayer.Character and __isInvincible(targetPlayer, targetPlayer.Character) then return end
    if __deflecting[targetPlayer] then return end
    if not __lplr.Character or not __lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    if not __FighterController or not __FighterController.LocalFighter then return end
    local item = __FighterController.LocalFighter.EquippedItem
    if not item then return end
    if tick() - __lastFire < getgenv().Config.FireRate then return end
    __lastFire = tick()
    local originPos = desyncCF and desyncCF.Position or targetRoot.Position
    local targetPos = targetHead.Position
    local aimCF = CFrame.lookAt(originPos, targetPos)
    local targetCF = targetHead.CFrame
    local randomOffset = Vector3.new((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1)
    local aimedPos = targetPos + randomOffset
    local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = __util:EncodeCFrame(aimCF),
        [utf8.char(1)] = __util:EncodeCFrame(targetCF),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = __util:EncodeCFrame(objSpaceHeadOffset)
    }
    lastAttackTime = tick()
    __repS.Remotes.Replication.Fighter.UseItem:FireServer(item:Get("ObjectID"), __enum:ToEnum("StartShooting"), cameradata, nil)
end)

WeaponGroup:AddToggle('RageBotToggle', {
    Text = 'RageBot (Universal)',
    Default = false,
    Callback = function(Value)
        getgenv().MeleeRageBotEnabled = Value
        getgenv().Config.Enabled = Value
    end
})

WeaponGroup:AddToggle('HeadTeleportToggle', {
    Text = 'Target Head Teleport',
    Default = false,
    Callback = function(Value)
        getgenv().HeadTeleportEnabled = Value
    end
})

WeaponGroup:AddToggle('BackTeleportToggle', {
    Text = 'Target Back Teleport',
    Default = false,
    Callback = function(Value)
        getgenv().BackTeleportEnabled = Value
    end
})

WeaponGroup:AddSlider('HeadStudsSlider', {
    Text = 'Head Studs Offset',
    Default = 5,
    Min = -10,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        getgenv().HeadStuds = Value
    end
})

WeaponGroup:AddSlider('BackStudsSlider', {
    Text = 'Back Studs Offset',
    Default = 3,
    Min = -10,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        getgenv().BackStuds = Value
    end
})

WeaponGroup:AddSlider('RageSpeedSlider', {
    Text = 'Switch Speed (Sec)',
    Default = 0.5,
    Min = 0.01,
    Max = 10.0,
    Rounding = 2,
    Callback = function(Value)
        getgenv().RageSpeed = Value
    end
})

WeaponGroup:AddDropdown('WeaponSlotDropdown', {
    Values = { 'Primary', 'Secondary', 'Melee', 'Swap' },
    Default = 'Melee',
    Multi = false,
    Text = 'Weapon Slot',
    Callback = function(Value)
        getgenv().Config.WeaponSlot = Value
        if Value == "Swap" then
            getgenv().Config.ForceEquip = false
            getgenv().Config.AutoSwap = true
        else
            getgenv().Config.ForceEquip = true
            getgenv().Config.AutoSwap = false
        end
    end
})

AntiAimGroup:AddToggle('AntiAimToggle', {
    Text = 'Anti-Aim Enabled',
    Default = false,
    Callback = function(Value)
        getgenv().AntiAimEnabled = Value
    end
})

AntiAimGroup:AddDropdown('AntiAimModeDropdown', {
    Values = { 'Random', 'Jitter', 'Shooter', 'Spin', 'Freestanding', 'Fake Head' },
    Default = 'Jitter',
    Multi = false,
    Text = 'Anti-Aim Mode',
    Callback = function(Value)
        getgenv().AntiAimMode = Value
    end
})

AntiAimGroup:AddSlider('AntiAimAngleSlider', {
    Text = 'Anti-Aim Angle',
    Default = 180,
    Min = 1,
    Max = 360,
    Rounding = 0,
    Callback = function(Value)
        getgenv().AntiAimAngle = Value
    end
})

RunService:BindToRenderStep("HoNyangAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not getgenv().AimbotEnabled then return end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local nearestTarget = nil
    local shortestDistance = math.huge
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local function isVisible(targetPart)
        if not getgenv().WallCheckEnabled then return true end
        local origin = Camera.CFrame.Position
        local direction = targetPart.Position - origin
        raycastParams.FilterDescendantsInstances = {char, targetPart.Parent}
        local result = workspace:Raycast(origin, direction, raycastParams)
        return result == nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local enemyChar = player.Character
            if enemyChar:FindFirstChildOfClass("ForceField") or (tick() - (player:GetAttribute("SpawnTime") or 0) < 1.5) then continue end
            local humanoid = enemyChar:FindFirstChildOfClass("Humanoid")
            local linkHead = enemyChar:FindFirstChild("Head")
            if humanoid and humanoid.Health > 0 and linkHead then
                local pos, onScreen = Camera:WorldToViewportPoint(linkHead.Position)
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if onScreen and distance <= FOV and distance < shortestDistance and isVisible(linkHead) then
                    shortestDistance = distance
                    nearestTarget = linkHead
                end
            end
        end
    end
    
    if nearestTarget then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, nearestTarget.Position)
    end
end)

VisualsGroup:AddToggle('NameEspToggle', {
    Text = 'Name ESP',
    Default = false,
    Callback = function(Value) getgenv().NameEnabled = Value end
})

VisualsGroup:AddToggle('HealthEspToggle', {
    Text = 'Health Bar ESP',
    Default = false,
    Callback = function(Value) getgenv().HealthEnabled = Value end
})

VisualsGroup:AddToggle('MapTransparencyToggle', {
    Text = 'Map Transparency',
    Default = false,
    Callback = function(Value)
        getgenv().MapTransparency = Value
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local isPlayerPart = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and obj:IsDescendantOf(p.Character) then isPlayerPart = true break end
                end
                if not isPlayerPart then
                    if Value then
                        if not obj:GetAttribute("OriginalTransparency") then obj:SetAttribute("OriginalTransparency", obj.Transparency) end
                        obj.Transparency = 0.6
                    else
                        local orig = obj:GetAttribute("OriginalTransparency")
                        obj.Transparency = orig or 0
                    end
                end
            end
        end
    end
})

VisualsGroup:AddToggle('UnlockAllToggle', {
    Text = 'Unlock All (Skin Changer)',
    Default = false,
    Callback = function(Value)
        if Value then
            pcall(function()
                if getgenv().SkinChangerLoaded then return end
                local scriptString = [=[
local plrs = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = plrs.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local controllers = playerScripts:WaitForChild("Controllers")
local EnumLibrary, CosmeticLibrary, ItemLibrary, DataController
pcall(function() EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10)) end)
pcall(function() CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10)) end)
pcall(function() ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10)) end)
pcall(function() DataController = require(controllers:WaitForChild("PlayerDataController", 10)) end)
if not (CosmeticLibrary and ItemLibrary and DataController) then return end
getgenv().SkinChangerLoaded = true
local equipped, favorites = {}, {}
CosmeticLibrary.OwnsCosmeticNormally = function() return true end
CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end
]=]
                loadstring(scriptString)()
            end)
        end
    end
})

-- Visual Customization Groupbox
CustomVisGroup:AddToggle('CustomCrosshairToggle', {
    Text = 'Enable Custom Crosshair',
    Default = false,
    Callback = function(Value)
        getgenv().CustomCrosshairEnabled = Value
        CustomCrosshairContainer.Visible = Value
    end
})

CustomVisGroup:AddSlider('CrosshairSizeSlider', {
    Text = 'Crosshair Line Length',
    Default = 10,
    Min = 2,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairSize = Value
        updateCrosshairLayout()
    end
})

CustomVisGroup:AddSlider('CrosshairGapSlider', {
    Text = 'Crosshair Gap (Spacing)',
    Default = 5,
    Min = 0,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairGap = Value
        updateCrosshairLayout()
    end
})

CustomVisGroup:AddLabel('Crosshair Color'):AddColorPicker('CrosshairColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        for _, frame in ipairs(ccFrames) do
            frame.BackgroundColor3 = Value
        end
    end
})

CustomVisGroup:AddToggle('CrosshairSpinToggle', {
    Text = 'Crosshair Spin',
    Default = false,
    Callback = function(Value)
        getgenv().CrosshairSpinEnabled = Value
    end
})

CustomVisGroup:AddSlider('CrosshairSpinSpeedSlider', {
    Text = 'Crosshair Spin Speed',
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairSpinSpeed = Value
    end
})

CustomVisGroup:AddToggle('CrosshairPulseToggle', {
    Text = 'Crosshair Pulse (Breathe)',
    Default = false,
    Callback = function(Value)
        getgenv().CrosshairPulseEnabled = Value
    end
})

CustomVisGroup:AddSlider('CrosshairPulseSpeedSlider', {
    Text = 'Pulse Speed',
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        getgenv().CrosshairPulseSpeed = Value
    end
})

CustomVisGroup:AddSlider('CrosshairPulseIntensitySlider', {
    Text = 'Pulse Intensity',
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairPulseIntensity = Value
    end
})

CustomVisGroup:AddToggle('RageTextToggle', {
    Text = 'Show RageBot UI Text',
    Default = false,
    Callback = function(Value)
        getgenv().RageTextEnabled = Value
        RageTextLabel.Visible = Value
    end
})

CustomVisGroup:AddToggle('HitLogToggle', {
    Text = 'Show Hit Damage Log',
    Default = false,
    Callback = function(Value)
        getgenv().HitLogEnabled = Value
        HitLogContainer.Visible = Value
    end
})

local espCounter = 0
RunService.RenderStepped:Connect(function()
    espCounter = (espCounter + 1) % 4
    if espCounter ~= 0 then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local char = p.Character
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            local isAlive = hum and hum.Health > 0
            local highlight = char:FindFirstChild("HoNyangHighlight")
            if (getgenv().NameEnabled or getgenv().HealthEnabled) and isAlive then
                if not highlight then
                    highlight = Instance.new("Highlight", char)
                    highlight.Name = "HoNyangHighlight"
                    highlight.Adornee = char
                end
                highlight.Enabled = true
                highlight.FillTransparency = 0.8
                highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
            else
                if highlight then highlight.Enabled = false end
            end
        end
    end
end)

getgenv().FlySpeed = 50

local bv, bg, flyConn
MoveGroup:AddToggle('FlyToggle', {
    Text = 'Fly',
    Default = false,
    Callback = function(Value)
        getgenv().FlyEnabled = Value
        local char = Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        if Value then
             if not hrp:FindFirstChild("HoNyangFlyBV") then
                bv = Instance.new("BodyVelocity", hrp)
                bv.Name = "HoNyangFlyBV"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 0, 0)
             end
             if not hrp:FindFirstChild("HoNyangFlyBG") then
                bg = Instance.new("BodyGyro", hrp)
                bg.Name = "HoNyangFlyBG"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 20000
                bg.CFrame = hrp.CFrame
             end
             if hum then hum.PlatformStand = true end
             flyConn = RunService.RenderStepped:Connect(function()
                if not getgenv().FlyEnabled then return end
                local currentTargetChar = Player.Character
                if not currentTargetChar or not currentTargetChar:FindFirstChild("HumanoidRootPart") then return end
                local currentHrp = currentTargetChar.HumanoidRootPart
                local currentHum = currentTargetChar:FindFirstChildOfClass("Humanoid")
                local currentBv = currentHrp:FindFirstChild("HoNyangFlyBV")
                local currentBg = currentHrp:FindFirstChild("HoNyangFlyBG")
                if currentBv and currentBg and currentHum then
                   local speed = getgenv().FlySpeed or 50
                   local camCF = Camera.CFrame
                   local moveDir = currentHum.MoveDirection
                   local velocity = Vector3.new(0, 0, 0)
                   if moveDir.Magnitude > 0 then
                      velocity = (camCF.LookVector * (moveDir:Dot(Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit)) + camCF.RightVector * (moveDir:Dot(Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit))) * speed
                   end
                   currentBv.Velocity = velocity
                   currentBg.CFrame = camCF
                end
             end)
        else
             if flyConn then flyConn:Disconnect() end
             if hrp:FindFirstChild("HoNyangFlyBV") then hrp.HoNyangFlyBV:Destroy() end
             if hrp:FindFirstChild("HoNyangFlyBG") then hrp.HoNyangFlyBG:Destroy() end
             if hum then hum.PlatformStand = false end
        end
    end
})

MoveGroup:AddSlider('FlySpeedSlider', {
    Text = 'Fly Speed',
    Default = 50,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        getgenv().FlySpeed = Value
    end
})

MoveGroup:AddToggle('NoclipToggle', {
    Text = 'Noclip',
    Default = false,
    Callback = function(Value)
        getgenv().NoclipEnabled = Value
        task.spawn(function()
             while getgenv().NoclipEnabled do
                RunService.Stepped:Wait()
                local char = Player.Character
                if char then
                   for _, v in pairs(char:GetDescendants()) do
                      if v:IsA("BasePart") then v.CanCollide = false end
                   end
                end
                task.wait(0.5)
             end
        end)
    end
})

MoveGroup:AddToggle('InfiniteJumpToggle', {
    Text = 'Infinite Jump',
    Default = false,
    Callback = function(Value)
        getgenv().InfiniteJumpEnabled = Value
    end
})

UserInputService.JumpRequest:Connect(function()
    if getgenv().InfiniteJumpEnabled then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local function getNearestAlivePlayer()
   local targetChar = nil
   local minD = math.huge
   if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
      local myPos = Player.Character.HumanoidRootPart.Position
      for _, p in pairs(Players:GetPlayers()) do
         if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
               local d = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
               if d < minD then minD = d targetChar = p.Character end
            end
         end
      end
   end
   return targetChar
end

TeleportGroup:AddToggle('HeadTPToggle', {
    Text = 'Head TP (15 Studs Above)',
    Default = false,
    Callback = function(Value)
        getgenv().HeadTPEnabled = Value
        if Value then
             task.spawn(function()
                while getgenv().HeadTPEnabled do
                   RunService.RenderStepped:Wait()
                   local char = Player.Character
                   local hum = char and char:FindFirstChildOfClass("Humanoid")
                   if not char or not hum or hum.Health <= 0 then break end
                   local targetPlayer = getNearestAlivePlayer()
                   if targetPlayer and targetPlayer:FindFirstChild("HumanoidRootPart") then
                      char.HumanoidRootPart.CFrame = targetPlayer.HumanoidRootPart.CFrame + Vector3.new(0, 15, 0)
                   else
                      task.wait(0.2)
                   end
                end
             end)
        end
    end
})

TeleportGroup:AddToggle('BackTPToggle', {
    Text = 'Back TP (Behind Target)',
    Default = false,
    Callback = function(Value)
        getgenv().BackTPEnabled = Value
        if Value then
             task.spawn(function()
                while getgenv().BackTPEnabled do
                   RunService.RenderStepped:Wait()
                   local char = Player.Character
                   local hum = char and char:FindFirstChildOfClass("Humanoid")
                   if not char or not hum or hum.Health <= 0 then break end
                   local targetPlayer = getNearestAlivePlayer()
                   if targetPlayer and targetPlayer:FindFirstChild("HumanoidRootPart") then
                      char.HumanoidRootPart.CFrame = targetPlayer.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                   else
                      task.wait(0.2)
                    end
                end
             end)
        end
    end
})

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://92281817840531"

EmotesGroup:AddToggle('CustomEmoteToggle', {
    Text = 'Custom Emote',
    Default = false,
    Callback = function(Value)
        getgenv().CustomEmoteEnabled = Value
        local char = Player.Character
        if Value then
            if char then
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    local anim = hum:LoadAnimation(animation)
                    anim:Play()
                    anim:AdjustSpeed(99999)
                end
            end
        end
    end
})

local function setSkybox(skyId)
    local existingSky = Lighting:FindFirstChild("HoNyangSky")
    if existingSky then existingSky:Destroy() end
    local sky = Instance.new("Sky")
    sky.Name = "HoNyangSky"
    if type(skyId) == "table" then
        sky.SkyboxBk = skyId.SkyboxBk or ""
        sky.SkyboxDn = skyId.SkyboxDn or ""
        sky.SkyboxFt = skyId.SkyboxFt or ""
        sky.SkyboxLf = skyId.SkyboxLf or ""
        sky.SkyboxRt = skyId.SkyboxRt or ""
        sky.SkyboxUp = skyId.SkyboxUp or ""
    else
        sky.SkyboxBk = skyId
        sky.SkyboxDn = skyId
        sky.SkyboxFt = skyId
        sky.SkyboxLf = skyId
        sky.SkyboxRt = skyId
        sky.SkyboxUp = skyId
    end
    sky.Parent = Lighting
end

local function removeSkybox()
    local existingSky = Lighting:FindFirstChild("HoNyangSky")
    if existingSky then existingSky:Destroy() end
end

local DARK_SKY = {
    SkyboxBk = "rbxassetid://570555736",
    SkyboxDn = "rbxassetid://570555964",
    SkyboxFt = "rbxassetid://570555800",
    SkyboxLf = "rbxassetid://570555840",
    SkyboxRt = "rbxassetid://570555882",
    SkyboxUp = "rbxassetid://570555929",
}

SkyboxGroup:AddToggle('GalaxySkyToggle', {
    Text = 'Galaxy Skybox',
    Default = false,
    Callback = function(Value)
        if Value then setSkybox("rbxassetid://159454299") else removeSkybox() end
    end
})

SkyboxGroup:AddToggle('DarkSkyToggle', {
    Text = 'Dark Sky',
    Default = false,
    Callback = function(Value)
        if Value then
            setSkybox(DARK_SKY)
            pcall(function()
                Lighting.Brightness = 0.4
                Lighting.Ambient = Color3.fromRGB(20, 20, 30)
                Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 25)
                Lighting.ClockTime = 0
            end)
        else
            removeSkybox()
            pcall(function()
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end)
        end
    end
})

SkyboxGroup:AddToggle('LockTimeToggle', {
    Text = 'Lock Custom Time',
    Default = false,
    Callback = function(Value)
        getgenv().LockTimeEnabled = Value
    end
})

SkyboxGroup:AddSlider('ClockTimeSlider', {
    Text = 'Clock Time (0 - 24)',
    Default = 12,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        getgenv().CustomClockTime = Value
    end
})

RunService.RenderStepped:Connect(function()
    if getgenv().LockTimeEnabled and getgenv().CustomClockTime then
        Lighting.ClockTime = getgenv().CustomClockTime
    end
end)

-- Device Spoofer UI
SpooferGroup:AddToggle('DeviceSpooferMaster', {
    Text = 'Enable Device Spoofer',
    Default = false,
    Callback = function(Value)
        getgenv().DeviceSpooferEnabled = Value
        if Value then fireDeviceSetControls(getgenv().SpoofedDeviceMode) end
    end
})

SpooferGroup:AddToggle('DeviceVR', {
    Text = 'Device: VR',
    Default = false,
    Callback = function(Value)
        if Value then
            getgenv().SpoofedDeviceMode = normalizeDeviceMode("vr")
            if getgenv().DeviceSpooferEnabled then fireDeviceSetControls() end
        end
    end
})

SpooferGroup:AddToggle('DeviceTouch', {
    Text = 'Device: Touch',
    Default = false,
    Callback = function(Value)
        if Value then
            getgenv().SpoofedDeviceMode = normalizeDeviceMode("touch")
            if getgenv().DeviceSpooferEnabled then fireDeviceSetControls() end
        end
    end
})

SpooferGroup:AddToggle('DeviceGamepad', {
    Text = 'Device: Gamepad',
    Default = false,
    Callback = function(Value)
        if Value then
            getgenv().SpoofedDeviceMode = normalizeDeviceMode("gamepad")
            if getgenv().DeviceSpooferEnabled then fireDeviceSetControls() end
        end
    end
})

SpooferGroup:AddToggle('DeviceMouseKeyboard', {
    Text = 'Device: MouseKeyboard',
    Default = true,
    Callback = function(Value)
        if Value then
            getgenv().SpoofedDeviceMode = normalizeDeviceMode("mousekeyboard")
            if getgenv().DeviceSpooferEnabled then fireDeviceSetControls() end
        end
    end
})

SpooferGroup:AddButton('Apply Spoof Now', function()
    getgenv().DeviceSpooferEnabled = true
    fireDeviceSetControls(getgenv().SpoofedDeviceMode)
end)

SpooferInfoGroup:AddLabel('Uses SetControls remote')
SpooferInfoGroup:AddLabel('Modes: VR / Touch / Gamepad / MouseKeyboard')
SpooferInfoGroup:AddLabel('Open-source Rivals control spoof pattern')
SpooferInfoGroup:AddLabel('Re-applies every 2.5s while enabled')

-- Hit Sound UI
HitSoundGroup:AddToggle('HitSoundMaster', {
    Text = 'Enable Hit Sound',
    Default = true,
    Callback = function(Value)
        getgenv().HitSoundEnabled = Value
    end
})

HitSoundGroup:AddSlider('HitSoundVolumeSlider', {
    Text = 'Sound Volume',
    Default = 1.0,
    Min = 0,
    Max = 2,
    Rounding = 2,
    Callback = function(Value)
        getgenv().HitSoundVolume = Value
    end
})

HitSoundGroup:AddSlider('HitSoundPitchSlider', {
    Text = 'Sound Pitch',
    Default = 1.0,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = function(Value)
        getgenv().HitSoundPitch = Value
    end
})

local function selectHitSound(name)
    getgenv().SelectedHitSound = name
    pcall(playHitSound)
end

HitSoundGroup:AddToggle('HS_rust', { Text = 'HS: rust hs', Default = true, Callback = function(Value) if Value then selectHitSound("rust hs") end end })
HitSoundGroup:AddToggle('HS_neverlose', { Text = 'HS: neverlose', Default = false, Callback = function(Value) if Value then selectHitSound("neverlose") end end })
HitSoundGroup:AddToggle('HS_sparkle', { Text = 'HS: sparkle', Default = false, Callback = function(Value) if Value then selectHitSound("sparkle") end end })
HitSoundGroup:AddToggle('HS_minecraft', { Text = 'HS: minecraft hit', Default = false, Callback = function(Value) if Value then selectHitSound("minecraft hit") end end })
HitSoundGroup:AddToggle('HS_bonk', { Text = 'HS: bonk', Default = false, Callback = function(Value) if Value then selectHitSound("bonk") end end })
HitSoundGroup:AddToggle('HS_osu', { Text = 'HS: osu', Default = false, Callback = function(Value) if Value then selectHitSound("osu") end end })
HitSoundGroup:AddToggle('HS_amongus', { Text = 'HS: among us', Default = false, Callback = function(Value) if Value then selectHitSound("among us") end end })
HitSoundGroup:AddToggle('HS_bruh', { Text = 'HS: bruh', Default = false, Callback = function(Value) if Value then selectHitSound("bruh") end end })
HitSoundGroup:AddToggle('HS_vine', { Text = 'HS: vine', Default = false, Callback = function(Value) if Value then selectHitSound("vine") end end })
HitSoundGroup:AddToggle('HS_gamesense', { Text = 'HS: gamesense', Default = false, Callback = function(Value) if Value then selectHitSound("gamesense") end end })

HitSoundGroup:AddButton('Test Hit Sound', function()
    pcall(playHitSound)
end)

MenuGroup:AddButton('Unload', function() 
    FOVGui:Destroy()
    SilentFOVGui:Destroy()
    CustomUIGui:Destroy()
    Library:Unload() 
end)

Library:OnUnload(function()
    FOVGui:Destroy()
    SilentFOVGui:Destroy()
    CustomUIGui:Destroy()
    Library.Unloaded = true
end)

ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:BuildConfigSection(Tabs['UI Settings'])
