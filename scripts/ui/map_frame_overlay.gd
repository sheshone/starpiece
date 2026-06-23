class_name MapFrameOverlay
extends Control

var elapsed: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var texture := _animation_frame()
	if not texture:
		texture = AssetCatalog.texture("map_frame")
	if texture:
		# 原图内部安全区约为 50..950。映射后恰好包住 903×903 的地图。
		draw_texture_rect(texture, Rect2(360, 12, 1003, 1003), false)


func _animation_frame() -> Texture2D:
	var frames := AssetCatalog.animation("map_frame")
	if not frames:
		return null
	var animation_name := &"idle"
	if not frames.has_animation(animation_name):
		return null
	var count := frames.get_frame_count(animation_name)
	if count <= 0:
		return null
	var fps := maxf(1.0, frames.get_animation_speed(animation_name))
	return frames.get_frame_texture(animation_name, int(elapsed * fps) % count)
