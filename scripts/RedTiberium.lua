-- Red Tiberium is unstable (TiberiumColours: unstable = true). Ore has no health, so every red tile carries a
-- hidden core (prototype/red-tiberium.lua) that only an explosion can break: its death is the big hit that
-- sets the tile off. Red's own drill mines a tile out quietly, its core going with it.
-- The cores are plain simple-entities: they do nothing on their own, so they cost nothing until something hits them.

local RedTiberium = {}

RedTiberium.CORE = "tiberium-red-core"
-- One tile's blast is about a grenade's: its explosion damage, over a few tiles
RedTiberium.RADIUS = 3
RedTiberium.DAMAGE = 35
-- A blast sets its red neighbours off a moment later, so a field ripples; at most CAP tiles go a tick
RedTiberium.RIPPLE = 20
RedTiberium.CAP = 40
-- Each tile throws shards 5-15 tiles out; one in four seeds a tile of red, which settles for SETTLE ticks
-- before anything can set it off, so it never joins the chain that threw it
RedTiberium.SHARDS = 3
RedTiberium.SHARD_NEAR = 5
RedTiberium.SHARD_FAR = 15
RedTiberium.SHARD_SEED = 0.25
RedTiberium.SETTLE = 600
-- A building dying this close to red is a big hit on it
RedTiberium.BUILDING_REACH = 2
---Upstream's Tiberium damage, as the settings make it now (set by control.lua)
---@type fun(): number
RedTiberium.tiberiumDamage = function() return 0 end
---The most ore a tile holds (set by control.lua); a shard seeds a quarter of it
RedTiberium.maxPerTile = 1000

---The core on the tile at `position`, if it has one
---@param surface LuaSurface
---@param position MapPosition
---@return LuaEntity?
local function coreAt(surface, position)
	return surface.find_entities_filtered{name = RedTiberium.CORE, position = position, radius = 0.5, limit = 1}[1]
end

---The blasts waiting (`queue`) and the shard-made red settling (`settling`), each by the tick it is due, and the
---tiles already waiting (`queued`)
---@return {queue: table<uint, RedTile[]>, queued: table<string, true>, settling: table<uint, RedTile[]>}
local function state()
	storage.redTiberium = storage.redTiberium or {queue = {}, queued = {}, settling = {}}
	return storage.redTiberium
end

---@class RedTile
---@field surface uint
---@field x number
---@field y number

---@param list table<uint, RedTile[]>
---@param tick uint
---@param surface LuaSurface
---@param position MapPosition
local function due(list, tick, surface, position)
	list[tick] = list[tick] or {}
	table.insert(list[tick], {surface = surface.index, x = position.x, y = position.y})
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
	state()
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

---Sets off the armed red on the tile at `position` in `delay` ticks, once however often it is hit. Red that is
---not armed (still settling) is not set off.
---@param surface LuaSurface
---@param position MapPosition
---@param delay uint
function RedTiberium.hit(surface, position, delay)
	local core = coreAt(surface, position)
	if not core then return end
	position = core.position
	local rt = state()
	local key = surface.index..":"..position.x..":"..position.y
	if rt.queued[key] then return end
	rt.queued[key] = true
	due(rt.queue, game.tick + math.max(delay, 1), surface, position)
end

---What a blast sets going round it: its red neighbours, and its shards
---@param surface LuaSurface
---@param position MapPosition
function RedTiberium.after_blast(surface, position)
	for _, ore in pairs(surface.find_entities_filtered{name = TiberiumColours.UNSTABLE, position = position, radius = 1.5}) do
		RedTiberium.hit(surface, ore.position, RedTiberium.RIPPLE)
	end
	for _ = 1, RedTiberium.SHARDS do
		local angle = math.random() * 2 * math.pi
		local distance = RedTiberium.SHARD_NEAR + math.random() * (RedTiberium.SHARD_FAR - RedTiberium.SHARD_NEAR)
		RedTiberium.shard(surface, {x = math.floor(position.x + distance * math.cos(angle)) + 0.5,
			y = math.floor(position.y + distance * math.sin(angle)) + 0.5})
	end
end

---A shard landing on the tile at `position`: armed red there is set off; anywhere else it may seed a tile of red,
---which settles before it is armed
---@param surface LuaSurface
---@param position MapPosition
function RedTiberium.shard(surface, position)
	if surface.count_entities_filtered{name = TiberiumColours.UNSTABLE, position = position, radius = 0.5} > 0 then
		RedTiberium.hit(surface, position, RedTiberium.RIPPLE)
		return
	end
	if math.random() >= RedTiberium.SHARD_SEED
			or not surface.is_chunk_generated{math.floor(position.x / 32), math.floor(position.y / 32)} then
		return
	end
	local ore = AddOre(surface, position, RedTiberium.maxPerTile / 4, TiberiumColours.UNSTABLE[1])
	if ore and ore.valid and TiberiumColours.BY_ORE[ore.name].unstable then
		RedTiberium.disarm(surface, ore.position)
		due(state().settling, game.tick + RedTiberium.SETTLE, surface, ore.position)
	end
end

---The blasts due this tick, CAP at most (the rest wait a tick), and the shard-made red settled this tick armed
---@param tick uint
function RedTiberium.on_tick(tick)
	local rt = storage.redTiberium
	if not rt then return end
	local blasts = rt.queue[tick]
	if blasts then
		rt.queue[tick] = nil
		for i, blast in ipairs(blasts) do
			if i > RedTiberium.CAP then
				local waiting = {table.unpack(blasts, i)}
				for _, later in ipairs(rt.queue[tick + 1] or {}) do table.insert(waiting, later) end
				rt.queue[tick + 1] = waiting
				break
			end
			rt.queued[blast.surface..":"..blast.x..":"..blast.y] = nil
			local surface = game.surfaces[blast.surface]
			if surface then
				RedTiberium.blast(surface, blast)
			end
		end
	end
	local settled = rt.settling[tick]
	if settled then
		rt.settling[tick] = nil
		for _, tile in pairs(settled) do
			local surface = game.surfaces[tile.surface]
			local ore = surface and surface.find_entities_filtered{name = TiberiumColours.UNSTABLE, position = tile, radius = 0.5, limit = 1}[1]
			if ore then
				RedTiberium.arm(ore)
			end
		end
	end
end

---Whether entities of a name are buildings
---@type table<string, boolean>
local isBuilding = {}

---A core killed (only an explosion can) sets its tile off; a building dying sets off the red right beside it
---@param event EventData.on_entity_died
function RedTiberium.on_entity_died(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end
	if entity.name == RedTiberium.CORE then
		RedTiberium.blast(entity.surface, entity.position, entity)
		return
	end
	if isBuilding[entity.name] == nil then
		isBuilding[entity.name] = entity.prototype.is_building
	end
	if isBuilding[entity.name] then
		for _, ore in pairs(entity.surface.find_entities_filtered{name = TiberiumColours.UNSTABLE, position = entity.position,
				radius = RedTiberium.BUILDING_REACH}) do
			RedTiberium.hit(entity.surface, ore.position, 1)
		end
	end
end

return RedTiberium
