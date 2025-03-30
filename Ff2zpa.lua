local Config = { QBAimbotEnabled = false,
    AimbotMode = "Legit", -- "Legit" or "Rage" (Affects offset)
    AimbotFOV = 300,
    AimbotSmoothing = 0.1, -- Lerp alpha for velocity change

    -- Silent Aim
    SilentAimEnabled = false,
    SilentAimRange = 50,

    -- ESP
    ESPEnabled = false,
    ESPMaxDistance = 500,
    ESPTracerThickness = 1,
    ESPNameSize = 12,
    ESPBoxTransparency = 0.5, -- Assuming Drawing.Square uses Transparency

    -- Magnet Catch
    MagnetCatchEnabled = false,
    MagnetCatchRange = 25,

    -- Speed Boost
    SpeedEnabled = false,
    SpeedAmount = 21,

    -- Infinite Jump
    InfiniteJumpEnabled = false,

    -- Auto Catch
    AutoCatchEnabled = false,
    AutoCatchRange = 15,

    -- Other Features
    PanicKeyEnabled = true, -- General toggle for all features
    AntiSpectate = true, -- Disable features if spectated
    BallPredictionEnabled = false,

    -- Hider/Bypass Settings (Integrated from 'sigma')
    JumpPowerEnabled = false, -- Renamed from jump_power
    JumpPowerAmount = 55, -- Default 50 * 1.1
    BoostOnHeight = true,
    AngleTolerance = 10,
    BoostAmount = 1.15,
    IncreaseCatchSize = Vector3.new(10, 10, 10),
    VisualizeCatchZone = true,
    ReduceCatchTackle = true,
    SilentMode = false, -- Hider silent mode (e.g., disable boost sound)

    -- Humanization (NEW)
    HumanizationEnabled = false,
    HumanizationFrequency = 0.05, -- Chance per frame to perform a human-like action

    -- Stealth (NEW - Multiplier for ranges/speeds)
    StealthLevel = 1.0, -- 1.0 = normal, < 1.0 = less obvious, > 1.0 = more obvious

    -- Targeting (NEW)
    TargetSpecificPlayers = false,
    TargetPlayerList = {"Player1", "Player2"}, -- List of player names to target if TargetSpecificPlayers is true
}


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local CurrentCamera = Workspace.CurrentCamera

-- Exploit Function Placeholders/Checks (Add your specific exploit functions here)
local hookfunction = hookfunction or function(...) warn("hookfunction not available") end
local hookmetamethod = hookmetamethod or function(...) warn("hookmetamethod not available") end
local firetouchinterest = firetouchinterest or function(...) warn("firetouchinterest not available") end
local Drawing = Drawing -- Assume Drawing library is available globally
local getgenv = getgenv or function() return _G end
local setfpscap = setfpscap or function(...) warn("setfpscap not available") end
local getconnections = getconnections or function(...) warn("getconnections not available"); return {} end
local readfile = readfile or function(...) warn("readfile not available") end
local writefile = writefile or function(...) warn("writefile not available") end
local isfile = isfile or function(...) warn("isfile not available") end
local newcclosure = newcclosure or function(f) return f end -- May cause issues if not the real newcclosure
local checkcaller = checkcaller or function() return false end -- Simplified fallback
local getexecutorname = getexecutorname or function() return "Unknown Executor" end
local setthreadidentity = setthreadidentity or function(...) warn("setthreadidentity not available") end
local getgc = getgc or function(...) warn("getgc not available"); return {} end

--========================================================================
--[ FF2 Hider / Bypass Code ]
--========================================================================
---! FF2 hider part.
---@note: Code is messy and ugly, but it was made hastily and for fun.

if game.PlaceId ~= 8204899140 and game.PlaceId ~= 104709320604721 and game.PlaceId ~= 8206123457 then
    warn("[FF2 Hider] Incorrect PlaceId, hider/bypass might not be effective.")
    -- return -- Optionally return if not in the target game
end

if not hookfunction or not hookmetamethod or not firetouchinterest then
    return LocalPlayer and LocalPlayer:Kick("Unsupported exploit for FF2 Hider")
end

if not _G.LPH_OBFUSCATED then -- Using _G as getfenv might be unreliable/hooked
    local LPH_NO_VIRTUALIZE_FUNC
    local success, err = pcall(function() LPH_NO_VIRTUALIZE_FUNC = loadstring("LPH_NO_VIRTUALIZE = function(...) return ... end") end)
    if success and LPH_NO_VIRTUALIZE_FUNC then LPH_NO_VIRTUALIZE_FUNC() end
end
local LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...) return ... end


local environment = getgenv()

local MIN_CPU_OFFSET = 100
local MAX_CPU_OFFSET = 9999
local DEFAULT_CPU_OFFSET = 3600

math.randomseed((os.clock() + os.time()) * 1000)

local cpu_offset_value = DEFAULT_CPU_OFFSET
pcall(function()
    if isfile and writefile and readfile then
        if not isfile("cpu_offset.txt") then
            writefile("cpu_offset.txt", tostring(math.random(MIN_CPU_OFFSET, MAX_CPU_OFFSET)))
        end
        local success_read, offset_str = pcall(readfile, "cpu_offset.txt")
        if success_read and tonumber(offset_str) then
            cpu_offset_value = math.clamp(math.round(tonumber(offset_str)), MIN_CPU_OFFSET, MAX_CPU_OFFSET)
        end
    end
end)

local content_provider = ContentProvider
local log_service = LogService
local script_context = ScriptContext
local core_gui = CoreGui
local starter_player = StarterPlayer
local players = Players
local run_service = RunService
local http_service = HttpService
local is_a = game.IsA -- Use the service directly

local fake_instance = Instance.new("Part")
local fake_signal = fake_instance:GetAttributeChangedSignal("FAKE_SIGNAL_")
local core_gui_instances_cache = {}

pcall(function()
    for _, instance in ipairs(core_gui:GetChildren()) do
        if instance and instance.Name == "RobloxGui" then continue end
        table.insert(core_gui_instances_cache, instance)
    end
end)

local default_walkspeed = starter_player.CharacterWalkSpeed
local default_jump_power = starter_player.CharacterJumpPower

local fake_request_internal = newcclosure(function()
    error("The current thread cannot call 'RequestInternal' (lacking capability RobloxScript)", 2)
end)

local cached_namecall_function = nil
pcall(function() game:_() end, function() cached_namecall_function = debug.info(2, "f") end)

if not cached_namecall_function then
    warn("[FF2 Hider] Failed to cache namecall function")
end

local Library = nil -- Will be set later by Fluent UI code

local reflection_map = {}
local default_index_map = {}
local catch_parts_data = {}
local football_parts_data = {}
local is_catching = false -- Managed by hider hooks

-- Original function storage
local orig_debug_info = debug.info
local orig_os_clock = os.clock
local orig_is_a_func = is_a -- Store the original function, not the service
local orig_get_property_changed_signal = game.GetPropertyChangedSignal
local orig_preload_async = content_provider.PreloadAsync
local orig_log_service_gethistory = log_service.GetLogHistory
local orig_game_namecall = nil -- Set by hookmetamethod
local orig_game_index = nil -- Set by hookmetamethod
local orig_game_newindex = nil -- Set by hookmetamethod
local orig_catch_func = nil -- Set later

local function log_warn(str, ...)
    warn("[FF2 Hider] " .. string.format(str, ...))
end

local table_shallow_clone = LPH_NO_VIRTUALIZE(function(tbl)
    local new_tbl = {}
    for idx, value in pairs(tbl) do new_tbl[idx] = value end
    return new_tbl
end)

