local Config = { QBAimbotEnabled = false,
    AimbotMode = "Legit",         -- "Legit" or "Rage"
    AimbotTargetPart = "Head",    -- "Head" or "HumanoidRootPart"
    AimbotFOV = 300,              -- Max distance/radius check for targeting
    AimbotSmoothing = 0.15,       -- Lerp alpha for velocity change (0=instant, 1=none)
    AimbotPrediction = true,      -- Simple target velocity prediction

    -- Silent Aim
    SilentAimEnabled = false,
    SilentAimRange = 60,          -- Max distance from target for ball correction

    -- ESP
    ESPEnabled = false,
    ESPMaxDistance = 750,
    ESPTracerThickness = 1,
    ESPNameSize = 12,
    ESPBoxTransparency = 0.5,
    ESPShowTeam = true,           -- Color teammates differently
    ESPShowBoxes = false,         -- Draw bounding boxes (Requires more complex Drawing setup)

    -- Magnet Catch
    MagnetCatchEnabled = false,
    MagnetCatchRange = 30,

    -- Speed Boost (Managed by Hider Hook)
    SpeedEnabled = false,
    SpeedAmount = 21,

    -- Jump Power (Managed by Hider Hook)
    JumpPowerEnabled = false,
    JumpPowerAmount = 55,         -- Default 50 * 1.1 = 55

    -- Infinite Jump
    InfiniteJumpEnabled = false,

    -- Auto Catch
    AutoCatchEnabled = false,
    AutoCatchRange = 18,          -- Slightly larger than default catch range

    -- Ball Prediction
    BallPredictionEnabled = false,

    -- Hider/Bypass Settings
    BoostOnHeight = true,         -- Air strafe/boost enabled
    AngleTolerance = 10,          -- Angle needed for boost
    BoostAmount = 1.15,           -- Boost velocity multiplier
    IncreaseCatchSize = Vector3.new(10, 10, 10), -- Amount to increase visual/touch zone
    VisualizeCatchZone = true,    -- Show the extended catch zone visually
    ReduceCatchTackle = true,     -- Shrink catch parts when holding ball
    SilentMode = false,           -- Hider silent mode (e.g., disable boost sound)

    -- Humanization
    HumanizationEnabled = false,
    HumanizationFrequency = 0.05, -- Chance per frame

    -- Stealth Multiplier (Affects ranges/speeds for less obvious cheating)
    StealthLevel = 1.0,           -- 1.0 = normal, < 1.0 = less obvious, > 1.0 = more obvious

    -- Targeting
    TargetSpecificPlayers = false,
    TargetPlayerList = {"Player1", "Player2"}, -- List of player names if TargetSpecificPlayers is true
}

--========================================================================
--[ Service & Exploit Function Validation ]
--========================================================================
-- Services
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
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- For potential game state checks

-- Exploit Function Placeholders/Checks (CRITICAL)
local hookfunction = hookfunction or error("Exploit Error: 'hookfunction' is required.")
local hookmetamethod = hookmetamethod or error("Exploit Error: 'hookmetamethod' is required.")
local firetouchinterest = firetouchinterest or error("Exploit Error: 'firetouchinterest' is required.")
local Drawing = Drawing or error("Exploit Error: 'Drawing' library is required.")
local getgenv = getgenv or function() return _G end
local setfpscap = setfpscap or function(...) warn("Warning: 'setfpscap' not available.") end
local getconnections = getconnections or function(...) warn("Warning: 'getconnections' not available."); return {} end
local readfile = readfile or function(...) warn("Warning: 'readfile' not available.") return nil end
local writefile = writefile or function(...) warn("Warning: 'writefile' not available.") end
local isfile = isfile or function(...) warn("Warning: 'isfile' not available.") return false end
local newcclosure = newcclosure or function(f) warn("Warning: 'newcclosure' not available, using fallback."); return f end -- Security risk if not real newcclosure
local checkcaller = checkcaller or function() return false end -- Assume not checking caller if unavailable
local getexecutorname = getexecutorname or function() return "Unknown Executor" end
local setthreadidentity = setthreadidentity or function(...) warn("Warning: 'setthreadidentity' not available.") end
local getgc = getgc or function(...) warn("Warning: 'getgc' not available."); return {} end
local getsenv = getsenv or function(sc) -- Function to get script environment (common in exploits)
    warn("Warning: 'getsenv' not available, attempting fallback.")
    local success, env = pcall(function() return getfenv(sc) end) -- Less reliable fallback
    return success and env or {}
end

-- Player Variables
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local CurrentCamera = Workspace.CurrentCamera

--========================================================================
--[ FF2 Hider / Bypass Code - Heavily Integrated ]
--========================================================================
local HIDER_PREFIX = "[FF2 Bypass] "
local function log_warn_hider(str, ...) warn(HIDER_PREFIX .. string.format(str, ...)) end

-- Place ID Check (Loosened to just warn)
if game.PlaceId ~= 8204899140 and game.PlaceId ~= 104709320604721 and game.PlaceId ~= 8206123457 then
    log_warn_hider("Running outside known FF2 PlaceIDs, bypass might be less effective.")
end

-- LPH Compatibility (Attempt)
if not _G.LPH_OBFUSCATED then
    local success, err = pcall(loadstring, "LPH_NO_VIRTUALIZE = function(...) return ... end")
    if not success then log_warn_hider("Failed to set LPH_NO_VIRTUALIZE: %s", tostring(err)) end
end
local LPH_NO_VIRTUALIZE = _G.LPH_NO_VIRTUALIZE or function(...) return ... end

local environment = getgenv() -- Use exploit's global env

-- CPU Offset Management
local MIN_CPU_OFFSET = 100
local MAX_CPU_OFFSET = 9999
local DEFAULT_CPU_OFFSET = 3600
local cpu_offset_value = DEFAULT_CPU_OFFSET
pcall(function()
    math.randomseed((os.clock() + os.time()) * 1000)
    if not isfile("cpu_offset.txt") then
        writefile("cpu_offset.txt", tostring(math.random(MIN_CPU_OFFSET, MAX_CPU_OFFSET)))
    end
    local offset_str = readfile("cpu_offset.txt")
    if offset_str and tonumber(offset_str) then
        cpu_offset_value = math.clamp(math.round(tonumber(offset_str)), MIN_CPU_OFFSET, MAX_CPU_OFFSET)
        log_warn_hider("Loaded CPU offset: %d", cpu_offset_value)
    end
end)

-- Hider Variables
local fake_instance = Instance.new("Part")
fake_instance.Name = HttpService:GenerateGUID(false) -- Random name
local fake_signal = fake_instance:GetAttributeChangedSignal("FAKE_SIGNAL_"..HttpService:GenerateGUID(false))
local core_gui_instances_cache = {} -- Populate safely
pcall(function()
    for _, instance in ipairs(CoreGui:GetChildren()) do
        if instance and instance.Name ~= "RobloxGui" then table.insert(core_gui_instances_cache, instance) end
    end
end)
local default_walkspeed = starter_player.CharacterWalkSpeed
local default_jump_power = starter_player.CharacterJumpPower
local fake_request_internal = newcclosure(function() error("The current thread cannot call 'RequestInternal' (lacking capability RobloxScript)", 2) end)
local cached_namecall_function = nil
pcall(function() game:_() end, function() cached_namecall_function = debug.info(2, "f") end)
if not cached_namecall_function then log_warn_hider("Failed to cache namecall function!") end

-- Hider Data Stores
local reflection_map = {}       -- Stores values we've set, to return them if AC asks
local default_index_map = {}    -- Stores original default values before modification
local catch_parts_data = {}     -- {inst, original_size}
local football_parts_data = {}  -- {inst, vis_inst}
local is_catching = false       -- Flag set by hooked catch function

-- Original Function Storage
local orig_debug_info = debug.info
local orig_os_clock = os.clock
local orig_is_a_func = is_a
local orig_get_property_changed_signal = game.GetPropertyChangedSignal
local orig_preload_async = ContentProvider.PreloadAsync
local orig_log_service_gethistory = LogService.GetLogHistory
local orig_game_namecall = nil
local orig_game_index = nil
local orig_game_newindex = nil
local orig_catch_func = nil -- Set later via hook

-- Hider Utility Functions (Shallow Clone, Patchers, Anticheat Caller Check)
local table_shallow_clone = LPH_NO_VIRTUALIZE(function(tbl) local new_tbl = {}; for i, v in pairs(tbl) do new_tbl[i] = v end return new_tbl end)

