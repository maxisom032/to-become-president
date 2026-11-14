# Иллюстрации для диалогов — 14 ноября 2026

Статус: созданные отдельные 2D-изображения для художественного просмотра. В игру не внедрены. Это не 3D-модели и не замена действующей 3D-комнаты.

Открой `index.html` для просмотра оригиналов и переключения чётких/мягких фонов. `characters-overview.jpg` и `backgrounds-overview.jpg` — обзорные листы, оригиналы находятся в подпапках.

Источник описаний: `content/ideas/IDEA-001-recurring-cast.md` и `docs/gameplay/GAMEPLAY_PROPOSAL_2026-11-14.md`. Стиль: `design/character-refinements/01-expressive.png`. Генерация — встроенный image_gen; задания сохранены в `prompts.json`. Имена и биографии не изменялись.

## Персонажи

11 отдельных PNG с прозрачностью, базовое выражение и характерный жест. Разрешение и границы прозрачности каждого файла — в `validation.json`. Дополнительные эмоции в этот набор не входят.

- Эллиот Финч: `characters/01-elliot-finch.png`
- Вера Холт: `characters/02-vera-holt.png`
- Маркус Роу: `characters/03-marcus-rowe.png`
- Селма Кроу: `characters/04-selma-crow.png`
- Адриан Нокс: `characters/05-adrian-knox.png`
- Кэмерон Стилл: `characters/06-cameron-still.png`
- Нора Блейк: `characters/07-nora-blake.png`
- Гарольд Прайс: `characters/08-harold-price.png`
- Ирис Вейл: `characters/09-iris-vale.png`
- Рэй Далтон: `characters/10-ray-dalton.png`
- Джун Белл: `characters/11-june-bell.png`

## Фоны

У каждого места отдельный чёткий PNG (`-sharp.png`) и мягкая версия (`-soft.png`). Мягкие версии получены редактированием чётких изображений: запрашивалось сохранение композиции, объектов, палитры и света с изменением только расфокуса. Это генеративное редактирование; геометрическое совпадение пиксель в пиксель не гарантируется.

- Кабинет: `backgrounds/01-office-{sharp,soft}.png`
- Общественная приёмная: `backgrounds/02-public-reception-{sharp,soft}.png`
- Кафе: `backgrounds/03-cafe-{sharp,soft}.png`
- Ресторан: `backgrounds/04-restaurant-{sharp,soft}.png`
- Банк: `backgrounds/05-bank-{sharp,soft}.png`
- Телестудия: `backgrounds/06-tv-studio-{sharp,soft}.png`
- Партийный совет: `backgrounds/07-party-council-{sharp,soft}.png`
- Улица / площадь: `backgrounds/08-city-square-{sharp,soft}.png`
- Общественный зал: `backgrounds/09-community-hall-{sharp,soft}.png`
- Служебная парковка: `backgrounds/10-service-parking-{sharp,soft}.png`
- Дом: `backgrounds/11-home-{sharp,soft}.png`

Фоны не содержат диалоговых панелей: персонаж, реплика и три ответа должны размещаться отдельно при будущем внедрении. Иллюстративный флаг в кабинете не утверждает эмблему партии.

## Проверка

`make_previews.py` читает оригиналы без изменения, собирает обзорные листы и записывает размер/альфа-канал в `validation.json`. Визуальный просмотр обзорных листов проверяет соответствие описаниям и отсутствие встроенного интерфейса. Работа в игровом окне и на физическом телефоне не проверялась: внедрение в эту задачу не входит.

