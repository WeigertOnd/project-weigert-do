extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var agree_button_escape_distance = 120
var agree_button_escape_speed = 8
var agree_button_running = true


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
	agree_button_running = true

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	text_label.text = LevelUtils.get_article_text(article_number)
	text_label.modulate = Color(0.10, 0.10, 0.10)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	LevelUtils.style_green_button(agree_button)
	LevelUtils.style_red_button(no_button)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if agree_button_running and agree_button.visible and not agree_button.disabled:
		move_agree_button_away_from_mouse()


func setup_ui():
	background.z_index = 0
	text_label.z_index = 5
	agree_button.z_index = 5
	no_button.z_index = 5

	layout_ui()
	last_window_size = window_size


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	text_label.position = Vector2(70, 48)
	text_label.size = Vector2(window_size.x - 140, window_size.y - 155)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 20)

	no_button.size = Vector2(180, 44)
	agree_button.size = Vector2(180, 44)

	var button_y = window_size.y - 68

	no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
	agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _on_agree_pressed():
	agree_button_running = false
	level_finished.emit()


func _on_no_pressed():
	level_failed.emit()


func move_agree_button_away_from_mouse():
	var mouse_position = to_local(get_global_mouse_position())
	var button_center = agree_button.position + agree_button.size / 2
	var distance = mouse_position.distance_to(button_center)

	if distance < agree_button_escape_distance:
		var direction = button_center - mouse_position

		if direction.length() == 0:
			direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))

		direction = direction.normalized()
		agree_button.position += direction * agree_button_escape_speed
		keep_agree_button_inside_content()


func keep_agree_button_inside_content():
	var rect = get_content_rect()

	agree_button.position.x = clamp(
		agree_button.position.x,
		rect.position.x,
		rect.position.x + rect.size.x - agree_button.size.x
	)

	agree_button.position.y = clamp(
		agree_button.position.y,
		rect.position.y,
		rect.position.y + rect.size.y - agree_button.size.y
	)


func get_content_rect() -> Rect2:
	return Rect2(
		Vector2(30, 40),
		Vector2(window_size.x - 60, window_size.y - 115)
	)