local function patch_content_id_list(content_id_list) -- Kept from original
    if typeof(content_id_list) ~= "table" then return error("list is not a table") end
	local core_gui_pos = table.find(content_id_list, CoreGui)
	if not core_gui_pos then return error("no core-gui was found in this list") end
	local contend_id_list_clone = table_shallow_clone(content_id_list)
	contend_id_list_clone[core_gui_pos] = nil
	local add_core_gui_cache = LPH_NO_VIRTUALIZE(function()
		for _, instance in ipairs(core_gui_instances_cache) do table.insert(contend_id_list_clone, instance) end
	end)
	add_core_gui_cache()
	-- log_warn_hider("patch_content_id_list(%i) -> replaced with (%i)", #content_id_list, #contend_id_list_clone)
	return contend_id_list_clone
end

local function patch_preload_async_args(args, content_id_list_pos) -- Kept from original
    if not args[content_id_list_pos] or typeof(args[content_id_list_pos]) ~= "table" then return error("invalid content_id_list") end
	args[content_id_list_pos] = patch_content_id_list(args[content_id_list_pos])
end

local function patch_is_a_ret(args, is_a_ret) -- Kept from original, slightly modified
    local self, class_name = args[1], args[2]
    if typeof(self) ~= "Instance" or typeof(class_name) ~= "string" then return is_a_ret end -- Return original if invalid args
    local stripped_class_name = string.gsub(class_name, "\0", "")
    -- If AC checks if our non-FF part is a BodyMover, lie and say no
    if self.Name:sub(1, 2) ~= "FF" and stripped_class_name == "BodyMover" and not checkcaller() then return false end
    return is_a_ret
end

local function anticheat_caller(caller_script_info) -- Kept from original
    if not caller_script_info or not caller_script_info.func then return false end
	local const_success, consts = pcall(debug.getconstants, caller_script_info.func)
	if not const_success or not consts then return false end
	local first_const = consts[1]
	if typeof(first_const) ~= "string" then return false end
	return first_const:match("_______________________________") -- Check for AC signature string
end

local any_anticheat_caller = LPH_NO_VIRTUALIZE(function(depth_limit) -- Kept from original, added depth limit
    depth_limit = depth_limit or 5 -- Limit stack walk
	for idx = 2, depth_limit + 1 do
		local info = debug.getinfo(idx)
		if not info then break end
		if anticheat_caller(info) then return true end
	end
    return false
end)

-- Hook Handlers (Core Bypass Logic)
local on_os_clock = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local os_clock_ret = orig_os_clock(...)
    if checkcaller() then return os_clock_ret end -- Don't modify for exploit itself
    -- Return spoofed time if AC might be calling
    if any_anticheat_caller() then
        -- log_warn_hider("os.clock() spoofed for potential AC caller.")
        return os_clock_ret + cpu_offset_value
    end
    return os_clock_ret -- Return original for normal game scripts
end))

local patch_log_service_return = LPH_NO_VIRTUALIZE(function(log_service_ret) -- Kept & slightly enhanced
    if typeof(log_service_ret) ~= "table" then return error("returned value is not a table") end
    local new_log_service_ret = {}
    local patched = false
    for _, entry in ipairs(log_service_ret) do
        local msg = entry and entry.message
        if not msg then table.insert(new_log_service_ret, entry); continue end
        -- Filter out common exploit/script error messages
        local is_suspicious = string.find(msg, "Script ''", 1, true)
                           or string.find(msg, "\n, line ", 1, true)
                           or string.find(msg, "Electron", 1, true)
                           or string.find(msg, "Synapse", 1, true)
                           or string.find(msg, "Krnl", 1, true)
                           or string.find(msg, "Fluxus", 1, true)
                           or string.find(msg, "Valyse", 1, true)
                           or string.find(msg, '%[string "', 1, true)
                           or string.find(msg, ":loadstring", 1, true)
                           or string.find(msg, ".Xeno", 1, true)
                           or string.find(msg, "Error:", 1, true) -- Generic error might be exploit related
                           or string.find(msg, "invalid argument", 1, true) -- Common script error hint

        if not is_suspicious then
            table.insert(new_log_service_ret, entry)
        else
            patched = true
            -- log_warn_hider("Filtered suspicious log entry: %s", msg:sub(1, 100)) -- Log snippet
        end
    end
    if not patched then return error("nothing to patch") end -- Signal no change needed
    return new_log_service_ret
end)

local on_log_service = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local success_orig, log_service_ret = pcall(orig_log_service_gethistory, ...)
    if not success_orig then return log_service_ret end -- Return error if original failed
    if checkcaller() then return log_service_ret end

    local patch_success, patch_result = pcall(patch_log_service_return, log_service_ret)
    -- Return patched only if successful, otherwise original
    return patch_success and patch_result or log_service_ret
end))

local on_preload_async = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    if checkcaller() then return orig_preload_async(...) end
    local args = { ... }
    if #args < 1 or typeof(args[1]) ~= "table" then return orig_preload_async(...) end -- Basic arg check
    local patch_success, _ = pcall(patch_preload_async_args, args, 1) -- Args list is usually the first arg
    return patch_success and orig_preload_async(table.unpack(args)) or orig_preload_async(...)
end))

local on_game_namecall = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local method = getnamecallmethod() -- Get method first

    -- Early exit for common/safe methods called frequently to reduce overhead
    if method == "findFirstChild" or method == "FindFirstChild" or method == "WaitForChild" or method == "IsA" or method == "isA" then
        -- Allow IsA but handle it later if needed
        if method == "IsA" or method == "isA" then
            local is_a_ret = orig_game_namecall(...)
            if checkcaller() then return is_a_ret end
            local args = { ... }
            local patch_success, patch_result = pcall(patch_is_a_ret, args, is_a_ret)
            return patch_success and patch_result or is_a_ret
        end
        return orig_game_namecall(...) -- Allow common methods
    end

    if checkcaller() then return orig_game_namecall(...) end

    local args = { ... }
    local self = args[1]

    if typeof(self) ~= "Instance" then return orig_game_namecall(...) end -- Must be instance method

    -- Anticheat Bind/Kick/Remote Blocks (More robust checks)
    if self == RunService and (method == "BindToRenderStep" or method == "bindToRenderStep") and any_anticheat_caller() and typeof(args[2]) == "string" then
        log_warn_hider("Blocked AC BindToRenderStep: %s", args[2])
        return
    end
    if method == "Kick" and any_anticheat_caller() then
        local reason = args[2] or "(no reason provided)"
        log_warn_hider("Blocked AC Kick on %s: %s", tostring(self), tostring(reason))
        return
    end
    if orig_is_a_func(self, "RemoteEvent") and (method == "FireServer" or method == "fireServer") then
        if typeof(args[2]) == "string" and args[2]:match("AC") and any_anticheat_caller() then -- Check if AC string and likely AC callstack
            log_warn_hider("Blocked AC RemoteEvent FireServer on %s with args: %s, %s", self.Name, tostring(args[2]), tostring(args[3]))
            return
        end
        -- Catching Logic Intercept (Check specific event name if possible)
        if self.Name == "CatchEventNameHere" and args[2] == "catch" then -- Replace with actual event name if known
            is_catching = true
        end
    end

    -- Hooked Service Calls
    if self == ContentProvider and (method == "PreloadAsync" or method == "preloadAsync") then
         if #args < 1 or typeof(args[1]) ~= "table" then return orig_game_namecall(...) end
         local patch_success, _ = pcall(patch_preload_async_args, args, 1)
         return patch_success and orig_game_namecall(table.unpack(args)) or orig_game_namecall(...)
    elseif self == LogService and (method == "GetLogHistory" or method == "getLogHistory") then
        return on_log_service(...) -- Call the dedicated handler
    elseif method == "GetPropertyChangedSignal" or method == "getPropertyChangedSignal" then
        return on_get_property_changed_signal(...) -- Call dedicated handler
    end

    -- Fallback: Allow other namecalls
    return orig_game_namecall(...)
end))

