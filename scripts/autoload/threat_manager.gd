extends Node

signal threat_changed

var values: Array[int] = [0, 0, 0, 0]


func reset() -> void:
	values = [0, 0, 0, 0]
	threat_changed.emit()


func add(direction: int, amount: int) -> void:
	values[direction] += amount
	threat_changed.emit()


func add_passive_threat() -> void:
	for i in range(values.size()):
		values[i] += 1
	threat_changed.emit()


func consume_spawns(direction: int) -> int:
	var count: int = floori(values[direction] / 3.0)
	values[direction] %= 3
	if count > 0:
		threat_changed.emit()
	return count
