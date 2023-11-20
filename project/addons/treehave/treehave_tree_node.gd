@tool
class_name TreehaveTreeNode
extends GraphNode


var parent: TreehaveTreeNode
var scene_node: BeehaveNode
var children: Array[TreehaveTreeNode] = []

var _decorators: Array[Decorator] = []


func _init(beehave_node: BeehaveNode):
	var parent_node: BeehaveNode = beehave_node.get_parent()

	while parent_node is Decorator:
		_decorators.append(parent_node)
		parent_node = parent_node.get_parent()

	title = beehave_node.name
	scene_node = beehave_node
	print("%s with %s decorators" % [scene_node.name, _decorators.size()])


func select() -> void:
	selected = true
