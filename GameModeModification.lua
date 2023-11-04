--[[
Copyright © [2023] [Flash_Hit a/k/a Bree_Arnold]
All Rights Reserved.
--]]

--------
-- This modifies the list of all existing gamemodes
-- Without adding the gamemode here, we won't be able to load the level
--------

-- Adds our custom gamemodes to the list off all existing gamemodes
---@param p_Instance DataContainer
local function _OnLevelLayerInclusion(p_Instance)
	p_Instance = WorldPartInclusion(p_Instance)
	---@cast p_Instance WorldPartInclusion

	local s_Criteria = p_Instance.criteria[1]
	s_Criteria:MakeWritable()

	for l_Name, _ in pairs(GameModeModificationConfig.aliasVersionedNames) do
		local s_Contains = false

		-- check if the gamemode exists already
		for _, l_Mode in pairs(s_Criteria.options) do
			if l_Mode == l_Name then
				s_Contains = true
				break
			end
		end

		if not s_Contains then
			s_Criteria.options:add(l_Name)
		end
	end
end

---@param p_Instance DataContainer
local function _PatchLevelDescriptionAsset(p_Instance)
	p_Instance = LevelDescriptionAsset(p_Instance)
	p_Instance:MakeWritable()
	---@cast p_Instance LevelDescriptionAsset

	local s_Category = p_Instance.categories[1]
	if not s_Category then return end

	for l_Name, _ in pairs(GameModeModificationConfig.aliasVersionedNames) do
		local s_Contains = false

		-- check if the gamemode exists already
		for _, l_Mode in pairs(s_Category.mode) do
			if l_Mode == l_Name then
				s_Contains = true
				break
			end
		end

		if not s_Contains then
			s_Category.mode:add(l_Name)
		end
	end
end

---@param p_LevelReportingAsset DataContainer
local function _OnLevelReportingAsset(p_LevelReportingAsset)
	p_LevelReportingAsset = LevelReportingAsset(p_LevelReportingAsset)
	---@cast p_LevelReportingAsset LevelReportingAsset

	for _, l_LevelDescriptionAsset in ipairs(p_LevelReportingAsset.builtLevels) do
		if l_LevelDescriptionAsset.isLazyLoaded then
			l_LevelDescriptionAsset:RegisterLoadHandlerOnce(_PatchLevelDescriptionAsset)
		else
			_PatchLevelDescriptionAsset(l_LevelDescriptionAsset)
		end
	end
end

---@param p_Instance DataContainer
local function _OnGameModeSettings(p_Instance)
	p_Instance = GameModeSettings(p_Instance)
	p_Instance:MakeWritable()
	---@cast p_Instance GameModeSettings

	local s_GameModeInformation = p_Instance.information[1]
	for l_Name, _ in pairs(GameModeModificationConfig.aliasNames) do
		local s_Contains = false

		-- check if the gamemode exists already
		for _, l_Size in pairs(s_GameModeInformation.sizes) do
			if l_Size.name == l_Name then
				s_Contains = true
				break
			end
		end

		if not s_Contains then
			local s_GameModeTeamSize = GameModeTeamSize()
			s_GameModeTeamSize.playerCount = GameModeModificationConfig.TeamSize
			s_GameModeTeamSize.squadSize = GameModeModificationConfig.SquadSize

			local s_GameModeSize = GameModeSize()
			s_GameModeSize.forceSquad = GameModeModificationConfig.ForceSquad
			s_GameModeSize.metaIdentifier = l_Name
			s_GameModeSize.name = l_Name
			s_GameModeSize.shortName = l_Name
			s_GameModeSize.roundsPerMap = GameModeModificationConfig.RoundsPerMap
			s_GameModeSize.teams:add(s_GameModeTeamSize)
			s_GameModeSize.teams:add(s_GameModeTeamSize)
			s_GameModeSize.teams:add(s_GameModeTeamSize)

			s_GameModeInformation.sizes:add(s_GameModeSize)
		end
	end
end

ResourceManager:RegisterInstanceLoadHandlerOnce(Guid("8553F314-33C6-11DE-9A60-82A633F14A46"), Guid("8553F315-33C6-11DE-9A60-82A633F14A46"), _OnLevelLayerInclusion)
ResourceManager:RegisterInstanceLoadHandlerOnce(Guid("4B6D07D6-F84D-11DD-BE32-C64EACA26B06"), Guid("4B6D07D7-FE4D-11DD-A232-C64E4C926B06"), _OnLevelReportingAsset)
ResourceManager:RegisterInstanceLoadHandlerOnce(Guid("C4DCACFF-ED8F-BC87-F647-0BC8ACE0D9B4"), Guid("AD413546-DEAF-8115-B89C-D666E801C67A"), _OnGameModeSettings)

if SharedUtils:IsClientModule() then
	local s_LevelLayerInclusion = ResourceManager:FindInstanceByGuid(Guid("8553F314-33C6-11DE-9A60-82A633F14A46"), Guid("8553F315-33C6-11DE-9A60-82A633F14A46"))

	if s_LevelLayerInclusion then
		_OnLevelLayerInclusion(s_LevelLayerInclusion)
	end

	local s_LevelReportingAsset = ResourceManager:FindInstanceByGuid(Guid("4B6D07D6-F84D-11DD-BE32-C64EACA26B06"), Guid("4B6D07D7-FE4D-11DD-A232-C64E4C926B06"))

	if s_LevelReportingAsset then
		_OnLevelReportingAsset(s_LevelReportingAsset)
	end

	-- NOTE: GameModeSettings is not available on the client for whatever reason.
end