local on_game_newindex = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local args = { ... }
    local self, index, new_value = args[1], args[2], args[3]

    if checkcaller() or typeof(self) ~= "Instance" or typeof(index) ~= "string" then
        return orig_game_newindex(...)
    end

    local stripped_index = string.gsub(index, "\0", "")
    local property_reflection = reflection_map[self] or {}
    if not reflection_map[self] then reflection_map[self] = property_reflection end

    local is_humanoid = orig_is_a_func(self, "Humanoid")
    local is_hrp = self.Name == "HumanoidRootPart"

    -- Apply cheat modifications if enabled and appropriate object/property
    if is_humanoid and (stripped_index == "WalkSpeed" or stripped_index == "walkSpeed") then
        property_reflection[stripped_index] = math.max(new_value, 0.0) -- Store intended value
        if Config.SpeedEnabled and Config.PanicKeyEnabled then
            return orig_game_newindex(self, index, new_value <= 0 and new_value or Config.SpeedAmount) -- Apply cheat value
        end
    elseif is_humanoid and (stripped_index == "JumpPower" or stripped_index == "jumpPower") then
        property_reflection[stripped_index] = math.max(new_value, 0.0)
        if Config.JumpPowerEnabled and Config.PanicKeyEnabled then
            return orig_game_newindex(self, index, new_value <= 0 and new_value or Config.JumpPowerAmount)
        end
    elseif is_hrp and (stripped_index == "AssemblyLinearVelocity" or stripped_index == "assemblyLinearVelocity") then
        -- Air strafe/boost logic
        if Config.BoostOnHeight and Config.PanicKeyEnabled and typeof(new_value) == "Vector3" then
            local humanoid = self.Parent and self.Parent:FindFirstChildOfClass("Humanoid")
            local can_boost = humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
            if can_boost then
                local angular_velocity = self.AssemblyAngularVelocity
                if angular_velocity and math.abs(angular_velocity.Y) >= Config.AngleTolerance then
                    local boosted_velocity = self.AssemblyLinearVelocity * Config.BoostAmount
                    property_reflection[stripped_index] = boosted_velocity -- Reflect the boosted value
                    if not Config.SilentMode then -- Play sound
                        pcall(function()
                            local sound = Instance.new("Sound", self)
                            sound.SoundId = "rbxassetid://1053296915"
                            sound.Volume = 0.5; sound:Play()
                            task.delay(0.5, function() pcall(sound.Destroy, sound) end)
                        end)
                    end
                    return orig_game_newindex(self, index, boosted_velocity) -- Apply boosted velocity
                end
            end
        end
         property_reflection[stripped_index] = new_value -- Store original/intended if not boosting
    elseif is_hrp and (stripped_index == "AssemblyAngularVelocity" or stripped_index == "assemblyAngularVelocity") then
        property_reflection[stripped_index] = new_value -- Reflect angular velocity changes too
    else
         -- Reflect other changes as well, important for things modified by cheats later (e.g., ball velocity)
        property_reflection[stripped_index] = new_value
    end

    -- Default: Apply the original change if no cheat logic intercepted
    return orig_game_newindex(...)
end))

local on_is_a = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local success, is_a_ret = pcall(orig_is_a_func, ...)
    if not success then return false end -- Return false on error
    if checkcaller() then return is_a_ret end
    local args = { ... }
    local patch_success, patch_result = pcall(patch_is_a_ret, args, is_a_ret)
    return patch_success and patch_result or is_a_ret
end))

local on_get_property_changed_signal = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    if checkcaller() then return orig_get_property_changed_signal(...) end
    local args = { ... }
    local self, property = args[1], args[2]
    if typeof(self) ~= "Instance" or typeof(property) ~= "string" then
        return orig_get_property_changed_signal(...)
    end

    -- Prevent AC from listening to sensitive property changes by returning a dummy signal
    local block_signal = false
    local lc_property = string.lower(property)

    if orig_is_a_func(self, "Workspace") and (lc_property == "gravity" or lc_property == "filteringenabled") then block_signal = true end
    if self.Name == "HumanoidRootPart" and (lc_property == "assemblylinearvelocity" or lc_property == "cframe") then block_signal = true end
    if orig_is_a_func(self, "Humanoid") and (lc_property == "walkspeed" or lc_property == "jumppower" or lc_property == "health") then block_signal = true end
    local is_catch_part = self.Name:sub(1, 5) == "Catch"
    local is_block_part = self.Name:match("Block") -- Broader check
    if (self.Name == "Football" or is_catch_part or is_block_part) and (lc_property == "size" or lc_property == "position" or lc_property == "cframe") then block_signal = true end

    if block_signal and any_anticheat_caller(3) then -- Check shallow stack depth for AC caller
        -- log_warn_hider("Blocked GetPropertyChangedSignal for %s.%s", self.Name, property)
        return fake_signal
    end

    return orig_get_property_changed_signal(...) -- Allow signal otherwise
end))

local on_game_index = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local args = { ... }
    local self, index = args[1], args[2]

    if checkcaller() or typeof(self) ~= "Instance" or typeof(index) ~= "string" then
        return orig_game_index(...)
    end

    local stripped_index = string.gsub(index, "\0", "")
    local lc_stripped_index = string.lower(stripped_index)

    -- Block AC access to sensitive methods/signals
    if self == ScriptContext and lc_stripped_index == "error" then return fake_signal end
    if self == RunService and lc_stripped_index == "heartbeat" and any_anticheat_caller() then return fake_signal end
    if self == HttpService and lc_stripped_index == "requestinternal" then return fake_request_internal end

    -- Return reflected value first if it exists (value we set or allowed)
    local reflections = reflection_map[self]
    local reflected_value = reflections and reflections[stripped_index]
    if reflected_value ~= nil then
        -- log_warn_hider("Returning reflected value for %s.%s", self.Name, stripped_index) -- VERY SPAMMY
        return reflected_value
    end

    -- If no reflection, determine if spoofing is needed and return default/capped value
    local should_spoof_ret = false
    if orig_is_a_func(self, "Camera") and lc_stripped_index == "fieldofview" then should_spoof_ret = true end
    if orig_is_a_func(self, "Workspace") and lc_stripped_index == "gravity" then should_spoof_ret = true end
    if orig_is_a_func(self, "Part") and (lc_stripped_index == "size" or lc_stripped_index == "cancollide") then should_spoof_ret = true end
    if orig_is_a_func(self, "Humanoid") and (lc_stripped_index ~= "movedirection") then should_spoof_ret = true end -- Allow MoveDirection

    if should_spoof_ret then
        local default_indexes = default_index_map[self] or {}
        if not default_index_map[self] then default_index_map[self] = default_indexes end

        local default_value = default_indexes[stripped_index]
        if default_value == nil then -- Get and cache original default value if not already done
            local success_orig, result = pcall(orig_game_index, ...)
            default_value = success_orig and result or nil
            if default_value ~= nil then default_indexes[stripped_index] = default_value end
        end

        -- Apply caps to default values if they exist
        if default_value ~= nil then
            if (lc_stripped_index == "walkspeed") and typeof(default_value) == "number" then default_value = math.min(default_value, default_walkspeed) end
            if (lc_stripped_index == "jumppower") and typeof(default_value) == "number" then default_value = math.min(default_value, default_jump_power) end
            if (lc_stripped_index == "hipheight") and typeof(default_value) == "number" then default_value = math.min(default_value, 2.0) end -- Use a reasonable default max hipheight
            if (lc_stripped_index == "size") and typeof(default_value) == "Vector3" then
                 local name = self.Name
                 if name:sub(1, 5) == "Catch" then default_value = Vector3.new(1.4, 1.65, 1.4) end -- Fixed default size
                 if name:match("Block") then default_value = Vector3.new(0.75, 5, 1.5) end -- Fixed default size
            end
             if (lc_stripped_index == "fieldofview") and typeof(default_value) == "number" then default_value = math.min(default_value, 70) end -- Default FOV
             if (lc_stripped_index == "gravity") and typeof(default_value) == "number" then default_value = math.min(default_value, 196.2) end -- Default gravity

            -- log_warn_hider("Returning default/capped value for %s.%s", self.Name, stripped_index) -- VERY SPAMMY
            return default_value
        end
    end

    -- If not spoofing or no reflection/default found, return original value
    return orig_game_index(...)
end))

-- Touch replication logic for increased catch size (Robust version)
local on_catch_touch = LPH_NO_VIRTUALIZE(function(toucher, touching, state)
    if not firetouchinterest then return end
    local transmitter = touching and touching:FindFirstChildWhichIsA("TouchTransmitter")
    if not transmitter or not toucher or not toucher.Parent then return end -- Basic checks

    local success = false
    local attempts = 0
    local try_fire = function(p1, p2, p_state)
        if success or attempts >= 4 then return end
        attempts = attempts + 1
        local s, _ = pcall(firetouchinterest, p1, p2, p_state)
        if s then success = true; return true end
        return false
    end

    -- Try various combinations known to work on different exploits
    try_fire(toucher, touching, state)
    task.wait()
    try_fire(toucher, transmitter, state)
    task.wait()
    try_fire(transmitter, touching, state)
    task.wait()
    try_fire(touching, toucher, state) -- Sometimes reversed args work

    -- if not success then log_warn_hider("Failed to replicate touch state %s via firetouchinterest.", tostring(state)) end
end)

