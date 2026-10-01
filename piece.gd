extends Node2D

var piece_type: String = "healthy"
var special_type: String = "normal"
var is_line_clear_row: bool = false
var column: int
var row: int

var first_touch = Vector2(0, 0)
var final_touch = Vector2(0, 0)
var controlling = false

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		first_touch = get_global_mouse_position()
		controlling = true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if controlling:
			final_touch = get_global_mouse_position()
			controlling = false
			calculate_swipe()

func calculate_swipe():
	var swipe = final_touch - first_touch
	var direction = Vector2.ZERO
	if swipe.length() > 20:
		if abs(swipe.x) > abs(swipe.y):
			if swipe.x > 0:
				direction = Vector2(1, 0)
			else:
				direction = Vector2(-1, 0)
		else:
			if swipe.y > 0:
				direction = Vector2(0, 1)
			else:
				direction = Vector2(0, -1)
		get_parent().swap_pieces(column, row, direction)

func move(target):
	var tween = create_tween()
	tween.tween_property(self, "position", target, 0.3)

func pop():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", rotation + PI, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func mark_as_line_clear(is_row: bool):
	special_type = "line_clear"
	is_line_clear_row = is_row
	get_node("Sprite2D").scale *= 1.3
	var outline = ColorRect.new()
	outline.color = Color.WHITE
	outline.size = Vector2(4, 4)
	outline.position = Vector2(-2, -2)
	outline.z_index = 1
	add_child(outline)
