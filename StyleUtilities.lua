local StyleSheet = StyleLib.StyleSheet
function StyleSheet:DeriveBy(tab)
	return StyleLib.DeriveFrom(self, tab)
end

function StyleSheet:WithLayer(layer)
	return self:DeriveBy({
		idle = {
			layer = layer
		}
	})
end

function StyleSheet:WithFixedRotation(rotation)
	return self:DeriveBy({
		idle = {
			rot = rotation,
			lockRot = true
		}
	})
end

function StyleSheet:WithRotationSpeed(rotSpd)
	return self:DeriveBy({
		idle = {
			rotSpd = rotSpd,
			lockRot = true
		}
	})
end

function StyleSheet:RemoveCreation()
	return self:DeriveBy({
		creation = {
			__remove = true
		}
	})
end

function StyleSheet:EliminationAsIfInCreation()
	return self:DeriveBy({
		eliminationInCreation = self.src.elimination
	})
end

function BulletSP.CreateXY(x, y, tracks, style, motionList, trackParam, styleParam)
	local b = BulletSP.Create(tracks, style, motionList, trackParam, styleParam)
	b.x = x
	b.y = y
	return b
end

function BulletSP.CreateXYRV(x, y, r, v, style, motionList, styleParam)
	local b = BulletSP.Create(CurveLib.builtIn.Uniform, style, motionList, { r = r, v = v }, styleParam)
	b.x = x
	b.y = y
	return b
end