@tool
@icon("res://icon.svg")
class_name TestAction extends ActionLeaf

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	return SUCCESS
