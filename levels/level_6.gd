extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var no_button = $NoButton

const BUTTON_SIZE = Vector2(164, 48)
const PLAY_MARGIN = 14.0
const FLOOR_PADDING = 8.0
const TARGET_OVERLAP = 0.42

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var play_area: Panel
var drop_zone: Panel
var instruction_label: Label
var result_label: Label
var control_label: Label
var drop_zone_label: Label

var left_button: Button
var catch_button: Button
var right_button: Button
var release_button: Button

var claw_hand: Node2D
var rope_line: Line2D
var claw_position = Vector2(300, 82)
var last_claw_position = Vector2(300, 82)
var claw_top_y = 82.0
var claw_width = 154.0
var claw_height = 92.0
var claw_min_x = 100.0
var claw_max_x = 700.0
var claw_move_speed = 280.0
var claw_step = 54.0
var claw_angle = 0.0
var claw_angle_velocity = 0.0
var rope_bend = 0.0
var rope_bend_velocity = 0.0

var moving_left = false
var moving_right = false
var claw_busy = false
var claw_open = true
var carrying_button = false
var waiting_for_click = false
var can_interact = true
var level_completed = false

var agree_buttons = []
var target_buttons = []
var button_states = {}
var released_buttons = []
var lifted_button: Button = null
var grab_candidate: Button = null

