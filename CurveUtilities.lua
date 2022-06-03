local ease = {}
CurveLib.ease = ease

ease.NoInterp = function(x) return x end

function ease.InSine(x)
	return 1 - cos(x * 90)
end

function ease.OutSine(x)
	return sin(x * 90)
end

function ease.InOutSine(x)
	return 0.5 - 0.5 * cos(x * 180)
end

function ease.InQuad(x)
	return x * x
end

function ease.OutQuad(x)
	return -x * x + 2 * x
end

function ease.InOutQuad(x)
	return x < 0.5 and 2 * x * x or -2 * x * x + 4 * x - 1
end

local mapFunc = {}
CurveLib.mapFunc = mapFunc
function mapFunc.SetV2(setRot)
	if setRot == nil then setRot = true end
	return function(self, tab)
		SetV2(self, tab[1], tab[2], (not self.lockRot) and setRot or false, false)
	end
end

function mapFunc.SetColorForBlend(blend)
	return function(self, tab)
		local a, r, g, b = tab[1], tab[2], tab[3], tab[4]
		r = r or 255
		g = g or 255
		b = b or 255
		_object.set_color(self, blend, a, r, g, b)
	end
end

function mapFunc.PostfixOn(propName, word)
	return function(self, tab)
		self[propName] = word .. tab[1]
	end
end

function mapFunc.Scale()
	return function(self, tab)
		self.hscale = tab[1]
		self.vscale = tab[1]
	end
end

local builtIn = {}
CurveLib.builtIn = builtIn
--[[
function builtIn.Uniform(v)
	assert(v, "V should not be empty.")
	return CurveLib.AsStates({
		{
			{
				{
					type = "numerical",
					mapType = "builtInFunction",
					mapper = "SetV2",
					curves = {
						{ 0, v }
					}
				}
			}
		}
	})
end
]]

builtIn.Uniform = CurveLib.AsStates({
	{
		{
			{
				type = "numerical",
				mapType = "builtInFunction",
				mapper = "SetV2",
				curves = {
					{
						{{ 0, "$v" }}
					},
					{
						{{ 0, "$r" }}
					}
				}
			}
		}
	}
})