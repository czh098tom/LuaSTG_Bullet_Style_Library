local cmax = 16

local baseStyle = {
	stayOnCreate = "$stay",
	eliminationMode = "Terminated",
	eliminationInCreationMode = "Pass",
	creation = {
		--image = "preimg1",
		--layer = LAYER_ENEMY_BULLET - size * 0.001,
		tracks = {
			{
				type = "numerical",
				mapType = "builtInFunction",
				mapper = "SetColorForBlend",
				mapperParam = { "" },
				curves = {
					{ points = {{ t = 0, val = 0 }, { t = 10, val = 255 }}}
				}
			},
			{
				type = "numerical",
				mapType = "builtInFunction",
				mapper = "Scale",
				curves = {
					{ points = {{ t = 0, val = 4 }, { t = 10, val = 1 }}},
				}
			}
		}
	},
	idle = {
		--image = "arrow_big1"
	},
	elimination = {
		group = GROUP_GHOST,
		--image = "etbreak1",
		layer = LAYER_ENEMY_BULLET - 50,
		rot = function() return ran:Float(0, 360) end,
		scale = function() return ran:Float(0.5, 0.75) end,
		tracks = {
			{
				type = "event",
				events = {
					{ t = 23, action = function() end }
				}
			}
		}
	},
	eliminationInCreation = {
		group = GROUP_GHOST,
		--image = "preimg1",
		--layer = LAYER_ENEMY_BULLET_EF - v.size * 0.001,
		blend = "mul+add",
		tracks = {
			{
				type = "numerical",
				mapType = "builtInFunction",
				mapper = "Scale",
				curves = {
					{ points = {{ t = 0, val = 1 }, { t = 10, val = 0 }}},
				}
			}
		}
	},
}

local subDelEff = {
	eliminationMode = "Terminated",
	eliminationInCreationMode = "Terminated",
	elimination = baseStyle.elimination
}

StyleLib.Effect = {}
StyleLib.Effect.etbreak = {}
for i = 1, cmax do
	StyleLib.Effect.etbreak[i] = StyleLib.StyleSheet(StyleLib.DeriveFromTable(subDelEff, {
		elimination = {
			image = "etbreak" .. i,
			layer = "$layer"
		}
	}))
end

local effBullet = Class(BulletSP)
function effBullet:init(x, y, color, layer)
	BulletSP.init(self)
	self.x = x
	self.y = y
	BulletSP.SetStyleSheet(self, StyleLib.Effect.etbreak[color], { layer = layer })
	BulletSP.Begin(self)
	Del(self)
end

local shapes = { 
	arrow_big = 0.6,
	arrow_mid = 0.61,
	gun_bullet = 0.4,
	gun_bullet_void = 0.4,
	butterfly = 0.7,
	square = 0.8,
	ball_mid = 0.75,
	ball_mid_b = 0.751,
	ball_mid_c = 0.752,
	ball_mid_d = 0.753,
	money = 0.753,
	mildew = 0.401,
	ellipse = 0.701,
	star_small = 0.5,
	star_big = 0.998,
	star_big_b = 0.999,
	ball_huge_dark = 2.0,
	ball_light_dark = 2.0,
	ball_big = 1.0,
	heart = 1.0,
	ball_small = 0.402,
	grain_a = 0.403,
	grain_b = 0.404,
	grain_c = 0.405,
	kite = 0.406,
	knife = 0.754,
	knife_b = 0.755,
	arrow_small = 0.407,
	water_drop_dark = 0.702,
	music = 0.8,
	silence = 0.8
}

local shapesWith8Color = { "arrow_mid", "butterfly", "ball_mid", "ball_mid_b", "ball_mid_c",
	"ball_mid_d", "money", "ellipse", "star_big", "star_big_b", "ball_huge_dark",
	"ball_light_dark", "ball_big", "heart", "knife", "knife_b", "water_drop_dark", "music",
	"silence"
}

do
	local tmp = shapesWith8Color
	shapesWith8Color = {}
	for i = 1, #tmp do
		shapesWith8Color[tmp[i]] = true
	end
end

