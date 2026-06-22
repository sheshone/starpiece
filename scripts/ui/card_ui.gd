class_name CardUI
extends Control

signal card_chosen(index: int)
signal card_hovered(index: int, card: CardBase, global_rect: Rect2)
signal card_unhovered(index: int)

var card_data: CardBase
var choice_index: int = -1
var hovered: bool = false
var hover_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(150, 125)
	size = Vector2(150, 125)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		AudioManager.play_sfx("button_hover", -8.0)
		hovered = true
		z_index = 40
		_animate_hover(Vector2(1.13, 1.13), -10.0)
		card_hovered.emit(choice_index, card_data, get_global_rect())
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		hovered = false
		z_index = 0
		_animate_hover(Vector2.ONE, 0.0)
		card_unhovered.emit(choice_index)
		queue_redraw()
	)
	queue_redraw()


func _animate_hover(target_scale: Vector2, target_rotation_degrees: float) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_parallel(true)
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale", target_scale, 0.16)
	# 仅使用极轻微倾斜，避免卡牌放大后仍显得僵硬。
	hover_tween.tween_property(self, "rotation_degrees", target_rotation_degrees * 0.08, 0.16)


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and card_data
	):
		card_chosen.emit(choice_index)
		accept_event()


func _draw() -> void:
	if not card_data:
		return
	var background := Color("66717d")
	if card_data is TerrainCard:
		background = (card_data as TerrainCard).color
	var rect := Rect2(Vector2.ZERO, size)
	# 卡框原图的透明安全区为 x=20..280、y=30..230；当前显示尺寸为原图的一半。
	var art_rect := Rect2(10, 15, 130, 100)
	draw_rect(art_rect, background.darkened(0.2))
	if card_data is TerrainCard:
		var terrain_card := card_data as TerrainCard
		var art_key := AssetCatalog.card_art_texture_key(terrain_card.terrain_type)
		var card_art := AssetCatalog.texture(art_key)
		if not card_art:
			card_art = AssetCatalog.texture(AssetCatalog.terrain_texture_key(terrain_card.terrain_type))
		if card_art:
			draw_texture_rect(card_art, art_rect, false)
	var frame := AssetCatalog.texture("card_frame_terrain")
	if frame:
		if hovered:
			var glow_color := Color(0.45, 0.9, 1.0, 0.22)
			for offset in [
				Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2),
				Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1),
			]:
				draw_texture_rect(frame, Rect2(offset, size), false, glow_color)
		draw_texture_rect(frame, rect, false)
	if card_data is TerrainCard:
		_draw_shape_placeholder((card_data as TerrainCard).shape, Vector2(31, 105))
	var power_icon := AssetCatalog.texture("icon_divine_power")
	if power_icon:
		_draw_power_cost(power_icon, card_data.divine_power_cost)
	if hovered:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(8, 14),
			card_data.card_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			134,
			13,
			Color(0.08, 0.055, 0.035, 0.96)
		)


func _draw_power_cost(power_icon: Texture2D, cost: float) -> void:
	var full_count := floori(cost)
	var has_half := not is_zero_approx(cost - float(full_count))
	var icon_size := 21.0
	var spacing := -1.0
	var total_icons := full_count + (1 if has_half else 0)
	var total_width := float(total_icons) * icon_size + float(maxi(0, total_icons - 1)) * spacing
	var start_x := 141.0 - total_width
	for index in range(full_count):
		var icon_rect := Rect2(start_x + float(index) * (icon_size + spacing), 97, icon_size, icon_size)
		draw_rect(icon_rect.grow(1.0), Color(0.08, 0.045, 0.025, 0.72))
		draw_texture_rect(
			power_icon,
			icon_rect,
			false
		)
	if has_half:
		var half_x := start_x + float(full_count) * (icon_size + spacing)
		var source_size := power_icon.get_size()
		draw_texture_rect_region(
			power_icon,
			Rect2(half_x, 97, icon_size * 0.5, icon_size),
			Rect2(0, 0, source_size.x * 0.5, source_size.y)
		)


func _draw_shape_placeholder(shape: Array[Vector2i], center: Vector2) -> void:
	if shape.is_empty():
		return
	var min_x := shape[0].x
	var min_y := shape[0].y
	var max_x := shape[0].x
	var max_y := shape[0].y
	for cell in shape:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	var cell_size := 9.0
	var total_size := Vector2(max_x - min_x + 1, max_y - min_y + 1) * cell_size
	var origin := center - total_size * 0.5
	for cell in shape:
		var local := Vector2(cell.x - min_x, cell.y - min_y) * cell_size
		var shape_rect := Rect2(origin + local, Vector2(cell_size - 1, cell_size - 1))
		draw_rect(shape_rect.grow(1.0), Color(0.08, 0.045, 0.025, 0.86))
		draw_rect(shape_rect, Color("f7e09b"))
