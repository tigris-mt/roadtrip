minetest.register_node("roadtrip:sand", {
	description = "Sand",
	tiles = {"roadtrip_sand.png"},
})

minetest.register_node("roadtrip:black_asphalt", {
	description = "Black Asphalt",
	tiles = {"roadtrip_sand.png^[colorize:#000:230"},
})

minetest.register_node("roadtrip:yellow_asphalt", {
	description = "Yellow Asphalt",
	tiles = {"roadtrip_sand.png^[colorize:#ff0:127"},
})

minetest.register_node("roadtrip:white_asphalt", {
	description = "White Asphalt",
	tiles = {"roadtrip_sand.png^[colorize:#fff:127"},
})