-- Hider functions (patch_content_id_list, patch_preload_async_args, etc.) - Keep these as they were in the original snippet
local function patch_content_id_list(content_id_list)
	if typeof(content_id_list) ~= "table" then return error("list is not a table") end
	local core_gui_pos = table.find(content_id_list, core_gui)
	if not core_gui_pos then return error("no core-gui was found in this list") end
	local contend_id_list_clone = table_shallow_clone(content_id_list)
	contend_id_list_clone[core_gui_pos] = nil
	local add_core_gui_cache = LPH_NO_VIRTUALIZE(function()
		for _, instance in ipairs(core_gui_instances_cache) do
			table.insert(contend_id_list_clone, instance)
		end
	end)
	add_core_gui_cache()
	log_warn("patch_content_id_list(content_id_list[%i]) -> replaced with core_gui_instances_cache[%i]", #content_id_list, #contend_id_list_clone)
	return contend_id_list_clone
end

local function patch_preload_async_args(args, content_id_list_pos)
	log_warn("patch_preload_async_args(args[%i] -> index[%i])", #args, content_id_list_pos) -- Removed extra arg
    if not args[content_id_list_pos] then return error("content_id_list_pos out of bounds") end
	local content_id_list = args[content_id_list_pos]
	args[content_id_list_pos] = patch_content_id_list(content_id_list)
end

local function patch_is_a_ret(args, is_a_ret)
	local self = args[1]
	local class_name = args[2]
	if typeof(self) ~= "Instance" then return error("self is not an instance") end
	if typeof(class_name) ~= "string" then return error("class name is not a string") end -- Fixed typo
	local stripped_class_name = string.gsub(class_name, "\0", "")
	if self.Name:sub(1, 2) ~= "FF" and stripped_class_name == "BodyMover" then return false end
	return is_a_ret
end

local function anticheat_caller(caller_script_info)
	if not caller_script_info or not caller_script_info.func then return false end
	local const_success, consts = pcall(debug.getconstants, caller_script_info.func)
	if not const_success or not consts then return false end
	local first_const = consts[1]
	if typeof(first_const) ~= "string" then return false end
	return first_const:match("_______________________________")
end

local any_anticheat_caller = LPH_NO_VIRTUALIZE(function()
	for idx = 2, 10 do -- Limit stack walk depth
		local caller_script_info = debug.getinfo(idx)
		if not caller_script_info then break end
		if not anticheat_caller(caller_script_info) then continue end
		return true
	end
    return false -- Explicitly return false if not found
end)

local on_os_clock = LPH_NO_VIRTUALIZE(function(...)
	local os_clock_ret = orig_os_clock(...)
	if checkcaller() then return os_clock_ret end
	-- log_warn("on_os_clock(...) -> orig_cpu_time[%f] + cpu_offset[%f]", os_clock_ret, cpu_offset_value) -- Reduce log spam
	return os_clock_ret + cpu_offset_value
end)

local patch_log_service_return = LPH_NO_VIRTUALIZE(function(log_service_ret)
	if typeof(log_service_ret) ~= "table" then return error("returned value is not a table") end
	local new_log_service_ret = {}
	local patched_log_history = false
	for _, log_service_entry in ipairs(log_service_ret) do -- Use ipairs for arrays
		local log_message = log_service_entry and log_service_entry.message
		if not log_message then continue end
		local log_entry_ok = not string.find(log_message, "Script ''", 1, true) -- Use string.find
			and not string.find(log_message, "\n, line", 1, true)
			and not string.find(log_message, "Electron[,:]")
            and not string.find(log_message, "Synapse") -- Common detection target
			and not string.find(log_message, "Valyse[,:]")
			and not string.find(log_message, '%[string "')
			and not string.find(log_message, ":loadstring[,:]")
			and not string.find(log_message, ".Xeno.")
            and not string.find(log_message, "Krnl") -- Common detection target
		if log_entry_ok then
			table.insert(new_log_service_ret, log_service_entry)
		else
			if not string.find(log_message, "[FF2 Hider]") and not string.find(log_message,"Fluent") then -- Filter own logs
				log_warn("patch_log_service_return(...) -> filtered log entry: %s", log_message)
			end
			patched_log_history = true
		end
	end
	if not patched_log_history then return error("nothing to patch") end -- Return error to indicate no changes needed
    if #new_log_service_ret == 0 then return error("no valid log entries") end -- Return error if all were filtered
	return new_log_service_ret
end)

local on_log_service = LPH_NO_VIRTUALIZE(function(...)
	local success, log_service_ret = pcall(orig_log_service_gethistory, ...) -- Call original safely
    if not success then return log_service_ret end -- Return error if original failed
	if checkcaller() then return log_service_ret end
	local patch_success, patch_result = pcall(patch_log_service_return, log_service_ret)
	-- log_warn("on_log_service(...) -> patch return result: (%s)", tostring(patch_success)) -- Reduce spam
	return patch_success and patch_result or log_service_ret -- Return patched or original if patch failed
end)

local on_preload_async = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then return orig_preload_async(...) end
	local args = { ... }
    if #args < 2 then return orig_preload_async(...) end -- Basic arg check
	local patch_success, patch_result = pcall(patch_preload_async_args, args, 2)
	-- log_warn("on_preload_async(...) -> patch args result: (%s)", tostring(patch_success)) -- Reduce spam
	return patch_success and orig_preload_async(table.unpack(args)) or orig_preload_async(...)
end)

local on_game_namecall = LPH_NO_VIRTUALIZE(function(...)
    local method = getnamecallmethod()
	if checkcaller() then return orig_game_namecall(...) end -- Check caller early

	local args = { ... }
	local self = args[1]

	if typeof(self) ~= "Instance" then return orig_game_namecall(...) end

	-- Anticheat Bind/Kick Blocks
	if self == run_service and (method == "BindToRenderStep" or method == "bindToRenderStep") and any_anticheat_caller() and typeof(args[2]) == "string" then
        log_warn("on_game_namecall(...) -> method[%s] -> Blocked AC bind: %s", method, args[2])
		return
	end
    if method == "Kick" and typeof(args[2]) == "string" and any_anticheat_caller() then -- Check arg 2 for kick reason
        log_warn("on_game_namecall(...) -> method[%s] -> Blocked AC kick: %s because %s", method, tostring(self), args[2])
        return
    end

    -- RemoteEvent Filtering
    if orig_is_a_func(self, "RemoteEvent") and (method == "FireServer" or method == "fireServer") and typeof(args[2]) == "string" and typeof(args[3]) == "string" then
        if args[2]:match("AC") then
            log_warn("on_game_namecall(...) -> method[%s] -> Blocked AC remote fire: Event=%s, Arg2=%s, Arg3=%s", method, self.Name, args[2], args[3])
            return
        end
        -- Catching Logic Intercept
        if args[2]:match("catch") then -- More specific check needed?
            is_catching = true
            -- log_warn("on_game_namecall(...) -> method[%s] -> is_catching[%s]", method, tostring(is_catching)) -- Spammy
        end
    end

    -- Hooked Service Calls
    if self == content_provider and (method == "PreloadAsync" or method == "preloadAsync") then
        local patch_success, _ = pcall(patch_preload_async_args, args, 2) -- Use args directly
        -- log_warn("on_game_namecall(...) -> method[%s] -> patch args result: (%s)", method, tostring(patch_success)) -- Spammy
        return patch_success and orig_game_namecall(table.unpack(args)) or orig_game_namecall(...)
    elseif self == log_service and (method == "GetLogHistory" or method == "getLogHistory") then
        local success_orig, log_service_ret = pcall(orig_game_namecall, ...)
        if not success_orig then return log_service_ret end
        local patch_success, patch_result = pcall(patch_log_service_return, log_service_ret)
        -- log_warn("on_game_namecall(...) -> method[%s] -> patch return result: (%s)", method, tostring(patch_success)) -- Spammy
        return patch_success and patch_result or log_service_ret
    elseif method == "IsA" or method == "isA" then
        local success_orig, is_a_ret = pcall(orig_game_namecall, ...)
        if not success_orig then return is_a_ret end
        local patch_success, patch_result = pcall(patch_is_a_ret, args, is_a_ret)
        return patch_success and patch_result or is_a_ret
    elseif method == "GetPropertyChangedSignal" or method == "getPropertyChangedSignal" then
         -- Call the dedicated hook for this
        return on_get_property_changed_signal(...)
    end

	return orig_game_namecall(...)
end)

local on_game_newindex = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then return orig_game_newindex(...) end

	local args = { ... }
	local self, index, new_value = args[1], args[2], args[3] -- Unpack args

	if typeof(self) ~= "Instance" or typeof(index) ~= "string" then
		return orig_game_newindex(...)
	end

	local stripped_index = string.gsub(index, "\0", "")
	local property_reflection = reflection_map[self] or {}
	if not reflection_map[self] then reflection_map[self] = property_reflection end

	local numeric_change = typeof(new_value) == "number"
	local velocity_change = typeof(new_value) == "Vector3"

    local is_walk_speed = (stripped_index == "WalkSpeed" or stripped_index == "walkSpeed")
	local is_jump_power = (stripped_index == "JumpPower" or stripped_index == "jumpPower")
    local is_assembly_linear_velocity = (stripped_index == "AssemblyLinearVelocity" or stripped_index == "assemblyLinearVelocity")
    local is_assembly_angular_velocity = (stripped_index == "AssemblyAngularVelocity" or stripped_index == "assemblyAngularVelocity")

    -- Apply cheat settings if enabled
    if numeric_change and is_walk_speed and Config.SpeedEnabled then
        orig_game_newindex(self, index, new_value <= 0 and new_value or Config.SpeedAmount) -- Apply speed hack
    elseif numeric_change and is_jump_power and Config.JumpPowerEnabled then
         orig_game_newindex(self, index, new_value <= 0 and new_value or Config.JumpPowerAmount) -- Apply jump hack
    elseif velocity_change and is_assembly_linear_velocity and (Config.JumpPowerEnabled or Config.BoostOnHeight) then
        local humanoid_state = self.Parent and self.Parent:FindFirstChildOfClass("Humanoid") and self.Parent.Humanoid:GetState()
        local can_boost = humanoid_state ~= Enum.HumanoidStateType.Freefall -- Prevent boosting infinitely while falling

        if Config.JumpPowerEnabled and Config.JumpPowerAmount > default_jump_power and not can_boost then
             -- Prevent unnatural upward velocity when high jump is enabled and falling
             -- log_warn("on_game_newindex(...) -> Denied velocity change due to high jump power while falling.")
        elseif Config.BoostOnHeight and can_boost then
            local angular_velocity = self.AssemblyAngularVelocity -- Use direct property access
            if angular_velocity and math.abs(angular_velocity.Y) >= Config.AngleTolerance then
                local boosted_velocity = self.AssemblyLinearVelocity * Config.BoostAmount -- Boost current velocity
                args[3] = boosted_velocity -- Modify the args table to pass the boosted velocity
                log_warn("on_game_newindex(...) -> Boosted velocity: %s -> %s", tostring(new_value), tostring(args[3]))

                -- Play sound (optional, controlled by Config.SilentMode)
                if not Config.SilentMode then
                    local sound = Instance.new("Sound", self)
                    sound.SoundId = "rbxassetid://1053296915"
                    sound.Volume = 1.0
                    sound.PlayOnRemove = true
                    task.delay(1, function() pcall(function() sound:Destroy() end) end) -- Cleanup sound
                end

                 orig_game_newindex(unpack(args)) -- Apply boosted velocity
            else
                 orig_game_newindex(...) -- Apply original velocity change if not boosting
            end
        else
            orig_game_newindex(...) -- Apply original velocity change
        end
    else
		orig_game_newindex(...) -- Apply changes for other properties or when cheats are off
	end

    -- Store the value the game *thinks* was set (might be the original or the cheat value)
    -- For WalkSpeed/JumpPower, ensure it's not negative before storing in reflection
    if numeric_change and (is_walk_speed or is_jump_power) then
        property_reflection[stripped_index] = math.max(new_value, 0.0)
    else
        property_reflection[stripped_index] = new_value -- Store the intended value for spoofing later
    end
end)

