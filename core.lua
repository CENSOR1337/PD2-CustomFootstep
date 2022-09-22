local function logConsole(...)
	log("[CustomFootstepSound] : " .. string.format(...))
end

if not (ModCore) then
	logConsole(" [ERROR] : BeardLib is not installed!")
	return
end

local footstepJsonPath = string.format("mods/CustomFootstep/footstep_data.json", ModPath)
local footstepJsonFile = io.open(footstepJsonPath, "r")
local soundBank = {}
local materialDefine = {}
if (footstepJsonFile) then
	local footstepData = json.decode(footstepJsonFile:read("*all"))
	footstepJsonFile:close()
	if not (footstepData) then
		logConsole("failed to load footstep_data.json")
		return
	end
	soundBank = footstepData.soundBank
	materialDefine = footstepData.materialDefine
else
	logConsole("could not find footstep_data.json")
	return
end

local soundInfos = {}
for key, value in pairs(soundBank) do
	local info = {}
	for movementType, sounds in pairs(value) do
		info[movementType] = {
			currentIndex = 1,
			maxIndex = #sounds,
		}
	end
	soundInfos[key] = info
end

local movieId = Idstring("movie")
local soundsId = {}
function CustomFootstepSound:playSound(sound)
	local soundId = soundsId[sound]
	if not (soundId) then
		soundId = Idstring(sound)
		soundsId[sound] = soundId
	end
	if not (PackageManager:has(movieId, soundId)) then
		logConsole(string.format("cannot find asset : %s", tostring(sound)))
		return
	end
	local volume = managers.user:get_setting("sfx_volume")
	local percentage = (volume - tweak_data.menu.MIN_SFX_VOLUME) / (tweak_data.menu.MAX_SFX_VOLUME - tweak_data.menu.MIN_SFX_VOLUME)
	managers.menu_component._main_panel:video({
		name = name,
		video = sound,
		visible = false,
		loop = false
	}):set_volume_gain(percentage)
end

local origin_play_footstep = PlayerSound.play_footstep
function CustomFootstepSound:footstepEvent(material, movementType)
	local materialName = tweak_data.materials[material:key()]
	local soundMaterial = materialDefine[materialName]
	if not (soundMaterial) then
		soundMaterial = materialDefine["default"]
	end

	local soundEntry = soundBank[soundMaterial]
	if not (soundEntry) then return end

	local footstepSounds = soundEntry[movementType]
	if not (footstepSounds) then
		return
	end

	local soundInfo = soundInfos[soundMaterial][movementType]
	local soundFile = footstepSounds[soundInfo.currentIndex]
	soundInfo.currentIndex = soundInfo.currentIndex + 1
	if soundInfo.currentIndex > soundInfo.maxIndex then
		soundInfo.currentIndex = 1
	end

	CustomFootstepSound:playSound(soundFile)
end

--[[ Hooks ]] --
function PlayerSound:play_footstep(foot, material)

	if (self._unit:movement():in_air()) then
		return
	end

	local bIsRunning = self._unit:movement():running()
	local bIsCrouching = self._unit:movement():crouching()
	local bIsOnLadder = self._unit:movement():on_ladder()
	local bAiming = false -- can't find one yet

	local movementType = bAiming and "CROUCH" or "WALK"
	if bIsRunning then
		movementType = "RUN"
	elseif bIsCrouching then
		movementType = "CROUCH"
	end
	CustomFootstepSound:footstepEvent(material, movementType)
end

function PlayerSound:play_land(material)
	CustomFootstepSound:footstepEvent(material, "LAND")
end
