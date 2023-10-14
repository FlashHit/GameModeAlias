--[[
Copyright © [2023] [Flash_Hit a/k/a Bree_Arnold]
All Rights Reserved.
--]]

if Class then
	-- Using LoggingClass
	---@class DynamicBundleLoader:Class
	---@overload fun():DynamicBundleLoader
	---@diagnostic disable-next-line: assign-type-mismatch
	DynamicBundleLoader = Class("DynamicBundleLoader")
else
	DynamicBundleLoader = class("DynamicBundleLoader")
	function DynamicBundleLoader:debug(...)
		print(...)
	end
end

function DynamicBundleLoader:__init()
	self.info = {}
end

-- Returns the highest index in this partition
---@param p_Partition DatabasePartition
---@return integer highestIndex
local function _GetHighestIndexInPartition(p_Partition)
	local s_HighestIndex = 0

	-- Loop all instances in this partition
	for _, l_Instance in ipairs(p_Partition.instances) do
		-- Filter for all instances that have an indexInBlueprint field
		if l_Instance:Is("GameObjectData") then
			l_Instance = l_Instance:Cast()
			local s_Index = l_Instance.indexInBlueprint

			-- Check if the index of this instance is higher then the highest we found so far
			-- Also make sure it's not index 65535 / Unknown.
			if s_HighestIndex < s_Index and s_Index ~= IndexInBlueprint.IndexInBlueprint_Unknown then
				s_HighestIndex = s_Index
			end
		end
	end

	return s_HighestIndex
end

---@param p_Partition DatabasePartition
function _ExcludePatch(p_Partition)
	local s_PrimaryInstance = SubWorldData(p_Partition.primaryInstance)
	s_PrimaryInstance:MakeWritable()

	for i = #s_PrimaryInstance.objects, 1, -1 do
		if not s_PrimaryInstance:Is("SubWorldReferenceObjectData") then
			local s_Object = _G[s_PrimaryInstance.objects[i].typeInfo.name](s_PrimaryInstance.objects[i])

			if s_Object.blueprint then
				s_Object:MakeWritable()
				s_Object.excluded = true
				s_PrimaryInstance.objects:erase(i)
			elseif s_Object.enabled then
				s_Object:MakeWritable()
				s_Object.enabled = false
				s_PrimaryInstance.objects:erase(i)
			end
		end
	end
end

---@param p_Partition DatabasePartition
function _Exclude(p_Partition)
	local s_PrimaryInstance = LevelData(p_Partition.primaryInstance)
	---@cast s_PrimaryInstance LevelData
	local m_LazyLoadedCount = 0
	for _, l_Object in ipairs(s_PrimaryInstance.objects) do
		l_Object = _G[l_Object.typeInfo.name](l_Object)

		if l_Object.blueprint and l_Object.blueprint.isLazyLoaded then
			m_LazyLoadedCount = m_LazyLoadedCount + 1

			l_Object.blueprint:RegisterLoadHandlerOnce(function(p_Instance)
				m_LazyLoadedCount = m_LazyLoadedCount - 1
				if m_LazyLoadedCount == 0 then _ExcludePatch(p_Partition) end
			end)
		end
	end

	if m_LazyLoadedCount == 0 then _ExcludePatch(p_Partition) end
end