var mistakes = 0
var max_mistakes = 3
var gravity = 980.0
var bounce = 0.14
var floor_friction = 0.82


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	moving_left = false
	moving_right = false
	claw_busy = false
	claw_open = true
	carrying_button = false
	waiting_for_click = false
	can_interact = true
	level_completed = false
	lifted_button = null
	grab_candidate = null
	mistakes = 0
	claw_position = Vector2(300, claw_top_y)
	last_claw_position = claw_position
	claw_angle = 0.0
	claw_angle_velocity = 0.0
	rope_bend = 0.0
	rope_bend_velocity = 0.0

	setup_ui()
	clear_dynamic_buttons()

	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false

	no_button.visible = true
	no_button.disabled = false
	no_button.text = "Nesouhlasím"
	no_button.focus_mode = Control.FOCUS_NONE
	no_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_target_button(no_button, false)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	create_button_pile()
	create_claw()
	move_claw_to_x(play_area.position.x + play_area.size.x * 0.45)
	set_controls_for_state()
	update_instruction_label()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if can_interact and not claw_busy:
		if moving_left:
			move_claw_by(-claw_move_speed * delta)
		if moving_right:
			move_claw_by(claw_move_speed * delta)

	if not level_completed:
		simulate_button_physics(delta)

	simulate_claw_sway(delta)


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = 0

	if play_area == null or not is_instance_valid(play_area):
		play_area = Panel.new()
		play_area.name = "PlayArea"
		play_area.z_index = 1
		add_child(play_area)
	play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if drop_zone == null or not is_instance_valid(drop_zone):
		drop_zone = Panel.new()
		drop_zone.name = "DropZone"
		drop_zone.z_index = 1
		add_child(drop_zone)
	drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if drop_zone_label == null or not is_instance_valid(drop_zone_label):
		drop_zone_label = Label.new()
		drop_zone_label.name = "DropZoneLabel"
		drop_zone_label.text = "Klikací zóna"
		drop_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		drop_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		drop_zone_label.add_theme_font_size_override("font_size", 15)
		drop_zone_label.modulate = Color(0.12, 0.12, 0.12)
		drop_zone_label.z_index = 4
		add_child(drop_zone_label)

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 14)
		instruction_label.modulate = Color(0.16, 0.16, 0.16)
		instruction_label.z_index = 100
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 17)
		result_label.modulate = Color(0.15, 0.15, 0.15)
		result_label.z_index = 100
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 105
		add_child(control_label)

	if left_button == null or not is_instance_valid(left_button):
		left_button = Button.new()
		left_button.name = "LeftButton"
		left_button.text = "<"
		left_button.z_index = 110
		left_button.button_down.connect(_on_left_down)
		left_button.button_up.connect(_on_left_up)
		left_button.pressed.connect(_on_left_pressed)
		add_child(left_button)

	if catch_button == null or not is_instance_valid(catch_button):
		catch_button = Button.new()
		catch_button.name = "CatchButton"
		catch_button.text = "Chytit"
		catch_button.z_index = 110
		catch_button.pressed.connect(_on_catch_pressed)
		add_child(catch_button)

	if right_button == null or not is_instance_valid(right_button):
		right_button = Button.new()
		right_button.name = "RightButton"
		right_button.text = ">"
		right_button.z_index = 110
		right_button.button_down.connect(_on_right_down)
		right_button.button_up.connect(_on_right_up)
		right_button.pressed.connect(_on_right_pressed)
		add_child(right_button)

	if release_button == null or not is_instance_valid(release_button):
		release_button = Button.new()
		release_button.name = "ReleaseButton"
		release_button.text = "Pustit"
		release_button.z_index = 110
		release_button.pressed.connect(_on_release_pressed)
		add_child(release_button)

	style_area(play_area)
	style_area(drop_zone)
	style_control_button(left_button)
	style_control_button(catch_button)
	style_control_button(right_button)
	style_control_button(release_button)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	play_area.position = Vector2(16, 44)
	play_area.size = Vector2(window_size.x - 286, window_size.y - 142)

	drop_zone.position = Vector2(window_size.x - 250, 44)
	drop_zone.size = Vector2(234, window_size.y - 142)

	drop_zone_label.position = drop_zone.position + Vector2(18, 12)
	drop_zone_label.size = Vector2(drop_zone.size.x - 36, 28)

	instruction_label.position = Vector2(42, 8)
	instruction_label.size = Vector2(window_size.x - 84, 30)

	result_label.position = Vector2(60, window_size.y - 126)
	result_label.size = Vector2(window_size.x - 120, 34)

	var controls_y = window_size.y - 74
	left_button.size = Vector2(78, 46)
	catch_button.size = Vector2(128, 46)
	right_button.size = Vector2(78, 46)
	release_button.size = Vector2(142, 46)
	left_button.position = Vector2(window_size.x / 2 - 236, controls_y)
	catch_button.position = Vector2(window_size.x / 2 - 144, controls_y)
	right_button.position = Vector2(window_size.x / 2 - 2, controls_y)
	release_button.position = Vector2(window_size.x / 2 + 90, controls_y)

	update_claw_bounds()
	update_claw_visual()


func clear_dynamic_buttons():
	for btn in agree_buttons:
		if btn and is_instance_valid(btn):
			btn.queue_free()
	agree_buttons.clear()
	target_buttons.clear()
	button_states.clear()
	released_buttons.clear()


func create_button_pile():
	target_buttons.append(no_button)
	setup_physics_button(no_button, false, play_area.position + Vector2(305, 104), Vector2(0, 40), -5.0, 0.0, 18)

	var starts = [
		Vector2(122, 58),
		Vector2(212, 100),
		Vector2(76, 170),
		Vector2(268, 190),
		Vector2(168, 244)
	]

	for i in range(starts.size()):
		var btn = Button.new()
		btn.name = "AgreeButton" + str(i)
		btn.text = "Souhlasím"
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.pressed.connect(_on_target_pressed.bind(btn))
		style_target_button(btn, true)
		add_child(btn)
		agree_buttons.append(btn)
		target_buttons.append(btn)

		var velocity = Vector2(randf_range(-36.0, 36.0), randf_range(10.0, 86.0))
		var angle = [-10.0, 7.0, -6.0, 12.0, -4.0][i]
		var angular_velocity = randf_range(-42.0, 42.0)
		setup_physics_button(btn, true, play_area.position + starts[i], velocity, angle, angular_velocity, 24 + i)


