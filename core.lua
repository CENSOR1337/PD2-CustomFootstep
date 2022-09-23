local function logConsole(...)
	log("[CustomFootstepSound] : " .. string.format(...))
end

if not (ModCore) then
	logConsole(" [ERROR] : BeardLib is not installed!")
	return
end

blt.xaudio.setup()

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
		local buffers = {}
		for key, sound in pairs(sounds) do
			local path = "mods/CustomFootstep/Assets/" .. sound .. ".ogg"
			buffers[#buffers + 1] = XAudio.Buffer:new(path)
		end
		info[movementType] = {
			currentIndex = 1,
			maxIndex = #sounds,
			buffers = buffers
		}
	end
	soundInfos[key] = info
end

function CustomFootstepSound:playSound(buffer)
	local audioSrc = XAudio.UnitSource:new(XAudio.PLAYER, buffer)
	audioSrc:set_volume(1)
end

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
	local buffer = soundInfo.buffers[soundInfo.currentIndex]
	soundInfo.currentIndex = soundInfo.currentIndex + 1
	if soundInfo.currentIndex > soundInfo.maxIndex then
		soundInfo.currentIndex = 1
	end
	
	CustomFootstepSound:playSound(buffer)
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
