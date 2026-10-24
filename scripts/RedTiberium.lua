-- Red Tiberium is unstable (TiberiumColours: unstable = true). Ore has no health, so every red tile carries a
-- hidden core (prototype/red-tiberium.lua) that only an explosion can break: its death is the big hit that
-- sets the tile off. Red's own drill mines a tile out quietly, its core going with it.
-- The cores are plain simple-entities: they do nothing on their own, so they cost nothing until something hits them.

local RedTiberium = {}

RedTiberium.CORE = "tiberium-red-core"
-- One tile's blast is about a grenade's: its explosion damage, over a few tiles
RedTiberium.RADIUS = 3
RedTiberium.DAMAGE = 35
---Upstream's Tiberium damage, as the settings make it now (set by control.lua)
---@type fun(): number
RedTiberium.tiberiumDamage = function() return 0 end

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

---Sets off the unstable ore on the tile at `position`: it and its core destroyed in a blast that hurts every
---entity with health round it, the other Tiberium left alone. With no unstable ore there, only the core goes.
---@param surface LuaSurface
---@param position MapPosition
---@param dying LuaEntity? The core whose death set it off, left to die
function RedTiberium.blast(surface, position, dying)
	local core = coreAt(surface, position)
	if core and core ~= dying then core.destroy() end
	local ore = surface.find_entities_filtered{name = TiberiumColours.UNSTABLE, position = position, radius = 0.5, limit = 1}[1]
	if not ore then return end
	local explosion = TiberiumColours.BY_ORE[ore.name].explosion
	position = ore.position
	ore.destroy()
	surface.create_entity{name = "small-scorchmark-tintable", position = position}
	surface.create_entity{name = explosion, position = position}
	for _, entity in pairs(surface.find_entities_filtered{position = position, radius = RedTiberium.RADIUS}) do
		if entity.valid and entity.is_entity_with_health and entity.name ~= RedTiberium.CORE then
			entity.damage(RedTiberium.DAMAGE, "neutral", "explosion")
			safeDamage(entity, RedTiberium.tiberiumDamage())
		end
	end
	RedTiberium.after_blast(surface, position)
end

---What a blast sets going round it
---@param surface LuaSurface
---@param position MapPosition
function RedTiberium.after_blast(surface, position)
end

---A core killed (only an explosion can) sets its tile off
---@param event EventData.on_entity_died
function RedTiberium.on_entity_died(event)
	local entity = event.entity
	if entity and entity.valid and entity.name == RedTiberium.CORE then
		RedTiberium.blast(entity.surface, entity.position, entity)
	end
end

return RedTiberium
