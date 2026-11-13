extends RefCounted

const FIRST_NAMES := ["Алекс", "Джейми", "Райли", "Морган", "Кейси", "Джордан", "Тейлор", "Куинн", "Робин", "Эйвери", "Кэмерон", "Дакота"]
const LAST_NAMES := ["Мерсер", "Беннет", "Харпер", "Лоусон", "Ривз", "Коллинз", "Саттон", "Палмер", "Хейс", "Уитмор", "Фостер", "Блейк"]
# Extend this roster when alternative recurring companions are designed.
const COMPANIONS := [{"id": "elliot", "name": "Эллиот Финч", "early_contact": "часто", "late_contact": "редко"}]
var full_name: String
var companion: Dictionary

func _init(seed_value: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	full_name = "%s %s" % [FIRST_NAMES[rng.randi_range(0, FIRST_NAMES.size() - 1)], LAST_NAMES[rng.randi_range(0, LAST_NAMES.size() - 1)]]
	companion = COMPANIONS[rng.randi_range(0, COMPANIONS.size() - 1)].duplicate(true)