local on_is_a = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then return orig_is_a_func(...) end -- Call original func
	local success_orig, is_a_ret = pcall(orig_is_a_func, ...)
    if not success_orig then return is_a_ret end
	local args = { ... }
	local patch_success, patch_result = pcall(patch_is_a_ret, args, is_a_ret)
	return patch_success and patch_result or is_a_ret
end)

local on_get_property_changed_signal = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then return orig_get_property_changed_signal(...) end
	local args = { ... }
	local self, property = args[1], args[2]
	if typeof(self) ~= "Instance" or typeof(property) ~= "string" then
		return orig_get_property_changed_signal(...)
	end

    -- Prevent AC from listening to sensitive property changes
    local block_signal = false
    if orig_is_a_func(self, "Workspace") then block_signal = true end
    if self.Name == "HumanoidRootPart" and orig_is_a_func(self, "Part") then block_signal = true end
    local is_catch_part = self.Name:sub(1, 5) == "Catch"
	local is_block_part = self.Name:sub(1, 6) == "BlockP" -- Assuming 'BlockPart' intended
    if (self.Name == "Football" or is_catch_part or is_block_part) and orig_is_a_func(self, "BasePart") then block_signal = true end

    if block_signal then
        -- log_warn("on_get_property_changed_signal(...) -> self[%s] -> property[%s] -> Blocked with fake_signal", self.Name, property)
        return fake_signal -- Return a dummy signal
    end

	-- log_warn("on_get_property_changed_signal(...) -> self[%s] -> property[%s] -> Allowed original signal", self.Name, property)
	return orig_get_property_changed_signal(...)
end)

local on_game_index = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then return orig_game_index(...) end

	local args = { ... }
	local self, index = args[1], args[2]

	if typeof(self) ~= "Instance" or typeof(index) ~= "string" then
		return orig_game_index(...)
	end

	local stripped_index = string.gsub(index, "\0", "")

    -- Block AC access to sensitive signals/methods
    if self == script_context and stripped_index == "Error" then return fake_signal end
    if self == run_service and stripped_index == "Heartbeat" and any_anticheat_caller() then return fake_signal end
    if self == http_service and (stripped_index == "RequestInternal" or stripped_index == "requestInternal") then return fake_request_internal end

    -- Spoof properties
    local should_spoof_ret = false
    if orig_is_a_func(self, "Camera") and (stripped_index == "FieldOfView" or stripped_index == "fieldOfView") then should_spoof_ret = true end
    if orig_is_a_func(self, "Workspace") and (stripped_index == "Gravity" or stripped_index == "gravity") then should_spoof_ret = true end
    if orig_is_a_func(self, "Part") and (stripped_index == "Size" or stripped_index == "size" or stripped_index == "CanCollide" or stripped_index == "canCollide") then should_spoof_ret = true end
    if orig_is_a_func(self, "Humanoid") and (stripped_index ~= "MoveDirection") then should_spoof_ret = true end -- Allow MoveDirection

    -- Return reflected value if available and spoofing is needed
    local reflections = reflection_map[self]
    local reflected_value = reflections and reflections[stripped_index]
    if should_spoof_ret and reflected_value ~= nil then
        -- log_warn("on_game_index(...) -> Spoofing %s.%s with reflected value: %s", self.Name, stripped_index, tostring(reflected_value)) -- Very Spammy
        return reflected_value
    end

    -- If no reflection, return a default/capped value if spoofing needed
    if should_spoof_ret then
        local default_indexes = default_index_map[self] or {}
        if not default_index_map[self] then default_index_map[self] = default_indexes end

        local default_value = default_indexes[stripped_index]
        if default_value == nil then
            local success_orig, result = pcall(orig_game_index, ...)
            default_value = success_orig and result or nil -- Get original value safely
            default_indexes[stripped_index] = default_value -- Cache it
        end

        -- Apply caps to default values to appear legitimate
        if default_value ~= nil then
            if (stripped_index == "WalkSpeed" or stripped_index == "walkSpeed") and typeof(default_value) == "number" then
                default_value = math.min(default_value, default_walkspeed)
            elseif (stripped_index == "JumpPower" or stripped_index == "jumpPower") and typeof(default_value) == "number" then
                default_value = math.min(default_value, default_jump_power)
            elseif (stripped_index == "HipHeight" or stripped_index == "hipHeight") and typeof(default_value) == "number" then
                default_value = math.min(default_value, 0.0) -- Original had 0.0? Seems odd, check game default. Usually > 0.
            elseif (stripped_index == "Size" or stripped_index == "size") and typeof(default_value) == "Vector3" then
                 local name = self.Name
                 if name:sub(1, 5) == "Catch" then
                    default_value = Vector3.new(math.min(default_value.X, 1.4), math.min(default_value.Y, 1.65), math.min(default_value.Z, 1.4))
                 elseif name == "BlockPart" then -- Ensure this name is correct
                    default_value = Vector3.new(math.min(default_value.X, 0.75), math.min(default_value.Y, 5), math.min(default_value.Z, 1.5))
                 end
            end
            -- log_warn("on_game_index(...) -> Spoofing %s.%s with default/capped value: %s", self.Name, stripped_index, tostring(default_value)) -- Very Spammy
            return default_value
        end
    end

	-- If not spoofing or no default found, return original value
	return orig_game_index(...)
end)

-- Touch replication logic for increased catch size
local on_catch_touch = LPH_NO_VIRTUALIZE(function(toucher, touching, state)
    if not firetouchinterest then return end
    local transmitter = touching and touching:FindFirstChildWhichIsA("TouchTransmitter")
    if not transmitter then return end -- No transmitter on the football?

    -- Try different firetouchinterest combinations as exploits handle it differently
    local success = false
    local methods_tried = {}

    local try_fire = function(p1, p2, p_state)
        local key = tostring(p1) .. tostring(p2) .. tostring(p_state)
        if methods_tried[key] then return end -- Don't retry exact same call

        local s, e = pcall(firetouchinterest, p1, p2, p_state)
        if s then success = true end
        methods_tried[key] = true
        return s
    end

    try_fire(toucher, touching, state)
    if success then return end

    try_fire(toucher, transmitter, state)
    if success then return end

    try_fire(transmitter, touching, state)
    if success then return end

    try_fire(touching, toucher, state)
    if success then return end

    if not success then
       -- log_warn("on_catch_touch(...) -> Failed to replicate touch state %s to server.", tostring(state))
    end
end)

local get_nearest_football_data = LPH_NO_VIRTUALIZE(function()
	local nearest_inst = nil
	local nearest_vis_inst = nil
	local nearest_distance = math.huge -- Initialize with infinity
    local player_hrp = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not player_hrp then return nil, nil, nil end

	for i = #football_parts_data, 1, -1 do -- Iterate backwards for safe removal
		local football_part_data = football_parts_data[i]
        if not football_part_data then continue end

		local inst, vis_inst = football_part_data.inst, football_part_data.vis_inst
        -- Check validity more thoroughly
        if not (inst and inst.Parent and vis_inst and vis_inst.Parent) then
			if vis_inst then pcall(function() vis_inst:Destroy() end) end
            table.remove(football_parts_data, i)
			continue
		end

		if inst.Parent ~= workspace then -- Check if still in workspace
            if vis_inst then pcall(function() vis_inst:Destroy() end) end
			table.remove(football_parts_data, i)
			continue
		end

		local distance = (inst.Position - player_hrp.Position).Magnitude
		if distance < nearest_distance then
			nearest_distance = distance
			nearest_inst = inst
			nearest_vis_inst = vis_inst
		end
	end

    if nearest_distance == math.huge then return nil, nil, nil end -- No valid football found

	return nearest_inst, nearest_vis_inst, nearest_distance
end)