func setup_physics_button(btn: Button, agree: bool, pos: Vector2, velocity: Vector2, angle: float, angular_velocity: float, z: int):
	btn.size = BUTTON_SIZE
	btn.pivot_offset = BUTTON_SIZE / 2.0
	btn.position = pos
	btn.rotation_degrees = angle
	btn.z_index = z
	btn.disabled = false
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_states[btn] = {
		"velocity": velocity,
		"angular_velocity": angular_velocity,
		"resting": false,
		"agree": agree
	}


func create_claw():
	if rope_line == null or not is_instance_valid(rope_line):
		rope_line = Line2D.new()
		rope_line.name = "RopeLine"
		rope_line.width = 7
		rope_line.default_color = Color(0.08, 0.22, 0.32)
		rope_line.z_index = 60
		add_child(rope_line)

	if claw_hand == null or not is_instance_valid(claw_hand):
		claw_hand = Node2D.new()
		claw_hand.name = "ClawHand"
		claw_hand.z_index = 70
		add_child(claw_hand)

		var palm = ColorRect.new()
		palm.name = "Palm"
		palm.size = Vector2(116, 38)
		palm.position = Vector2(-58, -4)
		palm.color = Color(0.06, 0.20, 0.34)
		claw_hand.add_child(palm)

		var left = ColorRect.new()
		left.name = "LeftFinger"
		left.size = Vector2(22, 62)
		left.position = Vector2(-84, 22)
		left.color = Color(0.06, 0.20, 0.34)
		claw_hand.add_child(left)

		var right = ColorRect.new()
		right.name = "RightFinger"
		right.size = Vector2(22, 62)
		right.position = Vector2(62, 22)
		right.color = Color(0.06, 0.20, 0.34)
		claw_hand.add_child(right)

	update_claw_visual()
	draw_claw_state()


func simulate_button_physics(delta):
	var bounds = get_play_bounds()

	for btn in target_buttons:
		if not should_simulate_button(btn):
			continue

		var state = button_states[btn]
		var velocity = state["velocity"]
		var angular_velocity = float(state["angular_velocity"])

		velocity.y += gravity * delta
		btn.position += velocity * delta
		btn.rotation_degrees = clamp(btn.rotation_degrees + angular_velocity * delta, -18.0, 18.0)

		if btn.position.x < bounds.position.x:
			btn.position.x = bounds.position.x
			velocity.x = abs(velocity.x) * bounce
			angular_velocity += abs(velocity.y) * 0.04
		elif btn.position.x + btn.size.x > bounds.end.x:
			btn.position.x = bounds.end.x - btn.size.x
			velocity.x = -abs(velocity.x) * bounce
			angular_velocity -= abs(velocity.y) * 0.04

		if btn.position.y + btn.size.y > bounds.end.y:
			btn.position.y = bounds.end.y - btn.size.y
			velocity.y = -abs(velocity.y) * bounce
			velocity.x *= floor_friction
			angular_velocity += velocity.x * 0.10
			angular_velocity *= 0.78

			if abs(velocity.y) < 26.0:
				velocity.y = 0.0
			if abs(velocity.x) < 7.0:
				velocity.x = 0.0
			if abs(angular_velocity) < 3.0:
				angular_velocity = 0.0

		state["velocity"] = velocity
		state["angular_velocity"] = angular_velocity
		state["resting"] = velocity == Vector2.ZERO and angular_velocity == 0.0
		button_states[btn] = state

	resolve_button_collisions(bounds)


