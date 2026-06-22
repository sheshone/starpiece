extends SceneTree

const DEFINITIONS := [
	{
		"output": "res://assets/animations/deities/attack/deity_attack_plain_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/attack/deity_attack_plain_idle_", 7.0, true],
			"attack": ["res://assets/art/deities/attack/deity_attack_plain_attack_", 12.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/attack/deity_attack_forest_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/attack/deity_attack_forest_idle_", 7.0, true],
			"attack": ["res://assets/art/deities/attack/deity_attack_forest_attack_", 12.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/attack/deity_attack_mountain_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/attack/deity_attack_mountain_idle_", 7.0, true],
			"attack": ["res://assets/art/deities/attack/deity_attack_mountain_attack_", 12.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/attack/deity_attack_river_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/attack/deity_attack_river_idle_", 7.0, true],
			"attack": ["res://assets/art/deities/attack/deity_attack_river_attack_", 12.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/resource/deity_resource_plain_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/resource/deity_resource_plain_idle_", 7.0, true],
			"produce": ["res://assets/art/deities/resource/deity_resource_plain_produce_", 10.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/resource/deity_resource_forest_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/resource/deity_resource_forest_idle_", 7.0, true],
			"produce": ["res://assets/art/deities/resource/deity_resource_forest_produce_", 10.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/resource/deity_resource_mountain_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/resource/deity_resource_mountain_idle_", 7.0, true],
			"produce": ["res://assets/art/deities/resource/deity_resource_mountain_produce_", 10.0, false],
		},
	},
	{
		"output": "res://assets/animations/deities/resource/deity_resource_river_frames.tres",
		"animations": {
			"idle": ["res://assets/art/deities/resource/deity_resource_river_idle_", 7.0, true],
			"produce": ["res://assets/art/deities/resource/deity_resource_river_produce_", 10.0, false],
		},
	},
	{
		"output": "res://assets/animations/enemies/enemy_default_frames.tres",
		"animations": {
			"move": ["res://assets/art/enemies/enemy_move_", 10.0, true],
			"attack": ["res://assets/art/enemies/enemy_attack_", 12.0, false],
		},
	},
]


func _initialize() -> void:
	for definition in DEFINITIONS:
		_build_resource(definition)
	quit()


func _build_resource(definition: Dictionary) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation_name in definition.animations:
		var settings: Array = definition.animations[animation_name]
		var textures := _load_sequence(str(settings[0]))
		if textures.is_empty():
			continue
		var name := StringName(animation_name)
		frames.add_animation(name)
		frames.set_animation_speed(name, float(settings[1]))
		frames.set_animation_loop(name, bool(settings[2]))
		for texture in textures:
			frames.add_frame(name, texture)
	if frames.get_animation_names().is_empty():
		print("SKIP ", definition.output)
		return
	var error := ResourceSaver.save(frames, str(definition.output))
	if error != OK:
		push_error("Unable to save %s: %s" % [definition.output, error])
	else:
		print("BUILT ", definition.output)


func _load_sequence(prefix: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for index in range(100):
		var path := "%s%02d.png" % [prefix, index]
		if not ResourceLoader.exists(path):
			break
		var texture := load(path) as Texture2D
		if texture:
			textures.append(texture)
	return textures
