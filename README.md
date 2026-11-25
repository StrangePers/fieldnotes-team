# Fieldnotes для команды

Публичный набор профилей для разработки с Codex, Claude Code и OpenCode. Выберите профиль для своего проекта. Из 35 скиллов 17 подключены из библиотеки как Git-подмодуль, ещё 18 находятся в `skills/`. Версию библиотеки фиксирует коммит этого репозитория. [Публичная библиотека Fieldnotes Skills](https://github.com/StrangePers/fieldnotes-skills)

| Профиль | Карточек | Для каких задач |
| --- | ---: | --- |
| `general` | 18 | Brainstorming, планирование, TDD, отладка, ревью и передача задачи. Включает 15 карточек Superpowers. |
| `web` | 23 | Общая разработка, frontend-design, Playwright, проверки интерфейса, размеров окна и клавиатурного фокуса. |
| `native` | 26 | C++ и Qt, диагностика сборки, проверка действия в UI, совместимости DLL и реконструкции вычислений. |
| `skill-author` | 22 | Создание карточек, проверка их обнаружения и выбора агентом, первый запуск учебного примера. |

## Первая установка

Если ваш проект хранится в SVN и вы используете OpenCode, перейдите к [установке профиля native для SVN](#opencode-svn).

Для установки нужны Git и Python 3.11+. Любой участник может скачать инструмент и набор профилей по HTTPS без приглашения или входа в GitHub. Выполните команды из каталога, где находится ваш Git-проект. Замените `my-project` на его путь и выберите профиль из таблицы.

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

## OpenCode (SVN)

Профиль `native` включает 26 скиллов для разработки на C++ и Qt. Рабочая копия проекта остаётся в SVN. Fieldnotes устанавливает карточки в отдельный каталог `fieldnotes-native`, а OpenCode читает их оттуда. Команды ниже предназначены для Windows PowerShell. Нужны Git, Python 3.11+ и OpenCode. Проверено с OpenCode 2.3.0 и Subversion 1.15.0.

**1. Установите профиль.** Откройте PowerShell в **родительском каталоге** рабочей копии SVN. Три каталога ниже должны оказаться рядом с ней. Подмодуль скачает закреплённую версию общей библиотеки скиллов.

```powershell
git clone https://github.com/StrangePers/project-fieldnotes.git
git clone --recurse-submodules https://github.com/StrangePers/fieldnotes-team.git
git init fieldnotes-native
python project-fieldnotes/fieldnotes.py init fieldnotes-native --workspace fieldnotes-team --project native
```

**2. Подключите OpenCode.** В **корне рабочей копии SVN** создайте `opencode.jsonc` со следующим содержимым. Если там уже есть `opencode.json` или `opencode.jsonc`, добавьте в него поле `skills` или дополните существующий массив этим путём.

```json
{
  "skills": ["../fieldnotes-native/.agents/skills"]
}
```

**3. Проверьте обнаружение.** Выполните команды из **корня рабочей копии SVN**. Фильтр учитывает путь к файлу, поэтому одноимённые глобальные скиллы не попадут в результат.

```powershell
$root = (Resolve-Path '../fieldnotes-native/.agents/skills').Path + '\'
$result = opencode.cmd api GET /api/skill --header "x-opencode-directory: $((Get-Location).Path)" | ConvertFrom-Json
$native = @($result.data | Where-Object { $_.path -and $_.path.Replace('/', '\').StartsWith($root, [StringComparison]::OrdinalIgnoreCase) })
$native.Count
$native | Where-Object id -eq 'cpp-dll-abi-check' | Format-List id, path
```

Ожидайте `26` и путь, оканчивающийся на `fieldnotes-native\.agents\skills\cpp-dll-abi-check\SKILL.md`. Если при первом запуске список пуст, через несколько секунд повторите весь блок проверки. Запускайте OpenCode из корня этой рабочей копии, чтобы относительный путь указывал на тот же каталог.

**4. Обновляйте скиллы.** Из **родительского каталога** выполните:

```powershell
git -C fieldnotes-team pull --ff-only
git -C fieldnotes-team submodule update --init --recursive
python project-fieldnotes/fieldnotes.py sync --workspace fieldnotes-team --check
python project-fieldnotes/fieldnotes.py sync --workspace fieldnotes-team
python project-fieldnotes/fieldnotes.py sync --workspace fieldnotes-team --check
```

Первая проверка показывает план, последняя должна вывести `0 file(s) to change`. Для других SVN-проектов в том же родительском каталоге можно использовать уже установленный профиль: повторите шаги 2 и 3 в каждой рабочей копии.

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

## Лицензии

StrangePers распространяет четыре профиля (`workspace.json` и материалы в `projects/`) под CC BY 4.0. При распространении укажите автора и источник, дайте ссылку на лицензию и отметьте внесённые изменения. Подходящая подпись — «Fieldnotes Team Profiles by StrangePers». [Область действия и текст лицензии](LICENSE)

Скиллы `task-brief-and-handoff` и `binary-debug-evidence` сопровождаются в Fieldnotes Skills. В каталог каждого входит уведомление об авторстве StrangePers и лицензии CC BY 4.0.

Для Superpowers действует MIT. У `frontend-design`, `skill-creator` и `playwright` свои файлы Apache 2.0 и сопроводительные уведомления. Для подмодуля Fieldnotes Skills действуют условия его репозитория. [Источники компонентов](sources.json)