-- This runs via PreSimulation for the hider's needs
local on_update_sigma_hider = LPH_NO_VIRTUALIZE(function()
	local player = LocalPlayer
	if not player then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

    -- Hider manages WalkSpeed/JumpPower based on Config via __newindex hook

    -- Hide all visual instances first
	for _, football_part_data in ipairs(football_parts_data) do
		local vis_inst = football_part_data and football_part_data.vis_inst
		if vis_inst and vis_inst.Parent then vis_inst.Transparency = 1.0 end -- Ensure parent exists
	end

    -- Adjust catch part size based on config
	for _, catch_part_data in ipairs(catch_parts_data) do
		local inst = catch_part_data and catch_part_data.inst
		if inst and inst.Parent then -- Ensure parent exists
            local target_size = catch_part_data.original_size or Vector3.new(1,1,1) -- Fallback size
            if Config.ReduceCatchTackle and character:FindFirstChild("Football") then
                target_size = Vector3.new(0.01, 0.01, 0.01)
            end
            -- Only set if changed to avoid unnecessary updates
            if inst.Size ~= target_size then inst.Size = target_size end
        end
	end

    -- Handle extended football catch zone logic
	local nearest_fb, nearest_vis_inst, nearest_distance = get_nearest_football_data()
	if not (nearest_fb and nearest_vis_inst and nearest_distance) then return end
	if not nearest_fb:FindFirstChildWhichIsA("TouchTransmitter") then return end
	if nearest_fb.Position.Y <= 3.5 then -- Don't extend if ball is low/on ground
        if nearest_vis_inst.Transparency ~= 1.0 then nearest_vis_inst.Transparency = 1.0 end
        return
    end

    -- Setup visualization part
    local target_size = nearest_fb.Size + Config.IncreaseCatchSize
    if nearest_vis_inst.Size ~= target_size then nearest_vis_inst.Size = target_size end
    nearest_vis_inst.Transparency = Config.VisualizeCatchZone and 0.5 or 1.0
    nearest_vis_inst.Color = BrickColor.DarkGray().Color
    if nearest_vis_inst.Position ~= nearest_fb.Position then nearest_vis_inst.Position = nearest_fb.Position end
    if nearest_vis_inst.Material ~= Enum.Material.SmoothPlastic then nearest_vis_inst.Material = Enum.Material.SmoothPlastic end
    if not nearest_vis_inst.Anchored then nearest_vis_inst.Anchored = true end
    if nearest_vis_inst.CanCollide then nearest_vis_inst.CanCollide = false end

    -- Check for overlap if catching and visualize zone is active or extended catching is implicitly needed
    if is_catching then -- Check overlap only when actively catching
        local overlap_params = OverlapParams.new()
        overlap_params.FilterType = Enum.RaycastFilterType.Include
        overlap_params.FilterDescendantsInstances = { character }
        overlap_params.MaxParts = 10 -- Limit parts to check

        local parts = workspace:GetPartsInPart(nearest_vis_inst, overlap_params)
        if #parts > 0 then
            for _, part in ipairs(parts) do
                if part and part.Parent == character and part.Name:match("Arm") then -- Be more specific about parts
                    -- log_warn("Extended catch: Firing touch interest for %s", part.Name) -- Spammy
                    on_catch_touch(part, nearest_fb, 0) -- Touch start
                    task.wait() -- Brief pause essential for some exploits
                    on_catch_touch(part, nearest_fb, 1) -- Touch end
                    break -- Only need one valid touch
                end
            end
        end
    end
end)


local on_workspace_child_added_sigma = LPH_NO_VIRTUALIZE(function(inst)
	if not inst:IsA("BasePart") or inst.Name ~= "Football" then return end
	log_warn("Football added: %s [%s]", tostring(inst.Name), tostring(inst.Size))
    local vis_part = Instance.new("Part")
    vis_part.Name = "VisualCatchZone"
    vis_part.Transparency = 1.0
    vis_part.CanCollide = false
    vis_part.Anchored = true
    vis_part.Parent = inst -- Parent to football for easier cleanup? Or workspace?
	table.insert(football_parts_data, { inst = inst, vis_inst = vis_part })
end)

local on_workspace_descendant_added_sigma = LPH_NO_VIRTUALIZE(function(inst)
	if not inst:IsA("BasePart") then return end
    if not LocalPlayer or LocalPlayer.Character ~= inst.Parent then return end

	if inst.Name:sub(1, 5) == "Catch" then
		log_warn("Catch part added: %s [%s]", tostring(inst.Name), tostring(inst.Size))
        -- Store original size immediately if possible
        local original_size = inst.Size
		table.insert(catch_parts_data, { inst = inst, original_size = original_size })
	end
end)

local on_debug_info = LPH_NO_VIRTUALIZE(function(...)
    local args = { ... }
    -- Allow debug.info for non-AC callers or non-sensitive info
    if checkcaller() or not any_anticheat_caller() or args[1] ~= 2 then
         return orig_debug_info(...) -- Call original directly
    end

    -- AC is likely checking the call stack or source
    if args[2] == "f" then -- Requesting function
        -- Return the cached namecall function to hide the hook environment
        log_warn("on_debug_info(...) -> Spoofing function for AC")
        return cached_namecall_function
    elseif args[2] == "s" then -- Requesting source
        log_warn("on_debug_info(...) -> Spoofing source 'LocalScript' for AC")
        return "LocalScript" -- Common legitimate source
    elseif args[2] == "l" then -- Requesting line number
         log_warn("on_debug_info(...) -> Spoofing line number for AC")
         return math.random(1, 100) -- Return a plausible line number
    else
        -- For other fields, potentially return nil or a default value
        log_warn("on_debug_info(...) -> Returning nil for field '%s' for AC", tostring(args[2]))
        return nil
    end
end)


-- Hook Setup
pcall(function()
    -- Disable existing error handlers that AC might use
    if getconnections then
        for _, connection in ipairs(getconnections(script_context.Error)) do
            pcall(connection.Disable, connection)
            log_warn("Disabled ScriptContext.Error connection: %s", tostring(connection))
        end
    end

    -- Place Hooks
    orig_debug_info = hookfunction(debug.info, newcclosure(on_debug_info))
    orig_os_clock = hookfunction(os.clock, newcclosure(on_os_clock))
    orig_is_a_func = hookfunction(is_a, newcclosure(on_is_a)) -- Hook the function 'is_a'
    orig_get_property_changed_signal = hookfunction(game.GetPropertyChangedSignal, newcclosure(on_get_property_changed_signal))
    if content_provider.PreloadAsync then -- Check if function exists
        orig_preload_async = hookfunction(content_provider.PreloadAsync, newcclosure(on_preload_async))
    end
    if log_service.GetLogHistory then -- Check if function exists
        orig_log_service_gethistory = hookfunction(log_service.GetLogHistory, newcclosure(on_log_service))
    end
    orig_game_namecall = hookmetamethod(game, "__namecall", newcclosure(on_game_namecall))
    orig_game_index = hookmetamethod(game, "__index", newcclosure(on_game_index))
    orig_game_newindex = hookmetamethod(game, "__newindex", newcclosure(on_game_newindex))

    log_warn("FF2 Hider hooks placed successfully.")

    -- Connect Hider Event Listeners
    workspace.DescendantAdded:Connect(on_workspace_descendant_added_sigma)
	workspace.ChildAdded:Connect(on_workspace_child_added_sigma)
	run_service.PreSimulation:Connect(on_update_sigma_hider)

    -- Initial population for existing items
    for _, inst in ipairs(workspace:GetDescendants()) do on_workspace_descendant_added_sigma(inst) end
    for _, inst in ipairs(workspace:GetChildren()) do on_workspace_child_added_sigma(inst) end

    -- Hook Catch Function (Requires ClientMain to load)
    task.spawn(function() -- Run in new thread to avoid yielding
        local client_main = player_scripts and player_scripts:WaitForChild("ClientMain", 30)
        if not client_main then
            warn("[FF2 Hider] ClientMain not found, cannot hook catch function.")
            return
        end
        local game_controls_module = client_main:FindFirstChild("GameControls") or client_main:FindFirstChild("OtherControls")
        if not game_controls_module then
             warn("[FF2 Hider] GameControls/OtherControls module not found.")
             return
        end

        local catch_module_script = require(game_controls_module)
        if catch_module_script and catch_module_script.Catch and typeof(catch_module_script.Catch) == "function" then
            orig_catch_func = hookfunction(catch_module_script.Catch, LPH_NO_VIRTUALIZE(function(...)
                local start_time = os.clock()
                if orig_catch_func then pcall(orig_catch_func, ...) end -- Call original safely
                -- Heuristic: if the call took significant time, likely a real catch attempt finished
                if os.clock() - start_time > 0.05 then is_catching = false end -- Reset after a short delay
                -- log_warn("on_catch(...) -> is_catching[%s]", tostring(is_catching)) -- Spammy
            end))
            log_warn("[FF2 Hider] Successfully hooked Catch function.")
        else
            warn("[FF2 Hider] Could not find or hook Catch function in module.")
        end
    end)

    --[[ -- Failsafe Hooking (Removed for potential instability/detection)
    local place_failsafe_func = LPH_NO_VIRTUALIZE(function() ... end)
    -- place_failsafe_func()
    -- log_warn("Failsafe placed (experimental).")
    --]]

end)

log_warn("FF2 Hider initialization complete.")

--========================================================================
--[ Cheat Feature Functions ]
--========================================================================

-- Function to Simulate Mouse Input (Placeholder for Undetectability)
local function SimulateMouseInput(targetPosition)
    --[[ !! IMPORTANT !!
         This requires an exploit-specific function like `mousemoveto` or `mousemove_relative`.
         Directly setting Camera CFrame is detectable. Using UserInputService:InjectMouse... is also detectable.
         Replace the comment below with your exploit's specific mouse movement function.
         Example:
         if syn and syn.mousemoveto then syn.mousemoveto(screenPos.X, screenPos.Y) end
         if getexecutorname() == "Script-Ware" then mousemoveto(screenPos.X, screenPos.Y) end
    --]]
    local screenPos, onScreen = CurrentCamera:WorldToScreenPoint(targetPosition)
    if onScreen then
        -- log_warn("Simulating mouse move towards: %s", tostring(Vector2.new(screenPos.X, screenPos.Y)))
        -- Replace with: YourExploit.MouseMove(screenPos.X, screenPos.Y)
    end
