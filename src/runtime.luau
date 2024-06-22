--!strict
export type PotokVariable<T> = {
	value: T,
}

export type PotokRoot = PotokVariable<any> & {
	type: "Root",
	dependents: { PotokNode },
	dependentsLength: number,
}

export type PotokNode = PotokVariable<any> & {
	type: "Node",
	roots: { [PotokRoot]: boolean },
	updaterSession: number,
	recompute: () -> any,
}

export type SharedContext = {
	CurrentNode: PotokNode?,
	CurrentSession: number,
}

export type SafeSharedContext = SharedContext & { CurrentNode: PotokNode }

export type Dependency = PotokNode | PotokRoot
export type Dependent = PotokNode

local SharedContext: SharedContext = { CurrentNode = nil, CurrentSession = 0 }

local function _add_dependency_root(dependency: PotokRoot, dependent: Dependent)
	table.insert(dependency.dependents, dependent)
	dependency.dependentsLength += 1
	dependent.roots[dependency] = true
end

local function add_dependency(dependency: Dependency, dependent: Dependent)
	if dependency.type == "Root" then
		_add_dependency_root(dependency, dependent)
	else
		for root in dependency.roots do
			_add_dependency_root(root, dependent)
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

local function evaluate_this_node(Node: PotokNode)
	local past = SharedContext.CurrentNode
	SharedContext.CurrentNode = Node
	evaluate(SharedContext :: SafeSharedContext)
	SharedContext.CurrentNode = past
end

local function has_been_evaluated(dependency: PotokNode)
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

local function update_root(Root: PotokRoot)
	local dependents = Root.dependents
	local length = Root.dependentsLength

	Root.dependents = {}
	Root.dependentsLength = 0
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