-- Hider Update Loop (PreSimulation) - Manages visuals and triggers extended catch
local on_update_sigma_hider = LPH_NO_VIRTUALIZE(function()
    local player = LocalPlayer
    local character = player and player.Character
    if not character then return end

    -- Hide visualization parts first
    for _, data in ipairs(football_parts_data) do
        if data and data.vis_inst and data.vis_inst.Parent then data.vis_inst.Transparency = 1.0 end
    end

    -- Update catch part sizes based on config
    for _, data in ipairs(catch_parts_data) do
        if data and data.inst and data.inst.Parent then
            local target_size = data.original_size or Vector3.one -- Fallback
            if Config.ReduceCatchTackle and character:FindFirstChild("Football") then
                target_size = Vector3.new(0.01, 0.01, 0.01)
            end
            if data.inst.Size ~= target_size then data.inst.Size = target_size end
        end
    end

    -- Handle extended football catch zone logic
    local nearest_fb, nearest_vis_inst, nearest_distance = get_nearest_football_data() -- Custom function needed
    if not (nearest_fb and nearest_vis_inst and nearest_distance and nearest_vis_inst.Parent) then return end
    if not nearest_fb:FindFirstChildWhichIsA("TouchTransmitter") then return end
    if nearest_fb.Position.Y <= 3.5 then -- Ball on ground check
        if nearest_vis_inst.Transparency ~= 1.0 then nearest_vis_inst.Transparency = 1.0 end
        return
    end

    -- Update visualization part properties
    local target_vis_size = nearest_fb.Size + Config.IncreaseCatchSize
    if nearest_vis_inst.Size ~= target_vis_size then nearest_vis_inst.Size = target_vis_size end
    nearest_vis_inst.Transparency = Config.VisualizeCatchZone and 0.6 or 1.0
    nearest_vis_inst.Color = Color3.new(0.5, 0.5, 0.5) -- Grey
    if nearest_vis_inst.Position ~= nearest_fb.Position then nearest_vis_inst.Position = nearest_fb.Position end
    if nearest_vis_inst.Material ~= Enum.Material.SmoothPlastic then nearest_vis_inst.Material = Enum.Material.SmoothPlastic end
    if not nearest_vis_inst.Anchored then nearest_vis_inst.Anchored = true end
    if nearest_vis_inst.CanCollide then nearest_vis_inst.CanCollide = false end

    -- Trigger extended catch via overlap check if catching
    if is_catching then
        local overlap_params = OverlapParams.new()
        overlap_params.FilterType = Enum.RaycastFilterType.Include
        overlap_params.FilterDescendantsInstances = { character }
        overlap_params.MaxParts = 5 -- Limit check

        local parts = Workspace:GetPartsInPart(nearest_vis_inst, overlap_params)
        if #parts > 0 then
            for _, part in ipairs(parts) do
                -- Check if it's a relevant part (e.g., Arm, Hand, maybe Torso)
                if part and part.Parent == character and (part.Name:match("Arm") or part.Name:match("Hand")) then
                    -- log_warn_hider("Extended catch triggered for part: %s", part.Name)
                    on_catch_touch(part, nearest_fb, 0) -- Touch start
                    task.wait()
                    on_catch_touch(part, nearest_fb, 1) -- Touch end
                    break -- Only need one touch per frame
                end
            end
        end
    end
end)

-- Hider Event Handlers (ChildAdded etc.)
local function get_nearest_football_data() -- Definition for the function used above
    local nearest_inst = nil
	local nearest_vis_inst = nil
	local nearest_distance = math.huge
    local player_hrp = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not player_hrp then return nil, nil, nil end

	for i = #football_parts_data, 1, -1 do
		local data = football_parts_data[i]
        if not (data and data.inst and data.inst.Parent and data.vis_inst and data.vis_inst.Parent) then
            if data and data.vis_inst then pcall(data.vis_inst.Destroy, data.vis_inst) end
            table.remove(football_parts_data, i); continue
		end
		if data.inst.Parent ~= Workspace then
             if data.vis_inst then pcall(data.vis_inst.Destroy, data.vis_inst) end
			table.remove(football_parts_data, i); continue
		end
		local distance = (data.inst.Position - player_hrp.Position).Magnitude
		if distance < nearest_distance then
			nearest_distance = distance; nearest_inst = data.inst; nearest_vis_inst = data.vis_inst
		end
	end
    if nearest_distance == math.huge then return nil, nil, nil end
	return nearest_inst, nearest_vis_inst, nearest_distance
end

local on_workspace_child_added_sigma = LPH_NO_VIRTUALIZE(function(inst)
    if inst:IsA("BasePart") and inst.Name == "Football" then
        log_warn_hider("Football added: %s", tostring(inst))
        local vis_part = Instance.new("Part")
        vis_part.Name = "VisualCatchZone_"..HttpService:GenerateGUID(false)
        vis_part.Transparency = 1.0; vis_part.CanCollide = false; vis_part.Anchored = true
        vis_part.Material = Enum.Material.SmoothPlastic; vis_part.Size = Vector3.one
        vis_part.Parent = Workspace -- Parent to workspace for easier management
        table.insert(football_parts_data, { inst = inst, vis_inst = vis_part })
    end
end)

local on_workspace_descendant_added_sigma = LPH_NO_VIRTUALIZE(function(inst)
    if inst:IsA("BasePart") and LocalPlayer and LocalPlayer.Character == inst.Parent then
        if inst.Name:sub(1, 5) == "Catch" then
            log_warn_hider("Catch part added: %s", inst.Name)
            -- Ensure original size is captured correctly
            local size = inst.Size
            task.wait() -- Wait a frame in case size isn't set immediately
            if inst.Size ~= size then size = inst.Size end
            table.insert(catch_parts_data, { inst = inst, original_size = size })
        end
    end
end)

local on_debug_info = LPH_NO_VIRTUALIZE(newcclosure(function(...)
    local args = { ... }
    -- Allow if not checking specific function/source info, or if not AC caller
    if checkcaller() or args[1] ~= 2 or not any_anticheat_caller() then
         return orig_debug_info(...)
    end
    -- Spoof specific sensitive info requests from AC
    if args[2] == "f" then return cached_namecall_function -- Spoof function
    elseif args[2] == "s" then return "Instance" -- Spoof source (less specific than LocalScript)
    elseif args[2] == "l" then return math.random(10, 500) -- Spoof line number
    else return nil -- Return nil for other fields
    end
end))


-- Place Hooks (Wrapped in pcall for safety)
local hooks_placed_successfully = pcall(function()
    -- Disable existing error handlers
    pcall(function()
        for _, connection in ipairs(getconnections(ScriptContext.Error)) do
            pcall(connection.Disable, connection)
        end
        log_warn_hider("Disabled existing ScriptContext.Error connections.")
    end)

    -- Core Hooks
    orig_debug_info = hookfunction(debug.info, on_debug_info)
    orig_os_clock = hookfunction(os.clock, on_os_clock)
    orig_is_a_func = hookfunction(is_a, on_is_a) -- Hook the global 'is_a'
    orig_get_property_changed_signal = hookfunction(game.GetPropertyChangedSignal, on_get_property_changed_signal)
    if ContentProvider.PreloadAsync then orig_preload_async = hookfunction(ContentProvider.PreloadAsync, on_preload_async) end
    if LogService.GetLogHistory then orig_log_service_gethistory = hookfunction(LogService.GetLogHistory, on_log_service) end
    orig_game_namecall = hookmetamethod(game, "__namecall", on_game_namecall)
    orig_game_index = hookmetamethod(game, "__index", on_game_index)
    orig_game_newindex = hookmetamethod(game, "__newindex", on_game_newindex)

    -- Hook Catch Function (Requires ClientMain to load - robust approach)
    task.spawn(function()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local clientMain = playerScripts and playerScripts:WaitForChild("ClientMain", 60)
        if not clientMain then log_warn_hider("ClientMain not found after 60s."); return end

        local controlsModuleScript = clientMain:FindFirstChild("GameControls") or clientMain:FindFirstChild("OtherControls")
        if not controlsModuleScript then log_warn_hider("GameControls/OtherControls module not found."); return end

        local success_require, controlsModule = pcall(require, controlsModuleScript)
        if not success_require or not controlsModule then log_warn_hider("Failed to require controls module: %s", tostring(controlsModule)); return end

        if controlsModule.Catch and typeof(controlsModule.Catch) == "function" then
            orig_catch_func = hookfunction(controlsModule.Catch, LPH_NO_VIRTUALIZE(newcclosure(function(...)
                local start_time = os.clock()
                local catch_args = {...}
                -- Heuristic: If the first arg is true, it might be initiating the catch state
                if catch_args[1] == true then is_catching = true end

                local ret = {pcall(orig_catch_func, ...)} -- Call original safely

                -- If call was short and first arg was false, likely ended catch state
                if os.clock() - start_time < 0.1 and catch_args[1] == false then is_catching = false end
                -- Reset catching state after a delay regardless, as a fallback
                task.delay(0.5, function() is_catching = false end)

                return table.unpack(ret, 2) -- Return original results
            end)))
            log_warn_hider("Successfully hooked Catch function.")
        else
            log_warn_hider("Catch function not found or invalid in controls module.")
        end
    end)

    -- Connect Hider Event Listeners AFTER hooks are placed
    Workspace.DescendantAdded:Connect(on_workspace_descendant_added_sigma)
	Workspace.ChildAdded:Connect(on_workspace_child_added_sigma)
	RunService.PreSimulation:Connect(on_update_sigma_hider) -- Use PreSim for hider updates

    -- Initial population for existing items
    task.spawn(function() -- Spawn to avoid potential yield issues
        for _, inst in ipairs(Workspace:GetDescendants()) do on_workspace_descendant_added_sigma(inst) end
        for _, inst in ipairs(Workspace:GetChildren()) do on_workspace_child_added_sigma(inst) end
    end)

end)

if not hooks_placed_successfully then
    error(HIDER_PREFIX .. "CRITICAL ERROR: Failed to place essential hooks! Aborting.")
