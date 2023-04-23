local gravity = vector.new(0, -9.81, 0)

minetest.register_entity("roadtrip_vehicles:car", {
	initial_properties = {
		physical = true,
		collide_with_objects = true,
		collisionbox = {-3, -0.5, -1, 3, 1, 1},
		mesh = "roadtrip_vehicles_car.b3d",
		textures = {"roadtrip_sand.png^[colorize:#0f0:127"},
		pointable = true,
		visual = "mesh",
	},

	on_activate = function(self, staticdata)
		self.data = b.t.merge({
			steering_angle = 0,
		}, (#staticdata > 0) and minetest.deserialize(minetest.decompress(staticdata)) or {})
		self.object:set_acceleration(gravity)
	end,

	get_staticdata = function(self)
		return minetest.compress(minetest.serialize(self.data))
	end,

	on_rightclick = function(self, clicker)
		if clicker:is_player() then
			if clicker:get_attach() == self.object then
				clicker:set_detach()
			else
				clicker:set_attach(self.object, "", vector.zero(), vector.zero(), true)
			end
		end
	end,

	on_step = function(self, dtime, moveresult)
		for _,driver in ipairs(self.object:get_children()) do
			if driver:is_player() then
				self.object:set_acceleration(gravity - self.object:get_velocity() * 1)

				local speed = self.object:get_velocity():length()

				local previous_dir = self.object:get_velocity():normalize()
				local dir = vector.new(math.cos(self.object:get_yaw()), 0, math.sin(self.object:get_yaw()))

				self.object:set_velocity(self.object:get_velocity() - previous_dir * speed)
				self.object:set_velocity(self.object:get_velocity() + dir * speed)

				local c = driver:get_player_control()
				if c.up then
					self.object:set_acceleration(self.object:get_acceleration() + dir * 50 / math.sqrt(math.max(1, speed)))
				end

				if c.down then
					self.object:set_acceleration(self.object:get_acceleration() - self.object:get_velocity() * 2)
				end

				if c.left then
					self.data.steering_angle = math.max(self.data.steering_angle - 0.3 * dtime, -0.9)
				elseif c.right then
					self.data.steering_angle = math.min(self.data.steering_angle + 0.3 * dtime, 0.9)
				else
					self.data.steering_angle = self.data.steering_angle - self.data.steering_angle * 2 * dtime
				end

				local yaw_change = self.data.steering_angle * math.max(0, math.log(speed)) * dtime

				if math.abs(yaw_change) > 0.05 * dtime then
					self.object:set_yaw(self.object:get_yaw() - yaw_change)
					driver:set_look_horizontal(driver:get_look_horizontal() - yaw_change)
				end

				return
			end
		end

		self.object:set_acceleration(gravity - self.object:get_velocity() * 1)
	end,
})

minetest.register_on_generated(function(minp, maxp)
	if minp.y > 0 or maxp.y < 0 then
		return
	end

	minetest.add_entity(vector.new((minp.x + maxp.x) / 2, 5, (minp.z + maxp.z) / 2), "roadtrip_vehicles:car")
end)