end

-- Function to Check if Spectated
local function IsSpectated()
    if not LocalPlayer then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") and player.CameraMode == Enum.CameraMode.LockFirstPerson then
                -- Check CameraSubject more reliably
                local currentSubject = player.CameraSubject
                if currentSubject == LocalPlayer.Character or currentSubject == LocalPlayer.Character.PrimaryPart then
                    -- log_warn("Spectated by: %s", player.Name)
                    return true
                end
            end
        end
    end
    return false
end


-- Function to Check Game State (Context-Aware Features - Needs Game Specific Logic)
local function IsGameActive()
    -- Placeholder: Check if the game is in a playable state
    -- Example: return game:GetService("ReplicatedStorage").GameStatus.Value == "InProgress"
    -- Example: return CoreGui:FindFirstChild("InGameUI", true) ~= nil
    return true -- Replace with actual game state check if available
end

-- Function to Find Closest Player for Aimbot/ESP etc.
local function FindClosestPlayer(useTargetList)
    local closestPlayer = nil
    local shortestDistance = Config.AimbotFOV -- Use FOV as initial max distance for aimbot
    local playerHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not playerHRP then return nil, math.huge end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetHRP and humanoid and humanoid.Health > 0 then
                 -- Team Check (Optional - Add UI toggle if needed)
                 -- if player.Team == LocalPlayer.Team then continue end

                 -- Check against target list if enabled
                if useTargetList and Config.TargetSpecificPlayers then
                    local found = false
                    for _, targetName in ipairs(Config.TargetPlayerList) do
                        if player.Name == targetName then
                            found = true
                            break
                        end
                    end
                    if not found then continue end -- Skip if not in target list
                end

                local distance = (playerHRP.Position - targetHRP.Position).Magnitude
                if distance < shortestDistance then
                    -- FOV Check (Optional - Check if target is within screen bounds or angle)
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetHRP.Position)
                    if onScreen then -- Simple on-screen check, could be refined with angle check
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer, shortestDistance
end

-- Quarterback Aimbot Function (Improved)
local function QuarterbackAimbot()
    if not Config.QBAimbotEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    -- Check if player has the ball (simple check, might need refinement for specific game)
    local hasBall = LocalPlayer.Character:FindFirstChild("Football") or Workspace:FindFirstChild("Football") -- More generic check
    if not hasBall then return end

    local closestPlayer, dist = FindClosestPlayer(true) -- Use target list setting
    if not closestPlayer or not closestPlayer.Character then return end

    local targetPart = closestPlayer.Character:FindFirstChild("Head") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local football = Workspace:FindFirstChild("Football") -- Find the actual football
    if not football then return end -- Ensure football exists in workspace

    -- Simple check if WE are holding the ball (more reliable check might be needed)
    local ballHolder = football:FindFirstChild("Holder") -- Example: Check for a holder value/attribute
    if ballHolder and ballHolder.Value ~= LocalPlayer then
       -- return -- Only aim if we are holding or ball is free? Adjust logic as needed.
    end


    -- Aim Offset Logic (Legit vs Rage)
    local aimOffset = Vector3.new(0, 0, 0)
    if Config.AimbotMode == "Legit" then
        -- Small, random offsets to simulate inaccuracy
        aimOffset = Vector3.new(
            math.random(-10, 10) / 10, -- +/- 1 stud max
            math.random(-10, 10) / 10,
            math.random(-10, 10) / 10
        ) * 0.5 * (1 / Config.StealthLevel) -- Smaller offset with higher stealth
    else -- Rage Mode
        -- Minimal or zero offset for precision
         aimOffset = Vector3.new(0, math.random(0,5)/10, 0) -- Slight vertical offset maybe?
    end

    local playerHRP = LocalPlayer.Character.HumanoidRootPart
    if not playerHRP then return end

    local aimPosition = targetPart.Position + aimOffset
    local aimDirection = (aimPosition - playerHRP.Position).Unit

    -- Predict target movement (simple prediction)
    local targetVelocity = targetPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
    local timeToTarget = dist / (100 * Config.StealthLevel) -- Estimate time based on throw speed
    local predictedPosition = aimPosition + (targetVelocity * timeToTarget)
    aimDirection = (predictedPosition - playerHRP.Position).Unit


    -- Apply velocity to the football
    -- IMPORTANT: Directly setting velocity might be detected or overridden by game scripts.
    -- Consider using RemoteEvents if the game uses them for throwing, or other methods if available.
    local currentVelocity = football.AssemblyLinearVelocity
    local targetVelocityMagnitude = 100 * Config.StealthLevel -- Adjust speed based on stealth
    local targetVelocityVector = aimDirection * targetVelocityMagnitude

    -- Smooth the velocity change
    football.AssemblyLinearVelocity = currentVelocity:Lerp(targetVelocityVector, Config.AimbotSmoothing)

    -- Simulate Mouse Movement towards target
    SimulateMouseInput(predictedPosition)
end

-- Silent Aim Function (Improved)
local function SilentAim()
    if not Config.SilentAimEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or not football.Position then return end

     -- Only run if ball is actually moving (e.g., thrown)
    if football.AssemblyLinearVelocity.Magnitude < 10 then return end

    local closestPlayer, dist = FindClosestPlayer(true) -- Use target list setting
    if not closestPlayer or not closestPlayer.Character then return end

    local targetPart = closestPlayer.Character:FindFirstChild("Head") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    -- Check distance between *football* and target
    local footballDistance = (football.Position - targetPart.Position).Magnitude

    if footballDistance < Config.SilentAimRange * Config.StealthLevel then
        -- Redirect ball velocity towards target head
        local aimDirection = (targetPart.Position - football.Position).Unit
        local currentSpeed = football.AssemblyLinearVelocity.Magnitude
        -- Don't drastically change speed, just direction
        football.AssemblyLinearVelocity = aimDirection * math.max(currentSpeed, 50 * Config.StealthLevel) -- Ensure minimum speed
        -- log_warn("Silent Aim corrected trajectory")
    end
end

-- ESP Data Storage
local ESP_Elements = {} -- { Player = { Tracer=Drawing, NameTag=Drawing, HealthBar=Drawing } }

-- ESP Creation Function
local function CreateESPForPlayer(player)
    if not Drawing then warn("Drawing library not available for ESP."); return end
    if ESP_Elements[player] then return end -- Already exists

    local elements = {}
    elements.Tracer = Drawing.new("Line")
    elements.Tracer.Visible = false
    elements.Tracer.Thickness = Config.ESPTracerThickness
    elements.Tracer.Transparency = Config.ESPBoxTransparency -- Use Transparency if available, otherwise calculate from Color
    elements.Tracer.Color = Color3.fromRGB(255, 0, 0) -- Default color
    elements.Tracer.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y) -- Start from bottom center
    elements.Tracer.To = Vector2.new(0, 0)

    elements.NameTag = Drawing.new("Text")
    elements.NameTag.Visible = false
    elements.NameTag.Size = Config.ESPNameSize
    elements.NameTag.Center = true
    elements.NameTag.Outline = true
    elements.NameTag.Font = Drawing.Fonts.Plex -- Ensure this font exists
    elements.NameTag.Color = Color3.fromRGB(255, 255, 255)
    elements.NameTag.Text = player.Name

    elements.HealthBar = Drawing.new("Square") -- Using Square for health bar background/fill
    elements.HealthBar.Visible = false
    elements.HealthBar.Thickness = 1 -- Or border size
    elements.HealthBar.Filled = true
    elements.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    elements.HealthBar.Size = Vector2.new(50, 5) -- Default size
    elements.HealthBar.Position = Vector2.new(0, 0)
     -- Maybe add a background bar too if needed
    elements.HealthBarBg = Drawing.new("Square")
    elements.HealthBarBg.Visible = false
    elements.HealthBarBg.Thickness = 1
    elements.HealthBarBg.Filled = false -- Outline or background
    elements.HealthBarBg.Color = Color3.fromRGB(50, 50, 50)
    elements.HealthBarBg.Size = Vector2.new(50, 5)
    elements.HealthBarBg.Position = Vector2.new(0,0)


    ESP_Elements[player] = elements
end

