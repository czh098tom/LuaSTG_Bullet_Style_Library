FunctionalWrappers = {}

--- convert parameters into functions that return value
--- function -> function
--- string begin without '@' '$' : keep
--- string begin with '$' : read parameter of name from parameter list
--- string begin with double '$' : string begin with 1 fewer '$'
--- string begin with '@' : read parameter of name from target object
--- string begin with double '@' : string begin with 1 fewer '@'
function FunctionalWrappers.canBeParam(v)
	if type(v) == "function" then
		return v, false
	elseif type(v) == "string" then
		local l = string.len(v)
		if l > 0 then
			local first = string.sub(v, 1, 1)
			if first == '$' then
				if l > 1 then
					local vs = string.sub(v, 2)
					if string.sub(v, 2, 2) == '$' then 
						return function(self, param) return vs end, true
					else
						local vs = string.sub(v, 2)
						return function(self, param) return param[vs] end, false
					end
				else
					error("Unable to resolve parameter expression: unnamed parameter")
				end
			elseif first == '@' then
				if l > 1 then
					local vs = string.sub(v, 2)
					if string.sub(v, 2, 2) == '@' then 
						return function(self, param) return vs end, true
					else
						local vs = string.sub(v, 2)
						return function(self, param) return self[vs] end, false
					end
				else
					error("Unable to resolve parameter expression: unnamed parameter")
				end
			end
		else
			return function(self, param) return vs end, true
		end
	end
	local vv = v
	return function(self, param) return vv end, true
end

function FunctionalWrappers.default(a, default)
	if a ~= nil then
		return a
	else
		return default
	end
end

Include 'THlib\\StyleLib\\Curve.lua'
Include 'THlib\\StyleLib\\StyleSheet.lua'
Include 'THlib\\StyleLib\\MotionModule.lua'
Include 'THlib\\StyleLib\\CurveUtilities.lua'
Include 'THlib\\StyleLib\\StyleUtilities.lua'
Include 'THlib\\StyleLib\\BuiltInStyleSheet.lua'