func resolve_button_collisions(bounds: Rect2):
	for a in range(target_buttons.size()):
		var first = target_buttons[a]
		if not should_simulate_button(first):
			continue

		for b in range(a + 1, target_buttons.size()):
			var second = target_buttons[b]
			if not should_simulate_button(second):
				continue

			var r1 = Rect2(first.position, first.size)
			var r2 = Rect2(second.position, second.size)
			if not r1.intersects(r2):
				continue

			var overlap_x = min(r1.end.x, r2.end.x) - max(r1.position.x, r2.position.x)
			var overlap_y = min(r1.end.y, r2.end.y) - max(r1.position.y, r2.position.y)
			var s1 = button_states[first]
			var s2 = button_states[second]
			var v1 = s1["velocity"]
			var v2 = s2["velocity"]

			if overlap_y < overlap_x:
				var push_y = overlap_y / 2.0 + 0.6
				if first.position.y < second.position.y:
					first.position.y -= push_y
					second.position.y += push_y
				else:
					first.position.y += push_y
					second.position.y -= push_y

				v1.y *= -bounce
				v2.y *= -bounce
				s1["angular_velocity"] = float(s1["angular_velocity"]) + randf_range(-26.0, 26.0)
				s2["angular_velocity"] = float(s2["angular_velocity"]) + randf_range(-26.0, 26.0)
			else:
				var push_x = overlap_x / 2.0 + 0.6
				if first.position.x < second.position.x:
					first.position.x -= push_x
					second.position.x += push_x
				else:
					first.position.x += push_x
					second.position.x -= push_x

				v1.x *= -bounce
				v2.x *= -bounce
				s1["angular_velocity"] = float(s1["angular_velocity"]) + randf_range(-32.0, 32.0)
				s2["angular_velocity"] = float(s2["angular_velocity"]) + randf_range(-32.0, 32.0)

			first.position.x = clamp(first.position.x, bounds.position.x, bounds.end.x - first.size.x)
			first.position.y = clamp(first.position.y, bounds.position.y, bounds.end.y - first.size.y)
			second.position.x = clamp(second.position.x, bounds.position.x, bounds.end.x - second.size.x)
			second.position.y = clamp(second.position.y, bounds.position.y, bounds.end.y - second.size.y)

			s1["velocity"] = v1
			s2["velocity"] = v2
			button_states[first] = s1
			button_states[second] = s2


func should_simulate_button(btn: Button) -> bool:
	if btn == null or not is_instance_valid(btn):
		return false
	if not button_states.has(btn):
		return false
	if released_buttons.has(btn):
		return false
	if btn == lifted_button and carrying_button:
		return false
	if btn == grab_candidate and claw_busy:
		return false
	return true


func simulate_claw_sway(delta):
	var movement = claw_position - last_claw_position
	last_claw_position = claw_position

	if abs(movement.x) > 0.01:
		claw_angle_velocity += movement.x * 0.26
		rope_bend_velocity += movement.x * 0.40
	if abs(movement.y) > 0.01:
		claw_angle_velocity += sign(movement.y) * 8.0
		rope_bend_velocity += sign(movement.y) * randf_range(-10.0, 10.0)

	claw_angle_velocity += -claw_angle * 16.0 * delta
	claw_angle_velocity *= pow(0.08, delta)
	claw_angle = clamp(claw_angle + claw_angle_velocity * delta, -12.0, 12.0)

	rope_bend_velocity += -rope_bend * 12.0 * delta
	rope_bend_velocity *= pow(0.06, delta)
	rope_bend = clamp(rope_bend + rope_bend_velocity * delta, -34.0, 34.0)

	update_claw_visual()


func update_claw_visual():
	if claw_hand:
		claw_hand.position = claw_position
		claw_hand.rotation_degrees = claw_angle

	if rope_line:
		var top = Vector2(claw_position.x, play_area.position.y)
		var bottom = Vector2(claw_position.x, claw_position.y - 4)
		var middle = top.lerp(bottom, 0.55) + Vector2(rope_bend, 0)
		rope_line.points = PackedVector2Array([top, middle, bottom])

	if lifted_button and is_instance_valid(lifted_button) and carrying_button:
		lifted_button.position = Vector2(claw_position.x - lifted_button.size.x / 2.0, claw_position.y + claw_height - 20.0)
		lifted_button.rotation_degrees = claw_angle * 0.45


func draw_claw_state():
	if claw_hand == null:
		return

	var left = claw_hand.get_node_or_null("LeftFinger")
	var right = claw_hand.get_node_or_null("RightFinger")
	if left:
		left.position.x = -88 if claw_open else -64
		left.rotation_degrees = -8 if claw_open else -1
	if right:
		right.position.x = 66 if claw_open else 42
		right.rotation_degrees = 8 if claw_open else 1


func _on_left_down():
	moving_left = true


func _on_left_up():
	moving_left = false


func _on_left_pressed():
	if can_interact and not claw_busy:
		move_claw_by(-claw_step)


func _on_right_down():
	moving_right = true


func _on_right_up():
	moving_right = false


func _on_right_pressed():
	if can_interact and not claw_busy:
		move_claw_by(claw_step)


func _on_catch_pressed():
	if can_interact and not claw_busy and not carrying_button:
		grab_attempt()


func _on_release_pressed():
	if can_interact and carrying_button and lifted_button and is_instance_valid(lifted_button):
		release_lifted_button()


func move_claw_by(amount: float):
	move_claw_to_x(claw_position.x + amount)


func move_claw_to_x(new_x: float):
	claw_position.x = clamp(new_x, claw_min_x, claw_max_x)
	claw_position.y = claw_top_y
	update_claw_visual()


func grab_attempt():
	claw_busy = true
	can_interact = false
	moving_left = false
	moving_right = false
	set_controls_for_state()
	result_label.visible = false

	claw_open = true
	draw_claw_state()

	grab_candidate = get_button_under_claw()
	if grab_candidate and is_instance_valid(grab_candidate):
		var state = button_states[grab_candidate]
		state["velocity"] = Vector2.ZERO
		state["angular_velocity"] = 0.0
		button_states[grab_candidate] = state

	var target_y = get_grab_y()
	var down_tween = create_tween()
	down_tween.set_ease(Tween.EASE_IN_OUT)
	down_tween.set_trans(Tween.TRANS_SINE)
	down_tween.tween_method(Callable(self, "set_claw_y"), claw_position.y, target_y, 0.72)
	await down_tween.finished

	result_label.modulate = Color(0.12, 0.12, 0.12)
	result_label.text = "Dráp se usazuje..."
	result_label.visible = true
	await get_tree().create_timer(0.35).timeout

	claw_open = false
	draw_claw_state()
	await get_tree().create_timer(0.20).timeout

	var caught = get_caught_button()
	if caught == null and grab_candidate and is_instance_valid(grab_candidate):
		caught = grab_candidate

	if caught:
		lifted_button = caught
		lifted_button.z_index = 80
		lifted_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(lifted_button, get_child_count() - 1)
		carrying_button = true
		var state = button_states[lifted_button]
		state["velocity"] = Vector2.ZERO
		state["angular_velocity"] = 0.0
		button_states[lifted_button] = state

	var up_tween = create_tween()
	up_tween.set_ease(Tween.EASE_IN_OUT)
	up_tween.set_trans(Tween.TRANS_SINE)
	up_tween.tween_method(Callable(self, "set_claw_y"), claw_position.y, claw_top_y, 0.68)
	await up_tween.finished

	claw_open = true
	claw_busy = false
	can_interact = true
	grab_candidate = null
	draw_claw_state()

	if carrying_button:
		result_label.modulate = Color(0.12, 0.12, 0.12)
		result_label.text = "Přenes tlačítko do klikací zóny a stiskni Pustit."
		result_label.visible = true
	else:
		result_label.modulate = Color(0.45, 0.32, 0.0)
		result_label.text = "Vedle."
		result_label.visible = true

	set_controls_for_state()
	update_instruction_label()


func set_claw_y(new_y: float):
	claw_position.y = new_y
	update_claw_visual()


