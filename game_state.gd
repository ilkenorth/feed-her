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
