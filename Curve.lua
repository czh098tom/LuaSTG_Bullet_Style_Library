CurveLib = {}
local CurveLib = CurveLib

CURVE_REPEAT_SEQUENTIAL = 1

local noInterp = function(x) return x end

local Point = plus.Class()
CurveLib.Point = Point
function Point:init(t, val, tIsRelative, interp)
	self.t = __canBeParam(t)
	self.val = __canBeParam(val)
	self.tIsRelative = tIsRelative
	self.interp = interp or noInterp
end

local Curve = plus.Class()
CurveLib.Curve = Curve
function Curve:init(points, offset, repeatType)
	self.points = points
	offset = offset or 0
	if type(offset) == "number" then
		local v = offset
		offset = function (_, _, j) return j < v end
	end
	self.offset = __canBeParam(offset)
	self.repeatType = repeatType
end

local Track = plus.Class()
CurveLib.Track = Track
function Track:init(map, curves)
	if type(map) ~= "function" then
		local mapStr = map
		map = function(self, tab)
			--Print(mapStr..': '..self[mapStr])
			self[mapStr] = tab[1] 
		end
	end
	self.curves = curves
	self.map = map
end

function Track:DoTrack(target, param)
	local track = self
	local tab = {}
	local trackCo = {}
	for i = 1, #track.curves do
		tab[i] = 0
	end
	for i = 1, #track.curves do
		local curve = track.curves[i]
		local tabIdx = i

		table.insert(trackCo, coroutine.create(function()
			--Print("co")
			local j = 0
			while curve.offset(target, param, j) do
				coroutine.yield()
				j = j + 1
			end
			--Print("init wait")
			repeat
				local tSum = 0
				local k = 1
				local lastVt
				while k <= #curve.points do
					--Print('points: '..#curve.points, 'k: '..k)
					local tCalculated = curve.points[k].t(target, param)
					local tRel = curve.points[k].tIsRelative and tCalculated or tCalculated - tSum
					local vt = curve.points[k].val(target, param)
					--Print(k,tRel,curve.points[k].tIsRelative,curve.points[k].t(self,param),tSum)
					if tRel > 0 then
						local v0 = lastVt or 0
						for l = 1, tRel do
							coroutine.yield()
							tSum = tSum + 1
							--Print(tSum)
							tab[tabIdx] = (vt - v0)*(curve.points[k].interp(l / tRel)) + v0
							--Print(tab[tabIdx])
							track.map(target, tab)
						end
					else
						--Print('tSum: '..tSum)
						tab[tabIdx] = vt
						track.map(target, tab)
					end
					lastVt = vt
					k = k + 1
					--Print('k: '..k)
				end
			until curve.repeatType == nil
		end))
		coroutine.resume(trackCo[i])
	end
	return trackCo
end

local Event = plus.Class()
CurveLib.Event = Event
function Event:init(t, func, tIsRelative)
	self.t = __canBeParam(t)
	self.func = func
	self.tIsRelative = tIsRelative
end

CurveLib.EventTrack = plus.Class()
local EventTrack = CurveLib.EventTrack
function EventTrack:init(events, repeatType)
	self.events = events
	self.repeatType = repeatType
end

function EventTrack:DoTrack(target, param)
	local track = self
	return { coroutine.create(function()
		repeat
			local lastT = 0
			for i = 1, #track.events do
				local ev = track.events[i]
				local tCalculated = ev.t(target, param)
				local relT = ev.tIsRelative and tCalculated or tCalculated - lastT
				task._Wait(relT)
				ev.func(target, param)
				lastT = lastT + relT
			end
		until track.repeatType == nil
	end) }
end

function CurveLib.DoTracks(self, tracks, param)
	param = param or {}
	local tasks = {}
	for i = 1, #tracks do
		local trackTasks = tracks[i]:DoTrack(self, param)
		for j = 1, #trackTasks do
			table.insert(tasks, trackTasks[j])
		end
	end
	return tasks
end

function CurveLib.IsFinished(tasks)
	for i = 1, #tasks do
		if coroutine.status(tasks[i]) ~= 'dead' then return false end
	end
	return true
end

function CurveLib.AsTracks(tab)
	local track = {}
	for i = 1, #tab do
		table.insert(track, CurveLib.AsTrack(tab[i]))
	end
	return track
end

function CurveLib.AsTrack(tab)
	if tab["type"] == "numerical" then
		return CurveLib.AsNumericalTrack(tab)
	elseif tab["type"] == "event" then
		return CurveLib.AsEventTrack(tab)
	end
end

function CurveLib.AsNumericalTrack(tab)
	local map
	if tab["mapType"] == "property" then
		map = tab["mapper"]
	elseif tab["mapType"] == "function" then
		map = tab["mapper"]
	elseif tab["mapType"] == "builtInFunction" then
		local param = tab["mapperParam"]
		map = CurveLib.mapFunc[tab["mapper"]](param and unpack(param))
	end
	local curves = {}
	for i = 1, #tab["curves"] do
		table.insert(curves, CurveLib.AsCurve(tab["curves"][i]))
	end
	return Track(map, curves)
end

function CurveLib.AsCurve(tab)
	local points = {}
	for i = 1, #tab["points"] do
		table.insert(points, CurveLib.AsPoint(tab["points"][i]))
	end
	return Curve(points, tab["offset"], tab["repeatType"])
end

function CurveLib.AsPoint(tab)
	return Point(tab["t"], tab["val"], tab["tIsRelative"], CurveLib.ease[tab["interpolation"]])
end

function CurveLib.AsEventTrack(tab)
	local events = {}
	for i = 1, #tab["events"] do
		table.insert(events, CurveLib.AsEvent(tab["events"][i]))
	end
	return EventTrack(events, tab["repeatType"])
end

function CurveLib.AsEvent(tab)
	return Event(tab["t"], tab["action"], tab["tIsRelative"])
end

CurveLib.emptyEv = function() end

local ease = {}
CurveLib.ease = ease

ease.NoInterp = noInterp

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