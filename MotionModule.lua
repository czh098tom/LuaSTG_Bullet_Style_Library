MOTION_CALCULATION = 0
MOTION_PREDICTATE = 1

local MotionModule = plus.Class()
StyleLib.MotionModule = MotionModule
function MotionModule:init(name, priority, frame, start)
	self.name = name
	self.priority = priority
	self.start = start
	self.frame = frame
end

function MotionModule:AssignTo(bulletSP, conv)
	self:Replace(bulletSP, nil, conv)
end

function MotionModule:Replace(bulletSP, name, conv)
	if name then
		local motion = bulletSP.motions[name]
		local idx
		for i, v in ipairs(bulletSP.sortedMotions) do
			if v == motion then idx = i break end
		end
		if idx then
			table.remove(bulletSP.sortedMotions, idx)
		end
	end
	bulletSP.motions[self.name] = self
	local idx = 1
	for i, v in ipairs(bulletSP.sortedMotions) do
		if bulletSP.sortedMotions[i + 1] then
			if bulletSP.sortedMotions[i + 1].priority > self.priority and self.priority >= v.priority then
				idx = i + 1
			end
		else
			idx = i + 1
		end
	end
	table.insert(bulletSP.sortedMotions, self, idx)
	if self.start then self.start(bulletSP) end
	if conv then conv(bulletSP) end
end