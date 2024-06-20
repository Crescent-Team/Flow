local runtime = require("runtime")
local testkit = require("../.lune/ecrtestkit")
local TEST, CASE, CHECK, FINISH = testkit.test()

local add_dependency, use, update_root, has_been_evaluated, evaluate_this_node, SharedContext =
	runtime.add_dependency,
	runtime.use,
	runtime.update_root,
	runtime.has_been_evaluated,
	runtime.evaluate_this_node,
	runtime.SharedContext

TEST("Runtime::add_dependency", function()
	do
		CASE("should link between root and node")
		local root = {
			value = nil,
			type = "Root",
			dependents = {},
		}
		local node = {
			type = "Node",
			value = nil,
			roots = {},
			updaterSession = 0,
			recompute = nil,
		}

		add_dependency(root, node)
		CHECK(root.dependents[1] == node)
		CHECK(node.roots[1] == root)
	end

	do
		CASE("should link between Nodes and Nodes")
		local root = {
			value = nil,
			type = "Root",
			dependents = {},
		}
		local node = {
			type = "Node",
			value = nil,
			roots = {},
			updaterSession = 0,
			recompute = nil,
		}

		local innerNode = {
			type = "Node",
			value = nil,
			roots = {},
			updaterSession = 0,
			recompute = nil,
		}

		add_dependency(root, node)
		add_dependency(node, innerNode)
		CHECK(root.dependents[2] == innerNode)
		CHECK(innerNode.roots[1] == root)
	end
end)

TEST("Runtime::evaluate_this_node", function()
	do
		CASE("should evaluate the node")
		local flag = false
		local function recompute()
			flag = true
		end

		local node = {
			type = "Node",
			value = nil,
			roots = {},
			updaterSession = 0,
			recompute = recompute,
		}

		local oldRoots = node.roots
		SharedContext.CurrentSession += 1
		evaluate_this_node(node)

		CHECK(flag == true)
		CHECK(node.roots ~= oldRoots)
		CHECK(node.updaterSession == SharedContext.CurrentSession)
	end
end)

TEST("Runtime::has_been_evaluated", function()
	do
		CASE("should determine whether the instance has been evaluated in this session")
		local node = {
			type = "Node",
			value = nil,
			roots = {},
			updaterSession = 0,
			recompute = function()
				return nil
			end,
		}

		SharedContext.CurrentSession += 1

		CHECK(has_been_evaluated(node) == false)
		evaluate_this_node(node)
		CHECK(has_been_evaluated(node) == true)
	end
end)

TEST("Runtime::update_node", function()
	do
		CASE("should work with use")
		local root = {
			value = nil,
			type = "Root",
			dependents = {},
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

		update_root(root)
		CHECK(root.dependents[2] == innerNode)
		CHECK(innerNode.roots[1] == root)
		CHECK(root.dependents[1] == node)
		CHECK(node.roots[1] == root)
	end
end)
FINISH()
