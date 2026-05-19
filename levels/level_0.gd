extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var article_number = 1

var title_label: Label
var scroll_container: ScrollContainer
var article_label: RichTextLabel
var agree_button: Button
var disagree_button: Button

func _ready():
	setup_ui()


func set_window_size(new_size):
	window_size = new_size
	layout_ui()


func setup_ui():
	if background:
		background.color = Color(0.96, 0.96, 0.92)
		background.z_index = -10

	scroll_container = ScrollContainer.new()
	scroll_container.name = "ArticleScrollContainer"
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)

	article_label = RichTextLabel.new()
	article_label.name = "ArticleText"
	article_label.bbcode_enabled = false
	article_label.fit_content = true
	article_label.scroll_active = false
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)
	article_label.add_theme_font_size_override("normal_font_size", 19)
	article_label.modulate = Color(0.08, 0.08, 0.08)
	scroll_container.add_child(article_label)

	agree_button = Button.new()
	agree_button.name = "AgreeButton"
	agree_button.text = "Souhlasím"
	agree_button.pressed.connect(_on_agree_pressed)
	style_green_button(agree_button)
	add_child(agree_button)

	disagree_button = Button.new()
	disagree_button.name = "DisagreeButton"
	disagree_button.text = "Nesouhlasím"
	disagree_button.pressed.connect(_on_disagree_pressed)
	style_red_button(disagree_button)
	add_child(disagree_button)

	layout_ui()


func layout_ui():
	if background:
		background.position = Vector2.ZERO
		background.size = window_size

	if scroll_container:
		scroll_container.position = Vector2(60, 42)
		scroll_container.size = Vector2(window_size.x - 120, window_size.y - 130)

	if article_label:
		article_label.custom_minimum_size = Vector2(window_size.x - 150, 680)

	var button_y = window_size.y - 68

	if disagree_button:
		disagree_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
		disagree_button.size = Vector2(180, 44)

	if agree_button:
		agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)
		agree_button.size = Vector2(180, 44)


func _on_agree_pressed():
	agree_button.disabled = true
	disagree_button.disabled = true
	article_label.modulate = Color(0.0, 0.50, 0.0)
	article_label.text = GameState.result_success_text
	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func _on_disagree_pressed():
	agree_button.disabled = true
	disagree_button.disabled = true
	article_label.modulate = Color(0.58, 0.0, 0.0)
	article_label.text = GameState.result_fail_text
	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func style_green_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var hover = make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 17)


func style_red_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var hover = make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 17)


func make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb
