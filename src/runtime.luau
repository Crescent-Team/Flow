--!strict

export type FlowVariable<T> = {
	value: T,
}

export type FlowRoot = FlowVariable<any> & {
    type: "Root",
	dependents: { FlowNode },
}

export type FlowNode = FlowVariable<any> & {
	type: "Node",
    roots: { FlowRoot },
	updaterSession: number,
	recompute: () -> any,
}

export type SharedContext = {
	CurrentNode: FlowNode?,
	CurrentSession: number,
}

export type Dependency = FlowNode | FlowRoot
export type Dependent = FlowNode
local SharedContext: SharedContext = { CurrentNode = nil, CurrentSession = 0 }

local function add_dependency(dependency: Dependency, dependent: Dependent)
	if dependency.type == "Root" then
		table.insert(dependency.dependents, dependent)
	else 
		for _, root in dependency.roots do
			table.insert(root.dependents, dependent)
		end
	end
end 

local Runtime = {
	add_dependency = add_dependency,
	evaluate_flow_node = evaluate_flow_node,
	evaluate_flow_node_with = evaluate_flow_node_with,
	use = use, 
	update_flow_root = update_flow_root,

	SharedContext = SharedContext
}

return Runtime