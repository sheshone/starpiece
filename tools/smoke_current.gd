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
	map.get_cell(source).enemy = EnemyData.create(1)
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
