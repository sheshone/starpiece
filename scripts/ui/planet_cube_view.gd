class_name PlanetCubeView
extends Control

var yaw: float = -0.62
var pitch: float = -0.48
var dragging: bool = false
var last_mouse: Vector2 = Vector2.ZERO
var snapshots: Array = []

const FACE_DEFINITIONS := [
	{"origin": Vector3(-1, -1, 1), "u": Vector3(2, 0, 0), "v": Vector3(0, 2, 0)},
	{"origin": Vector3(1, -1, -1), "u": Vector3(-2, 0, 0), "v": Vector3(0, 2, 0)},
	{"origin": Vector3(1, -1, 1), "u": Vector3(0, 0, -2), "v": Vector3(0, 2, 0)},
	{"origin": Vector3(-1, -1, -1), "u": Vector3(0, 0, 2), "v": Vector3(0, 2, 0)},
	{"origin": Vector3(-1, 1, 1), "u": Vector3(2, 0, 0), "v": Vector3(0, 0, -2)},
	{"origin": Vector3(-1, -1, -1), "u": Vector3(2, 0, 0), "v": Vector3(0, 0, 2)},
]


func _ready() -> void:
	custom_minimum_size = Vector2(360, 270)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_snapshots([])


func _process(delta: float) -> void:
	if not dragging:
		yaw += delta * 0.11
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_button := event as InputEventMouseButton
		dragging = mouse_button.pressed
		last_mouse = mouse_button.position
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		var mouse_motion := event as InputEventMouseMotion
		var motion: Vector2 = mouse_motion.position - last_mouse
		last_mouse = mouse_motion.position
		yaw += motion.x * 0.012
		pitch = clampf(pitch + motion.y * 0.009, -1.05, 0.35)
		queue_redraw()
		accept_event()


func set_snapshots(face_data: Array) -> void:
	snapshots.clear()
	for index in range(1, ProgressManager.MAX_MAPS + 1):
		var snapshot: Array = (
			face_data[index - 1]
			if index - 1 < face_data.size() and face_data[index - 1] is Array
			else []
		)
		snapshots.append(snapshot)
	queue_redraw()


func _draw() -> void:
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var visible_faces: Array[Dictionary] = []
	for index in range(FACE_DEFINITIONS.size()):
		var definition: Dictionary = FACE_DEFINITIONS[index]
		var raw_u: Vector3 = definition.u
		var raw_v: Vector3 = definition.v
		var raw_origin: Vector3 = definition.origin
		var u: Vector3 = basis * raw_u
		var v: Vector3 = basis * raw_v
		var normal := u.cross(v).normalized()
		if normal.z <= 0.03:
			continue
		var origin: Vector3 = basis * raw_origin
		var center := origin + u * 0.5 + v * 0.5
		visible_faces.append({
			"index": index,
			"origin": origin,
			"u": u,
			"v": v,
			"depth": center.z,
		})
	visible_faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.depth) < float(b.depth)
	)
	for face in visible_faces:
		_draw_face(face)


func _draw_face(face: Dictionary) -> void:
	var face_index := int(face.index)
	var origin: Vector3 = face.origin
	var u: Vector3 = face.u
	var v: Vector3 = face.v
	var snapshot: Array = snapshots[face_index] if face_index < snapshots.size() else []
	for y in range(11):
		for x in range(11):
			var p00 := origin + u * (float(x) / 11.0) + v * (float(y) / 11.0)
			var p10 := origin + u * (float(x + 1) / 11.0) + v * (float(y) / 11.0)
			var p11 := origin + u * (float(x + 1) / 11.0) + v * (float(y + 1) / 11.0)
			var p01 := origin + u * (float(x) / 11.0) + v * (float(y + 1) / 11.0)
			var terrain := GameDefinitions.TerrainType.NONE
			var cell_index := y * 11 + x
			if snapshot.size() == 121:
				terrain = int(snapshot[cell_index])
			var polygon := PackedVector2Array([
				_project(p00), _project(p10), _project(p11), _project(p01),
			])
			var is_center := x == 5 and y == 5 and snapshot.size() == 121
			var terrain_texture := AssetCatalog.texture(
				AssetCatalog.terrain_texture_key(terrain)
			)
			if not terrain_texture:
				terrain_texture = AssetCatalog.texture("terrain_void")
			var texture := terrain_texture
			if is_center:
				draw_colored_polygon(polygon, Color(0.92, 0.04, 0.08, 1.0))
				texture = AssetCatalog.texture("core")
			if texture:
				var texture_size := texture.get_size()
				draw_colored_polygon(
					polygon,
					Color(1.0, 0.32, 0.34, 0.96)
					if is_center
					else Color.WHITE,
					PackedVector2Array([
						Vector2.ZERO,
						Vector2(texture_size.x, 0),
						texture_size,
						Vector2(0, texture_size.y),
					]),
					texture
				)
	var corners := PackedVector2Array([
		_project(origin),
		_project(origin + u),
		_project(origin + u + v),
		_project(origin + v),
		_project(origin),
	])
	draw_polyline(corners, Color(0.92, 0.78, 0.38, 0.9), 2.2, true)


func _project(point: Vector3) -> Vector2:
	var camera_distance := 4.4
	var perspective := 1.0 / maxf(1.8, camera_distance - point.z)
	var scale_factor := minf(size.x, size.y) * 1.42
	return size * 0.5 + Vector2(point.x, -point.y) * scale_factor * perspective
