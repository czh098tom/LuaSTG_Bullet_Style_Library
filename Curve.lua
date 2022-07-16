CurveLib = {}
local CurveLib = CurveLib

local __canBeParam = FunctionalWrappers.canBeParam
local __default = FunctionalWrappers.default
local __notNil = FunctionalWrappers.notNil

local defaultStateName = "__DEFAULT"

local ccreate = coroutine.create
local cyield = coroutine.yield
local cresume = coroutine.resume
local cstat = coroutine.status

CURVE_REPEAT_SEQUENTIAL = 1

local noInterp = function(x) return x end

local ArrayPool = {}
for i = 1, 10000 do
	ArrayPool[i] = {}
end
local nArrayPool = 10000

local function GetArray(size)
	if not size then size = 0 end
	if nArrayPool > 0 then
		local arr = ArrayPool[nArrayPool]
		for i = 1, size do
			arr[i] = 0
		end
		for i = size + 1, #arr do
			arr[i] = nil
		end
		--ArrayPool[nArrayPool] = nil
		nArrayPool = nArrayPool - 1
		return arr
	else
		local arr = {}
		for i = 1, size do
			arr[i] = 0
		end
		return arr
	end
end

local function ReturnArray(arr)
	nArrayPool = nArrayPool + 1
	ArrayPool[nArrayPool] = arr
end

CurveLib.ReturnArray = ReturnArray

local Point = plus.Class()
CurveLib.Point = Point
function Point:init(t, val, tIsRelative, interp)
	__notNil(t)
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

function Track:BeginTrack(target, param)
	local track = self
	--local tab = {}
	--local trackCo = GetArray(#track.curves)
	local trackCo = {}
	--for i = 1, #track.curves do
	--	tab[i] = 0
	--end
	local tab = GetArray(#track.curves)
	for i = 1, #track.curves do
		local curve = track.curves[i]
		local tabIdx = i

		trackCo[i] = ccreate(function()
			--Print("co")
			local j = 0
			while curve.offset(target, param, j) do
				cyield()
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
							cyield()
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
		end)
		cresume(trackCo[i])
	end
	return trackCo, tab
end

local Event = plus.Class()
CurveLib.Event = Event
function Event:init(t, func, tIsRelative)
	self.t = __canBeParam(t)
	self.func = func
	self.tIsRelative = tIsRelative
end

local EventTrack = plus.Class()
CurveLib.EventTrack = EventTrack
function EventTrack:init(events, repeatType)
	self.events = events
	self.repeatType = repeatType
end

function EventTrack:BeginTrack(target, param)
	local track = self
	return { ccreate(function()
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

function CurveLib.BeginTracks(self, tracks, param)
	param = param or {}
	local tasks = {}
	local arrays = {}
	
	for i = 1, #tracks do
		local trackTasks, trackArr = tracks[i]:BeginTrack(self, param)
		for j = 1, #trackTasks do
			table.insert(tasks, trackTasks[j])
		end
		if trackArr then
			table.insert(arrays, trackArr)
		end
	end
	
	return tasks, arrays
end

function CurveLib.IsFinished(tasks)
	for i = 1, #tasks do
		if cstat(tasks[i]) ~= 'dead' then return false end
	end
	return true
end

local State = plus.Class()
CurveLib.State = State
function State:init(name, tracks)
	self.name = name or ""
	self.tracks = tracks
end

local StateMachine = plus.Class()
CurveLib.StateMachine = StateMachine
function StateMachine:init(target, states, param)
	self.states = {}
	self.param = param
	self.target = target
	for _, v in ipairs(states) do
		self.states[v.name] = v
	end
	self.entryPoint = states[1]
end

function StateMachine:begin()
	if self.entryPoint then
		self.co, self.arr = CurveLib.BeginTracks(self.target, self.entryPoint.tracks, self.param)
		self.currentState = self.entryPoint.name
	end
end

function StateMachine:proceed()
	if self.co then
		for _, v in ipairs(self.co) do
			if cstat(v) ~= 'dead' then
				local _, errmsg = cresume(v)
				if errmsg then
					error(tostring(errmsg) .. "\n========== coroutine traceback ==========\n" .. debug.traceback(v)
						.. "\n========== C traceback ==========")
				end
			end
		end
	end
end

function StateMachine:Collect()
	for _, v in ipairs(self.arr) do
		ReturnArray(v)
	end
	--ReturnArray(self.co)
	--ReturnArray(self.arr)
end

function StateMachine:switch(targetName)
	if not self.states[targetName] then
		error("State " .. targetName .. " does not exist.")
	end
	self:Collect()
	local state = self.states[targetName]
	self.co = CurveLib.BeginTracks(self.target, state.tracks, self.param)
	self.currentState = targetName
end

function CurveLib.AsStates(tab)
	local states = {}
	for _, v in ipairs(tab) do
		table.insert(states, CurveLib.AsState(v))
	end
	return states
end

function CurveLib.AsState(tab)
	local tracks = tab["tracks"] or tab[1]
	return State(tab["name"] or defaultStateName, CurveLib.AsTracks(tracks))
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
	local type = tab["mapType"] or "property"
	if type == "property" then
		map = tab["mapper"]
	elseif type == "function" then
		map = tab["mapper"]
	elseif type == "builtInFunction" then
		local param = tab["mapperParam"]
		map = CurveLib.mapFunc[tab["mapper"]](param and unpack(param))
	end
	local curves = {}
	for i = 1, #tab["curves"] do
		local c = CurveLib.AsCurve(tab["curves"][i])
		if type == "builtInFunction" then c.mapperName = tab["mapper"] end
		table.insert(curves, c)
	end
	return Track(map, curves)
end

function CurveLib.AsCurve(tab)
	local points = {}
	local tabPoints = tab["points"] or tab[1]
	for i = 1, #tabPoints do
		table.insert(points, CurveLib.AsPoint(tabPoints[i]))
	end
	return Curve(points, tab["offset"], tab["repeatType"])
end

function CurveLib.AsPoint(tab)
	local t, val
	t = tab["t"] or tab[1]
	val = tab["val"] or tab[2]
	return Point(t, val, tab["tIsRelative"], CurveLib.ease[tab["interpolation"]])
end

function CurveLib.AsEventTrack(tab)
	local events = {}
	local tabEvents = tab["events"] or tab[1]
	for i = 1, #tabEvents do
		table.insert(events, CurveLib.AsEvent(tabEvents[i]))
	end
	return EventTrack(events, tab["repeatType"])
end

function CurveLib.AsEvent(tab)
	local t, act
	t = tab["t"] or tab[1]
	act = tab["action"] or tab[2]
	return Event(t, act, tab["tIsRelative"])
end

CurveLib.emptyEv = function() end