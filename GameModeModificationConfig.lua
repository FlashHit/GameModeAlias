--[[
Copyright © [2023] [Flash_Hit a/k/a Bree_Arnold]
All Rights Reserved.
--]]

GameModeModificationConfig = {
	-- TODO: revisit if these settings do anything
	SquadSize = 8,
	TeamSize = 100,
	RoundsPerMap = 1
}

AllGameModeNames = {}

PlainGameModeNames = {}

GameModeAliasVanillaMap = {}
GameModeVanillaAliasMap = {}

function AddGameModeAlias(vanillaNames, alias, versions)
	for version = 0, versions - 1 do
		local s_Name = string.format("%s%s", alias, version)
		table.insert(AllGameModeNames, s_Name)
		GameModeAliasVanillaMap[s_Name] = vanillaNames

		for _, vanillaName in ipairs(vanillaNames) do
			if not GameModeVanillaAliasMap[vanillaName] then
				GameModeVanillaAliasMap[vanillaName] = {}
			end

			table.insert(GameModeVanillaAliasMap[vanillaName], s_Name)
		end
	end

	table.insert(PlainGameModeNames, alias)
end

AddGameModeAlias({"ConquestLarge0", "ConquestAssaultLarge0"}, "AdvanceAndSecure", 2)
AddGameModeAlias({"ConquestLarge0", "ConquestAssaultLarge0"}, "Skirmish", 1)