local function _PatchInternal(p_Partition, p_Info)
	local s_LevelLayerInclusion = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Static, "LevelLayerInclusion"):Cast()
	---@cast s_LevelLayerInclusion WorldPartInclusion

	local s_SubWorldInclusionSetting = SubWorldInclusionSetting(MathUtils:RandomGuid())
	s_SubWorldInclusionSetting.criterion = s_LevelLayerInclusion.criteria[1]

	for _, l_GameModeName in ipairs(p_Info.gameModes) do
		s_SubWorldInclusionSetting.enabledOptions:add(l_GameModeName)
	end

	local s_SubWorldInclusionSettings = SubWorldInclusionSettings(MathUtils:RandomGuid())
	s_SubWorldInclusionSettings.settings:add(s_SubWorldInclusionSetting)

	local s_SubWorldReferenceObjectData = SubWorldReferenceObjectData(MathUtils:RandomGuid())
	s_SubWorldReferenceObjectData.isEventConnectionTarget = Realm.Realm_ClientAndServer
	s_SubWorldReferenceObjectData.isPropertyConnectionTarget = Realm.Realm_None
	s_SubWorldReferenceObjectData.indexInBlueprint = _GetHighestIndexInPartition(p_Partition) + 1
	s_SubWorldReferenceObjectData.streamRealm = StreamRealm.StreamRealm_Both
	s_SubWorldReferenceObjectData.castSunShadowEnable = true
	s_SubWorldReferenceObjectData.excluded = false
	s_SubWorldReferenceObjectData.bundleName = p_Info.bundleName
	s_SubWorldReferenceObjectData.inclusionSettings = s_SubWorldInclusionSettings
	s_SubWorldReferenceObjectData.autoLoad = true
	s_SubWorldReferenceObjectData.isWin32SubLevel = true
	s_SubWorldReferenceObjectData.isXenonSubLevel = true
	s_SubWorldReferenceObjectData.isPs3SubLevel = true

	local s_PrimaryInstance = LevelData(p_Partition.primaryInstance)
	s_PrimaryInstance:MakeWritable()
	s_PrimaryInstance.objects:add(s_SubWorldReferenceObjectData)

	local s_LinkConnection = LinkConnection()
	s_LinkConnection.target = s_SubWorldReferenceObjectData
	s_PrimaryInstance.linkConnections:add(s_LinkConnection)

	local s_RegistryContainer = s_PrimaryInstance.registryContainer
	if not s_RegistryContainer then
		error("Failed to find RegistryContainer for " .. s_PrimaryInstance.name)
	end
	s_RegistryContainer:MakeWritable()
	s_RegistryContainer.referenceObjectRegistry:add(s_SubWorldReferenceObjectData)

	local s_ExcludeConfig = LevelModificationConfig[p_Info.bundleName:gsub(".*/", "")]
	if s_ExcludeConfig then
		ResourceManager:RegisterPartitionLoadHandlerOnce(s_ExcludeConfig.MainPartitionGuid, _Exclude)
	end
end

local function _Patch(p_Partition, p_Info)
	for _, l_Info in ipairs(p_Info) do
		_PatchInternal(p_Partition, l_Info)
	end
end

---@param p_Partition DatabasePartition
function DynamicBundleLoader:OnLevelDataLoaded(p_Partition)
	local s_PrimaryInstance = LevelData(p_Partition.primaryInstance)
	---@cast s_PrimaryInstance LevelData
	local m_LazyLoadedCount = 0
	for _, l_Object in ipairs(s_PrimaryInstance.objects) do
		l_Object = _G[l_Object.typeInfo.name](l_Object)

		if l_Object.blueprint and l_Object.blueprint.isLazyLoaded then
			m_LazyLoadedCount = m_LazyLoadedCount + 1

			l_Object.blueprint:RegisterLoadHandlerOnce(function(p_Instance)
				m_LazyLoadedCount = m_LazyLoadedCount - 1
				if m_LazyLoadedCount == 0 then _Patch(p_Partition, self.info[s_PrimaryInstance.name]) end
			end)
		end
	end

	if m_LazyLoadedCount == 0 then _Patch(p_Partition, self.info[s_PrimaryInstance.name]) end
end

---@param levelName string
---@param gameModes string[]
---@param bundleName string
function DynamicBundleLoader:Add(levelName, gameModes, bundleName)
	if not self.info[levelName] then
		self.info[levelName] = {}
		local s_LevelModificationConfig = LevelModificationConfig[levelName:gsub(".*/", "")]
		ResourceManager:RegisterPartitionLoadHandler(s_LevelModificationConfig.MainPartitionGuid, self, self.OnLevelDataLoaded)
	end

	table.insert(self.info[levelName], {
		gameModes = gameModes,
		bundleName = bundleName
	})
end

DynamicBundleLoader = DynamicBundleLoader()
