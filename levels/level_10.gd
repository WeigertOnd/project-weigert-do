extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var arena = $Arena
@onready var line = $Line
@onready var target_label = $TargetLabel
@onready var no_button = $NoButton
@onready var score_label = $ScoreLabel
@onready var error_label = $ErrorLabel

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO
var decoy_nodes = []
var decoy_velocities = []
var score = 0
var target_score = 4
var error_time = 0.0
var completed = false


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	score = 0
	error_time = 0.0
	completed = false
	clear_decoys()

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	error_label.visible = false
	no_button.disabled = false
	no_button.text = "Nesouhlasím"
	create_decoys()
	update_score_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if completed:
		return

	if error_time > 0:
		error_time -= delta
		if error_time <= 0:
			error_label.visible = false
			background.color = Color(0.96, 0.96, 0.92)
			no_button.disabled = false
		return

	move_decoys(delta)


func setup_ui():
	background.z_index = 0
	arena.z_index = 1
	line.z_index = 2
	target_label.z_index = 4
	score_label.z_index = 4
	error_label.z_index = 6
	no_button.z_index = 5

	style_panel(arena)
	style_button_soft_xp(no_button)
	style_label_pill(target_label, Color(0.46, 0.82, 0.56), Color(0.18, 0.43, 0.22))
	target_label.focus_mode = Control.FOCUS_NONE
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	arena.position = Vector2(34, 30)
	arena.size = Vector2(window_size.x - 68, 330)

	target_label.text = "Nesouhlasím"
	target_label.position = Vector2(window_size.x / 2 - 78, 60)
	target_label.size = Vector2(156, 38)
	target_label.add_theme_font_size_override("font_size", 15)

	no_button.size = Vector2(220, 64)
	no_button.position = Vector2(window_size.x / 2 - no_button.size.x / 2, window_size.y - 92)

	line.color = Color(0.42, 0.38, 0.32)
	line.position = Vector2(window_size.x / 2 - 2, target_label.position.y + target_label.size.y)
	line.size = Vector2(4, no_button.position.y - line.position.y - 16)

	score_label.position = Vector2(60, window_size.y - 86)
	score_label.size = Vector2(220, 30)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 15)
	score_label.modulate = Color(0.12, 0.12, 0.12)

	error_label.position = Vector2(window_size.x / 2 - 180, 378)
	error_label.size = Vector2(360, 34)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 22)
	error_label.modulate = Color(0.65, 0.0, 0.0)


func create_decoys():
	var rect = get_arena_inner_rect()
	for i in range(11):
		var decoy = Button.new()
		decoy.text = "Souhlasím"
		decoy.size = Vector2(104, 34)
		decoy.position = Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x - decoy.size.x),
			randf_range(rect.position.y + 60, rect.position.y + rect.size.y - decoy.size.y - 20)
		)
		decoy.focus_mode = Control.FOCUS_NONE
		decoy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decoy.z_index = 3
		style_label_pill(decoy, Color(0.78, 0.42, 0.48), Color(0.78, 0.42, 0.48))
		add_child(decoy)

		var velocity = Vector2(randf_range(-470, 470), randf_range(-230, 230))
		if abs(velocity.x) < 180:
			velocity.x = 260 if velocity.x >= 0 else -260
		if abs(velocity.y) < 70:
			velocity.y = 120 if velocity.y >= 0 else -120
		decoy_nodes.append(decoy)
		decoy_velocities.append(velocity)


func move_decoys(delta):
	var rect = get_arena_inner_rect()
	for i in range(decoy_nodes.size()):
		var decoy = decoy_nodes[i]
		var velocity = decoy_velocities[i]
		if decoy == null or not is_instance_valid(decoy):
			continue

		decoy.position += velocity * delta
		if decoy.position.x < rect.position.x:
			decoy.position.x = rect.position.x
			velocity.x = abs(velocity.x)
		elif decoy.position.x + decoy.size.x > rect.position.x + rect.size.x:
			decoy.position.x = rect.position.x + rect.size.x - decoy.size.x
			velocity.x = -abs(velocity.x)

		if decoy.position.y < rect.position.y:
			decoy.position.y = rect.position.y
			velocity.y = abs(velocity.y)
		elif decoy.position.y + decoy.size.y > rect.position.y + rect.size.y:
			decoy.position.y = rect.position.y + rect.size.y - decoy.size.y
			velocity.y = -abs(velocity.y)

		decoy_velocities[i] = velocity


func _on_no_pressed():
	if completed or error_time > 0:
		return

	if is_agree_on_line():
		show_error()
		return

	score += 1
	GameState.reduce_system_control(1)
	update_score_label()

	if score >= target_score:
		complete_level()


func is_agree_on_line() -> bool:
	var line_x = line.position.x + line.size.x / 2
	for decoy in decoy_nodes:
		if decoy == null or not is_instance_valid(decoy):
			continue
		if line_x >= decoy.position.x and line_x <= decoy.position.x + decoy.size.x:
			return true
	return false


func clear_decoys():
	for decoy in decoy_nodes:
		if decoy and is_instance_valid(decoy):
			decoy.queue_free()
	decoy_nodes.clear()
	decoy_velocities.clear()


func show_error():
	score = 0
	GameState.add_system_control(10)
	update_score_label()
	background.color = Color(0.95, 0.82, 0.82)
	error_label.text = "CHYBA"
	error_label.visible = true
	error_time = 0.9
	no_button.disabled = true


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	no_button.disabled = true

	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func update_score_label():
	score_label.text = "Reakce: %d/%d" % [score, target_score]


func get_arena_inner_rect() -> Rect2:
	return Rect2(arena.position + Vector2(12, 12), arena.size - Vector2(24, 24))


func style_panel(panel: Panel):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.96)
	sb.border_color = Color(0.09, 0.22, 0.32)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)


func style_label_pill(control: Control, bg: Color, border: Color):
	var sb = make_button_style(bg, border, 8)
	control.add_theme_stylebox_override("normal", sb)
	control.add_theme_stylebox_override("hover", sb)
	control.add_theme_stylebox_override("pressed", sb)
	control.add_theme_color_override("font_color", Color(1, 1, 1))
	control.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	control.add_theme_font_size_override("font_size", 14)


func style_button_soft_xp(button):
	var normal = make_button_style(Color(0.80, 0.96, 0.80), Color(0.10, 0.40, 0.62), 10)
	var hover = make_button_style(Color(0.70, 1.0, 0.72), Color(0.05, 0.35, 0.78), 10)
	var pressed = make_button_style(Color(0.58, 0.84, 0.62), Color(0.05, 0.28, 0.58), 10)
	var disabled = make_button_style(Color(0.74, 0.78, 0.74), Color(0.42, 0.42, 0.42), 10)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.10, 0.18, 0.50))
	button.add_theme_color_override("font_hover_color", Color(0.08, 0.14, 0.45))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.14, 0.45))
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.42, 0.42))
	button.add_theme_font_size_override("font_size", 26)


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
	return sb
