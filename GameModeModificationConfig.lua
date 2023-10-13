--[[
Copyright © [2023] [Flash_Hit a/k/a Bree_Arnold]
All Rights Reserved.
--]]

--[[
Usage Examples:

-- This one allows using `MP_001 MyAwesomeMode0 1` in your MapList.txt and it will be the same as normal TDM.
GameModeModificationConfig.AddGameModeAlias("Levels/MP_001/MP_001", "TeamDeathMatch0", "MyAwesomeMode", 1)

-- This one allows using `MP_001 MyAwesomeMode0 1` AND `MP_001 MyAwesomeMode1 1` in your MapList.txt
GameModeModificationConfig.AddGameModeAlias("Levels/MP_001/MP_001", "TeamDeathMatch0", "MyAwesomeMode", 2)

-- In this example no base gamemode will be loaded. This will probably require you to add additional bundles manually.
GameModeModificationConfig.AddGameModeAlias("Levels/MP_001/MP_001", nil, "MyAwesomeMode", 1)
--]]

GameModeModificationConfig = {
	-- TODO: revisit if these settings do anything
	SquadSize = 8,
	TeamSize = 100,
	RoundsPerMap = 1,

	aliasNames = {},
	aliasVersionedNames = {},
	aliasToVanilla = {},
	vanillaToAlias = {}
}

function GameModeModificationConfig.AddGameModeAlias(levelName, gameMode, alias, versions)
	levelName = levelName:gsub(".*/", "")

	for version = 0, versions - 1 do
		local s_Name = string.format("%s%s", alias, version)
		GameModeModificationConfig.aliasVersionedNames[s_Name] = true

		if not GameModeModificationConfig.aliasToVanilla[levelName] then
			GameModeModificationConfig.aliasToVanilla[levelName] = {}
		end

		if not GameModeModificationConfig.vanillaToAlias[levelName] then
			GameModeModificationConfig.vanillaToAlias[levelName] = {}
		end

		if not gameMode then
			gameMode = ""
		end

		local s_LevelVanillaToAlias = GameModeModificationConfig.vanillaToAlias[levelName]

		if not s_LevelVanillaToAlias[gameMode] then
			s_LevelVanillaToAlias[gameMode] = {}
		end

		local s_Contains = false
		for _, l_Name in ipairs(s_LevelVanillaToAlias[gameMode]) do
			if l_Name == s_Name then
				s_Contains = true
				break
			end
		end

		if not s_Contains then
			table.insert(s_LevelVanillaToAlias[gameMode], s_Name)
		end

		local s_AliasToVanillaLevel = GameModeModificationConfig.aliasToVanilla[levelName]

		if not s_AliasToVanillaLevel[s_Name] then
			s_AliasToVanillaLevel[s_Name] = {}
		end

		local s_Contains = false
		for _, l_Name in ipairs(s_AliasToVanillaLevel[s_Name]) do
			if l_Name == gameMode then
				s_Contains = true
				break
			end
		end

		if not s_Contains then
			table.insert(s_AliasToVanillaLevel[s_Name], gameMode)
		end
	end

	GameModeModificationConfig.aliasNames[alias] = true
end
