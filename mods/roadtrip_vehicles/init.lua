local gravity = vector.new(0, -9.81, 0)

minetest.register_entity("roadtrip_vehicles:tire", {
	initial_properties = {
		mesh = "roadtrip_vehicles_tire.b3d",
		textures = {"roadtrip_sand.png^[colorize:#00f:127"},
		pointable = true,
		visual = "mesh",
	},

	on_rightclick = function(self, clicker)
		local parent = self.object:get_attach()
		if parent then
			return parent:get_luaentity():on_rightclick(clicker)
		end
	end,
})

minetest.register_entity("roadtrip_vehicles:car", {
	initial_properties = {
		physical = true,
		collide_with_objects = true,
		collisionbox = {-1, -1, -1, 1, 1, 1},
		mesh = "roadtrip_vehicles_car.b3d",
		textures = {"roadtrip_sand.png^[colorize:#0f0:127"},
		pointable = true,
		visual = "mesh",
		stepheight = 1.5,
	},

	on_activate = function(self, staticdata)
		self.data = b.t.merge({
			steering_angle = 0,
			acceleration = vector.zero(),
			old_pos = self.object:get_pos(),
			rolling_time = 0,
		}, (#staticdata > 0) and minetest.deserialize(minetest.decompress(staticdata)) or {})
		self.data.acceleration = vector.copy(self.data.acceleration)

		self.tire_positions = {
			front_left = {
				pos = vector.new(12, 0, 12),
				steers = true,
			},
			front_right = {
				pos = vector.new(12, 0, -12),
				steers = true,
			},
			back_left = {
				pos = vector.new(-12, 0, 12),
				steers = false,
			},
			back_right = {
				pos = vector.new(-12, 0, -12),
				steers = false,
			},
		}

		for _,tire_position in pairs(self.tire_positions) do
			tire_position.tire = minetest.add_entity(self.object:get_pos(), "roadtrip_vehicles:tire")
			if tire_position.tire then
				tire_position.tire:set_attach(self.object, "", tire_position.pos, vector.zero(), true)
			end
		end
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
				clicker:set_look_horizontal(self.object:get_yaw() - math.pi / 2)
			end
		end
	end,

	on_step = function(self, dtime, moveresult)
		self.data.old_pos = self.data.old_pos or self.object:get_pos()

		if self.object:get_velocity():length() < 1 then
			self.object:set_velocity(vector.zero())
			self.data.acceleration = vector.zero()
		end

		local function velocity_2d(velocity)
			local v = velocity and vector.copy(velocity) or self.object:get_velocity()
			v.y = 0
			return v
		end

		self.data.acceleration = gravity

		local friction = 0

		local dir = vector.new(math.cos(self.object:get_yaw()), 0, math.sin(self.object:get_yaw()))

		for _,driver in ipairs(self.object:get_children()) do
			if driver:is_player() then
				local speed = velocity_2d():length()

				local previous_dir = velocity_2d():normalize()

				local c = driver:get_player_control()

				if c.up then
					self.data.acceleration = self.data.acceleration + dir * 120
				elseif c.down then
					self.data.acceleration = self.data.acceleration - dir * 40
				end

				if c.jump then
					friction = friction + 10
				end

				local steering_angle_limit = 0.5
				local driver_look = driver:get_look_horizontal() + math.pi / 2
				local car_yaw = self.object:get_yaw()

				local difference = b.math.angledelta(driver_look, car_yaw)

				local new_steering_angle = self.data.steering_angle + (difference - self.data.steering_angle) * 5 * dtime

				self.data.steering_angle = (new_steering_angle > self.data.steering_angle) and math.min(difference, new_steering_angle) or math.max(difference, new_steering_angle)

				self.data.steering_angle = math.max(-steering_angle_limit, math.min(self.data.steering_angle, steering_angle_limit))

				local yaw_change = self.data.steering_angle * math.max(0, math.log(speed)) * dtime

				self.object:set_yaw(self.object:get_yaw() - yaw_change)

				break
			end
		end

		for _,tire_position in pairs(self.tire_positions) do
			if tire_position.tire and tire_position.steers then
				tire_position.tire:set_attach(self.object, "", tire_position.pos, vector.new(0, self.data.steering_angle * 180.0 / math.pi, 0), true)
			end
		end

		local roll_dir = (velocity_2d(self.object:get_pos()) - velocity_2d(self.data.old_pos)):normalize()

		self.data.rolling_time = self.data.rolling_time + (self.data.old_pos.y - self.object:get_pos().y)

		local instant_roll = math.sign(self.data.rolling_time) * dtime

		if math.abs(instant_roll) > math.abs(self.data.rolling_time) then
			instant_roll = math.sign(instant_roll) * math.abs(self.data.rolling_time)
		end

		self.data.rolling_time = self.data.rolling_time - instant_roll

		self.data.acceleration = self.data.acceleration + math.sign(instant_roll) * roll_dir * 60

		friction = friction + 5

		local previous_velocity = self.object:get_velocity()
		local new_velocity = previous_velocity + self.data.acceleration * dtime

		new_velocity.x = new_velocity.x / (1 + friction * dtime)
		new_velocity.z = new_velocity.z / (1 + friction * dtime)

		self.object:add_velocity(new_velocity - previous_velocity)

		self.data.old_pos = self.object:get_pos()
	end,
})

minetest.register_on_generated(function(minp, maxp)
	if minp.y > 0 or maxp.y < 0 then
		return
	end

	minetest.add_entity(vector.new((minp.x + maxp.x) / 2, 16, (minp.z + maxp.z) / 2), "roadtrip_vehicles:car")
end)
