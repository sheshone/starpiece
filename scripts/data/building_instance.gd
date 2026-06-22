class_name BuildingInstance
extends Resource

@export var building_id: String = "farm"
@export var hp: int = 1
@export var population_granted: bool = false

static func create(id: String) -> BuildingInstance:
	var result := BuildingInstance.new()
	result.building_id = id
	result.hp = int(GameDefinitions.BUILDING_DEFS[id]["max_hp"])
	return result

func definition() -> Dictionary:
	return GameDefinitions.BUILDING_DEFS.get(building_id, {})

func display_name() -> String:
	return str(definition().get("name", building_id))

