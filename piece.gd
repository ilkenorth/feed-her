extends Node2D

var piece_type: String = "healthy"
var special_type: String = "normal"
var is_line_clear_row: bool = false
var is_fate_piece: bool = false
var fate_is_good: bool = false
var column: int
var row: int

var first_touch = Vector2(0, 0)
var final_touch = Vector2(0, 0)
var controlling = false

const ARROW_TEX = preload("res://assets/sprites/special_piece_arrow.png")
const WALL_TEX = preload("res://assets/sprites/special_piece_wall.png")
const GOOD_TEX = preload("res://assets/sprites/ending_piece_good.png")
const BAD_TEX = preload("res://assets/sprites/ending_piece_bad.png")

var wall_overlay: Sprite2D

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

func make_overlay(tex: Texture2D) -> Sprite2D:
	var overlay = Sprite2D.new()
	overlay.texture = tex
	overlay.scale = Vector2(2, 2)
	add_child(overlay)
	return overlay

func mark_as_line_clear(is_row: bool):
	special_type = "line_clear"
	is_line_clear_row = is_row
	var overlay = make_overlay(ARROW_TEX)
	if not is_row:
		overlay.rotation_degrees = 90

func mark_as_fate(is_good: bool):
	special_type = "fate"
	is_fate_piece = true
	fate_is_good = is_good
	make_overlay(GOOD_TEX if is_good else BAD_TEX)

func show_wall():
	wall_overlay = make_overlay(WALL_TEX)

func hide_wall():
	if wall_overlay != null:
		wall_overlay.queue_free()
		wall_overlay = null
