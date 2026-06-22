class_name HandUI
extends Control

signal shop_card_hovered(card: CardBase, global_rect: Rect2)
signal shop_card_unhovered

var shop_nodes: Array[Control] = []
var shop_controls: Array[Control] = []


func _ready() -> void:
	theme = AssetCatalog.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardManager.shop_changed.connect(_show_shop)
	ResourceManager.resources_changed.connect(_refresh_controls)
	GameManager.state_changed.connect(_refresh_controls)
	TurnManager.phase_changed.connect(_on_phase_changed)
	_show_shop(CardManager.shop_slots)


func _show_shop(slots: Array) -> void:
	for node in shop_nodes:
		if is_instance_valid(node):
			node.queue_free()
	shop_nodes.clear()
	for node in shop_controls:
		if is_instance_valid(node):
			node.queue_free()
	shop_controls.clear()
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		return
	var scene: PackedScene = load("res://scenes/ui/card_display.tscn")
	var card_positions := [
		Vector2(1500, 70),
		Vector2(1300, 235),
		Vector2(1235, 430),
		Vector2(1300, 625),
		Vector2(1500, 790),
	]
	for i in range(CardManager.SHOP_SIZE):
		if i < slots.size() and slots[i] != null:
			var card_ui := scene.instantiate() as CardUI
			card_ui.card_data = slots[i] as CardBase
			card_ui.choice_index = i
			card_ui.card_chosen.connect(_purchase)
			card_ui.card_hovered.connect(_on_card_hovered)
			card_ui.card_unhovered.connect(_on_card_unhovered)
			card_ui.position = card_positions[i]
			add_child(card_ui)
			shop_nodes.append(card_ui)
		else:
			var active_index := -1
			var active_card: TerrainCard = null
			if GameManager.scene_root:
				active_index = int(GameManager.scene_root.get("active_tile_shop_index"))
				active_card = GameManager.scene_root.get("active_tile_card") as TerrainCard
			if i == active_index and active_card:
				var ghost := scene.instantiate() as CardUI
				ghost.card_data = active_card
				ghost.choice_index = -1
				ghost.position = card_positions[i]
				ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ghost.modulate = Color(0.52, 0.56, 0.62, 0.42)
				add_child(ghost)
				shop_nodes.append(ghost)
				continue
			var empty := Control.new()
			empty.position = card_positions[i]
			empty.size = Vector2(150, 125)
			empty.tooltip_text = "该商店位置的地块已购买"
			var empty_art := TextureRect.new()
			empty_art.texture = AssetCatalog.texture("shop_slot_empty")
			empty_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			empty_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			empty_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			empty.add_child(empty_art)
			add_child(empty)
			shop_nodes.append(empty)
	_build_shop_controls(Vector2(1490, 244), Vector2(1490, 632))


func _purchase(index: int) -> void:
	if GameManager.scene_root:
		GameManager.scene_root.purchase_shop_card(index)


func _build_shop_controls(refresh_position: Vector2, migrate_position: Vector2) -> void:
	var controls := Control.new()
	controls.position = Vector2.ZERO
	controls.size = Vector2(1680, 1000)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)
	shop_controls.append(controls)
	var refresh := Button.new()
	var free_count := int(GameManager.scene_root.free_refreshes) if GameManager.scene_root else 0
	refresh.text = "免费刷新 ×%d" % free_count
	refresh.tooltip_text = refresh.text
	refresh.position = refresh_position
	refresh.size = Vector2(184, 184)
	refresh.custom_minimum_size = Vector2(184, 184)
	refresh.mouse_filter = Control.MOUSE_FILTER_STOP
	refresh.set_meta("persistent_icon_outline", true)
	refresh.disabled = free_count <= 0 or TurnManager.current_phase != TurnManager.Phase.BUILD
	refresh.pressed.connect(func() -> void:
		if GameManager.scene_root:
			GameManager.scene_root.refresh_shop()
	)
	AssetCatalog.apply_button_visual(refresh, "icon_refresh", true, true)
	controls.add_child(refresh)
	var migrate := Button.new()
	migrate.text = "布置神祇"
	migrate.tooltip_text = "布置／迁移神祇"
	migrate.position = migrate_position
	migrate.size = Vector2(184, 184)
	migrate.custom_minimum_size = Vector2(184, 184)
	migrate.mouse_filter = Control.MOUSE_FILTER_STOP
	migrate.set_meta("persistent_icon_outline", true)
	migrate.disabled = TurnManager.current_phase != TurnManager.Phase.BUILD
	migrate.pressed.connect(func() -> void:
		if GameManager.scene_root and GameManager.scene_root.has_method("begin_deity_migration_selection"):
			GameManager.scene_root.call("begin_deity_migration_selection")
	)
	AssetCatalog.apply_button_visual(
		migrate,
		"icon_move" if AssetCatalog.texture("icon_move") else "icon_remove",
		true,
		true
	)
	controls.add_child(migrate)


func _refresh_controls(_value: Variant = null) -> void:
	_show_shop(CardManager.shop_slots)


func _on_card_hovered(_index: int, card: CardBase, global_rect: Rect2) -> void:
	shop_card_hovered.emit(card, global_rect)


func _on_card_unhovered(_index: int) -> void:
	shop_card_unhovered.emit()


func _on_phase_changed(phase: TurnManager.Phase) -> void:
	_show_shop(CardManager.shop_slots if phase == TurnManager.Phase.BUILD else [])
