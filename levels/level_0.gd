extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

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
	article_label.text = LevelUtils.get_article_text(article_number)
	article_label.add_theme_font_size_override("normal_font_size", 19)
	article_label.modulate = Color(0.08, 0.08, 0.08)
	scroll_container.add_child(article_label)

	agree_button = Button.new()
	agree_button.name = "AgreeButton"
	agree_button.text = "Souhlasím"
	agree_button.pressed.connect(_on_agree_pressed)
	LevelUtils.style_green_button(agree_button)
	add_child(agree_button)

	disagree_button = Button.new()
	disagree_button.name = "DisagreeButton"
	disagree_button.text = "Nesouhlasím"
	disagree_button.pressed.connect(_on_disagree_pressed)
	LevelUtils.style_red_button(disagree_button)
	add_child(disagree_button)

	layout_ui()


func layout_ui():
	if background:
		LevelUtils.layout_background(background, window_size)

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
