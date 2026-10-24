-- The Tiberium colours, one entry each, for the data stage and the control stage alike.
-- The code every Tiberium shares - the ore list, ore blasts, trigger effects, slurry
-- spilled back as ore - reads it, so a colour is an entry here and its prototypes.
-- What only blue does (it mutates from green and infects it, its saturation, its
-- monoculture and Sonic Emitter) stays blue's own.
-- Green first: it wins a tie, and its ore is the one growth places when nothing else is asked.

---@class TiberiumColour
---@field key string Its name in code: "green", "blue"
---@field ore string Its ore, resource and item alike
---@field slurry string Its slurry fluid
---@field explosion string The blast made when its ore is destroyed
---@field grows boolean Whether growth spreads and grows it
---@field unlock string? The hidden recipe that adds it to filter selections when it is first seen
---@field value number Tiberian Sun's price for it (Riparius 25, Vinifera 40)
---@field tint data.Color The tint of its blast

---@class TiberiumColours: TiberiumColour[]
local TiberiumColours = {
	{key = "green", ore = "tiberium-ore", slurry = "tiberium-slurry", explosion = "tiberium-explosion-green", grows = true,
		value = 25, tint = {r = 0.109804, g = 0.721567, b = 0.231373, a = 1}},
	{key = "blue", ore = "tiberium-ore-blue", slurry = "tiberium-slurry-blue", explosion = "tiberium-explosion-blue", grows = true,
		unlock = "tiberium-unlock-blue-filter", value = 40, tint = {r = 0.04, g = 0.4, b = 1, a = 1}},
}

---Every colour's ore, in order
TiberiumColours.ORES = {}
---The colours by key and by ore
TiberiumColours.BY_KEY, TiberiumColours.BY_ORE = {}, {}
for _, colour in ipairs(TiberiumColours) do
	table.insert(TiberiumColours.ORES, colour.ore)
	TiberiumColours.BY_KEY[colour.key] = colour
	TiberiumColours.BY_ORE[colour.ore] = colour
end

return TiberiumColours
