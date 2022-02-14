StyleLib = {}
local StyleLib = StyleLib

local STATE_IDLE = 0
local STATE_INIT = 1
local STATE_INIT_AND_DEFAULT = 2
local STATE_ELIM = 3

function StyleLib.DeriveFromTable(source, derivation)
	if type(derivation) ~= 'table' then return derivation end
	if derivation.__remove then return nil end
	local tab = {}
	for k, v in pairs(derivation) do
		tab[k] = StyleLib.DeriveFromTable(source and source[k], v)
	end
	if source and not derivation.__clear then
		for k, v in pairs(source) do
			if tab[k] ~= nil then
				tab[k] = tab[k]
			else
				if not(type(derivation[k]) == "table" and derivation[k].__remove) then
					tab[k] = v
				end
			end
		end
	end
	return tab
end

function StyleLib.ForkImg(styleName, imgName)
	local resName = string.format("%s::%s", styleName, imgName)
	if not CheckRes(2, resName) then
		CopyImage(resName, imgName)
	end
end

local Style = plus.Class()
StyleLib.Style = Style
function Style:init(tab)
	local blendIsConst
	self.image, self.imgIsConst = __canBeParam(tab.image)

	self.horizontalScale = __canBeParam(tab.horizontalScale)
	self.verticalScale = __canBeParam(tab.verticalScale)
	self.scale = __canBeParam(tab.scale)

	self.layer = __canBeParam(tab.layer)
	self.group = __canBeParam(tab.group)

	self.rot = __canBeParam(tab.rot)
	self.rotSpd = __canBeParam(tab.rotSpd)
	self.lockRot = __canBeParam(tab.lockRot)

	self.collision = __canBeParam(tab.collision)
	self.blend, blendIsConst = __canBeParam(tab.blend)

	self.tracks = CurveLib.AsTracks(__default(tab.tracks, {}))

	self.blendIsDefault = blendIsConst and (self.blend() == "" or self.blend() == "mul+alpha")
end

function Style:Set(target, params)
	local image = self.image(target, params)
	--StyleLib.CacheImg(self.name, img)
	if image ~= nil then
		target.img = image
		target._a_base = target.a
		target._b_base = target.b
		target.hscale = 1
		target.vscale = 1
	end

	local scale = self.scale(target, params)
	if scale then
		target.hscale = scale
		target.vscale = scale
		target.a = scale * target._a_base
		target.b = scale * target._b_base
	else
		local hscale = self.horizontalScale(target, params)
		if hscale then
			target.hscale = hscale
			target.a = hscale * target._a_base
		end
		local vscale = self.verticalScale(target, params)
		if vscale then
			target.vscale = vscale
			target.b = vscale * target._b_base
		end
	end

	target.rot = __default(self.rot(target, params), target.rot)
	target.omiga = __default(self.rotSpd(target, params), target.omiga)
	target.lockRot = __default(self.lockRot(target, params), target.lockRot)

	target.layer = __default(self.layer(target, params), target.layer)
	target.group = __default(self.group(target, params), target.group)

	target.colli = __default(self.collision(target, params), target.colli)
	target._blend = __default(self.blend(target, params), target._blend)
	return CurveLib.DoTracks(target, self.tracks, params)
end

local StyleSheet = plus.Class()
StyleLib.StyleSheet = StyleSheet
function StyleSheet:init(tab)
	self.src = tab

	self.creation = Style(__default(tab.creation, {}))
	self.idle = Style(__default(tab.idle, {}))
	self.elimination = Style(__default(tab.elimination, {}))
	self.eliminationInCreation = Style(__default(tab.eliminationInCreation, __default(tab.elimination, {})))

	self.stayOnCreate = __canBeParam(__default(tab.stayOnCreate, false))
	self.eliminationMode = __canBeParam(__default(tab.eliminationMode, "Terminated"))
	self.eliminationInCreationMode = __canBeParam(__default(tab.eliminationInCreationMode, "Terminated"))
end

function StyleLib.DeriveFrom(source, derivation)
	return StyleSheet(StyleLib.DeriveFromTable(source.src, derivation))
end

BulletSP = Class(object)
function BulletSP:init()
	self.styleState = STATE_INIT
	self.tracks = {}
	self.trackParams = {}

	self.motions = {}
	self.sortedMotions = {}

	self.group = GROUP_ENEMY_BULLET
	self.layer = LAYER_ENEMY_BULLET
end

function BulletSP:SetStyleSheet(styleSheet, params)
	if not self.styleState then error("样式表系统目标错误") end
	self.styleSheet = styleSheet
	self.styleSheetParams = __default(params, {})
end

function BulletSP:Begin()
	if self.styleSheet.stayOnCreate(self, self.styleSheetParams) then
		BulletSP.SetCreate(self)
	else
		BulletSP.SetCreateAndIdle(self)
	end
end

function BulletSP:SetTracks(tracks, params)
	if self.trackCoroutine then error("已经设置曲线") end
	self.tracks = tracks
	self.trackParams = __default(params, {})
end

function BulletSP:SetCreate()
	--Print("create")
	self.styleState = STATE_INIT
	self.styleCoroutine = self.styleSheet.creation:Set(self, self.styleSheetParams)
end

