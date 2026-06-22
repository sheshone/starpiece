class_name AnimatedAssetRect
extends TextureRect

var asset_key: String = ""
var preferred_animation: StringName = &"idle"
var elapsed: float = 0.0
var pulse_speed: float = 4.2


func configure(key: String, animation_name: StringName = &"idle") -> void:
	asset_key = key
	preferred_animation = animation_name
	texture = AssetCatalog.texture(key)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	elapsed += delta
	var frames := AssetCatalog.animation(asset_key)
	if frames:
		var animation_name := preferred_animation
		if not frames.has_animation(animation_name):
			animation_name = &"default"
		if frames.has_animation(animation_name):
			var count := frames.get_frame_count(animation_name)
			if count > 0:
				var fps := maxf(1.0, frames.get_animation_speed(animation_name))
				var frame_index := int(elapsed * fps) % count
				texture = frames.get_frame_texture(animation_name, frame_index)
	var wave := sin(elapsed * pulse_speed)
	scale = Vector2.ONE
	var brightness := 1.0 + maxf(0.0, wave) * 0.18
	self_modulate = Color(brightness, brightness, brightness, 1.0)
