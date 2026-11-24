# Fieldnotes для команды

Этот приватный workspace задаёт, какие скиллы получит каждый проект. Из 35 выбранных скиллов 15 загружаются из публичной библиотеки как Git-подмодуль, ещё 20 находятся в `skills/`. Версию библиотеки фиксирует коммит этого репозитория. [Публичная библиотека Fieldnotes Skills](https://github.com/StrangePers/fieldnotes-skills)

| Профиль | Карточек | Для каких задач |
| --- | ---: | --- |
| `general` | 18 | Brainstorming, планирование, TDD, отладка, ревью и передача задачи. Включает 15 карточек Superpowers. |
| `web` | 23 | Общая разработка, frontend-design, Playwright, проверки интерфейса, размеров окна и клавиатурного фокуса. |
| `native` | 26 | C++ и Qt, диагностика сборки, проверка действия в UI, совместимости DLL и реконструкции вычислений. |
| `skill-author` | 22 | Создание карточек, проверка их обнаружения и выбора агентом, первый запуск учебного примера. |

## Первая установка

Понадобятся Git, Python 3.11+ и доступ на чтение к этому репозиторию. Из общего родительского каталога клонируйте инструмент и командный workspace. Пример предполагает, что рядом уже лежит Git-проект `my-project`. Замените путь и выберите профиль из таблицы.

```sh
git clone https://github.com/StrangePers/project-fieldnotes.git
git clone --recurse-submodules https://github.com/StrangePers/fieldnotes-team.git
python project-fieldnotes/fieldnotes.py init "my-project" --workspace "fieldnotes-team" --project native
python project-fieldnotes/fieldnotes.py sync --workspace "fieldnotes-team" --check
```

Последняя команда должна показать `0 file(s) to change`. Для профиля `native` откройте в проекте `.agents/skills/cpp-dll-abi-check/examples/worked-example.md`. Такая же карточка доступна для Claude Code в `.claude/skills/`. Если workspace клонировали без подмодулей, выполните `git -C fieldnotes-team submodule update --init --recursive` и повторите подключение.

Для следующего проекта повторите `init` с его путём и профилем. Один клон workspace обслуживает несколько проектов. Если целевой checkout уже подключён к workspace из прежнего ZIP, для первой проверки Git-версии используйте отдельный checkout проекта: Fieldnotes хранит привязку к пути workspace.

## Обновление у участника

Из того же родительского каталога получите изменения команды, установите закреплённую версию библиотеки и просмотрите план по всем подключённым на этой машине проектам.

```sh
git -C fieldnotes-team pull --ff-only
git -C fieldnotes-team submodule update --init --recursive
python project-fieldnotes/fieldnotes.py sync --workspace "fieldnotes-team" --check
```

Примените план и проверьте результат:

```sh
python project-fieldnotes/fieldnotes.py sync --workspace "fieldnotes-team"
python project-fieldnotes/fieldnotes.py sync --workspace "fieldnotes-team" --check
```

После применения ожидается `0 file(s) to change` для каждого проекта.

## Как сопровождающему обновить библиотеку

Выберите проверенный коммит публичного репозитория. В рабочей ветке командного workspace выполните команды ниже, подставив полный SHA вместо `COMMIT_SHA`.

```sh
git -C packs/fieldnotes-skills fetch origin
git -C packs/fieldnotes-skills checkout --detach COMMIT_SHA
git add packs/fieldnotes-skills
git diff --cached --submodule=log
```

Проверьте затронутые профили в тестовом проекте и закоммитьте указатель подмодуля. Если меняется выбор скиллов, обновите также списки в [workspace.json](workspace.json) и перечень источников в [sources.json](sources.json). Публичная карточка подключается по имени из `packs/fieldnotes-skills/skills`. Это имя должно иметь единственный источник среди каталогов, указанных в манифесте, и локального `skills/`.

## Источники и инструменты

Источники 35 карточек перечислены в [sources.json](sources.json). Для локальных дистрибутивов сохранены контрольные суммы и файлы лицензий. Публичные карточки распространяются как Fieldnotes Skills by StrangePers под [CC BY 4.0](https://github.com/StrangePers/fieldnotes-skills/blob/main/LICENSE).

Карточки Superpowers взяты из версии 7.0.0. Для хуков и вызовов с пространством имён используйте [плагин Superpowers](https://github.com/obra/superpowers). Для Playwright CLI нужны Node.js, npm и Bash. Некоторые средства оценки skill-creator используют Claude CLI. Подключения MCP и ключи доступа участники настраивают у себя.