end
log_warn_hider("Bypass hooks placed successfully.")

--========================================================================
--[ Cheat Feature Functions ]
--========================================================================
local ESP_Elements = {} -- { Player = { Tracer, NameTag, HealthBar, HealthBarBg, Box } }

-- Function to Simulate Mouse Input (CRITICAL PLACEHOLDER)
local function SimulateMouseInput(targetPosition)
    --[[ !! REPLACE THIS SECTION !!
         Use your exploit's specific UNDETECTED mouse movement function.
         Setting Camera CFrame is detectable. UserInputService:InjectMouse is detectable.
         Examples (These might be outdated or detected - check your exploit docs):
         - Fluxus/OxygenU: mousemoveto(screenPos.X, screenPos.Y)
         - Synapse X (Old): syn.mousemoveto(screenPos.X, screenPos.Y) or custom DLL call
         - Script-Ware: External function call or specific API if available
    --]]
    local screenPos, onScreen = CurrentCamera:WorldToScreenPoint(targetPosition)
    if onScreen then
         -- warn("Placeholder: Would move mouse to", screenPos.X, screenPos.Y) -- DEBUG
         -- YOUR_EXPLOIT.mouse_move_function(screenPos.X, screenPos.Y) -- Replace this line
    end
end

local function IsSpectated()
    if not LocalPlayer then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            pcall(function() -- Wrap in pcall as Camera properties can sometimes error
                 if player.CameraMode == Enum.CameraMode.LockFirstPerson and player.CameraSubject == LocalPlayer.Character then
                    return true
                 end
            end)
        end
    end
    return false
end

local function IsGameActive() -- Basic Check - IMPROVE IF NEEDED
    -- Example: return ReplicatedStorage:FindFirstChild("GameStatusValue") and ReplicatedStorage.GameStatusValue.Value == "Active"
    return true -- Assume active for now
end

local function FindClosestPlayer(useTargetList)
    local closestPlayer = nil
    local shortestDistance = Config.AimbotFOV -- Use FOV as max distance
    local playerHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil, math.huge end

    local playerHRP_Pos = playerHRP.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetHRP and humanoid and humanoid.Health > 0 then
                 -- Team Check
                 if Config.ESPShowTeam and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end -- Skip teammates if configured

                 -- Target List Check
                if useTargetList and Config.TargetSpecificPlayers then
                    local isTarget = false
                    for _, targetName in ipairs(Config.TargetPlayerList) do
                        if player.Name == targetName then isTarget = true; break end
                    end
                    if not isTarget then continue end
                end

                local distance = (playerHRP_Pos - targetHRP.Position).Magnitude
                if distance < shortestDistance then
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetHRP.Position)
                    -- Check if within FOV cone (more accurate than just onScreen)
                    local directionToTarget = (targetHRP.Position - CurrentCamera.CFrame.Position).Unit
                    local lookVector = CurrentCamera.CFrame.LookVector
                    local angle = math.deg(math.acos(directionToTarget:Dot(lookVector)))
                    if onScreen and angle < (CurrentCamera.FieldOfView / 1.5) then -- Check within ~2/3 of visual FOV
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer, shortestDistance
end

local function QuarterbackAimbot()
    if not Config.QBAimbotEnabled or not Config.PanicKeyEnabled or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    local character = LocalPlayer.Character
    local playerHRP = character and character:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return end

    -- Check if player is likely holding the ball (adjust based on game mechanics)
    local hasBall = character:FindFirstChild("Football") -- Or check tool equipped, etc.
    if not hasBall then return end

    local closestPlayer, dist = FindClosestPlayer(true)
    if not closestPlayer or not closestPlayer.Character then return end

    local targetPart = closestPlayer.Character:FindFirstChild(Config.AimbotTargetPart) or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local football = Workspace:FindFirstChild("Football") -- Find the actual world football object
    if not football or not football:IsA("BasePart") then return end

    -- Aim Offset
    local aimOffset = Vector3.zero
    if Config.AimbotMode == "Legit" then
        aimOffset = Vector3.new(math.random(-8, 8)/10, math.random(-5, 8)/10, math.random(-8, 8)/10) * (1 / Config.StealthLevel)
    end

    local aimPosition = targetPart.CFrame * CFrame.new(aimOffset) -- Apply offset relative to part's CFrame
    local aimDirection = (aimPosition.Position - playerHRP.Position).Unit

    -- Prediction
    if Config.AimbotPrediction then
        local targetVelocity = targetPart.AssemblyLinearVelocity
        -- Simple prediction: estimate time based on distance and typical throw speed
        local estSpeed = 80 * Config.StealthLevel -- Estimated ball speed
        local timeToTarget = math.max(0.1, dist / estSpeed) -- Avoid division by zero
        local predictedPos = aimPosition.Position + (targetVelocity * timeToTarget)
        aimDirection = (predictedPos - playerHRP.Position).Unit
        aimPosition = CFrame.new(predictedPos) -- Update aimPosition for mouse simulation
    end

    -- Apply velocity to the football (use AssemblyLinearVelocity)
    local currentVelocity = football.AssemblyLinearVelocity
    local targetVelocityMagnitude = 100 * Config.StealthLevel
    local targetVelocityVector = aimDirection * targetVelocityMagnitude
    local smoothedVelocity = currentVelocity:Lerp(targetVelocityVector, Config.AimbotSmoothing)

    -- Directly setting velocity can be risky, ensure the bypass hook reflects this change
    reflection_map[football] = reflection_map[football] or {}
    reflection_map[football].AssemblyLinearVelocity = smoothedVelocity -- Manually update reflection
    football.AssemblyLinearVelocity = smoothedVelocity

    -- Simulate Mouse Movement
    SimulateMouseInput(aimPosition.Position)
end

local function SilentAim()
    if not Config.SilentAimEnabled or not Config.PanicKeyEnabled or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or not football.Parent then return end

    -- Only run if ball is in the air and moving
    if football.AssemblyLinearVelocity.Magnitude < 15 or football.Position.Y < 5 then return end

    local closestPlayer, dist = FindClosestPlayer(true)
    if not closestPlayer or not closestPlayer.Character then return end

    local targetPart = closestPlayer.Character:FindFirstChild(Config.AimbotTargetPart) or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local footballDistance = (football.Position - targetPart.Position).Magnitude

    if footballDistance < (Config.SilentAimRange * Config.StealthLevel) then
        local aimDirection = (targetPart.Position - football.Position).Unit
        local currentSpeed = football.AssemblyLinearVelocity.Magnitude
        local newVelocity = aimDirection * math.max(currentSpeed, 60 * Config.StealthLevel) -- Maintain speed

        -- Update reflection and set velocity
        reflection_map[football] = reflection_map[football] or {}
        reflection_map[football].AssemblyLinearVelocity = newVelocity
        football.AssemblyLinearVelocity = newVelocity
        -- log_warn("Silent Aim corrected trajectory")
    end
end

-- ESP Functions
local function CreateESPForPlayer(player)
    if not Drawing or ESP_Elements[player] then return end
    local elements = {}
    elements.Tracer = Drawing.new("Line")
    elements.NameTag = Drawing.new("Text")
    elements.HealthBar = Drawing.new("Square")
    elements.HealthBarBg = Drawing.new("Square")
    -- elements.Box = Drawing.new("Square") -- Uncomment if box ESP is desired

    for _, obj in pairs(elements) do obj.Visible = false end

    elements.Tracer.Thickness = Config.ESPTracerThickness; elements.Tracer.Color = Color3.new(1,0,0)
    elements.NameTag.Size = Config.ESPNameSize; elements.NameTag.Center = true; elements.NameTag.Outline = true; elements.NameTag.Font = Drawing.Fonts.Plex; elements.NameTag.Color = Color3.new(1,1,1)
    elements.HealthBar.Thickness = 1; elements.HealthBar.Filled = true; elements.HealthBar.Color = Color3.new(0,1,0)
    elements.HealthBarBg.Thickness = 1; elements.HealthBarBg.Filled = true; elements.HealthBarBg.Color = Color3.new(0.2,0.2,0.2); elements.HealthBarBg.ZIndex = 0 -- Background behind health
    elements.HealthBar.ZIndex = 1 -- Health on top of background

    -- if elements.Box then elements.Box.Thickness = 1; elements.Box.Filled = false; elements.Box.Color = Color3.new(1,0,0) end

    ESP_Elements[player] = elements
end

