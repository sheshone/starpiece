extends SceneTree

const Definitions := preload("res://scripts/data/game_definitions.gd")
const DeityData := preload("res://scripts/data/deity_instance.gd")
const EnemyData := preload("res://scripts/data/enemy_instance.gd")


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("SMOKE FAILED: %s" % message)
	quit(1)


func _run() -> void:
	var packed := load("res://scenes/game.tscn") as PackedScene
	if not packed:
		_fail("cannot load main scene")
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.call("_start_new_game")
	await process_frame
	var card_manager := root.get_node("/root/CardManager")
	var turn_manager := root.get_node("/root/TurnManager")
	var resource_manager := root.get_node("/root/ResourceManager")
	if card_manager.shop_slots.size() != card_manager.SHOP_SIZE:
		_fail("shop did not create five cards")
		return
	if int(turn_manager.current_phase) != 0:
		_fail("new game did not enter build phase")
		return
	var hand := game.get_node("UICanvas/HandUI")
	var card_clickable := false
	for child in hand.get_children():
		var script: Script = child.get_script() as Script
		if (
			script
			and script.resource_path == "res://scripts/ui/card_ui.gd"
			and child.mouse_filter == Control.MOUSE_FILTER_STOP
		):
			card_clickable = true
			break
	if not card_clickable:
		_fail("shop cards are not clickable")
		return
	var game_ui := game.get_node("UICanvas/GameUI")
	if game_ui.start_button.disabled:
		_fail("time flow button is disabled during build phase")
		return
	for control in hand.shop_controls:
		if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_fail("shop control layer blocks card or time-flow input")
			return
	var map := game.get_node("GameMap")
	if not is_equal_approx(float(map.domain_area_multiplier(10)), 1.0):
		_fail("domain area still changes ordinary attributes")
		return
	if str(Definitions.REWORKED_DEITY_FORM_NAMES[Definitions.TerrainType.PLAIN][Definitions.DeityType.ATTACK]) != "疾野神":
		_fail("reworked deity names are not active")
		return
	if str(Definitions.REWORKED_DEITY_FORM_NAMES[Definitions.TerrainType.MOUNTAIN][Definitions.DeityType.RESOURCE]) != "泞滞神":
		_fail("mountain support deity name is not active")
		return
	if str(Definitions.REWORKED_DEITY_FORM_NAMES[Definitions.TerrainType.RIVER][Definitions.DeityType.ATTACK]) != "澜沧神":
		_fail("river attack deity name is not active")
		return
	if not bool(map.call("_can_relocate_enemy_to", Vector2i(1, 1))):
		_fail("enemy cannot walk through chaos cells")
		return
	if not bool(map.call("_can_relocate_enemy_to", Vector2i(1, 1), true)):
		_fail("legacy placed-terrain flag still rejects chaos cells")
		return
	if not bool(map.call("_can_relocate_enemy_to", Vector2i(1, 1), false, true)):
		_fail("chaos cell is not accepted as a river bank")
		return
	map.get_cell(Vector2i(1, 1)).terrain = Definitions.TerrainType.RIVER
	if bool(map.call("_can_relocate_enemy_to", Vector2i(1, 1), false, true)):
		_fail("river cell is incorrectly accepted as its own bank")
		return
	map.get_cell(Vector2i(1, 1)).terrain = Definitions.TerrainType.NONE
	var stack_pos := Vector2i(1, 1)
	var stack_enemy_a := EnemyData.create(1)
	var stack_enemy_b := EnemyData.create(1)
	map.call("_add_enemy_to_cell", stack_pos, stack_enemy_a)
	map.call("_add_enemy_to_cell", stack_pos, stack_enemy_b)
	if (map.call("_enemies_at", stack_pos) as Array).size() != 2:
		_fail("enemies cannot stack in one cell")
		return
	map.call("_remove_enemy_from_cell", stack_pos, stack_enemy_a)
	map.call("_remove_enemy_from_cell", stack_pos, stack_enemy_b)
	var bounce_origin := Vector2i(3, 3)
	var bounce_enemy := EnemyData.create(1)
	map.call("_add_enemy_to_cell", bounce_origin, bounce_enemy)
	map.get_cell(bounce_origin + Vector2i.RIGHT).terrain = Definitions.TerrainType.MOUNTAIN
	var bounced := Vector2i(map.call(
		"_forced_move_with_bounce",
		bounce_origin,
		Vector2i.RIGHT,
		bounce_enemy,
		"knockback"
	))
	if bounced == bounce_origin or bounced == bounce_origin + Vector2i.RIGHT:
		_fail("forced movement did not bounce away from a hard obstacle")
		return
	map.call("_remove_enemy_from_cell", bounced, bounce_enemy)
	map.get_cell(bounce_origin + Vector2i.RIGHT).terrain = Definitions.TerrainType.NONE
	if (
		float(Definitions.BALANCE.terrain_path_cost[Definitions.TerrainType.PLAIN]) != 1.0
		or float(Definitions.BALANCE.terrain_path_cost[Definitions.TerrainType.RIVER]) != 1.0
		or float(Definitions.BALANCE.terrain_path_cost[Definitions.TerrainType.FOREST]) != 1.0
	):
		_fail("non-mountain terrain still has weighted path cost")
		return
	var source: Vector2i = Vector2i(map.core_pos) + Vector2i.RIGHT
	var target: Vector2i = source + Vector2i.RIGHT
	for pos in [source, target]:
		var cell: Variant = map.get_cell(pos)
		cell.terrain = Definitions.TerrainType.PLAIN
		cell.piece_id = 999
	var deity := DeityData.create(Definitions.DeityType.ATTACK)
	deity.level = 2
	deity.hp = 5
	deity.attack_count = 3
	map.get_cell(source).deity = deity
	resource_manager.add_divine_power(20.0)
	if not map.begin_deity_migration(source):
		_fail("migration could not begin")
		return
	if not map.migrate_deity(target):
		_fail("migration could not finish")
		return
	if map.get_cell(target).deity != deity:
		_fail("migration did not preserve deity instance")
		return
	if deity.level != 2 or deity.hp != 5 or deity.attack_count != 3:
		_fail("migration did not preserve state")
		return
	var power_before_remove := float(resource_manager.divine_power)
	if not map.remove_deity(target):
		_fail("deity removal could not finish")
		return
	if map.get_cell(target).deity != null:
		_fail("deity removal left the deity on the map")
		return
	if not is_equal_approx(
		float(resource_manager.divine_power),
		power_before_remove - float(Definitions.BALANCE.deity_removal_cost)
	):
		_fail("deity removal charged the wrong cost")
		return
	map.get_cell(source).enemy = EnemyData.create(1)
	map.get_cell(source).enemy.hp = 10
	map.get_cell(source).enemy.max_hp = 10
	map.call("_damage_enemy", source, 4, target, Color.WHITE, "deity_plain")
	if int(map.get_cell(source).enemy.hp) >= 6:
		_fail("plain exposure did not increase incoming damage")
		return
	if bool(game.call("can_end_combat")):
		_fail("combat can end while an enemy remains")
		return
	map.get_cell(source).enemy = null
	map.pending_spawn_core = Vector2i(-1, -1)
	if not bool(game.call("can_end_combat")):
		_fail("combat cannot end after the field is clear")
		return
	print("SMOKE OK")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
