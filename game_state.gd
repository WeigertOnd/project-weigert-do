extends Node

var highest_unlocked_level = 1
var max_selectable_level = 22
var result_freeze_time = 1.5
var result_success_text = "Souhlas byl přijatý."
var result_fail_text = "Souhlas nebyl přijatý."


func reset_level_progress():
	highest_unlocked_level = 1


func unlock_next_level(completed_level: int):
	highest_unlocked_level = clamp(max(highest_unlocked_level, completed_level + 1), 1, max_selectable_level)


func is_level_unlocked(level_number: int) -> bool:
	return level_number <= highest_unlocked_level


func get_system_control_text():
	return ""
