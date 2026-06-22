class_name UnitInstance
extends Resource

@export var unit_id: String = "militia"
@export var hp: int = 1
@export var acted: bool = false
@export var emergency_used: bool = false

static func create(id: String) -> UnitInstance:
	var result := UnitInstance.new()
	result.unit_id = id
	result.hp = int(GameDefinitions.UNIT_DEFS[id]["max_hp"])
	return result

func definition() -> Dictionary:
	return GameDefinitions.UNIT_DEFS.get(unit_id, {})

func display_name() -> String:
	return str(definition().get("name", unit_id))

func is_special() -> bool:
	return unit_id in ["hunter", "craftsman", "veteran"]

