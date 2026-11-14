extends RefCounted

const PARTIES := ["Конституционный союз", "Федеральный альянс"]
const PARTY_ENGLISH := ["Constitutional Union", "Federal Alliance"]
const ROOMS := [
	{"rank": "Референт", "title": "Общий аппарат", "layout": "open_hall", "width": 12.0, "back": -7.2, "height": 3.3, "wall": "#727e75", "people": ["Эллиот Финч", "Вера Холт"]},
	{"rank": "Легат", "title": "Комната отделения", "layout": "shared_room", "width": 4.8, "back": -3.8, "height": 2.8, "wall": "#a59c81", "people": ["Эллиот Финч", "Маркус Роу"]},
	{"rank": "Префект", "title": "Региональный кабинет", "layout": "regional", "width": 7.0, "back": -5.0, "height": 3.4, "wall": "#48665e", "people": ["Маркус Роу", "Селма Кроу"]},
	{"rank": "Консул", "title": "Кабинет при совете", "layout": "council", "width": 10.0, "back": -7.0, "height": 4.0, "wall": "#455b6a", "people": ["Селма Кроу", "Адриан Нокс"]},
	{"rank": "Архонт", "title": "Кабинет с приёмной", "layout": "reception", "width": 12.0, "back": -9.0, "height": 4.8, "wall": "#66715d", "people": ["Адриан Нокс", "Эллиот Финч"]},
	{"rank": "Первый архонт", "title": "Руководство партии", "layout": "leader", "width": 16.0, "back": -12.0, "height": 5.6, "wall": "#344d61", "people": ["Адриан Нокс", "Кэмерон Стилл"]},
]
