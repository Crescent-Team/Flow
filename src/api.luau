local runtime = require("runtime")
local _add_dependency, _use, update_root, _has_been_evaluated, evaluate_this_node, _SharedContext =
	runtime.add_dependency,
	runtime.use,
	runtime.update_root,
	runtime.has_been_evaluated,
	runtime.evaluate_this_node,
	runtime.SharedContext

export type Reader<T> = () -> T
export type Writer<T> = (T) -> ()
export type ReaderWriter<T> = Reader<T> & Writer<T>

local GET_POTOK_INSTANCE = {}

local function source<T>(value: T): ReaderWriter<T>
	local self = {
		type = "Root",
		value = value,
		dependents = {},
	}

	return function(value: T?)
		if value == nil then
			return self.value
		end

		if value == GET_POTOK_INSTANCE then
			return self :: any
		end
		self.value = value
		update_root(self)
		return nil :: any
	end
end

local function computed<T>(processor: () -> T): Reader<T>
	local self = {
		value = nil,
		type = "Node",
		roots = {},
		updaterSession = 0,
		recompute = processor,
	}

	evaluate_this_node(self)

	return function(value: any)
		if value == GET_POTOK_INSTANCE then
			return self :: any
		end

		return self.value
	end
end

local function effect(runner)
	local self = {
		value = nil,
		type = "Node",
		roots = {},
		updaterSession = 0,
		recompute = runner,
	}

	evaluate_this_node(self)
end

local function use<T>(dependency: ReaderWriter<T>): T
	return _use(dependency(GET_POTOK_INSTANCE :: any))
end

return {
	use = use,
	effect = effect,
	computed = computed,
	source = source,
}
