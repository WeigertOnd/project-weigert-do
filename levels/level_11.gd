extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var start_button = $StartButton
@onready var agree_button = $NoButton
@onready var instruction_label = $InstructionLabel
@onready var timer_label = $TimerLabel
@onready var result_label = $ResultLabel

var article_label: Label

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var running = false
var completed = false
var failed = false
var elapsed = 0.0

var target_time = 15.0
var tolerance = 0.5

var min_time = 14.5
var max_time = 15.5
var auto_fail_time = 18.0

var timer_fade_start = 5.0
var timer_fade_duration = 1.2



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
	running = false
	completed = false
	failed = false
	elapsed = 0.0

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	instruction_label.visible = true
	instruction_label.modulate = Color(0.12, 0.12, 0.12)
	instruction_label.text = (
		"Stiskni Start a potom klikni na Souhlasím po 15 sekundách. (odchylka ±  0.5 sekund)"
	)

	timer_label.visible = false
	timer_label.modulate = Color(0.10, 0.10, 0.10)
	timer_label.modulate.a = 1.0
	timer_label.text = "0.00 s"

	result_label.visible = false
	result_label.modulate = Color(0.56, 0.0, 0.0)

	start_button.disabled = false
	start_button.visible = true
	start_button.text = "Start"

	agree_button.disabled = true
	agree_button.visible = true
	agree_button.text = "Souhlasím"

	LevelUtils.style_blue_button(start_button)
	LevelUtils.style_green_button(agree_button)

	layout_ui()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if completed or failed:
		return

	if running:
		elapsed += delta
		update_timer_label()

		if elapsed > auto_fail_time:
			fail_level("Pozdě")
			return


func setup_ui():
	background.z_index = -10

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 17)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	timer_label.z_index = 6
	instruction_label.z_index = 6
	result_label.z_index = 8
	start_button.z_index = 7
	agree_button.z_index = 7

	start_button.focus_mode = Control.FOCUS_NONE
	agree_button.focus_mode = Control.FOCUS_NONE

	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if article_label:
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, 320)
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)

	instruction_label.position = Vector2(70, 360)
	instruction_label.size = Vector2(window_size.x - 140, 52)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 15)

	timer_label.position = Vector2(window_size.x / 2.0 - 120, 410)
	timer_label.size = Vector2(240, 42)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 30)

	result_label.position = Vector2(window_size.x / 2.0 - 250, 390)
	result_label.size = Vector2(500, 64)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 21)

	var button_size = Vector2(180, 44)
	var spacing = 80
	var total_width = button_size.x * 2 + spacing
	var start_x = window_size.x / 2.0 - total_width / 2.0
	var button_y = window_size.y - 68

	start_button.size = button_size
	agree_button.size = button_size

	start_button.position = Vector2(start_x, button_y)
	agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)


func _on_start_pressed():
	if completed or failed or running:
		return

	elapsed = 0.0
	running = true

	start_button.disabled = true
	agree_button.disabled = false

	result_label.visible = false

	timer_label.visible = true
	timer_label.modulate = Color(0.10, 0.10, 0.10)
	timer_label.modulate.a = 1.0
	update_timer_label()

	instruction_label.text = ("Klikni na Souhlasím až po 15 sekundách. (odchylka ±  0.5 sekund)")


func _on_agree_pressed():
	if completed or failed or not running:
		return

	if elapsed >= min_time and elapsed <= max_time:
		complete_level()
	else:
		if elapsed < min_time:
			fail_level("Brzo")
		else:
			fail_level("Pozdě")


func update_timer_label():
	timer_label.text = "%.2f s" % elapsed

	if elapsed <= timer_fade_start:
		timer_label.modulate.a = 1.0
	else:
		var fade_progress = (elapsed - timer_fade_start) / timer_fade_duration
		timer_label.modulate.a = clamp(1.0 - fade_progress, 0.0, 1.0)


func fail_level(reason_text: String):
	if failed:
		return

	failed = true
	running = false

	background.color = Color(0.95, 0.82, 0.82)

	start_button.disabled = true
	agree_button.disabled = true

	hide_final_time()

	result_label.modulate = Color(0.56, 0.0, 0.0)
	result_label.text = "Souhlas nebyl přijat (%.2f s)" % elapsed
	result_label.visible = true

	instruction_label.text = ""


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func complete_level():
	if completed:
		return

	completed = true
	running = false

	background.color = Color(0.84, 0.94, 0.84)

	start_button.disabled = true
	agree_button.disabled = true

	hide_final_time()

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Souhlas byl přijat (%.2f s)" % elapsed
	result_label.visible = true

	instruction_label.text = ""

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func hide_final_time():
	timer_label.visible = false
