extends RefCounted

const PARTIES := ["Конституционный союз", "Федеральный альянс"]
const PARTY_ENGLISH := ["Constitutional Union", "Federal Alliance"]
const ROOMS := [
	{"rank": "Референт", "title": "Общий аппарат", "layout": "open_hall", "width": 6.4, "back": -3.4, "height": 3.2, "wall": "#bca780", "people": ["Эллиот Финч", "Вера Холт"]},
	{"rank": "Легат", "title": "Комната отделения", "layout": "shared_room", "width": 6.4, "back": -3.6, "height": 3.3, "wall": "#91905c", "people": ["Эллиот Финч", "Маркус Роу"]},
	{"rank": "Префект", "title": "Региональный кабинет", "layout": "regional", "width": 7.0, "back": -3.9, "height": 3.6, "wall": "#3c5b45", "people": ["Маркус Роу", "Селма Кроу"]},
	{"rank": "Консул", "title": "Кабинет при совете", "layout": "council", "width": 7.6, "back": -4.2, "height": 3.9, "wall": "#354d59", "people": ["Селма Кроу", "Адриан Нокс"]},
	{"rank": "Архонт", "title": "Кабинет с приёмной", "layout": "reception", "width": 8.2, "back": -4.6, "height": 4.2, "wall": "#596044", "people": ["Адриан Нокс", "Эллиот Финч"]},
	{"rank": "Первый архонт", "title": "Руководство партии", "layout": "leader", "width": 9.0, "back": -5.0, "height": 4.5, "wall": "#643536", "people": ["Адриан Нокс", "Кэмерон Стилл"]},
]
