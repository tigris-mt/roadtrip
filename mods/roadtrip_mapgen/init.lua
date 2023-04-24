local c_air = minetest.get_content_id("air")
local c_sand = minetest.get_content_id("roadtrip:sand")
local c_black = minetest.get_content_id("roadtrip:black_asphalt")
local c_yellow = minetest.get_content_id("roadtrip:yellow_asphalt")
local c_white = minetest.get_content_id("roadtrip:white_asphalt")

local seed = tonumber(minetest.get_mapgen_setting("seed"))

local seed_random = b.seed_random(seed + 0x40AD)

local z_factor = 60 + 60 * seed_random()
local z_factor_2 = 160 + 160 * seed_random()
local x_factor = 60 + 60 * seed_random()

local function road_x(z)
	return math.floor(math.sin(z / z_factor) * (math.sin(z / z_factor_2) ^ 4) * x_factor + 0.5)
end

local width_z_factor = 60 + 60 * seed_random()
local width_x_factor = 4 * seed_random()

local function road_width(z)
	return 8 + math.floor((math.sin(z / width_z_factor) + 1) * width_x_factor + 0.5)
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

	local data = vm:get_data()

	local perlin = minetest.get_perlin_map({
		seed = 1344,
		scale = 8,
		spread = vector.new(512, 512, 512),
		offset = 4,
		octaves = 6,
		persist = 0.5,
	}, vector.new(1, 1, 1) * (emax.x - emin.x + 1)):get_3d_map_flat(emin)

	local function height(x, z)
		return math.floor(perlin[area:index(x, 0, z)])
	end

	for z=minp.z,maxp.z do
		for x=minp.x,maxp.x do
			local h = height(x, z)
			for y=minp.y,math.min(h, maxp.y) do
				data[area:index(x, y, z)] = c_sand
			end
		end
	end

	if minp.y > 0 or maxp.y < 0 then
		return
	end

	for z=minp.z,maxp.z do
		local offset_limit = road_width(z)
		local previous_center = vector.new(road_x(z), 0, z)
		local next_center = vector.new(road_x(z + 1), 0, z + 1)
		local difference = (next_center - previous_center)
		local length = math.ceil(difference:length()) * 2
		local normalized = difference:normalize() / 2
		for i=0,length do
			for offset=-offset_limit,offset_limit do
				local current = (previous_center + normalized * i + vector.new(offset, 0, 0)):round()
				current.y = height(current.x, current.z)
				if area:containsp(current) and data[area:indexp(current)] == c_sand then
					local color = c_black
					if offset == 0 then
						color = c_yellow
					elseif math.abs(offset) == offset_limit then
						color = c_white
					end
					data[area:indexp(current)] = color
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map()
end)

local start_z = b.WORLD.min.z

function roadtrip.start_pos()
	local x = road_x(start_z) + math.random(-road_width(start_z), road_width(start_z))
	return vector.new(x, 16, start_z)
end
