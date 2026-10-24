-- Red Tiberium (Tiberium Cruentus): the rarest and richest Tiberium. It never grows or spreads by itself
-- (TiberiumColours: grows = false), so it has blue's products and none of what makes or grows a colour:
-- no enrichment, seed, monoculture or Sonic Emitter of its own.
-- Its prototypes are blue's finished ones, copied with "red" for "blue" in every name, order, locale key and
-- picture path; its pictures are ruby recolours made by tools/tiberium/recolour_red.py. Run after
-- recipe-settings, so blue's processing recipe already holds its ore.

-- Tiberian Sun's prices: Cruentus 70 against Vinifera's 40
local RED_PER_BLUE = 70 / 40
local RUBY = {r = 0.8, g = 0.02, b = 0.08}
local RED_CRAFTING_TINT = {
	primary		= {r = 1,   g = 0.05, b = 0.14, a = 1},
	secondary	= {r = 0.9, g = 0.1,  b = 0.2,  a = 1},
	tertiary	= {r = 1,   g = 0.3,  b = 0.35, a = 0.3},
	quaternary	= {r = 1,   g = 0.2,  b = 0.3,  a = 0.4},
}  --[[@as data.RecipeTints]]

---A copy of `value` with "red" for "blue" in every string in it
local function reddened(value)
	if type(value) == "string" then
		return (value:gsub("blue", "red"))
	elseif type(value) == "table" then
		local copy = {}
		for k, v in pairs(value) do
			copy[reddened(k)] = reddened(v)
		end
		return copy
	end
	return value
end

---Red's copy of blue's prototype `name` of `type`, added to data.raw
local function redCopy(type, name)
	local copy = reddened(data.raw[type][name])
	data:extend{copy}
	return copy
end

-- The ore: blue's resource with green's sharper sheets, recoloured; it never generates on the map
local ore = redCopy("resource", "tiberium-ore-blue")
ore.autoplace = nil
ore.stages = flib_table.deep_copy(data.raw.resource["tiberium-ore"].stages)
ore.stages.sheet.filename = tiberiumInternalName.."/graphics/entity/ores/hr-tiberium-ore-red.png"
ore.stages_effect = flib_table.deep_copy(data.raw.resource["tiberium-ore"].stages_effect)
ore.stages_effect.sheet.filename = tiberiumInternalName.."/graphics/entity/ores/tiberium-ore-glow-red.png"
-- The eye sees red so much dimmer than green that at green's strength red hardly glows at night: stronger
ore.min_effect_alpha = 0.5
ore.max_effect_alpha = 0.8
ore.map_color = RUBY

local oreItem = redCopy("item", "tiberium-ore-blue")
local blueFuel = tonumber(data.raw.item["tiberium-ore-blue"].fuel_value:match("^[%d%.]+"))
oreItem.fuel_value = (blueFuel * RED_PER_BLUE).."MJ"

local slurry = redCopy("fluid", "tiberium-slurry-blue")
slurry.base_color = RUBY
slurry.flow_color = RUBY

redCopy("item", "tiberium-blue-explosives")
redCopy("item", "tiberium-primed-reactant-blue")
redCopy("capsule", "tiberium-grenade-blue")
redCopy("projectile", "tiberium-grenade-blue")
redCopy("ammo", "tiberium-catalyst-missile-blue")
redCopy("projectile", "tiberium-catalyst-missile-blue")
redCopy("projectile", "tiberium-catalyst-chain-blue")
redCopy("achievement", "tiberium-blue-spawn")

for _, name in pairs({"tiberium-ore-processing-blue", "tiberium-liquid-processing-blue", "tiberium-blue-explosives",
		"tiberium-primed-reactant-blue", "tiberium-grenade-blue", "tiberium-catalyst-missile-blue", "tiberium-unlock-blue-filter"}) do
	local recipe = redCopy("recipe", name)
	if recipe.crafting_machine_tint then
		recipe.crafting_machine_tint = flib_table.deep_copy(RED_CRAFTING_TINT)
	end
end
-- Refined, red gives liquid Tiberium by its price against blue's
for _, result in pairs(data.raw.recipe["tiberium-liquid-processing-red"].results) do
	if result.name == "liquid-tiberium" then
		result.amount = math.floor(result.amount * RED_PER_BLUE + 0.5)
	end
end

-- Red Tiberium Refining: after blue's, a science pack further, unlocking all of red
local tech = redCopy("technology", "tiberium-refining-blue")
for _, recipe in pairs({"tiberium-primed-reactant-red", "tiberium-grenade-red", "tiberium-catalyst-missile-red"}) do
	table.insert(tech.effects, {type = "unlock-recipe", recipe = recipe})
end
tech.prerequisites = {"tiberium-refining-blue", "production-science-pack"}
tech.unit.count = 500
table.insert(tech.unit.ingredients, {"production-science-pack", 1})
