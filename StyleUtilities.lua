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