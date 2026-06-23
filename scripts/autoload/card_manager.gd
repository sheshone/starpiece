extends Node

signal shop_changed(slots: Array)

const SHOP_SIZE: int = 5

var shop_slots: Array = []


func reset() -> void:
	shop_slots.clear()
	shop_changed.emit(shop_slots)


func begin_build_phase() -> void:
	refresh_shop()


func refresh_shop() -> bool:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		return false
	shop_slots.clear()
	if ProgressManager.current_map == 0:
		shop_slots.append(_generate_prologue_card())
		while shop_slots.size() < SHOP_SIZE:
			shop_slots.append(null)
		shop_changed.emit(shop_slots)
		return true
	for _i in range(SHOP_SIZE):
		shop_slots.append(_generate_terrain_card())
	shop_changed.emit(shop_slots)
	return true


func purchase_shop_card(index: int) -> TerrainCard:
	if (
		TurnManager.current_phase != TurnManager.Phase.BUILD
		or index < 0
		or index >= shop_slots.size()
		or shop_slots[index] == null
	):
		return null
	var card := shop_slots[index] as TerrainCard
	if not ResourceManager.spend(card.divine_power_cost):
		return null
	shop_slots[index] = null
	shop_changed.emit(shop_slots)
	return card


func return_shop_card(index: int, card: TerrainCard) -> bool:
	if not card or index < 0 or index >= SHOP_SIZE:
		return false
	while shop_slots.size() < SHOP_SIZE:
		shop_slots.append(null)
	if shop_slots[index] != null:
		return false
	shop_slots[index] = card
	shop_changed.emit(shop_slots)
	return true


func _generate_terrain_card() -> TerrainCard:
	var shape_index := _weighted_shape_index()
	var available_terrains := _available_terrains_for_current_map()
	var terrain: int = int(available_terrains[
		GameManager.rng.randi_range(0, available_terrains.size() - 1)
	])
	var card := TerrainCard.new()
	card.shape.assign(PieceShapeConfig.SHAPES[shape_index])
	card.terrain_type = terrain
	card.card_name = "%s·%s" % [
		GameDefinitions.TERRAIN_NAMES[terrain],
		PieceShapeConfig.SHAPE_NAMES[shape_index],
	]
	var terrain_costs: Dictionary = GameDefinitions.BALANCE.terrain_card_cost_by_size
	card.divine_power_cost = float(terrain_costs.get(card.shape.size(), 1.0))
	card.description = ""
	card.color = GameDefinitions.TERRAIN_COLORS[terrain]
	return card


func _generate_prologue_card() -> TerrainCard:
	var card := TerrainCard.new()
	card.shape.assign(PieceShapeConfig.SHAPES[0])
	card.terrain_type = CardBase.TerrainType.PLAIN
	card.card_name = "平原·单格"
	card.divine_power_cost = float(GameDefinitions.BALANCE.terrain_card_cost_by_size.get(1, 1.0))
	card.description = ""
	card.color = GameDefinitions.TERRAIN_COLORS[GameDefinitions.TerrainType.PLAIN]
	return card


func _available_terrains_for_current_map() -> Array[int]:
	if ProgressManager.current_map <= 1:
		return [GameDefinitions.TerrainType.PLAIN]
	if ProgressManager.current_map == 2:
		return [GameDefinitions.TerrainType.PLAIN, GameDefinitions.TerrainType.MOUNTAIN]
	if ProgressManager.current_map == 3:
		return [
			GameDefinitions.TerrainType.PLAIN,
			GameDefinitions.TerrainType.MOUNTAIN,
			GameDefinitions.TerrainType.RIVER,
		]
	return [
		GameDefinitions.TerrainType.PLAIN,
		GameDefinitions.TerrainType.MOUNTAIN,
		GameDefinitions.TerrainType.RIVER,
		GameDefinitions.TerrainType.FOREST,
	]


func _weighted_shape_index() -> int:
	var weights: Array = PieceShapeConfig.SHAPE_WEIGHTS
	var total_weight: int = 0
	for weight in weights:
		total_weight += int(weight)
	var roll: int = GameManager.rng.randi_range(1, total_weight)
	var cumulative: int = 0
	for i in range(weights.size()):
		cumulative += int(weights[i])
		if roll <= cumulative:
			return i
	return weights.size() - 1
