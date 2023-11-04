--[[
Copyright (c) [2023] [Flash_Hit a/k/a Bree_Arnold]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

--------
-- This modifies the main level partition (ex. Levels/MP_001/MP_001) to automatically
-- load the custom bundle as a subbundle when using a RM gamemode.
-- The MapList file would have an entry like this: Levels/MP_001/MP_001 AdvanceAndSecureStd 1
--------

require("__shared/submodules/GameModeAlias/GameModeModificationConfig")
require("__shared/submodules/GameModeAlias/LevelModificationConfig")
require("__shared/submodules/GameModeAlias/DynamicBundleLoader")

local m_CurrentLevelConfig
local m_CurrentGameModeAliasMap

---@param p_Partition DatabasePartition
local function _TweakLevel(p_Partition)
	local s_LevelName = SharedUtils:GetLevelName():gsub(".*/", "")
	local s_LevelVanillaAlias = GameModeModificationConfig.vanillaToAlias[s_LevelName]

	if not s_LevelVanillaAlias then
		return
	end

	for _, l_Instance in ipairs(p_Partition.instances) do
		-- Filter for all SubWorldInclusionSetting
		-- These contain the gamemode name to check
		if l_Instance.typeInfo.name == "SubWorldInclusionSetting" then
			l_Instance = SubWorldInclusionSetting(l_Instance)

			-- check all gamemode names and search for ConquestLarge0 or ConquestAssaultLarge0
			for _, l_GameModeName in ipairs(l_Instance.enabledOptions) do
				-- if ConquestLarge0 or ConquestAssaultLarge0 exists we want to add our custom gamemode names
				if s_LevelVanillaAlias[l_GameModeName] then
					l_Instance:MakeWritable()

					for _, l_Name in pairs(s_LevelVanillaAlias[l_GameModeName]) do
						-- TODO: make sure there are no entries with the same name.
						l_Instance.enabledOptions:add(l_Name)
					end

					break
				end
			end
		end
	end
end

---@param p_LevelName string
---@param p_GameMode string
---@return boolean isValid
local function _IsGameModeValid(p_LevelName, p_GameMode)
	local s_LevelAlias = GameModeModificationConfig.aliasToVanilla[p_LevelName]
	m_CurrentGameModeAliasMap = s_LevelAlias and s_LevelAlias[p_GameMode] or nil
	return s_LevelAlias and s_LevelAlias[p_GameMode] ~= nil
end

---@param p_HookCtx HookContext
---@param p_Bundles string[]
---@param p_Compartment ResourceCompartment|integer
local function OnLoadBundles(p_HookCtx, p_Bundles, p_Compartment)
	if p_Compartment == ResourceCompartment.ResourceCompartment_Game then
		local s_LevelName = SharedUtils:GetLevelName():gsub(".*/", "")
		---@cast s_LevelName -nil
		local s_GameMode = SharedUtils:GetCurrentGameMode()
		---@cast s_GameMode -nil

		if not _IsGameModeValid(s_LevelName, s_GameMode) then
			return
		end

		m_CurrentLevelConfig = LevelModificationConfig[s_LevelName]

		if not m_CurrentLevelConfig then
			error(string.format("LevelConfig not found for %s", s_LevelName))
		end

		ResourceManager:RegisterPartitionLoadHandlerOnce(m_CurrentLevelConfig.MainPartitionGuid, _TweakLevel)
	elseif p_Compartment == ResourceCompartment.ResourceCompartment_Dynamic_Begin_ then
		if not m_CurrentLevelConfig or not m_CurrentLevelConfig.Sub or not m_CurrentGameModeAliasMap then
			return
		end

		for _, l_CurrentVanillaName in ipairs(m_CurrentGameModeAliasMap) do
			for _, l_Table in ipairs(m_CurrentLevelConfig.Sub) do
				for _, l_VanillaName in ipairs(l_Table.Names) do
					if l_CurrentVanillaName == l_VanillaName then
						ResourceManager:RegisterPartitionLoadHandlerOnce(l_Table.PartitionGuid, _TweakLevel)
						return
					end
				end
			end
		end
	end
end

Hooks:Install("ResourceManager:LoadBundles", 1, OnLoadBundles)
