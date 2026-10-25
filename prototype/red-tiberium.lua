-- Red Tiberium (Tiberium Cruentus): the rarest and richest Tiberium. It never grows or spreads by itself
-- (TiberiumColours: grows = false), so it has blue's products and none of what makes or grows a colour:
-- no enrichment, seed or monoculture of its own. It is unstable (scripts/RedTiberium.lua): only its own
-- drill mines it, and a Sonic Emitter of its own clears it without setting it off.
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

-- Red never becomes liquid Tiberium: it has uses of its own (brain: Red Tiberium - Project 3b - Red's Uses), and
-- liquid Tiberium is its own thing, not molten crystal - so blue's refining recipe is the one not copied
for _, name in pairs({"tiberium-ore-processing-blue", "tiberium-blue-explosives",
		"tiberium-primed-reactant-blue", "tiberium-grenade-blue", "tiberium-catalyst-missile-blue", "tiberium-unlock-blue-filter"}) do
	local recipe = redCopy("recipe", name)
	if recipe.crafting_machine_tint then
		recipe.crafting_machine_tint = flib_table.deep_copy(RED_CRAFTING_TINT)
	end
end

-- Red Tiberium Refining: after blue's, a science pack further, unlocking all of red but liquid
local tech = redCopy("technology", "tiberium-refining-blue")
for i = #tech.effects, 1, -1 do
	if tech.effects[i].recipe == "tiberium-liquid-processing-red" then table.remove(tech.effects, i) end
end
for _, recipe in pairs({"tiberium-primed-reactant-red", "tiberium-grenade-red", "tiberium-catalyst-missile-red"}) do
	table.insert(tech.effects, {type = "unlock-recipe", recipe = recipe})
end
tech.prerequisites = {"tiberium-refining-blue", "production-science-pack"}
tech.unit.count = 500
table.insert(tech.unit.ingredients, {"production-science-pack", 1})

-- Red is unstable: no hand and no ordinary drill mines it, only a stabilised drill of its own
data:extend{{type = "resource-category", name = "red-tiberium"}}
ore.category = "red-tiberium"

local RED_ICON = tiberiumInternalName.."/graphics/icons/tiberium-ore-red-20-114-10.png"
local drill = flib.copy_prototype(data.raw["mining-drill"]["electric-mining-drill"], "tiberium-red-drill")
drill.icons = common.layeredIcons("__base__/graphics/icons/electric-mining-drill.png", 64, RED_ICON, 64, "ne")
drill.resource_categories = {"red-tiberium"}
drill.next_upgrade = nil
drill.fast_replaceable_group = nil
local drillItem = flib.copy_prototype(data.raw.item["electric-mining-drill"], "tiberium-red-drill")
drillItem.icons = drill.icons
drillItem.order = drillItem.order.."-red"
data:extend{drill, drillItem, {
	type = "recipe",
	name = "tiberium-red-drill",
	enabled = false,
	energy_required = 10,
	ingredients = {
		{type = "item", name = "electric-mining-drill", amount = 1},
		{type = "item", name = "steel-plate", amount = 20},
		{type = "item", name = "processing-unit", amount = 5},
	},
	results = {{type = "item", name = "tiberium-red-drill", amount = 1}},
}}

-- Its blast's crater, drawn under the ore: the vanilla one draws over it, hiding red a shard seeds in a crater
local crater = flib.copy_prototype(data.raw.corpse["small-scorchmark-tintable"], "tiberium-red-scorchmark")
crater.ground_patch_higher = nil
crater.ground_patch_render_layer = "decals"
crater.final_render_layer = "decals"
data:extend{crater}

-- A shard: one of red ore's smallest crystals, glowing, thrown from a blast; where it lands it may seed red
-- (scripts/RedTiberium.lua). A placeholder look until red's own art
local shardPicture = {
	filename = tiberiumInternalName.."/graphics/entity/ores/hr-tiberium-ore-red.png",
	priority = "high",
	width = 128,
	height = 128,
	x = 128 * 11,
	scale = 0.25,
}
local shardShadow = flib_table.deep_copy(shardPicture)
shardShadow.draw_as_shadow = true
data:extend{{
	type = "projectile",
	name = "tiberium-red-shard",
	flags = {"not-on-map"},
	hidden = true,
	acceleration = 0,
	rotatable = false,
	animation = shardPicture,
	shadow = shardShadow,
	light = {intensity = 0.6, size = 4, color = RUBY},
	action = {
		type = "direct",
		action_delivery = {type = "instant", target_effects = {{type = "script", effect_id = "red-shard"}}},
	},
}}

-- Its Sonic Emitter, made as the blue one, shakes red apart without setting it off
redCopy("electric-energy-interface", "tiberium-sonic-emitter-blue")
redCopy("item", "tiberium-sonic-emitter-blue")
redCopy("recipe", "tiberium-sonic-emitter-blue")
local sonicRed = flib.copy_prototype(data.raw.projectile["tiberium-sonic-emitter-projectile"], "tiberium-sonic-emitter-projectile-red")
sonicRed.action[1].action_delivery.target_effects[1].effect_id = "sonic-clear-red"
data:extend{sonicRed}

-- Red Tiberium Mining: after Red Refining, with its science packs
local mining = flib_table.deep_copy(tech)
mining.name = "tiberium-red-mining"
mining.prerequisites = {"tiberium-refining-red"}
mining.effects = {{type = "unlock-recipe", recipe = "tiberium-red-drill"}, {type = "unlock-recipe", recipe = "tiberium-sonic-emitter-red"}}
mining.unit.count = 300
data:extend{mining}

-- Ore has no health, so every red tile carries a hidden core that only an explosion breaks: its death is
-- the big hit that sets the tile off (scripts/RedTiberium.lua). Bullets, bites, fire and the rest do nothing.
local coreResistances = {}
for name in pairs(data.raw["damage-type"]) do
	if name ~= "explosion" then
		table.insert(coreResistances, {type = name, percent = 100})
	end
end
-- Area damage passes over an entity with no collision layers, so the core has a layer of its own that nothing else has
data:extend{{type = "collision-layer", name = "tiberium-red-core"}, {
	type = "simple-entity",
	name = "tiberium-red-core",
	icons = common.blankIcons,
	flags = {"not-on-map", "not-blueprintable", "not-deconstructable", "not-repairable", "not-flammable", "placeable-off-grid",
		"not-upgradable", "no-copy-paste", "not-in-kill-statistics"},
	hidden = true,
	max_health = 30,
	resistances = coreResistances,
	collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
	collision_mask = {layers = {["tiberium-red-core"] = true}},
	selectable_in_game = false,
	remove_decoratives = "false",
	picture = common.blankPicture,
}}
