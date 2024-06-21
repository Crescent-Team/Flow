--!strict
export type FlowVariable<T> = {
	value: T,
}

export type FlowRoot = FlowVariable<any> & {
	type: "Root",
	dependents: { FlowNode },
	dependentsLength: number,
}

export type FlowNode = FlowVariable<any> & {
	type: "Node",
	roots: { [FlowRoot]: boolean },
	updaterSession: number,
	recompute: () -> any,
}

export type SharedContext = {
	CurrentNode: FlowNode?,
	CurrentSession: number,
}

export type SafeSharedContext = SharedContext & { CurrentNode: FlowNode }

export type Dependency = FlowNode | FlowRoot
export type Dependent = FlowNode

local SharedContext: SharedContext = { CurrentNode = nil, CurrentSession = 0 }

local function add_dependency(dependency: Dependency, dependent: Dependent)
	if dependency.type == "Root" then
		table.insert(dependency.dependents, dependent)
		dependency.dependentsLength += 1
		dependent.roots[dependency] = true
	else
		for root in dependency.roots do
			table.insert(root.dependents, dependent)
			root.dependentsLength += 1
			dependent.roots[root] = true
		end
	end
end

local function evaluate(SharedContext: SafeSharedContext)
	local Node, CurrentSession = SharedContext.CurrentNode, SharedContext.CurrentSession

	Node.roots = {}
	local value = Node.recompute()
	Node.updaterSession = CurrentSession

	if value ~= Node.value then
		Node.value = value
		return true
	end

	return false
end

local function evaluate_this_node(Node: FlowNode)
	local past = SharedContext.CurrentNode
	SharedContext.CurrentNode = Node
	evaluate(SharedContext :: SafeSharedContext)
	SharedContext.CurrentNode = past
end

local function has_been_evaluated(dependency: FlowNode)
	if SharedContext.CurrentSession == dependency.updaterSession then
		return true
	end
	return false
end

local function use(dependency: Dependency)
	if dependency.type == "Node" and has_been_evaluated(dependency) == false then
		evaluate_this_node(dependency)
	end

	add_dependency(dependency, SharedContext.CurrentNode :: any)
	return dependency.value
end

local function update_root(Root: FlowRoot)
	local dependents = Root.dependents
	local length = Root.dependentsLength

	Root.dependents = {}
	Root.dependentsLength = 0
	local _ = #Root.dependents
	SharedContext.CurrentSession += 1

	for index = length, 1, -1 do
		local Node = dependents[index]

		if has_been_evaluated(Node) then
			continue
		end

		evaluate_this_node(Node)
	end
end

local Runtime = {
	add_dependency = add_dependency,
	use = use,
	update_root = update_root,
	has_been_evaluated = has_been_evaluated,
	evaluate = evaluate,
	evaluate_this_node = evaluate_this_node,

	SharedContext = SharedContext,
}

return Runtime