-- ESP Update Function (Call this in RenderStepped)
local function UpdateESP()
    if not Config.ESPEnabled or Config.PanicKeyEnabled == false then
        -- Hide all existing ESP elements if disabled
        for player, elements in pairs(ESP_Elements) do
            if elements then
                if elements.Tracer then elements.Tracer.Visible = false end
                if elements.NameTag then elements.NameTag.Visible = false end
                if elements.HealthBar then elements.HealthBar.Visible = false end
                if elements.HealthBarBg then elements.HealthBarBg.Visible = false end
            end
        end
        return
    end

    if not LocalPlayer or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local playerHRP_Pos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid and hrp and humanoid.Health > 0 then
            local distance = (playerHRP_Pos - hrp.Position).Magnitude

            if distance <= Config.ESPMaxDistance then
                if not ESP_Elements[player] then CreateESPForPlayer(player) end -- Create if doesn't exist

                local elements = ESP_Elements[player]
                if not elements then continue end -- Skip if creation failed

                local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    -- Determine Color (Team-based or Hostile)
                    local espColor = Color3.fromRGB(255, 0, 0) -- Default Red (Enemy)
                    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        espColor = Color3.fromRGB(0, 255, 0) -- Green (Team)
                    end

                    -- Update Tracer
                    if elements.Tracer then
                        elements.Tracer.Visible = true
                        elements.Tracer.Color = espColor
                        elements.Tracer.Thickness = Config.ESPTracerThickness
                        -- elements.Tracer.Transparency = Config.ESPBoxTransparency -- Update transparency if needed
                        elements.Tracer.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
                        elements.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    end

                    -- Update Name Tag
                    if elements.NameTag then
                        elements.NameTag.Visible = true
                        elements.NameTag.Color = espColor
                        elements.NameTag.Size = Config.ESPNameSize
                        elements.NameTag.Text = string.format("%s [%dm]", player.Name, math.floor(distance))
                        elements.NameTag.Position = Vector2.new(screenPos.X, screenPos.Y - 20) -- Position above head
                    end

                    -- Update Health Bar
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local healthColor = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    local barWidth = 50 -- Fixed width
                    local barHeight = 5

                    if elements.HealthBar then
                        elements.HealthBar.Visible = true
                        elements.HealthBar.Color = healthColor
                        elements.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
                        elements.HealthBar.Position = Vector2.new(screenPos.X - barWidth / 2, screenPos.Y - 15) -- Position below name
                    end
                     if elements.HealthBarBg then
                        elements.HealthBarBg.Visible = true
                        elements.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
                        elements.HealthBarBg.Position = Vector2.new(screenPos.X - barWidth / 2, screenPos.Y - 15)
                    end

                else
                    -- Hide elements if off-screen
                    if elements then
                        if elements.Tracer then elements.Tracer.Visible = false end
                        if elements.NameTag then elements.NameTag.Visible = false end
                        if elements.HealthBar then elements.HealthBar.Visible = false end
                         if elements.HealthBarBg then elements.HealthBarBg.Visible = false end
                    end
                end
            else
                -- Hide elements if too far
                 if ESP_Elements[player] then
                    local elements = ESP_Elements[player]
                    if elements.Tracer then elements.Tracer.Visible = false end
                    if elements.NameTag then elements.NameTag.Visible = false end
                    if elements.HealthBar then elements.HealthBar.Visible = false end
                     if elements.HealthBarBg then elements.HealthBarBg.Visible = false end
                end
            end
        else
            -- Player is dead or invalid, hide elements
            if ESP_Elements[player] then
                local elements = ESP_Elements[player]
                if elements.Tracer then elements.Tracer.Visible = false end
                if elements.NameTag then elements.NameTag.Visible = false end
                if elements.HealthBar then elements.HealthBar.Visible = false end
                if elements.HealthBarBg then elements.HealthBarBg.Visible = false end
            end
        end
    end
end

-- ESP Cleanup Function (Call this periodically or on PlayerRemoving)
local function CleanupESP()
    for player, elements in pairs(ESP_Elements) do
        local playerExists = pcall(function() return Players:GetPlayerByUserId(player.UserId) end)
        if not playerExists or not player:IsDescendantOf(Players) then
            -- Remove Drawing objects
            if elements then
                if elements.Tracer then elements.Tracer:Remove() end
                if elements.NameTag then elements.NameTag:Remove() end
                if elements.HealthBar then elements.HealthBar:Remove() end
                 if elements.HealthBarBg then elements.HealthBarBg:Remove() end
            end
            ESP_Elements[player] = nil -- Remove from table
        end
    end
end

-- Magnet Catch Function (Improved)
local function MagnetCatch()
    if not Config.MagnetCatchEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    if not firetouchinterest then return end -- Essential for this feature

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") then return end

    local character = LocalPlayer.Character
    if not character then return end

    -- Use Left Arm or HumanoidRootPart as reference point
    local catchPart = character:FindFirstChild("Left Arm") or character:FindFirstChild("HumanoidRootPart")
    if not catchPart then return end

    local distance = (catchPart.Position - football.Position).Magnitude
    local effectiveRange = Config.MagnetCatchRange * Config.StealthLevel

    if distance < effectiveRange then
        -- Trigger touch interest slightly delayed/randomly for less detection
        if math.random() < 0.5 then -- Add randomness
            task.wait(math.random(1, 5) / 100) -- Small random delay (0.01 to 0.05s)
            -- log_warn("Magnet Catch: Firing touch interest")
            -- Fire both states to simulate a quick touch
            local success1, err1 = pcall(firetouchinterest, catchPart, football, 0) -- Touch start
            task.wait() -- Crucial tiny wait
            local success2, err2 = pcall(firetouchinterest, catchPart, football, 1) -- Touch end
            -- if not success1 or not success2 then log_warn("Magnet Catch firetouchinterest failed: %s / %s", tostring(err1), tostring(err2)) end
        end
    end
end


-- Speed Boost Function (Now controlled by Hider hook + Config.SpeedEnabled/Amount)
--[[
local function SpeedBoost()
    -- This function is now effectively handled by the __newindex hook in the hider
    -- when Config.SpeedEnabled is true. Keep the logic commented out or remove.
    -- if not Config.SpeedEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    -- if Config.AntiSpectate and IsSpectated() then return end
    -- if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    --     local humanoid = LocalPlayer.Character.Humanoid
    --     -- Directly setting WalkSpeed might conflict with the hook.
    --     -- The hook already sets it based on Config.SpeedAmount.
    --     -- If the hook isn't working, uncomment this and remove the hook logic for WalkSpeed.
    --     -- humanoid.WalkSpeed = Config.SpeedAmount * Config.StealthLevel
    -- end
end
--]]

-- Infinite Jump Function (Improved Handling)
local JumpConnection = nil
local function InfiniteJump()
    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if Config.InfiniteJumpEnabled and Config.PanicKeyEnabled ~= false and IsGameActive() and humanoid then
        if not JumpConnection or not JumpConnection.Connected then
            JumpConnection = UserInputService.JumpRequest:Connect(function()
                if Config.InfiniteJumpEnabled and humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                     -- Check if anti-spectate applies
                    if Config.AntiSpectate and IsSpectated() then return end
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    -- log_warn("Infinite Jump triggered")
                end
            end)
            -- log_warn("Infinite Jump enabled.")
        end
    else
        if JumpConnection and JumpConnection.Connected then
            JumpConnection:Disconnect()
            JumpConnection = nil
            -- log_warn("Infinite Jump disabled.")
        end
    end
end
-- Call InfiniteJump once initially and whenever the toggle changes to manage the connection
InfiniteJump() -- Initial setup

-- Auto Catch Function (Improved - More Aggressive Touch Spam)
local function AutoCatch()
    if not Config.AutoCatchEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    if not firetouchinterest then return end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") then return end

    local character = LocalPlayer.Character
    if not character then return end
    local catchPart = character:FindFirstChild("Left Arm") or character:FindFirstChild("HumanoidRootPart")
    if not catchPart then return end

    local distance = (catchPart.Position - football.Position).Magnitude
    local effectiveRange = Config.AutoCatchRange -- No stealth multiplier for aggressive auto-catch

    if distance < effectiveRange then
        -- Spam touch interest more aggressively to ensure catch
        for _ = 1, 3 do -- Try multiple times quickly
            -- log_warn("Auto Catch: Firing touch interest attempt")
            local s1, e1 = pcall(firetouchinterest, catchPart, football, 0)
            task.wait()
            local s2, e2 = pcall(firetouchinterest, catchPart, football, 1)
            -- if not s1 or not s2 then log_warn("Auto Catch firetouchinterest failed: %s / %s", tostring(e1), tostring(e2)) end

            -- Check if ball was caught (parent changed)
            if not football.Parent or football.Parent ~= Workspace then
                -- log_warn("Auto Catch Successful!")
                break -- Stop spamming if caught
            end
            task.wait(0.05) -- Short delay between attempts
        end
    end
end


-- Ball Prediction Function (Improved - Uses Drawing)
local BallPredictionLine = nil
local function UpdateBallPrediction()
    if not Drawing then return end -- Need drawing library

    if not Config.BallPredictionEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then
        if BallPredictionLine then
            BallPredictionLine:Remove()
            BallPredictionLine = nil
        end
        return
    end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or football.AssemblyLinearVelocity.Magnitude < 5 then
        -- Hide line if ball doesn't exist or isn't moving significantly
        if BallPredictionLine then BallPredictionLine.Visible = false end
        return
    end

    if not BallPredictionLine then
        BallPredictionLine = Drawing.new("Line")
        BallPredictionLine.Thickness = 2
        BallPredictionLine.Color = Color3.fromRGB(0, 255, 255) -- Cyan color
        BallPredictionLine.Transparency = 0.3
    end

    local startPos = football.Position
    local velocity = football.AssemblyLinearVelocity
    local gravity = Workspace.Gravity -- Use actual workspace gravity
    local timeStep = 0.05 -- Simulation step
    local maxTime = 1.5 -- Predict for 1.5 seconds max
    local endPos = startPos

    -- Simple projectile calculation loop
    local currentPos = startPos
    local currentVel = velocity
    for t = 0, maxTime, timeStep do
        currentPos = currentPos + currentVel * timeStep + 0.5 * Vector3.new(0, -gravity, 0) * timeStep^2
        currentVel = currentVel + Vector3.new(0, -gravity, 0) * timeStep
        -- Optional: Add air resistance approximation if needed
        -- currentVel = currentVel * (1 - airResistanceConstant * timeStep)

        -- Optional: Check for ground collision (simple check)
        -- local ray = Ray.new(endPos, (currentPos - endPos).Unit * (currentPos - endPos).Magnitude)
        -- local hitPart, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, {football, LocalPlayer.Character})
        -- if hitPart then
        --    endPos = hitPos -- Stop prediction at collision point
        --    break
        -- end

        endPos = currentPos -- Update end position for the line

        -- More advanced: Draw multiple segments for a curve
        -- DrawSegment(previousPos, currentPos)
        -- previousPos = currentPos
    end

    -- Draw a single line from start to predicted end point
    local startScreen, onScreenStart = CurrentCamera:WorldToViewportPoint(startPos)
    local endScreen, onScreenEnd = CurrentCamera:WorldToViewportPoint(endPos)

    if onScreenStart and onScreenEnd then
        BallPredictionLine.Visible = true
        BallPredictionLine.From = Vector2.new(startScreen.X, startScreen.Y)
        BallPredictionLine.To = Vector2.new(endScreen.X, endScreen.Y)
    else
        BallPredictionLine.Visible = false -- Hide if ends go off-screen
    end
