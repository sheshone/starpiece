extends Node

signal tutorial_requested(step: Dictionary)
signal tutorial_cleared

const TutorialDefinitionsScript := preload("res://scripts/data/tutorial_definitions.gd")
const TUTORIAL_VERSION_PREFIX := "guide_v7:"

var active_step: Dictionary = {}
var pending_steps: Array[Dictionary] = []


func trigger(trigger_name: String, payload: Dictionary = {}) -> bool:
	if trigger_name.is_empty():
		return false
	for step in TutorialDefinitionsScript.STEPS:
		if str(step.get("trigger", "")) != trigger_name:
			continue
		if not _matches_current_context(step, payload):
			continue
		var id := TUTORIAL_VERSION_PREFIX + str(step.get("id", ""))
		if id.is_empty():
			continue
		if bool(step.get("once", true)) and ProgressManager.has_seen_tutorial(id):
			continue
		if bool(step.get("once", true)):
			ProgressManager.mark_tutorial_seen(id)
		var prepared := step.duplicate(true)
		prepared["payload"] = payload.duplicate(true)
		if payload.has("tutorial_text"):
			prepared["text"] = str(payload.get("tutorial_text", prepared.get("text", "")))
		if active_step.is_empty():
			_activate(prepared)
		elif bool(active_step.get("non_blocking", false)) or not bool(active_step.get("pause", false)):
			_activate(prepared)
		else:
			pending_steps.append(prepared)
		return true
	return false


func clear() -> void:
	active_step.clear()
	pending_steps.clear()
	tutorial_cleared.emit()


func complete_active() -> void:
	active_step.clear()
	tutorial_cleared.emit()
	if not pending_steps.is_empty():
		call_deferred("_activate_next")


func reset_seen_for_testing() -> void:
	ProgressManager.reset_tutorial_seen()


func _activate(step: Dictionary) -> void:
	active_step = step
	tutorial_requested.emit(active_step)


func _activate_next() -> void:
	if not active_step.is_empty() or pending_steps.is_empty():
		return
	_activate(pending_steps.pop_front())


func _matches_current_context(step: Dictionary, payload: Dictionary) -> bool:
	if step.has("map") and int(step.get("map", -1)) != ProgressManager.current_map:
		return false
	if step.has("terrain") and int(payload.get("terrain", -1)) != int(step.get("terrain", -2)):
		return false
	if step.has("deity_type") and int(payload.get("deity_type", -1)) != int(step.get("deity_type", -2)):
		return false
	return true
