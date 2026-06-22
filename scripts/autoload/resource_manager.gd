extends Node

signal resources_changed

var divine_power: float = 0.0


func reset() -> void:
	divine_power = (
		float(GameDefinitions.BALANCE.attack_deity_cost)
		+ float(GameDefinitions.BALANCE.resource_deity_cost)
		+ float(GameDefinitions.BALANCE.terrain_card_cost_by_size.get(1, 1.0))
		+ float(GameDefinitions.BALANCE.starting_reserve_after_opening)
	)
	if ProgressManager.current_map == 2:
		divine_power += ProgressManager.blessing_value("initial_resource")
	resources_changed.emit()


func can_afford(cost: float) -> bool:
	return divine_power + 0.001 >= cost


func spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	divine_power -= cost
	resources_changed.emit()
	return true


func add_divine_power(amount: float) -> void:
	divine_power += amount
	resources_changed.emit()
