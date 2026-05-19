extends Node

const ArticleData = preload("res://data/ArticleData.gd")

# Společné utility pro všechny levely

static func is_valid_node(node) -> bool:
	return node != null and is_instance_valid(node)


static func layout_background(background: ColorRect, window_size: Vector2):
	if not is_valid_node(background):
		return

	background.position = Vector2.ZERO
	background.size = window_size


static func get_article_text(article_number: int) -> String:
	return ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)


static func update_system_control_label(label: Label, position: Vector2):
	if not is_valid_node(label):
		return

	label.position = position
	label.text = GameState.get_system_control_text()


static func refresh_system_control_label(label: Label):
	if is_valid_node(label):
		label.text = GameState.get_system_control_text()


static func style_green_button(button: Button):
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


static func style_red_button(button: Button):
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


static func style_green_button_no_hover_change(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)
	var disabled = make_button_style(Color(0.52, 0.62, 0.52), Color(0.32, 0.42, 0.32), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 17)


static func style_red_button_no_hover_change(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)
	var disabled = make_button_style(Color(0.62, 0.48, 0.48), Color(0.42, 0.30, 0.30), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 17)


static func style_blue_button(button: Button):
	var normal = make_button_style(Color(0.12, 0.38, 0.62), Color(0.06, 0.18, 0.32), 7)
	var hover = make_button_style(Color(0.18, 0.52, 0.82), Color(0.08, 0.26, 0.42), 7)
	var pressed = make_button_style(Color(0.08, 0.28, 0.48), Color(0.04, 0.14, 0.24), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 17)


static func make_button_style(
	bg: Color,
	border: Color,
	radius: int,
	border_width: int = 1,
	shadow_color: Color = Color(0, 0, 0, 0),
	shadow_size: int = 0
) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = shadow_color
	sb.shadow_size = shadow_size
	return sb


static func make_bold_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	return make_button_style(bg, border, radius, 2)


static func make_grid_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	return make_button_style(bg, border, 8, 2)


static func make_soft_shadow_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	return make_button_style(bg, border, radius, 1, Color(1, 1, 1, 0.20), 1)


static func style_soft_xp_button(button: Button):
	var normal = make_soft_shadow_button_style(Color(0.94, 0.94, 0.91), Color(0.43, 0.48, 0.58), 5)
	var hover = make_soft_shadow_button_style(Color(0.98, 0.99, 1.0), Color(0.22, 0.47, 0.88), 5)
	var pressed = make_soft_shadow_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 5)
	var disabled = make_soft_shadow_button_style(Color(0.84, 0.84, 0.82), Color(0.64, 0.64, 0.64), 5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.43, 0.43))
	button.add_theme_font_size_override("font_size", 14)