StyleLib.Default = {}
for k, v in pairs(shapes) do
	StyleLib.Default[k] = {}
	for j = 1, cmax do
		local jidx = int((j + 1) / 2)
		if shapesWith8Color[k] then
			StyleLib.Default[k][j] = StyleLib.StyleSheet(StyleLib.DeriveFromTable(baseStyle, {
				eliminationInCreationMode = "Pass",
				creation = {
					image = "preimg" .. jidx,
					layer = LAYER_ENEMY_BULLET_EF - v * 0.001,
					tracks = { [2] = { curves = { [1] = {points = {{ val = 4 * v }, { val = v }}}}}}
				}, 
				idle = { 
					image = k .. jidx,
					layer = LAYER_ENEMY_BULLET - v * 0.001
				}, 
				elimination = { image = "etbreak" .. j, size = v },
				eliminationInCreation = {
					image = "preimg" .. jidx,
					layer = LAYER_ENEMY_BULLET_EF - v * 0.001,
				}
			}))
		else
			StyleLib.Default[k][j] = StyleLib.StyleSheet(StyleLib.DeriveFromTable(baseStyle, {
				eliminationInCreationMode = "Pass",
				creation = {
					image = "preimg" .. jidx, 
					layer = LAYER_ENEMY_BULLET_EF - v * 0.001,
					tracks = { [2] = { curves = { [1] = {points = {{ val = 4 * v }, { val = v }}}}}}
				}, 
				idle = { 
					image = k .. j,
					layer = LAYER_ENEMY_BULLET - v * 0.001
				}, 
				elimination = { image = "etbreak" .. j, size = v },
				eliminationInCreation = {
					image = "preimg" .. jidx,
					layer = LAYER_ENEMY_BULLET_EF - v * 0.001,
				}
			}))
		end
	end
end

local lowerLayeredStyles = { "ball_huge_dark", "ball_light_dark" }

for i = 1, #lowerLayeredStyles do
	local shape = StyleLib.Default[lowerLayeredStyles[i]]
	for j = 1, cmax do
		local jidx = int((j + 1) / 2)
		local size = shapes[lowerLayeredStyles[i]]
		shape[j] = StyleLib.DeriveFrom(shape[j], {
			eliminationMode = "Pass",
			eliminationInCreationMode = "Pass",
			creation = {
				image = lowerLayeredStyles[i] .. jidx,
				tracks = {
					{
						type = "numerical",
						mapType = "builtInFunction",
						mapper = "SetColorForBlend",
						mapperParam = { "" },
						curves = {
							{ points = {{ t = 0, val = 0 }, { t = 10, val = 255 }}}
						}
					},
					{
						type = "numerical",
						mapType = "builtInFunction",
						mapper = "Scale",
						curves = {
							{ points = {{ t = 0, val = 2 }, { t = 10, val = 1 }}},
						}
					},
					__clear = true
				}
			},
			idle = { layer = LAYER_ENEMY_BULLET - 2.0 },
			elimination = {
				image = lowerLayeredStyles[i] .. jidx,
				scale = { __remove = true },
				tracks = {
					{
						type = "numerical",
						mapType = "builtInFunction",
						mapper = "SetColorForBlend",
						mapperParam = { "" },
						curves = {
							{ points = {{ t = 0, val = 255 }, { t = 10, val = 0 }}}
						}
					},
					{
						type = "numerical",
						mapType = "builtInFunction",
						mapper = "Scale",
						curves = {
							{ points = {{ t = 0, val = 1 }, { t = 10, val = 0 }}}
						}
					},
					{
						type = "event",
						events = {{ t = 0, action = function(self) New(effBullet, self.x, self.y, j, LAYER_ENEMY_BULLET_EF - size * 0.001) end }}
					},
					__clear = true
				}
			},
			eliminationInCreation = {
				__remove = true
			}
		})
	end
end

local enlightenedShapes = { ball_huge_dark = "ball_huge", ball_light_dark = "ball_light", water_drop_dark = "water_drop" }

for k, v in pairs(enlightenedShapes) do
	StyleLib.Default[v] = {}
	for j = 1, cmax do
		StyleLib.Default[v][j] = StyleLib.DeriveFrom(StyleLib.Default[k][j], {
			creation = {
				blend = "mul+add",
				tracks = { [1] = { mapperParam = { "mul+add" }}
				}
			},
			idle = { blend = "mul+add" }
		})
	end
end