end


-- Human Behavior Simulator
local function SimulateHumanBehavior()
    if not Config.HumanizationEnabled or Config.PanicKeyEnabled == false or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end -- Don't act weird if watched

    if math.random() < Config.HumanizationFrequency then -- Chance to trigger per frame
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local action = math.random(1, 4) -- Increased action count
        if action == 1 then
            -- Tiny random mouse movement (Requires exploit function)
             -- SimulateMouseInput(CurrentCamera.CFrame.LookVector * 10 + Vector3.new(math.random(-2,2), math.random(-2,2), 0)) -- Example
             -- YourExploit.MouseMoveRelative(math.random(-5,5), math.random(-5,5)) -- Placeholder
             -- log_warn("Human Sim: Mouse Jiggle")
        elseif action == 2 then
            -- Small random brief movement
            humanoid:Move(Vector3.new(math.random(-5, 5)/10, 0, math.random(-5, 5)/10), false)
            task.wait(0.1)
            humanoid:Move(Vector3.zero, false)
            -- log_warn("Human Sim: Movement Twitch")
        elseif action == 3 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            -- Occasional small jump
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            -- log_warn("Human Sim: Random Jump")
        elseif action == 4 then
            -- Slight camera look adjustment (Requires exploit function or CFrame manipulation)
            -- This is harder to make look natural and safe. Be careful.
            -- local currentCF = CurrentCamera.CFrame
            -- local randomLook = CFrame.Angles(0, math.rad(math.random(-1,1)), 0) * CFrame.Angles(math.rad(math.random(-1,1)), 0, 0)
            -- CurrentCamera.CFrame = currentCF * randomLook -- Potentially detectable CFrame setting
             -- log_warn("Human Sim: Camera Adjustment")
        end
    end
end

--========================================================================
--[ UI Setup (Fluent) ]
--========================================================================
local function SetupUI()
    if _G.FluentLoaded then return end -- Prevent multiple UI loads

    Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))() -- Use HttpGet without Async
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

    if not Library then
        warn("Failed to load Fluent library.")
        return
    end
     _G.FluentLoaded = true

    -- Window
    local Window = Library:CreateWindow({
        Title = "FF2 Supreme Cheats (Combined)",
        SubTitle = "Features & Bypass",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 450), -- Adjusted size
        Acrylic = true,
        Theme = "Dark", -- Or "Light", "Grey" etc.
        MinimizeKey = Enum.KeyCode.RightControl,
    })

    -- Tabs
    local MainTab = Window:CreateTab({ Title = "Main", Icon = "settings" })
    local CombatTab = Window:CreateTab({ Title = "Combat", Icon = "sword" })
    local MovementTab = Window:CreateTab({ Title = "Movement", Icon = "humanoid" })
    local VisualsTab = Window:CreateTab({ Title = "Visuals", Icon = "eye" })
    local MiscTab = Window:CreateTab({ Title = "Misc", Icon = "list" })

    --[[ Main Tab ]]--
    MainTab:CreateToggle("PanicKey", {
        Title = "Panic Key (Enable/Disable All)",
        Description = "Quickly toggle all features on or off.",
        Enabled = Config.PanicKeyEnabled, -- Default to true
        Callback = function(Value) Config.PanicKeyEnabled = Value end,
    })
    MainTab:CreateToggle("AntiSpectate", {
        Title = "Anti-Spectate",
        Description = "Disable features when someone is spectating you.",
        Enabled = Config.AntiSpectate,
        Callback = function(Value) Config.AntiSpectate = Value end,
    })
    MainTab:CreateToggle("Humanization", {
        Title = "Enable Humanization",
        Description = "Simulate small random actions to appear less robotic.",
        Enabled = Config.HumanizationEnabled,
        Callback = function(Value) Config.HumanizationEnabled = Value end,
    })
    MainTab:CreateSlider("HumanizationFrequency", {
        Title = "Humanization Frequency",
        Description = "Lower value = less frequent actions.",
        Default = Config.HumanizationFrequency * 100, Min = 0, Max = 20, Rounding = 1, Suffix = "%",
        Callback = function(Value) Config.HumanizationFrequency = Value / 100 end,
    })
    MainTab:CreateSlider("StealthLevel", {
        Title = "Stealth Level",
        Description = "Adjusts ranges/speeds. Lower = Less Obvious.",
        Default = Config.StealthLevel * 10, Min = 1, Max = 20, Rounding = 1, -- Scale 0.1-2.0
        Callback = function(Value) Config.StealthLevel = Value / 10 end,
    })

     --[[ Combat Tab ]]--
    CombatTab:CreateToggle("QBAimbot", {
        Title = "Quarterback Aimbot",
        Enabled = Config.QBAimbotEnabled,
        Callback = function(Value) Config.QBAimbotEnabled = Value end,
    })
    CombatTab:CreateDropdown("AimbotMode", {
        Title = "Aimbot Mode",
        Values = {"Legit", "Rage"},
        Default = Config.AimbotMode,
        Callback = function(Value) Config.AimbotMode = Value end,
    })
     CombatTab:CreateSlider("AimbotFOV", {
        Title = "Aimbot FOV",
        Description = "Maximum distance for aimbot.",
        Default = Config.AimbotFOV, Min = 10, Max = 1000, Rounding = 0,
        Callback = function(Value) Config.AimbotFOV = Value end,
    })
     CombatTab:CreateSlider("AimbotSmoothing", {
        Title = "Aimbot Smoothing",
        Description = "Lower value = faster lock.",
        Default = Config.AimbotSmoothing * 100, Min = 0, Max = 100, Rounding = 1, Suffix = "%",
        Callback = function(Value) Config.AimbotSmoothing = Value / 100 end,
    })
    CombatTab:CreateToggle("SilentAim", {
        Title = "Silent Aim",
        Description = "Redirects ball mid-air towards target.",
        Enabled = Config.SilentAimEnabled,
        Callback = function(Value) Config.SilentAimEnabled = Value end,
    })
    CombatTab:CreateSlider("SilentAimRange", {
        Title = "Silent Aim Range",
        Description = "Max distance from target to activate.",
        Default = Config.SilentAimRange, Min = 5, Max = 150, Rounding = 0,
        Callback = function(Value) Config.SilentAimRange = Value end,
    })
    CombatTab:CreateToggle("TargetSpecific", {
        Title = "Target Specific Players",
        Description = "Only aim/ESP players in the list.",
        Enabled = Config.TargetSpecificPlayers,
        Callback = function(Value) Config.TargetSpecificPlayers = Value end,
    })
     CombatTab:CreateInput("TargetList", {
        Title = "Target List (CSV)",
        Description = "Player names, separated by commas.",
        Placeholder = "Player1,Player2,Another",
        Default = table.concat(Config.TargetPlayerList, ","),
        Callback = function(Value)
            local list = {}
            for name in string.gmatch(Value, "([^,]+)") do
                table.insert(list, name:match("^%s*(.-)%s*$")) -- Trim whitespace
            end
            Config.TargetPlayerList = list
        end,
    })


    --[[ Movement Tab ]]--
    MovementTab:CreateToggle("SpeedHack", {
        Title = "Enable Speed",
        Enabled = Config.SpeedEnabled,
        Callback = function(Value) Config.SpeedEnabled = Value end,
    })
    MovementTab:CreateSlider("SpeedAmount", {
        Title = "Speed Amount",
        Default = Config.SpeedAmount, Min = 16, Max = 100, Rounding = 0,
        Callback = function(Value) Config.SpeedAmount = Value end,
    })
    MovementTab:CreateToggle("JumpPowerHack", {
        Title = "Enable Jump Power",
        Enabled = Config.JumpPowerEnabled,
        Callback = function(Value) Config.JumpPowerEnabled = Value end,
    })
     MovementTab:CreateSlider("JumpPowerAmount", {
        Title = "Jump Power Amount",
        Default = Config.JumpPowerAmount, Min = 50, Max = 200, Rounding = 0,
        Callback = function(Value) Config.JumpPowerAmount = Value end,
    })
     MovementTab:CreateToggle("InfiniteJump", {
        Title = "Infinite Jump",
        Enabled = Config.InfiniteJumpEnabled,
        Callback = function(Value)
             Config.InfiniteJumpEnabled = Value
             InfiniteJump() -- Re-evaluate connection state
        end,
    })
    MovementTab:CreateToggle("BoostOnHeight", {
        Title = "Air Strafe/Boost",
        Description = "Allows boosting mid-air by turning (hider).",
        Enabled = Config.BoostOnHeight,
        Callback = function(Value) Config.BoostOnHeight = Value end,
    })
     MovementTab:CreateSlider("BoostAmount", {
        Title = "Boost Multiplier",
        Default = Config.BoostAmount, Min = 1.0, Max = 5.0, Rounding = 2,
        Callback = function(Value) Config.BoostAmount = Value end,
    })


    --[[ Visuals Tab ]]--
    VisualsTab:CreateToggle("ESP", {
        Title = "Enable Player ESP",
        Enabled = Config.ESPEnabled,
        Callback = function(Value) Config.ESPEnabled = Value end,
    })
    VisualsTab:CreateSlider("ESPMaxDistance", {
        Title = "ESP Max Distance",
        Default = Config.ESPMaxDistance, Min = 50, Max = 2000, Rounding = 0,
        Callback = function(Value) Config.ESPMaxDistance = Value end,
    })
    VisualsTab:CreateSlider("ESPNameSize", {
        Title = "ESP Name Size",
        Default = Config.ESPNameSize, Min = 8, Max = 24, Rounding = 0,
        Callback = function(Value) Config.ESPNameSize = Value end,
    })
    VisualsTab:CreateSlider("ESPTracerThickness", {
        Title = "ESP Tracer Thickness",
        Default = Config.ESPTracerThickness, Min = 1, Max = 5, Rounding = 0,
        Callback = function(Value) Config.ESPTracerThickness = Value end,
    })
    VisualsTab:CreateToggle("BallPrediction", {
        Title = "Enable Ball Prediction Line",
        Enabled = Config.BallPredictionEnabled,
        Callback = function(Value) Config.BallPredictionEnabled = Value end,
    })
    VisualsTab:CreateToggle("VisualizeCatchZone", {
        Title = "Visualize Extended Catch Zone",
        Description = "Shows the area added by the hider's catch logic.",
        Enabled = Config.VisualizeCatchZone,
        Callback = function(Value) Config.VisualizeCatchZone = Value end,
    })
     VisualsTab:CreateSlider("FieldOfView", { -- Keep the original FOV slider
        Title = "Field Of View",
        Description = "Set the camera field of view.",
        Default = CurrentCamera.FieldOfView, Min = 70, Max = 120, Rounding = 1,
        Callback = function(Value) workspace.CurrentCamera.FieldOfView = Value end,
    })


    --[[ Misc Tab ]]--
     MiscTab:CreateToggle("MagnetCatch", {
        Title = "Magnet Catch",
        Description = "Attempts to catch ball using touch interest.",
        Enabled = Config.MagnetCatchEnabled,
        Callback = function(Value) Config.MagnetCatchEnabled = Value end,
    })
    MiscTab:CreateSlider("MagnetCatchRange", {
        Title = "Magnet Catch Range",
        Default = Config.MagnetCatchRange, Min = 5, Max = 50, Rounding = 0,
        Callback = function(Value) Config.MagnetCatchRange = Value end,
    })
    MiscTab:CreateToggle("AutoCatch", {
        Title = "Auto Catch (Aggressive)",
        Description = "Spams touch interest when ball is close.",
        Enabled = Config.AutoCatchEnabled,
        Callback = function(Value) Config.AutoCatchEnabled = Value end,
    })
    MiscTab:CreateSlider("AutoCatchRange", {
        Title = "Auto Catch Range",
        Default = Config.AutoCatchRange, Min = 1, Max = 30, Rounding = 0,
        Callback = function(Value) Config.AutoCatchRange = Value end,
    })
    MiscTab:CreateToggle("ReduceCatchTackle", {
        Title = "Reduce Catch Tackle Size",
        Description = "Shrinks catch parts when holding ball (hider).",
        Enabled = Config.ReduceCatchTackle,
        Callback = function(Value) Config.ReduceCatchTackle = Value end,
    })
    MiscTab:CreateToggle("HiderSilentMode", {
        Title = "Hider Silent Mode",
        Description = "Disables hider sounds (like boost).",
        Enabled = Config.SilentMode,
        Callback = function(Value) Config.SilentMode = Value end,
    })
    MiscTab:CreateInput("FPSCap", {
        Title = "FPS Cap",
        Description = "0 for unlimited.", Default = 0, Numeric = true, Max = 360,
        Finished = true, -- Only trigger callback when done editing
        Callback = function(Value)
            local num = tonumber(Value)
            if num then setfpscap(num) end
        end,
    })
    local cpuOffsetInput = MiscTab:CreateInput("CPUOffset", {
        Title = "CPU Offset (Hider)",
        Description = "!!! Modify with caution !!! Changes os.clock() value.",
        Default = cpu_offset_value, Numeric = true, Max = 9999, Min = 100,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                cpu_offset_value = math.clamp(math.round(num), MIN_CPU_OFFSET, MAX_CPU_OFFSET)
                -- Save the new offset
                pcall(function() if writefile then writefile("cpu_offset.txt", tostring(cpu_offset_value)) end end)
                log_warn("CPU Offset updated to: %d", cpu_offset_value)
            else -- Revert input field if invalid
                -- cpuOffsetInput:SetValue(cpu_offset_value) -- Find Fluent API to reset value if needed
            end
        end,
    })


    -- Save Manager & Interface Manager Setup
    task.spawn(function() -- Use task.spawn for async operations if needed
        pcall(function()
            if InterfaceManager and SaveManager then
                 InterfaceManager:SetLibrary(Library)
                 InterfaceManager:SetFolder("FF2Supreme/Interface") -- Unique folder name
                 InterfaceManager:BuildInterfaceSection(MainTab) -- Add Interface Manager controls to Main Tab

                 SaveManager:SetLibrary(Library)
                 SaveManager:SetFolder("FF2Supreme/Save") -- Unique folder name
                 -- SaveManager:IgnoreThemeSettings() -- Uncomment if you don't want theme saved
                 -- Ignore specific settings if necessary: SaveManager:SetIgnoreIndexes({"CPUOffset"})
                 SaveManager:BuildConfigSection(MainTab) -- Add Save Manager controls to Main Tab
                 SaveManager:LoadAutoloadConfig() -- Load saved settings
                 log_warn("Save/Interface Managers initialized.")
            else
                warn("SaveManager or InterfaceManager failed to load.")
            end
        end)
    end)

    -- Select Initial Tab & Minimize
    Window:SelectTab(1)
    -- Window:Minimize() -- Keep open initially

     log_warn("Fluent UI setup complete.")
