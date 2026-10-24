-- The blast of each Tiberium colour when its ore is destroyed, tinted its colour
for _, colour in ipairs(require("scripts.TiberiumColours")) do
	local explosion = flib.copy_prototype(data.raw.explosion["grenade-explosion"], colour.explosion)
	for i,_ in pairs(explosion.animations) do
		explosion.animations[i].tint = colour.tint
	end
	data:extend{explosion}
end
