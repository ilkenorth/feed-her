extends Node

var nutrition_score: int = 0

func add_score(piece_type: String, amount: int = 1):
	match piece_type:
		"healthy":
			nutrition_score += amount
		"unhealthy":
			nutrition_score -= amount

func get_score() -> int:
	return nutrition_score

func reset_score():
	nutrition_score = 0

const MAX_LEVEL = 10
var level_goals = [12, 15, 18, 22, 26, 30, 35, 40, 45, 50]
var current_level: int = 1
var pieces_cleared: int = 0

func register_clears(count: int):
	pieces_cleared += count

func get_goal() -> int:
	return level_goals[current_level - 1]

func is_level_complete() -> bool:
	return pieces_cleared >= get_goal()

func next_level():
	current_level += 1
	pieces_cleared = 0

func is_game_finished() -> bool:
	return current_level > MAX_LEVEL

func get_health_state() -> String:
	if nutrition_score <= -30:
		return "Very unhealthy"
	elif nutrition_score <= -10:
		return "Unhealthy"
	elif nutrition_score < 10:
		return "Average"
	elif nutrition_score < 30:
		return "Healthy"
	else:
		return "Very healthy"

func get_life_stage() -> String:
	if current_level <= 2:
		return "Baby"
	elif current_level <= 5:
		return "Child"
	elif current_level <= 8:
		return "Teen"
	else:
		return "Adult"