end

--========================================================================
--[ Main Loop & Event Connections ]
--========================================================================
local MainLoopConnection = nil

local function StartMainLoop()
    if MainLoopConnection and MainLoopConnection.Connected then return end -- Already running

    local frameCount = 0
    MainLoopConnection = RunService.RenderStepped:Connect(function(dt)
        -- Run expensive operations less frequently
        frameCount = frameCount + 1

        -- Always run (or check enablement inside)
        UpdateESP()
        QuarterbackAimbot()
        SilentAim()
        MagnetCatch()
        AutoCatch()
        UpdateBallPrediction()
        SimulateHumanBehavior()

        -- Less frequent updates
        if frameCount % 30 == 0 then -- Roughly every half second
             CleanupESP()
        end
         if frameCount % 15 == 0 then -- Check spectate status less often
             -- Can store IsSpectated() result if needed elsewhere frequently
        end

        -- Reset counter
        if frameCount >= 60 then frameCount = 0 end
    end)
    log_warn("Main cheat loop started.")
end

local function StopMainLoop()
    if MainLoopConnection and MainLoopConnection.Connected then
        MainLoopConnection:Disconnect()
        MainLoopConnection = nil
        -- Clean up visuals immediately when stopped
        CleanupESP()
        if BallPredictionLine then pcall(function() BallPredictionLine:Remove() end); BallPredictionLine = nil end
        log_warn("Main cheat loop stopped.")
    end
    -- Also ensure infinite jump connection is stopped
    Config.InfiniteJumpEnabled = false
    InfiniteJump()
end

-- Handle player loading and script removal
if LocalPlayer and LocalPlayer.Character then
    StartMainLoop()
else
    LocalPlayer.CharacterAdded:Connect(function(character)
        -- Wait briefly for humanoid etc. to load
        task.wait(1)
        StartMainLoop()
    end)
end

LocalPlayer.CharacterRemoving:Connect(function(character)
    StopMainLoop()
    -- Could add more cleanup here if needed
end)

-- Initial UI Setup
SetupUI()

-- Optional: Add a keybind to toggle the Panic Key
local panicBind = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    -- Example: Use Delete key for panic
    if input.KeyCode == Enum.KeyCode.Delete then
        Config.PanicKeyEnabled = not Config.PanicKeyEnabled
        log_warn("Panic Key Toggled: %s", tostring(Config.PanicKeyEnabled))
        -- Update the UI Toggle state if Fluent allows it
        -- Find the toggle object and call :SetValue(Config.PanicKeyEnabled) if possible
    end
end)

-- Clean up connections when script ends (e.g., player leaves, script is disabled)
-- This might require specific handling depending on the exploit environment
game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then -- Player is leaving
        StopMainLoop()
        if panicBind and panicBind.Connected then panicBind:Disconnect() end
        -- Add cleanup for hider hooks/connections if necessary (difficult/risky)
        log_warn("Script cleanup on player leaving.")
    end
end)