func get_button_under_claw() -> Button:
	var best: Button = null
	var best_y = INF
	var claw_left = claw_position.x - claw_width * 0.36
	var claw_right = claw_position.x + claw_width * 0.36

	for btn in target_buttons:
		if btn == null or not is_instance_valid(btn) or released_buttons.has(btn):
			continue
		if btn == lifted_button and carrying_button:
			continue

		var rect = Rect2(btn.position, btn.size)
		var overlap = min(claw_right, rect.end.x) - max(claw_left, rect.position.x)
		if overlap < btn.size.x * 0.26:
			continue

		if rect.position.y < best_y:
			best = btn
			best_y = rect.position.y

	return best


func get_grab_y() -> float:
	var floor_y = play_area.position.y + play_area.size.y - claw_height - FLOOR_PADDING
	if grab_candidate and is_instance_valid(grab_candidate):
		return clamp(grab_candidate.position.y - 22.0, claw_top_y + 12.0, floor_y)
	return floor_y


func get_caught_button() -> Button:
	var contact = Rect2(
		Vector2(claw_position.x - claw_width * 0.38, claw_position.y + 18.0),
		Vector2(claw_width * 0.76, 72.0)
	)
	var best: Button = null
	var best_score = INF

	for btn in target_buttons:
		if btn == null or not is_instance_valid(btn) or released_buttons.has(btn):
			continue

		var rect = Rect2(btn.position, btn.size)
		if not contact.intersects(rect):
			continue

		var score = abs((btn.position.x + btn.size.x / 2.0) - claw_position.x) + rect.position.y * 0.04
		if score < best_score:
			best = btn
			best_score = score

	return best


func release_lifted_button():
	var button_rect = Rect2(lifted_button.position, lifted_button.size)
	var zone_rect = Rect2(drop_zone.position, drop_zone.size)
	var overlap_x = max(0.0, min(button_rect.end.x, zone_rect.end.x) - max(button_rect.position.x, zone_rect.position.x))
	var overlap_y = max(0.0, min(button_rect.end.y, zone_rect.end.y) - max(button_rect.position.y, zone_rect.position.y))
	var overlap_area = overlap_x * overlap_y
	var in_zone = overlap_area >= button_rect.size.x * button_rect.size.y * TARGET_OVERLAP

	if not in_zone:
		drop_carried_button(true)
		return

	carrying_button = false
	waiting_for_click = true
	lifted_button.z_index = 95
	lifted_button.disabled = false
	lifted_button.mouse_filter = Control.MOUSE_FILTER_STOP
	move_child(lifted_button, get_child_count() - 1)
	released_buttons.append(lifted_button)

	var state = button_states[lifted_button]
	state["velocity"] = Vector2.ZERO
	state["angular_velocity"] = 0.0
	button_states[lifted_button] = state

	result_label.modulate = Color(0.12, 0.12, 0.12)
	result_label.text = "Tady už jde tlačítko kliknout."
	result_label.visible = true
	lifted_button = null
	set_controls_for_state()
	update_instruction_label()


func drop_carried_button(was_error: bool):
	var btn = lifted_button
	carrying_button = false
	lifted_button = null

	if btn and is_instance_valid(btn):
		btn.z_index = 28
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var state = button_states[btn]
		state["velocity"] = Vector2(randf_range(-26.0, 26.0), 150.0)
		state["angular_velocity"] = randf_range(-70.0, 70.0)
		state["resting"] = false
		button_states[btn] = state

	if was_error:
		GameState.add_system_control(5)

	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.55, 0.0, 0.0)
	result_label.text = "Pusť tlačítko až v pravé klikací zóně."
	result_label.visible = true
	update_system_control_label()

	await get_tree().create_timer(0.6).timeout
	if not level_completed:
		background.color = Color(0.96, 0.96, 0.92)
	set_controls_for_state()
	update_instruction_label()


