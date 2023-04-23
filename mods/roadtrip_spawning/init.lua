minetest.register_on_newplayer(function(player)
	player:set_pos(roadtrip.start_pos())
end)

minetest.register_on_respawnplayer(function(player)
	player:set_pos(roadtrip.start_pos())
end)
