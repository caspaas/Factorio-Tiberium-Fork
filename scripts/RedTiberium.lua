-- Red Tiberium is unstable (TiberiumColours: unstable = true). Ore has no health, so every red tile carries a
-- hidden core (prototype/red-tiberium.lua) that only an explosion can break: its death is the big hit that
-- sets the tile off. Red's own drill mines a tile out quietly, its core going with it.
-- The cores are plain simple-entities: they do nothing on their own, so they cost nothing until something hits them.

local RedTiberium = {}

RedTiberium.CORE = "tiberium-red-core"

---The core on the tile at `position`, if it has one
---@param surface LuaSurface
---@param position MapPosition
---@return LuaEntity?
local function coreAt(surface, position)
	return surface.find_entities_filtered{name = RedTiberium.CORE, position = position, radius = 0.5, limit = 1}[1]
end

---Arms an unstable ore: a core on its tile, if it has none. Other ore is left as it is.
---@param ore LuaEntity
function RedTiberium.arm(ore)
	local colour = TiberiumColours.BY_ORE[ore.name]
	if not (colour and colour.unstable) or coreAt(ore.surface, ore.position) then return end
	ore.surface.create_entity{name = RedTiberium.CORE, position = ore.position, force = "neutral"}
end

---Disarms the tile at `position`: its core destroyed, with no blast
---@param surface LuaSurface
---@param position MapPosition
function RedTiberium.disarm(surface, position)
	local core = coreAt(surface, position)
	if core then core.destroy() end
end

---Arms every unstable ore on every surface (red made by a command or another mod), and removes every core
---with no unstable ore left under it
function RedTiberium.sweep()
	for _, surface in pairs(game.surfaces) do
		for _, ore in pairs(surface.find_entities_filtered{name = TiberiumColours.UNSTABLE}) do
			RedTiberium.arm(ore)
		end
		for _, core in pairs(surface.find_entities_filtered{name = RedTiberium.CORE}) do
			if surface.count_entities_filtered{name = TiberiumColours.UNSTABLE, position = core.position, radius = 0.5} == 0 then
				core.destroy()
			end
		end
	end
end

return RedTiberium
