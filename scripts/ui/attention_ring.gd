class_name AttentionRing
extends Control

var elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var pulse := (sin(elapsed * 4.2) + 1.0) * 0.5
	draw_circle(center, minf(size.x, size.y) * (0.46 + pulse * 0.04), Color(1.0, 0.8, 0.25, 0.055 + pulse * 0.055))
	draw_arc(
		center,
		minf(size.x, size.y) * (0.43 + pulse * 0.025),
		0.0,
		TAU,
		64,
		Color(1.0, 0.86, 0.4, 0.45 + pulse * 0.35),
		2.4
	)