local function UpdateESP()
    if not Drawing or not Config.ESPEnabled or not Config.PanicKeyEnabled then
        if next(ESP_Elements) then -- Hide if any elements exist
             for _, elements in pairs(ESP_Elements) do
                for _, obj in pairs(elements) do if obj and obj.Visible then obj.Visible = false end end
             end
        end
        return
    end

    local playerHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return end
    local playerHRP_Pos = playerHRP.Position
    local viewportSize = CurrentCamera.ViewportSize

    for player, elements in pairs(ESP_Elements) do -- Update existing first
        local char = player and player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not (player and player.Parent and hum and hrp and hum.Health > 0) then
             for _, obj in pairs(elements) do if obj and obj.Visible then obj.Visible = false end end
             continue -- Hide if player invalid/dead
        end

        local distance = (playerHRP_Pos - hrp.Position).Magnitude
        if distance > Config.ESPMaxDistance then
             for _, obj in pairs(elements) do if obj and obj.Visible then obj.Visible = false end end
             continue -- Hide if too far
        end

        local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _, obj in pairs(elements) do if obj and obj.Visible then obj.Visible = false end end
            continue -- Hide if off-screen
        end

        -- Determine Color
        local espColor = Color3.new(1, 0.2, 0.2) -- Enemy Red
        if Config.ESPShowTeam and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            espColor = Color3.new(0.2, 1, 0.2) -- Team Green
        end

        -- Update Elements
        local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local healthColor = Color3.fromHSV(healthPercent * 0.33, 1, 1) -- Green to Red gradient
        local barWidth, barHeight = 50, 5
        local nameYOffset = -25
        local healthYOffset = nameYOffset + Config.ESPNameSize + 2

        if elements.Tracer then
            elements.Tracer.Visible = true; elements.Tracer.Color = espColor; elements.Tracer.Thickness = Config.ESPTracerThickness
            elements.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y); elements.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        end
        if elements.NameTag then
            elements.NameTag.Visible = true; elements.NameTag.Color = espColor; elements.NameTag.Size = Config.ESPNameSize
            elements.NameTag.Text = string.format("%s [%dm]", player.Name, math.floor(distance))
            elements.NameTag.Position = Vector2.new(screenPos.X, screenPos.Y + nameYOffset)
        end
        if elements.HealthBarBg then
             elements.HealthBarBg.Visible = true; elements.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
             elements.HealthBarBg.Position = Vector2.new(screenPos.X - barWidth / 2, screenPos.Y + healthYOffset)
        end
         if elements.HealthBar then
             elements.HealthBar.Visible = true; elements.HealthBar.Color = healthColor
             elements.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
             elements.HealthBar.Position = Vector2.new(screenPos.X - barWidth / 2, screenPos.Y + healthYOffset)
        end
         --[[ -- Box ESP Logic (Example)
         if elements.Box then
             local headPos = char:FindFirstChild("Head") and char.Head.Position or hrp.Position + Vector3.new(0, 2, 0)
             local feetPos = hrp.Position - Vector3.new(0, 3, 0)
             local headScreen, headOn = CurrentCamera:WorldToViewportPoint(headPos)
             local feetScreen, feetOn = CurrentCamera:WorldToViewportPoint(feetPos)
             if headOn and feetOn then
                 local height = math.abs(headScreen.Y - feetScreen.Y)
                 local width = height / 2 -- Approximate width based on height
                 elements.Box.Visible = true; elements.Box.Color = espColor
                 elements.Box.Size = Vector2.new(width, height)
                 elements.Box.Position = Vector2.new(screenPos.X - width / 2, headScreen.Y)
             else
                 elements.Box.Visible = false
             end
         end
         --]]
    end

    -- Check for new players to draw
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not ESP_Elements[player] then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                CreateESPForPlayer(player)
            end
        end
    end
end

local function CleanupESP()
    for player, elements in pairs(ESP_Elements) do
        local playerExists = pcall(function() return player and player.Parent == Players end)
        if not playerExists then
            for _, obj in pairs(elements) do pcall(obj.Remove, obj) end
            ESP_Elements[player] = nil
        end
    end
end

-- Feature Functions (Magnet, AutoCatch, Jump)
local function MagnetCatch()
    if not Config.MagnetCatchEnabled or not Config.PanicKeyEnabled or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    if not firetouchinterest then return end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or not football.Parent then return end
    local character = LocalPlayer.Character
    local catchPart = character and (character:FindFirstChild("Left Arm") or character:FindFirstChild("Right Arm") or character:FindFirstChild("HumanoidRootPart"))
    if not catchPart then return end

    local distance = (catchPart.Position - football.Position).Magnitude
    local effectiveRange = Config.MagnetCatchRange * Config.StealthLevel

    if distance < effectiveRange then
        if math.random() < 0.3 then -- Reduce frequency slightly
            task.wait(math.random(1, 3) / 100)
            on_catch_touch(catchPart, football, 0) -- Use the robust touch function
            task.wait()
            on_catch_touch(catchPart, football, 1)
        end
    end
end

local AutoCatchRunning = false
local function AutoCatch()
    if not Config.AutoCatchEnabled or not Config.PanicKeyEnabled or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end
    if not firetouchinterest or AutoCatchRunning then return end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or not football.Parent then return end
    local character = LocalPlayer.Character
    local catchPart = character and (character:FindFirstChild("Left Arm") or character:FindFirstChild("Right Arm") or character:FindFirstChild("HumanoidRootPart"))
    if not catchPart then return end

    local distance = (catchPart.Position - football.Position).Magnitude
    if distance < Config.AutoCatchRange then -- Use specific range for auto catch
        AutoCatchRunning = true
        -- Spam touch interest aggressively in a new thread
        task.spawn(function()
            for i = 1, 5 do -- Spam attempts
                if not (football and football.Parent == Workspace) then break end -- Stop if caught or ball despawned
                on_catch_touch(catchPart, football, 0)
                task.wait()
                on_catch_touch(catchPart, football, 1)
                task.wait(0.03) -- Very short delay between spams
            end
            AutoCatchRunning = false
        end)
    end
end

