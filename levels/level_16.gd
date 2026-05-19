extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var article_label: Label
var instruction_label: Label
var result_label: Label
var control_label: Label

var no_button: Button
var yes_button: Button

var completed = false
var failed = false
var swap_cooldown = false

var no_positions = [
	Vector2(176, 178),
	Vector2(482, 150),
	Vector2(246, 312),
	Vector2(596, 292),
	Vector2(92, 270)
]

var yes_positions = [
	Vector2(500, 238),
	Vector2(168, 270),
	Vector2(565, 168),
	Vector2(326, 220),
	Vector2(416, 332)
]

var move_index = 0
var escape_distance = 260.0
var escape_duration = 0.25
var swap_duration = 0.15
var hover_cooldown_time = 0.25


func _ready():
	start_level()


func set_article_number(new_article_number: int):
	article_number = new_article_number

	if is_inside_tree():
		start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	completed = false
	failed = false
	swap_cooldown = false
	move_index = 0

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	instruction_label.visible = true
	instruction_label.modulate = Color(0.15, 0.15, 0.15)

	result_label.visible = false

	no_button.disabled = false
	yes_button.disabled = false

	no_button.text = "Nesouhlasím"
	yes_button.text = "Souhlasím"

	LevelUtils.style_red_button(no_button)
	LevelUtils.style_green_button(yes_button)

	no_button.position = clamp_button_position(no_positions[0])
	yes_button.position = clamp_button_position(yes_positions[0])

	update_system_control_label()
	layout_ui()


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()


func setup_ui():
	LevelUtils.layout_background(background, window_size)
	background.z_index = -10

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	if not LevelUtils.is_valid_node(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if not LevelUtils.is_valid_node(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 30
		add_child(result_label)

	if not LevelUtils.is_valid_node(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 40
		add_child(control_label)

	if not LevelUtils.is_valid_node(no_button):
		no_button = Button.new()
		no_button.name = "FailNoButton"
		no_button.text = "Nesouhlasím"
		no_button.size = Vector2(130, 40)
		no_button.z_index = 10
		no_button.focus_mode = Control.FOCUS_NONE
		no_button.pressed.connect(_on_no_pressed)
		add_child(no_button)

	if not LevelUtils.is_valid_node(yes_button):
		yes_button = Button.new()
		yes_button.name = "SwappingYesButton"
		yes_button.text = "Souhlasím"
		yes_button.size = Vector2(130, 40)
		yes_button.z_index = 10
		yes_button.focus_mode = Control.FOCUS_NONE
		yes_button.mouse_entered.connect(_on_yes_hovered)
		yes_button.pressed.connect(_on_yes_pressed)
		add_child(yes_button)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if article_label:
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, 250)
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)

	if instruction_label:
		instruction_label.position = Vector2(70, 286)
		instruction_label.size = Vector2(window_size.x - 140, 42)

	if result_label:
		result_label.position = Vector2(70, window_size.y - 108)
		result_label.size = Vector2(window_size.x - 140, 44)

	update_system_control_label_position()


func _on_yes_hovered():
	if completed or failed or swap_cooldown:
		return

	swap_cooldown = true

	var old_yes_position = yes_button.position
	var mouse_pos = to_local(get_global_mouse_position())

	var direction = yes_button.position + yes_button.size / 2.0 - mouse_pos

	if direction.length() < 1.0:
		direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))

	direction = direction.normalized()

	var random_push = Vector2(randf_range(-140.0, 140.0), randf_range(-100.0, 100.0))

	var new_yes_position = clamp_button_position(
		yes_button.position + direction * escape_distance + random_push
	)

	# Když by nová pozice byla moc blízko, hoď ho úplně náhodně jinam.
	if new_yes_position.distance_to(old_yes_position) < 120.0:
		new_yes_position = clamp_button_position(Vector2(
			randf_range(34.0, window_size.x - yes_button.size.x - 34.0),
			randf_range(120.0, window_size.y - yes_button.size.y - 34.0)
		))

	var yes_tween = create_tween()
	yes_tween.set_ease(Tween.EASE_OUT)
	yes_tween.set_trans(Tween.TRANS_EXPO)
	yes_tween.tween_property(yes_button, "position", new_yes_position, escape_duration)

	# Nesouhlasím skočí na staré místo Souhlasím rychleji.
	var no_tween = create_tween()
	no_tween.set_ease(Tween.EASE_OUT)
	no_tween.set_trans(Tween.TRANS_QUAD)
	no_tween.tween_property(no_button, "position", old_yes_position, swap_duration)

	await get_tree().create_timer(hover_cooldown_time).timeout
	swap_cooldown = false


func _on_yes_pressed():
	if completed or failed:
		return

	complete_level()


func _on_no_pressed():
	if completed or failed:
		return

	fail_level()


func complete_level():
	if completed:
		return

	completed = true

	no_button.disabled = true
	yes_button.disabled = true

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level():
	if failed:
		return

	failed = true

	no_button.disabled = true
	yes_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func clamp_button_position(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, 24.0, window_size.x - yes_button.size.x - 24.0),
		clamp(pos.y, 90.0, window_size.y - yes_button.size.y - 28.0)
	)


func update_system_control_label_position():
	LevelUtils.update_system_control_label(control_label, Vector2(window_size.x - 340, 8))


func update_system_control_label():
	LevelUtils.refresh_system_control_label(control_label)
