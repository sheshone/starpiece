class_name ResourceUI
extends Control

var last_message := ""
var toast_alpha: float = 0.0


func _ready() -> void:
	theme = AssetCatalog.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.message_posted.connect(_on_message)


func _on_message(text: String) -> void:
	last_message = text
	toast_alpha = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(self, "toast_alpha", 0.0, 0.5)
	tween.tween_callback(queue_redraw)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if toast_alpha > 0.01 and not last_message.is_empty():
		var toast_rect := Rect2(14, 790, 372, 58)
		var bg := Color(0.035, 0.055, 0.08, 0.78 * toast_alpha)
		draw_rect(toast_rect, bg)
		draw_rect(toast_rect, Color(0.62, 0.75, 0.86, 0.34 * toast_alpha), false, 1.0)
		var text_color := Color.WHITE
		text_color.a = toast_alpha
		draw_string(font, Vector2(24, 826), last_message,
			HORIZONTAL_ALIGNMENT_CENTER, 352, 18, text_color)

	if not GameManager.is_game_running and GameManager.current_round > 0:
		var result := "星球表面完成！" if GameManager.core_hp > 0 else "核心已被摧毁"
		draw_rect(Rect2(430, 410, 580, 120), Color("11141af2"))
		draw_string(font, Vector2(540, 480), result,
			HORIZONTAL_ALIGNMENT_CENTER, 360, 30, Color("f0d174"))