local JumpConnection = nil
local function UpdateInfiniteJumpBinding()
    local shouldBeEnabled = Config.InfiniteJumpEnabled and Config.PanicKeyEnabled and IsGameActive()

    if shouldBeEnabled then
        if not JumpConnection or not JumpConnection.Connected then
            JumpConnection = UserInputService.JumpRequest:Connect(function()
                if not Config.InfiniteJumpEnabled or not Config.PanicKeyEnabled then return end -- Double check state
                if Config.AntiSpectate and IsSpectated() then return end
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
            log_warn("Infinite Jump enabled.")
        end
    else
        if JumpConnection and JumpConnection.Connected then
            JumpConnection:Disconnect()
            JumpConnection = nil
            log_warn("Infinite Jump disabled.")
        end
    end
end

-- Ball Prediction
local BallPredictionLine = nil
local function UpdateBallPrediction()
    if not Drawing then return end

    if not Config.BallPredictionEnabled or not Config.PanicKeyEnabled or not IsGameActive() then
        if BallPredictionLine then BallPredictionLine:Remove(); BallPredictionLine = nil end
        return
    end

    local football = Workspace:FindFirstChild("Football")
    if not football or not football:IsA("BasePart") or not football.Parent or football.AssemblyLinearVelocity.Magnitude < 5 then
        if BallPredictionLine then BallPredictionLine.Visible = false end
        return
    end

    if not BallPredictionLine then
        BallPredictionLine = Drawing.new("Line")
        BallPredictionLine.Thickness = 2; BallPredictionLine.Color = Color3.new(0, 1, 1); BallPredictionLine.Transparency = 0.4; BallPredictionLine.Visible = false; BallPredictionLine.ZIndex = 5
    end

    -- Simple Prediction Path
    local startPos = football.Position
    local velocity = football.AssemblyLinearVelocity
    local gravity = Workspace.Gravity
    local timeStep = 0.05; local maxTime = 1.5
    local endPos = startPos
    local currentPos = startPos; local currentVel = velocity

    for t = 0, maxTime, timeStep do
        currentPos = currentPos + currentVel * timeStep + 0.5 * Vector3.new(0, -gravity, 0) * timeStep^2
        currentVel = currentVel + Vector3.new(0, -gravity, 0) * timeStep
        endPos = currentPos
        -- Simple ground check
        if endPos.Y < 0.5 then break end -- Stop predicting if below ground level
    end

    local startScreen, onScreenStart = CurrentCamera:WorldToViewportPoint(startPos)
    local endScreen, onScreenEnd = CurrentCamera:WorldToViewportPoint(endPos)

    if onScreenStart and onScreenEnd then
        BallPredictionLine.Visible = true
        BallPredictionLine.From = Vector2.new(startScreen.X, startScreen.Y)
        BallPredictionLine.To = Vector2.new(endScreen.X, endScreen.Y)
    else
        BallPredictionLine.Visible = false
    end
end

-- Humanization
local function SimulateHumanBehavior()
    if not Config.HumanizationEnabled or not Config.PanicKeyEnabled or not IsGameActive() then return end
    if Config.AntiSpectate and IsSpectated() then return end

    if math.random() < Config.HumanizationFrequency then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local action = math.random(1, 3)
        if action == 1 then -- Tiny mouse jiggle (PLACEHOLDER)
            -- SimulateMouseInput(CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 10 + Vector3.new(math.random(-1,1)*0.1, math.random(-1,1)*0.1, 0))
            -- YOUR_EXPLOIT.mouse_move_relative(math.random(-3,3), math.random(-3,3)) -- Replace
        elseif action == 2 then -- Brief movement twitch
            local moveDir = Vector3.new(math.random(-5, 5)/10, 0, math.random(-5, 5)/10)
            humanoid:Move(moveDir, false)
            task.wait(math.random(5, 15) / 100)
            humanoid:Move(Vector3.zero, false)
        elseif action == 3 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid.FloorMaterial ~= Enum.Material.Air then -- Random jump only if grounded
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end


--========================================================================
--[ UI Setup (Fluent) ]
--========================================================================
local Library = nil -- Define Library locally
local function SetupUI()
    if _G.FluentLoaded then log_warn("Fluent UI already loaded."); return end

    local fluentSuccess, fluentLib = pcall(loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true)))
    if not fluentSuccess or not fluentLib then error("Failed to load Fluent library: " .. tostring(fluentLib)) end
    Library = fluentLib() -- Assign to the local variable

    local saveMgrSuccess, saveMgrLoad = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau")))
    local SaveManager = saveMgrSuccess and saveMgrLoad() or nil
    local ifaceMgrSuccess, ifaceMgrLoad = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau")))
    local InterfaceManager = ifaceMgrSuccess and ifaceMgrLoad() or nil

    _G.FluentLoaded = true

    local Window = Library:CreateWindow({
        Title = "FF2 Supreme v1.0", SubTitle = "Combined Bypass & Features",
        TabWidth = 160, Size = UDim2.fromOffset(600, 500), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl,
    })

    local Tabs = {
        Main = Window:CreateTab({ Title = "Main", Icon = "settings" }),
        Combat = Window:CreateTab({ Title = "Combat", Icon = "sword" }),
        Movement = Window:CreateTab({ Title = "Movement", Icon = "humanoid" }),
        Visuals = Window:CreateTab({ Title = "Visuals", Icon = "eye" }),
        Catching = Window:CreateTab({ Title = "Catching", Icon = "hand" }),
        Misc = Window:CreateTab({ Title = "Misc", Icon = "list" })
    }

    -- Populate Tabs (Callbacks directly modify Config table)
    -- Main Tab
    Tabs.Main:CreateToggle("PanicKey", { Title = "Panic Key (Master Switch)", Enabled = Config.PanicKeyEnabled, Callback = function(v) Config.PanicKeyEnabled = v end })
    Tabs.Main:CreateToggle("AntiSpectate", { Title = "Anti-Spectate", Enabled = Config.AntiSpectate, Callback = function(v) Config.AntiSpectate = v end })
    Tabs.Main:CreateToggle("Humanization", { Title = "Enable Humanization", Enabled = Config.HumanizationEnabled, Callback = function(v) Config.HumanizationEnabled = v end })
    Tabs.Main:CreateSlider("HumanizationFrequency", { Title = "Humanization Freq.", Default = Config.HumanizationFrequency * 100, Min = 1, Max = 20, Rounding = 1, Suffix = "%", Callback = function(v) Config.HumanizationFrequency = v / 100 end })
    Tabs.Main:CreateSlider("StealthLevel", { Title = "Stealth Level", Default = Config.StealthLevel * 10, Min = 1, Max = 20, Rounding = 1, Callback = function(v) Config.StealthLevel = v / 10 end })

    -- Combat Tab
    Tabs.Combat:CreateToggle("QBAimbot", { Title = "QB Aimbot", Enabled = Config.QBAimbotEnabled, Callback = function(v) Config.QBAimbotEnabled = v end })
    Tabs.Combat:CreateDropdown("AimbotMode", { Title = "Aimbot Mode", Values = {"Legit", "Rage"}, Default = Config.AimbotMode, Callback = function(v) Config.AimbotMode = v end })
    Tabs.Combat:CreateDropdown("AimbotTargetPart", { Title = "Aimbot Target", Values = {"Head", "HumanoidRootPart"}, Default = Config.AimbotTargetPart, Callback = function(v) Config.AimbotTargetPart = v end })
    Tabs.Combat:CreateToggle("AimbotPrediction", { Title = "Aimbot Prediction", Enabled = Config.AimbotPrediction, Callback = function(v) Config.AimbotPrediction = v end })
    Tabs.Combat:CreateSlider("AimbotFOV", { Title = "Aimbot FOV", Default = Config.AimbotFOV, Min = 10, Max = 1000, Callback = function(v) Config.AimbotFOV = v end })
    Tabs.Combat:CreateSlider("AimbotSmoothing", { Title = "Aimbot Smoothing", Default = Config.AimbotSmoothing * 100, Min = 0, Max = 99, Suffix = "%", Callback = function(v) Config.AimbotSmoothing = v / 100 end })
    Tabs.Combat:CreateToggle("SilentAim", { Title = "Silent Aim", Enabled = Config.SilentAimEnabled, Callback = function(v) Config.SilentAimEnabled = v end })
    Tabs.Combat:CreateSlider("SilentAimRange", { Title = "Silent Aim Range", Default = Config.SilentAimRange, Min = 5, Max = 150, Callback = function(v) Config.SilentAimRange = v end })
    Tabs.Combat:CreateToggle("TargetSpecific", { Title = "Target Specific Players", Enabled = Config.TargetSpecificPlayers, Callback = function(v) Config.TargetSpecificPlayers = v end })
    Tabs.Combat:CreateInput("TargetList", { Title = "Target List (CSV)", Placeholder = "Name1,Name2", Default = table.concat(Config.TargetPlayerList, ","), Callback = function(v) local l={};for n in string.gmatch(v,"([^,]+)") do table.insert(l,n:match("^%s*(.-)%s*$")) end Config.TargetPlayerList=l end })

    -- Movement Tab
    Tabs.Movement:CreateToggle("SpeedHack", { Title = "Enable Speed", Enabled = Config.SpeedEnabled, Callback = function(v) Config.SpeedEnabled = v end })
    Tabs.Movement:CreateSlider("SpeedAmount", { Title = "Speed Amount", Default = Config.SpeedAmount, Min = 16, Max = 100, Callback = function(v) Config.SpeedAmount = v end })
    Tabs.Movement:CreateToggle("JumpPowerHack", { Title = "Enable Jump Power", Enabled = Config.JumpPowerEnabled, Callback = function(v) Config.JumpPowerEnabled = v end })
    Tabs.Movement:CreateSlider("JumpPowerAmount", { Title = "Jump Power Amount", Default = Config.JumpPowerAmount, Min = 50, Max = 200, Callback = function(v) Config.JumpPowerAmount = v end })
    Tabs.Movement:CreateToggle("InfiniteJump", { Title = "Infinite Jump", Enabled = Config.InfiniteJumpEnabled, Callback = function(v) Config.InfiniteJumpEnabled = v; UpdateInfiniteJumpBinding() end })
    Tabs.Movement:CreateToggle("BoostOnHeight", { Title = "Air Strafe/Boost", Enabled = Config.BoostOnHeight, Callback = function(v) Config.BoostOnHeight = v end })
    Tabs.Movement:CreateSlider("BoostAmount", { Title = "Boost Multiplier", Default = Config.BoostAmount, Min = 1.0, Max = 5.0, Rounding = 2, Callback = function(v) Config.BoostAmount = v end })
    Tabs.Movement:CreateSlider("AngleTolerance", { Title = "Boost Angle Tolerance", Default = Config.AngleTolerance, Min = 1, Max = 45, Callback = function(v) Config.AngleTolerance = v end })

    -- Visuals Tab
    Tabs.Visuals:CreateToggle("ESP", { Title = "Enable Player ESP", Enabled = Config.ESPEnabled, Callback = function(v) Config.ESPEnabled = v end })
    Tabs.Visuals:CreateToggle("ESPShowTeam", { Title = "Hide Teammates", Enabled = Config.ESPShowTeam, Callback = function(v) Config.ESPShowTeam = v end })
    -- Tabs.Visuals:CreateToggle("ESPBoxes", { Title = "Draw ESP Boxes", Enabled = Config.ESPShowBoxes, Callback = function(v) Config.ESPShowBoxes = v end }) -- Uncomment if Box ESP added
    Tabs.Visuals:CreateSlider("ESPMaxDistance", { Title = "ESP Max Distance", Default = Config.ESPMaxDistance, Min = 50, Max = 2000, Callback = function(v) Config.ESPMaxDistance = v end })
    Tabs.Visuals:CreateSlider("ESPNameSize", { Title = "ESP Name Size", Default = Config.ESPNameSize, Min = 8, Max = 24, Callback = function(v) Config.ESPNameSize = v end })
    Tabs.Visuals:CreateSlider("ESPTracerThickness", { Title = "ESP Tracer Thickness", Default = Config.ESPTracerThickness, Min = 1, Max = 5, Callback = function(v) Config.ESPTracerThickness = v end })
    Tabs.Visuals:CreateToggle("BallPrediction", { Title = "Ball Prediction Line", Enabled = Config.BallPredictionEnabled, Callback = function(v) Config.BallPredictionEnabled = v end })
    Tabs.Visuals:CreateToggle("VisualizeCatchZone", { Title = "Visualize Extended Catch", Enabled = Config.VisualizeCatchZone, Callback = function(v) Config.VisualizeCatchZone = v end })
    Tabs.Visuals:CreateSlider("FieldOfView", { Title = "Camera FOV", Default = CurrentCamera.FieldOfView, Min = 70, Max = 120, Callback = function(v) Workspace.CurrentCamera.FieldOfView = v end })

     -- Catching Tab
    Tabs.Catching:CreateToggle("MagnetCatch", { Title = "Magnet Catch", Enabled = Config.MagnetCatchEnabled, Callback = function(v) Config.MagnetCatchEnabled = v end })
    Tabs.Catching:CreateSlider("MagnetCatchRange", { Title = "Magnet Catch Range", Default = Config.MagnetCatchRange, Min = 5, Max = 50, Callback = function(v) Config.MagnetCatchRange = v end })
    Tabs.Catching:CreateToggle("AutoCatch", { Title = "Auto Catch (Aggressive)", Enabled = Config.AutoCatchEnabled, Callback = function(v) Config.AutoCatchEnabled = v end })
    Tabs.Catching:CreateSlider("AutoCatchRange", { Title = "Auto Catch Range", Default = Config.AutoCatchRange, Min = 1, Max = 30, Callback = function(v) Config.AutoCatchRange = v end })
    Tabs.Catching:CreateToggle("ReduceCatchTackle", { Title = "Reduce Catch Tackle Size", Enabled = Config.ReduceCatchTackle, Callback = function(v) Config.ReduceCatchTackle = v end })
    Tabs.Catching:CreateSlider("IncreaseCatchSizeX", { Title = "Increase Catch Size X", Default = Config.IncreaseCatchSize.X, Min = 0, Max = 30, Rounding = 1, Callback = function(v) Config.IncreaseCatchSize = Vector3.new(v, Config.IncreaseCatchSize.Y, Config.IncreaseCatchSize.Z) end })
    Tabs.Catching:CreateSlider("IncreaseCatchSizeY", { Title = "Increase Catch Size Y", Default = Config.IncreaseCatchSize.Y, Min = 0, Max = 30, Rounding = 1, Callback = function(v) Config.IncreaseCatchSize = Vector3.new(Config.IncreaseCatchSize.X, v, Config.IncreaseCatchSize.Z) end })
    Tabs.Catching:CreateSlider("IncreaseCatchSizeZ", { Title = "Increase Catch Size Z", Default = Config.IncreaseCatchSize.Z, Min = 0, Max = 30, Rounding = 1, Callback = function(v) Config.IncreaseCatchSize = Vector3.new(Config.IncreaseCatchSize.X, Config.IncreaseCatchSize.Y, v) end })

    -- Misc Tab
    Tabs.Misc:CreateToggle("HiderSilentMode", { Title = "Bypass Silent Mode", Enabled = Config.SilentMode, Callback = function(v) Config.SilentMode = v end })
    Tabs.Misc:CreateInput("FPSCap", { Title = "FPS Cap (0=Unlock)", Default = 0, Numeric = true, Max = 360, Finished=true, Callback = function(v) local n=tonumber(v); if n then setfpscap(n) end end })
    local cpuOffsetInput = Tabs.Misc:CreateInput("CPUOffset", { Title = "CPU Offset (Bypass)", Default = cpu_offset_value, Numeric = true, Max = MAX_CPU_OFFSET, Min = MIN_CPU_OFFSET, Finished=true, Callback = function(v)
        local n=tonumber(v); if n then cpu_offset_value=math.clamp(math.round(n),MIN_CPU_OFFSET,MAX_CPU_OFFSET); pcall(writefile,"cpu_offset.txt",tostring(cpu_offset_value)); log_warn_hider("CPU Offset set to: %d", cpu_offset_value) end
    end })
    Tabs.Misc:CreateButton("Reset CPU Offset", { Title = "Reset Offset", Description = "Resets offset to random & saves.", Callback = function()
        cpu_offset_value = math.random(MIN_CPU_OFFSET, MAX_CPU_OFFSET); pcall(writefile,"cpu_offset.txt",tostring(cpu_offset_value)); cpuOffsetInput:SetValue(cpu_offset_value); log_warn_hider("CPU Offset reset to: %d", cpu_offset_value)
    end })
    Tabs.Misc:CreateButton("Unload Script", { Title = "Unload Script", Description = "Stops loops and removes UI.", Danger = true, Callback = function()
        Config.PanicKeyEnabled = false -- Ensure features are off
        if MainLoopConnection and MainLoopConnection.Connected then MainLoopConnection:Disconnect() end
        UpdateInfiniteJumpBinding() -- Disconnect jump bind
        CleanupESP(); if BallPredictionLine then BallPredictionLine:Remove() end
        -- Attempt to disconnect bypass listeners (might not always work reliably)
        -- pcall(function() bypass_desc_added_conn:Disconnect() end) -- Need to store connection variables globally
        -- pcall(function() bypass_child_added_conn:Disconnect() end)
        -- pcall(function() bypass_presim_conn:Disconnect() end)
        Library:Unload()
        _G.FluentLoaded = false
        log_warn("Script unloaded.")
        -- Note: Hooks placed by hookfunction/hookmetamethod cannot be reliably removed without restarting the game or specific exploit support.
    end })


    -- Load SaveManager/InterfaceManager (Optional, requires the addons)
    if SaveManager and InterfaceManager then
        task.spawn(function() -- Use task.spawn to avoid blocking
            pcall(function()
                InterfaceManager:SetLibrary(Library); InterfaceManager:SetFolder("FF2Supreme/Interface")
                InterfaceManager:BuildInterfaceSection(Tabs.Main)
                SaveManager:SetLibrary(Library); SaveManager:SetFolder("FF2Supreme/Save")
                SaveManager:IgnoreThemeSettings()
                SaveManager:BuildConfigSection(Tabs.Main)
                SaveManager:LoadAutoloadConfig()
                log_warn("Save/Interface Managers initialized.")
            end)
        end)
    else
        log_warn("SaveManager or InterfaceManager not loaded.")
    end

    Window:SelectTab(1) -- Select Main tab by default
    log_warn("Fluent UI setup complete.")
