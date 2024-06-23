local bencher = require("bencher")
local runtime = require("src/runtime")
local add_dependency, use, update_root, has_been_evaluated, evaluate_this_node, SharedContext =
	runtime.add_dependency,
runtime.use,
runtime.update_root,
runtime.has_been_evaluated,
runtime.evaluate_this_node,
runtime.SharedContext

local root = {
	value = nil,
	type = "Root",
	dependents = {},
    dependentsLength = 0
}
local node = {
	type = "Node",
	value = nil,
	roots = {},
	updaterSession = 0,
	recompute = function()
		return use(root)
	end,
}

local innerNode = {
	type = "Node",
	value = nil,
	roots = {},
	updaterSession = 0,
	recompute = function()
		return use(node)
	end,
}

evaluate_this_node(node)
evaluate_this_node(innerNode)

local _, info = bencher.benchmark(20_000, update_root, root)

print(info)