extends Control

signal button_pressed(button_type: String)

enum ButtonType {
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_DOWN,
	AGREE_1,
	AGREE_2,
	AGREE_3,
	DISAGREE
}

var movement_buttons = {}
var decision_buttons = {}

var hand_animator = null
var window_size = Vector2(1280, 720)
var buttons_visible = false

var button_spacing = 10
var button_width = 80
var button_height = 60
var decision_button_width = 100


func _ready():
	setup_buttons()
	layout_buttons()
	hide_ui()


func set_window_size(new_size: Vector2):
	if window_size == new_size:
		return
	
	window_size = new_size
	layout_buttons()


func setup_buttons():
	var button_types = [
		{"name": "MoveLeft", "type": "MOVE_LEFT", "text": "←", "category": "movement"},
		{"name": "MoveDown", "type": "MOVE_DOWN", "text": "↓", "category": "movement"},
		{"name": "MoveRight", "type": "MOVE_RIGHT", "text": "→", "category": "movement"},
		{"name": "Agree1", "type": "AGREE_1", "text": "Souhlasím", "category": "decision"},
		{"name": "Agree2", "type": "AGREE_2", "text": "Souhlasím", "category": "decision"},
		{"name": "Agree3", "type": "AGREE_3", "text": "Souhlasím", "category": "decision"},
		{"name": "Disagree", "type": "DISAGREE", "text": "Nesouhlasím", "category": "decision"},
	]
	
	for btn_data in button_types:
		var button = Button.new()
		button.name = btn_data["name"]
		button.text = btn_data["text"]
		button.custom_minimum_size = Vector2(button_width, button_height) if btn_data["category"] == "movement" else Vector2(decision_button_width, button_height)
		button.pressed.connect(_on_button_pressed.bindv([btn_data["type"]]))
		
		style_button(button, btn_data["category"] == "decision")
		add_child(button)
		
		if btn_data["category"] == "movement":
			movement_buttons[btn_data["type"]] = button
		else:
			decision_buttons[btn_data["type"]] = button
	
	create_hand_animator()


func create_hand_animator():
	hand_animator = Node2D.new()
	hand_animator.name = "HandAnimator"
	hand_animator.z_index = 100
	add_child(hand_animator)
	
	var hand_visual = ColorRect.new()
	hand_visual.name = "HandVisual"
	hand_visual.color = Color(0.3, 0.3, 0.3)
	hand_visual.size = Vector2(30, 40)
	hand_visual.position = Vector2(-15, -20)
	hand_visual.z_index = 101
	hand_animator.add_child(hand_visual)
	hand_animator.visible = false


func layout_buttons():
	var bottom_padding = 20
	var start_y = window_size.y - button_height - bottom_padding
	
	var movement_y = start_y
	var decision_y = start_y - button_height - button_spacing
	
	var center_x = window_size.x / 2
	
	var movement_start_x = center_x - (button_width * 1.5 + button_spacing)
	
	var move_left_btn = movement_buttons.get("MOVE_LEFT")
	var move_down_btn = movement_buttons.get("MOVE_DOWN")
	var move_right_btn = movement_buttons.get("MOVE_RIGHT")
	
	if move_left_btn:
		move_left_btn.position = Vector2(movement_start_x, movement_y)
	if move_down_btn:
		move_down_btn.position = Vector2(movement_start_x + button_width + button_spacing, movement_y)
	if move_right_btn:
		move_right_btn.position = Vector2(movement_start_x + (button_width + button_spacing) * 2, movement_y)
	
	var decision_buttons_list = [
		decision_buttons.get("AGREE_1"),
		decision_buttons.get("AGREE_2"),
		decision_buttons.get("AGREE_3"),
		decision_buttons.get("DISAGREE")
	]
	
	var decision_start_x = center_x - (decision_button_width * 2 + button_spacing * 1.5)
	
	for i in range(decision_buttons_list.size()):
		if decision_buttons_list[i]:
			decision_buttons_list[i].position = Vector2(
				decision_start_x + i * (decision_button_width + button_spacing),
				decision_y
			)


func style_button(button: Button, is_decision: bool):
	var normal = make_button_style(
		Color(0.94, 0.94, 0.91),
		Color(0.43, 0.48, 0.58),
		5
	)
	
	var hover = make_button_style(
		Color(0.98, 0.99, 1.0),
		Color(0.22, 0.47, 0.88),
		5
	)
	
	var pressed = make_button_style(
		Color(0.76, 0.86, 0.98),
		Color(0.16, 0.33, 0.70),
		5
	)
	
	var disabled = make_button_style(
		Color(0.84, 0.84, 0.82),
		Color(0.64, 0.64, 0.64),
		5
	)
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	
	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.43, 0.43))
	button.add_theme_font_size_override("font_size", 12 if is_decision else 18)


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
	sb.shadow_color = Color(1, 1, 1, 0.20)
	sb.shadow_size = 1
	return sb


func _on_button_pressed(button_type: String):
	if not buttons_visible:
		return
	
	trigger_hand_animation(get_button_position(button_type))
	button_pressed.emit(button_type)


func get_button_position(button_type: String) -> Vector2:
	var btn = null
	
	if button_type in movement_buttons:
		btn = movement_buttons[button_type]
	elif button_type in decision_buttons:
		btn = decision_buttons[button_type]
	
	if btn:
		return btn.get_global_position() + btn.size / 2
	
	return Vector2.ZERO


func trigger_hand_animation(target_position: Vector2):
	if not hand_animator:
		return
	
	var start_y = target_position.y - 200
	var start_x = target_position.x
	
	hand_animator.position = Vector2(start_x, start_y)
	hand_animator.visible = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hand_animator, "position", target_position, 0.7)
	
	await tween.finished
	hand_animator.visible = false


func show_ui():
	buttons_visible = true
	for btn in movement_buttons.values():
		btn.visible = true
	for btn in decision_buttons.values():
		btn.visible = true


func hide_ui():
	buttons_visible = false
	for btn in movement_buttons.values():
		btn.visible = false
	for btn in decision_buttons.values():
		btn.visible = false


func disable_buttons():
	for btn in movement_buttons.values():
		btn.disabled = true
	for btn in decision_buttons.values():
		btn.disabled = true


func enable_buttons():
	for btn in movement_buttons.values():
		btn.disabled = false
	for btn in decision_buttons.values():
		btn.disabled = false
