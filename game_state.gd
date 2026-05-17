extends Node

signal system_control_changed(new_value)
signal system_control_maxed

var system_control = 0
var max_system_control = 100
var maxed_already_triggered = false
var highest_unlocked_level = 1
var max_selectable_level = 22


func reset_system_control():
	system_control = 0
	maxed_already_triggered = false
	system_control_changed.emit(system_control)


func add_system_control(amount):
	if maxed_already_triggered:
		return

	system_control += amount
	system_control = clamp(system_control, 0, max_system_control)
	system_control_changed.emit(system_control)

	if system_control >= max_system_control:
		maxed_already_triggered = true
		system_control_maxed.emit()


func reduce_system_control(amount):
	if maxed_already_triggered:
		return

	system_control -= amount
	system_control = clamp(system_control, 0, max_system_control)
	system_control_changed.emit(system_control)


func allow_system_control_again():
	maxed_already_triggered = false


func reset_level_progress():
	highest_unlocked_level = 1


func unlock_next_level(completed_level: int):
	highest_unlocked_level = clamp(max(highest_unlocked_level, completed_level + 1), 1, max_selectable_level)


func is_level_unlocked(level_number: int) -> bool:
	return level_number <= highest_unlocked_level


func get_system_control_text():
	return ""
