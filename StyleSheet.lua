StyleLib = {}
local StyleLib = StyleLib

local __canBeParam = FunctionalWrappers.canBeParam
local __default = FunctionalWrappers.default

local STATE_IDLE = 0
local STATE_INIT = 1
local STATE_INIT_AND_DEFAULT = 2
local STATE_ELIM = 3

local CACHE_NONE = 0
local CACHE_IMAGE = 1
local CACHE_IMAGE_AND_BLEND = 2

local EMPTY = {}

local ReturnArray = CurveLib.ReturnArray

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
	self.image, self.imgIsConst = __canBeParam(tab.image)
	self.noImageCaching = __canBeParam(tab.noImageCaching)

	self.horizontalScale = __canBeParam(tab.horizontalScale)
	self.verticalScale = __canBeParam(tab.verticalScale)
	self.scale = __canBeParam(tab.scale)

	self.layer = __canBeParam(tab.layer)
	self.group = __canBeParam(tab.group)

	self.rot = __canBeParam(tab.rot)
	self.rotSpd = __canBeParam(tab.rotSpd)
	self.lockRot = __canBeParam(tab.lockRot)

	self.collision = __canBeParam(tab.collision)

	local blendIsConst, redConst, greenConst, blueConst, alphaConst
	self.blend, blendIsConst = __canBeParam(tab.blend)
	self.noBlendCaching = __canBeParam(tab.noBlendCaching)
	self.red, redConst = __canBeParam(tab.red)
	self.green, greenConst = __canBeParam(tab.green)
	self.blue, blueConst = __canBeParam(tab.blue)
	self.alpha, alphaConst = __canBeParam(tab.alpha)

	self.tracks = CurveLib.AsTracks(__default(tab.tracks, {}))

	self.immutableBlend = blendIsConst and redConst and greenConst and blueConst and alphaConst
	if self.immutableBlend then
		for _, v in ipairs(self.tracks) do
			if v.mapperName == "SetColorForBlend" then
				self.immutableBlend = false
				break
			end
		end
	end
end

function Style:BuildCacheOf(image, target, params)
	--[[
	if self.imgIsConst and not self.noImageCaching then
		local cacheName = string.format('%s_cache_%X', image, self)
		if not ImageList[cacheName] then
			CopyImage(cacheName, image)
			if self.immutableBlend and not self.noBlendCaching then
				SetImageState(cacheName, self.blend(target, params), Color(self.alpha(), self.red(), self.green(), self.blue()))
				target.imageCache = CACHE_IMAGE_AND_BLEND
			else
				target._blend = __default(self.blend(target, params), target._blend)
				target._a = __default(self.alpha(target, params), target._a)
				target._r = __default(self.red(target, params), target._r)
				target._g = __default(self.green(target, params), target._g)
				target._b = __default(self.blue(target, params), target._b)
				target.imageCache = CACHE_IMAGE
			end
		end
		return cacheName
	else
		target.imageCache = CACHE_NONE
	end
	]]
end

function Style:Set(target, params)
	local image = self.image(target, params)

	if image ~= nil then
		target.originalImage = image
		image = self:BuildCacheOf(image, target, params) or image
		target.img = image
		target._a_base = target.a
		target._b_base = target.b
		target.hscale = 1
		target.vscale = 1
	end

	target._blend = __default(self.blend(target, params), nil)
	local c = nil
	if target._blend then c = 255 end
	target._a = __default(self.alpha(target, params), c)
	target._r = __default(self.red(target, params), c)
	target._g = __default(self.green(target, params), c)
	target._b = __default(self.blue(target, params), c)

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

	return CurveLib.BeginTracks(target, self.tracks, params)
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

function BulletSP:CollectStyleArr()
	for _, v in ipairs(self.styleArr) do
		ReturnArray(v)
	end
end

