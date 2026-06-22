class_name MenuAmbient
extends Control

var elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var viewport := get_viewport_rect().size
	for index in range(13):
		var seed := float(index * 41)
		var x := 22.0 + fposmod(seed * 7.7, viewport.x * 0.23)
		var y := viewport.y * 0.25 + fposmod(seed * 11.3 + elapsed * (8.0 + index), viewport.y * 0.5)
		var drop := Vector2(x, y)
		draw_circle(drop, 2.0 + fmod(seed, 3.0), Color(0.45, 0.78, 1.0, 0.12))
		draw_line(drop, drop + Vector2(-2, 8), Color(0.55, 0.86, 1.0, 0.12), 1.2)
	var corners: Array[Vector2] = [Vector2(40, 35), Vector2(viewport.x - 40, 35)]
	for corner in corners:
		for index in range(8):
			var side := 1.0 if corner.x < viewport.x * 0.5 else -1.0
			var sway := sin(elapsed * 0.7 + index) * 4.0
			var center := corner + Vector2(side * index * 18.0, index * 8.0 + sway)
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(-7, 0),
					center + Vector2(0, -4),
					center + Vector2(8, 1),
					center + Vector2(0, 5),
				]),
				Color(0.35, 0.62, 0.28, 0.16)
			)
	for index in range(9):
		var x := fposmod(elapsed * (18.0 + index) + index * 190.0, viewport.x + 160.0) - 80.0
		var y := viewport.y - 55.0 - float(index % 3) * 18.0
		draw_line(Vector2(x, y), Vector2(x + 80, y - 8), Color(0.75, 0.9, 0.82, 0.09), 2.0)
	var sun_center := Vector2(viewport.x * 0.5, -40)
	for index in range(7):
		var angle := (
			lerpf(0.25, PI - 0.25, float(index) / 6.0)
			+ elapsed * 0.12
		)
		var end := sun_center + Vector2.from_angle(angle) * (240.0 + index * 16.0)
		draw_line(sun_center, end, Color(1.0, 0.85, 0.42, 0.055), 28.0)