func _on_target_pressed(button: Button):
	if not waiting_for_click or not released_buttons.has(button):
		return

	if button == no_button:
		complete_level()
	else:
		wrong_button_clicked(button)


func _on_no_pressed():
	_on_target_pressed(no_button)


func wrong_button_clicked(button: Button):
	mistakes += 1
	GameState.add_system_control(10)
	update_system_control_label()
	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = "Špatně. To bylo SOUHLASÍM."
	result_label.visible = true

	if button and is_instance_valid(button):
		button.disabled = true

	if mistakes >= max_mistakes:
		await get_tree().create_timer(1.0).timeout
		start_level()
		return

	await get_tree().create_timer(0.75).timeout
	if not level_completed:
		background.color = Color(0.96, 0.96, 0.92)
	update_instruction_label()


func complete_level():
	level_completed = true
	can_interact = false
	background.color = Color(0.84, 0.94, 0.84)
	no_button.disabled = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Správně. NESOUHLASÍM doručeno."
	result_label.visible = true
	set_controls_for_state()

	await get_tree().create_timer(1.0).timeout
	level_finished.emit()


func set_controls_for_state():
	var disabled = level_completed or claw_busy
	left_button.disabled = disabled
	right_button.disabled = disabled
	catch_button.disabled = disabled or carrying_button
	release_button.disabled = disabled or not carrying_button


func update_instruction_label():
	if carrying_button:
		instruction_label.text = "Přenes tlačítko do pravé klikací zóny a stiskni Pustit."
	elif waiting_for_click:
		instruction_label.text = "Klikni v pravé zóně jen na NESOUHLASÍM. Chyby: %d/%d" % [mistakes, max_mistakes]
	else:
		instruction_label.text = "Odtáhni tlačítka, najdi NESOUHLASÍM a pusť ho v klikací zóně. Chyby: %d/%d" % [mistakes, max_mistakes]


func update_claw_bounds():
	if play_area == null or drop_zone == null:
		return
	claw_min_x = play_area.position.x + claw_width / 2.0
	claw_max_x = drop_zone.position.x + drop_zone.size.x - claw_width / 2.0


func get_play_bounds() -> Rect2:
	return Rect2(
		play_area.position + Vector2(PLAY_MARGIN, PLAY_MARGIN),
		play_area.size - Vector2(PLAY_MARGIN * 2.0, PLAY_MARGIN + FLOOR_PADDING)
	)


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_area(panel: Panel):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.96)
	sb.border_color = Color(0.08, 0.22, 0.32)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)


func style_target_button(button: Button, agree: bool):
	var bg = Color(0.82, 0.50, 0.56) if agree else Color(0.65, 0.90, 0.66)
	var border = Color(0.55, 0.16, 0.28) if agree else Color(0.10, 0.45, 0.22)
	var normal = make_button_style(bg, border, 8)
	var hover = make_button_style(bg.lerp(Color(1, 1, 1), 0.08), border, 8)
	var pressed = make_button_style(bg.lerp(Color(0, 0, 0), 0.08), border, 8)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 15)


func style_control_button(button: Button):
	var normal = make_button_style(Color(0.94, 0.94, 0.91), Color(0.20, 0.40, 0.72), 8)
	var hover = make_button_style(Color(0.98, 0.99, 1.0), Color(0.24, 0.48, 0.92), 8)
	var pressed = make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 8)
	var disabled = make_button_style(Color(0.64, 0.70, 0.76), Color(0.32, 0.42, 0.52), 8)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.08, 0.18, 0.32))
	button.add_theme_color_override("font_hover_color", Color(0.08, 0.18, 0.32))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.18, 0.32))
	button.add_theme_color_override("font_disabled_color", Color(0.28, 0.38, 0.48))
	button.add_theme_font_size_override("font_size", 15)


func make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = Color(1, 1, 1, 0.20)
	sb.shadow_size = 1
	return sb
