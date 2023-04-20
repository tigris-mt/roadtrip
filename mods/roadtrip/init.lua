minetest.register_node("roadtrip:sand", {
	description = "Sand",
	tiles = {"roadtrip_sand.png"},
})

local sandid = minetest.get_content_id("roadtrip:sand")

minetest.register_on_generated(function(minp, maxp, blockseed)
	if minp.y > 0 or maxp.y < 0 then
		return
	end

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

	local data = vm:get_data()

	for z=minp.z,maxp.z do
		for x=minp.x,maxp.x do
			data[area:index(x, 0, z)] = sandid
		end
	end

	vm:set_data(data)
	vm:write_to_map()
end)

minetest.register_on_newplayer(function(player)
	player:set_pos(vector.new(0, 1, 0))
end)

minetest.register_on_respawnplayer(function(player)
	player:set_pos(vector.new(0, 1, 0))
end)
