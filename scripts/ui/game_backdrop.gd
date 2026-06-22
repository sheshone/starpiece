class_name GameBackdrop
extends Control

const TILE_SIZE := 180.0
const TERRAIN_KEYS := [
	"terrain_plain",
	"terrain_forest",
	"terrain_mountain",
	"terrain_river",
]
var elapsed: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("101820"))
	var background_texture := _animation_frame("game_background")
	if not background_texture:
		background_texture = AssetCatalog.texture("game_background")
	if background_texture:
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, viewport_size), false)
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.03, 0.06, 0.08, 0.28))
	else:
		_draw_terrain_fallback(viewport_size)

	_draw_background_particles(viewport_size)


func _draw_background_particles(viewport_size: Vector2) -> void:
	for index in range(34):
		var seed := float(index * 97)
		var x := fposmod(seed * 13.7 + elapsed * (3.0 + fmod(seed, 5.0)), viewport_size.x)
		var y := fposmod(seed * 7.3 + sin(elapsed * 0.22 + seed) * 28.0, viewport_size.y)
		var radius := 1.5 + fmod(seed, 3.0) * 0.75
		var alpha := 0.1 + 0.1 * (sin(elapsed * 0.8 + seed) + 1.0) * 0.5
		draw_circle(Vector2(x, y), radius, Color(0.55, 0.82, 1.0, alpha))


func _draw_terrain_fallback(viewport_size: Vector2) -> void:
	var columns := ceili(viewport_size.x / TILE_SIZE) + 1
	var rows := ceili(viewport_size.y / TILE_SIZE) + 1
	for y in range(rows):
		for x in range(columns):
			var key: String = TERRAIN_KEYS[(x + y * 3) % TERRAIN_KEYS.size()]
			var texture := AssetCatalog.texture(key)
			if not texture:
				continue
			var rect := Rect2(
				Vector2(x, y) * TILE_SIZE,
				Vector2.ONE * TILE_SIZE
			)
			var tint := Color(0.58, 0.68, 0.72, 0.09 if (x + y) % 2 == 0 else 0.055)
			draw_texture_rect(texture, rect, false, tint)
	# 让中央地图保持清楚，边缘保留地形纹理作为装饰。
	draw_rect(
		Rect2(Vector2(137, 46), Vector2(970, 920)),
		Color(0.03, 0.055, 0.075, 0.48)
	)


func _animation_frame(key: String) -> Texture2D:
	var frames := AssetCatalog.animation(key)
	if not frames:
		return null
	var animation_name := &"idle"
	if not frames.has_animation(animation_name):
		animation_name = &"default"
	if not frames.has_animation(animation_name):
		return null
	var count := frames.get_frame_count(animation_name)
	if count <= 0:
		return null
	var fps := maxf(1.0, frames.get_animation_speed(animation_name))
	return frames.get_frame_texture(animation_name, int(elapsed * fps) % count)