end


--========================================================================
--[ Main Loop & Event Connections ]
--========================================================================
local MainLoopConnection = nil
local frameCount = 0

local function MainLoop(dt)
    if not Config.PanicKeyEnabled then return end -- Skip loop if panicked

    frameCount = frameCount + 1

    -- Per-Frame Features
    pcall(UpdateESP) -- ESP runs every frame for responsiveness
    pcall(QuarterbackAimbot)
    pcall(SilentAim)
    pcall(MagnetCatch)
    pcall(AutoCatch) -- Checks range, spawns spam thread if needed
    pcall(UpdateBallPrediction)
    pcall(SimulateHumanBehavior)

    -- Less Frequent Updates
    if frameCount % 60 == 0 then -- Every second approx
        pcall(CleanupESP)
    end
    if frameCount >= 300 then frameCount = 0 end -- Reset counter periodically
end

local function StartMainLoop()
    if MainLoopConnection and MainLoopConnection.Connected then return end
    frameCount = 0
    MainLoopConnection = RunService.RenderStepped:Connect(MainLoop)
    UpdateInfiniteJumpBinding() -- Ensure jump state is correct
    log_warn("Main cheat loop started.")
end

local function StopMainLoop()
    if MainLoopConnection and MainLoopConnection.Connected then
        MainLoopConnection:Disconnect()
        MainLoopConnection = nil
    end
    -- Clean up visuals immediately
    pcall(CleanupESP)
    if BallPredictionLine then pcall(BallPredictionLine.Remove, BallPredictionLine); BallPredictionLine = nil end
    Config.InfiniteJumpEnabled = false -- Ensure jump is off logically
    pcall(UpdateInfiniteJumpBinding) -- Disconnect listener
    log_warn("Main cheat loop stopped.")
end

-- Initial Setup Calls
pcall(SetupUI) -- Setup UI first
if LocalPlayer and LocalPlayer.Character then StartMainLoop() end -- Start loop if character already exists
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); StartMainLoop() end) -- Start on spawn
LocalPlayer.CharacterRemoving:Connect(function(char) StopMainLoop() end) -- Stop on death/despawn

-- Toggle Panic Key with Delete key (Example)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        Config.PanicKeyEnabled = not Config.PanicKeyEnabled
        log_warn("Panic Key Toggled: %s", tostring(Config.PanicKeyEnabled))
        if not Config.PanicKeyEnabled then StopMainLoop() else StartMainLoop() end -- Stop/Start loop with panic key
         -- TODO: Update the Fluent UI Toggle state if possible via API
    end
end)

log_warn("FF2 Supreme Script Initialized.")
--// EOF