function BulletSP:SetStyleSheet(styleSheet, params)
	if not self.styleState then error("Style sheet system set target failed: invalid target.") end
	self.styleSheet = styleSheet
	self.styleSheetParams = __default(params, EMPTY)
end

function BulletSP:SetCreate()
	--Print("create")
	self.styleState = STATE_INIT
	self.styleCoroutine, self.styleArr = self.styleSheet.creation:Set(self, self.styleSheetParams)
end

function BulletSP:SetCreateAndIdle()
	--Print("create & idle")
	self.styleState = STATE_INIT_AND_DEFAULT
	self.styleCoroutine, self.styleArr = self.styleSheet.creation:Set(self, self.styleSheetParams)
	if self.stateMachine then self.stateMachine:begin() end
end

function BulletSP:SetIdle()
	--Print("idle")
	self.styleState = STATE_IDLE
	BulletSP.CollectStyleArr(self)
	self.styleCoroutine, self.styleArr = self.styleSheet.idle:Set(self, self.styleSheetParams)
	if self.stateMachine then self.stateMachine:begin() end
end

function BulletSP:SetIdleFromCreateAndIdle()
	--Print("idle")
	self.styleState = STATE_IDLE
	BulletSP.CollectStyleArr(self)
	self.styleCoroutine, self.styleArr = self.styleSheet.idle:Set(self, self.styleSheetParams)
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
		eff.vx = self.vx
		eff.vy = self.vy
		eff.styleState = STATE_ELIM
		eff.styleSheetParams = self.styleSheetParams
		BulletSP.SetEliminationFor(eff, "Keep", style)
	elseif mode == "Keep" then
		self.styleState = STATE_ELIM
		PreserveObject(self)
		self.styleCoroutine, self.styleArr = style:Set(self, self.styleSheetParams)
	end
end

function BulletSP:SetElimination()
	--Print("elimination")
	BulletSP.CollectStyleArr(self)
	local mode = self.styleSheet.eliminationMode(self, self.styleSheetParams)
	BulletSP.SetEliminationFor(self, mode, self.styleSheet.elimination)
end

function BulletSP:SetEliminationInCreation()
	--Print("eliminationInCreation")
	BulletSP.CollectStyleArr(self)
	local mode = self.styleSheet.eliminationInCreationMode(self, self.styleSheetParams)
	BulletSP.SetEliminationFor(self, mode, self.styleSheet.eliminationInCreation)
end

function BulletSP:Begin()
	if self.styleSheet.stayOnCreate(self, self.styleSheetParams) then
		BulletSP.SetCreate(self)
	else
		BulletSP.SetCreateAndIdle(self)
	end
end

function BulletSP:SetStateMachine(states, params)
	if self.stateMachine then error("State machine has already set.") end
	self.stateMachine = CurveLib.StateMachine(self, states, __default(params, EMPTY))
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
	if self.stateMachine then self.stateMachine:proceed() end

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
	if self.stateMachine then self.stateMachine:Collect() end
	BulletSP.remove(self)
end

function BulletSP:kill()
	if self.stateMachine then self.stateMachine:Collect() end
	BulletSP.remove(self)
    New(item_faith_minor, self.x, self.y)
end

function BulletSP:render()
    if self.imageCache == CACHE_NONE or self.imageCache == CACHE_IMAGE or not self.imageCache then
		if self._blend and self._a and self._r and self._g and self._b then
        	SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
		end
    end
    DefaultRenderFunc(self)
    if self.imageCache == CACHE_NONE or self.imageCache == CACHE_IMAGE or not self.imageCache then
		if self._blend and self._a and self._r and self._g and self._b then
			SetImgState(self, '', 255, 255, 255, 255)
		end
    end
end

function BulletSP.Create(states, style, motionList, stateParam, styleParam)
	local b = New(BulletSP)
	BulletSP.SetStyleSheet(b, style, styleParam)
	BulletSP.SetStateMachine(b, states, stateParam)
	BulletSP.Begin(b)
	return b
end