function BulletSP:SetCreateAndIdle()
	--Print("create & idle")
	self.styleState = STATE_INIT_AND_DEFAULT
	self.styleCoroutine = self.styleSheet.creation:Set(self, self.styleSheetParams)
	self.trackCoroutine = CurveLib.DoTracks(self, self.tracks, self.trackParams)
end

function BulletSP:SetIdle()
	--Print("idle")
	self.styleState = STATE_IDLE
	self.styleCoroutine = self.styleSheet.idle:Set(self, self.styleSheetParams)
	self.trackCoroutine = CurveLib.DoTracks(self, self.tracks, self.trackParams)
end

function BulletSP:SetIdleFromCreateAndIdle()
	--Print("idle")
	self.styleState = STATE_IDLE
	self.styleCoroutine = self.styleSheet.idle:Set(self, self.styleSheetParams)
end

function BulletSP:SetEliminationFor(mode, style)
	if mode == "Terminated" then
		local eff = New(BulletSP)
		eff.x = self.x
		eff.y = self.y
		eff.styleState = STATE_ELIM
		eff.styleSheetParams = self.styleSheetParams
		BulletSP.SetEliminationFor(eff, "Keep", style)
	elseif mode == "Pass" then
		local eff = New(BulletSP)
		eff.x = self.x
		eff.y = self.y
		eff.vx = self.dx
		eff.vy = self.dy
		eff.styleState = STATE_ELIM
		eff.styleSheetParams = self.styleSheetParams
		BulletSP.SetEliminationFor(eff, "Keep", style)
	elseif mode == "Keep" then
		self.styleState = STATE_ELIM
		PreserveObject(self)
		self.styleCoroutine = style:Set(self, self.styleSheetParams)
	end
end

function BulletSP:SetElimination()
	--Print("elimination")
	local mode = self.styleSheet.eliminationMode(self, self.styleSheetParams)
	BulletSP.SetEliminationFor(self, mode, self.styleSheet.elimination)
end

function BulletSP:SetEliminationInCreation()
	--Print("eliminationInCreation")
	local mode = self.styleSheet.eliminationInCreationMode(self, self.styleSheetParams)
	BulletSP.SetEliminationFor(self, mode, self.styleSheet.eliminationInCreation)
end

function BulletSP:frame()
	if self.styleCoroutine then
		for _, v in ipairs(self.styleCoroutine) do
			if coroutine.status(v) ~= 'dead' then
				local _, errmsg = coroutine.resume(v)
                if errmsg then
                    error(tostring(errmsg) .. "\n========== coroutine traceback ==========\n" .. debug.traceback(v)
						.. "\n========== C traceback ==========")
                end
			end
		end
	end
	if self.trackCoroutine then
		for _, v in ipairs(self.trackCoroutine) do
			if coroutine.status(v) ~= 'dead' then
				local _, errmsg = coroutine.resume(v)
                if errmsg then
                    error(tostring(errmsg) .. "\n========== coroutine traceback ==========\n" .. debug.traceback(v)
						.. "\n========== C traceback ==========")
                end
			end
		end
	end

	if self.styleState == STATE_INIT or self.styleState == STATE_INIT_AND_DEFAULT then
		for _, v in ipairs(self.sortedMotions) do
			v.frame(self)
		end
	end

	if self._blend then
		self._a = self._a or 255
		self._r = self._r or 255
		self._g = self._g or 255
		self._b = self._b or 255
	end

	if self.styleState == STATE_INIT then
		if CurveLib.IsFinished(self.styleCoroutine) then BulletSP.SetIdle(self) end
	elseif self.styleState == STATE_INIT_AND_DEFAULT then
		if CurveLib.IsFinished(self.styleCoroutine) then BulletSP.SetIdleFromCreateAndIdle(self) end
	elseif self.styleState == STATE_ELIM then
		if CurveLib.IsFinished(self.styleCoroutine) then Del(self) end
	end
end

function BulletSP:del()
	BulletSP.remove(self)
end

function BulletSP:kill()
	BulletSP.remove(self)
    New(item_faith_minor, self.x, self.y)
end

function BulletSP:remove()
	if self.styleState == STATE_IDLE then
		BulletSP.SetElimination(self)
	elseif self.styleState == STATE_INIT or self.styleState == STATE_INIT_AND_DEFAULT then
		BulletSP.SetEliminationInCreation(self)
	elseif self.styleState == STATE_ELIM then
		--PreserveObject(self)
	end
end

function BulletSP:render()
    if self._blend and self._a and self._r and self._g and self._b then
        SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    end
    DefaultRenderFunc(self)
    if self._blend and self._a and self._r and self._g and self._b then
        SetImgState(self, '', 255, 255, 255, 255)
    end
end

function BulletSP.Create(tracks, style, motionList, trackParam, styleParam)
	local b = New(BulletSP)
	BulletSP.SetStyleSheet(b, style, styleParam)
	BulletSP.SetTracks(b, tracks, trackParam)
	BulletSP.Begin(b)
	return b
end

function BulletSP.CreateXY(x, y, tracks, style, motionList, trackParam, styleParam)
	local b = BulletSP.Create(tracks, style, motionList, trackParam, styleParam)
	b.x = x
	b.y = y
	return b
end