local function waitForLoadingScreen()
	local players = game:GetService("Players")
	local coreGui = game:GetService("CoreGui")

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local player = players.LocalPlayer
	while not player do
		players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		player = players.LocalPlayer
	end

	local playerGui = player:WaitForChild("PlayerGui")
	local function isActiveLoadingGui(object)
		local normalizedName = object.Name:lower():gsub("[%s_%-]", "")
		if normalizedName ~= "loadingscreen" and not normalizedName:find("loadingscreen", 1, true) then
			return false
		end
		local current = object
		while current and current ~= playerGui and current ~= coreGui do
			if current:IsA("LayerCollector") and not current.Enabled then
				return false
			end
			if current:IsA("GuiObject") and not current.Visible then
				return false
			end
			current = current.Parent
		end
		return object:IsDescendantOf(playerGui) or object:IsDescendantOf(coreGui)
	end

	local clearSince
	repeat
		local loading = false
		for _, root in ipairs({playerGui, coreGui}) do
			for _, object in ipairs(root:GetDescendants()) do
				if isActiveLoadingGui(object) then
					loading = true
					break
				end
			end
			if loading then break end
		end

		clearSince = loading and nil or (clearSince or os.clock())
		task.wait(0.1)
	until clearSince and os.clock() - clearSince >= 0.5
end

waitForLoadingScreen()

do
    local function safeNewcclosure(fn)
        return newcclosure and newcclosure(fn) or fn
    end

    if not getgenv().__LionStartupHooks then
        getgenv().__LionStartupHooks = true
        if setthreadidentity then
            pcall(setthreadidentity, 8)
        end

        local okEnv, renv = pcall(getrenv)
        local setmetatableTarget = okEnv and renv and renv.setmetatable
        if hookfunction and setmetatableTarget then
            local oldSetmetatable = setmetatableTarget
            local okHook, hooked = pcall(hookfunction, setmetatableTarget, safeNewcclosure(function(Table, Metatable)
                if Metatable and type(Metatable) == "table" and rawget(Metatable, "__mode") then
                    local mode = rawget(Metatable, "__mode")
                    if mode == "kv" or mode == "v" or mode == "k" then
                        local okTrace, trace = pcall(debug.traceback)
                        trace = okTrace and trace or ""
                        if trace:find("MiscellaneousController", 1, true)
                            or trace:find("CameraSecurity", 1, true)
                            or trace:find("AnalyticsPipelineController", 1, true) then
                            return oldSetmetatable({1, 2, 3}, {})
                        end
                    end
                end
                return oldSetmetatable(Table, Metatable)
            end))
            if okHook and hooked then
                oldSetmetatable = hooked
            end
        end

        local okPlayer, localPlayer = pcall(function()
            return cloneref(game:GetService("Players")).LocalPlayer
        end)
        if okPlayer and localPlayer and hookfunction then
            pcall(function()
                local oldKick
                oldKick = hookfunction(localPlayer.Kick, safeNewcclosure(function(self, ...)
                    if self == localPlayer then return nil end
                    return oldKick(self, ...)
                end))
            end)

            pcall(function()
                local oldGetMouse
                oldGetMouse = hookfunction(localPlayer.GetMouse, safeNewcclosure(function(self, ...)
                    if self == localPlayer then
