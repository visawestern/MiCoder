# Чеклист: Создание проекта (NewProjectSheet.swift)

Источник: `MiCoder/Sources/Views/NewProjectSheet.swift`. Ручная сверка кода:
2026-08-06; `swift test` — 1716/1716 PASS. Файловый picker нельзя честно
считать кликнутым без живого macOS-сеанса.

| № | Контрол / действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Закрыть (x) | Закрыть sheet без создания проекта. | ✅ |
| 2 | Project Name | Принять имя; пробелы по краям удаляются при создании. | ✅ |
| 3 | Folder | Принять путь вручную. | ✅ |
| 4 | Choose folder | Открыть `NSOpenPanel` только для одной папки, разрешить создание папки; после выбора подставить путь. | ⚠️ Требует live-QA NSOpenPanel. |
| 5 | Автоимя после выбора папки | Если имя пусто, использовать последний компонент выбранного пути. | ✅ |
| 6 | Create Project | Disabled при пустом имени или пути; иначе вызвать `createNewProject` и закрыть sheet. | ✅ |
| 7 | Cancel | Закрыть sheet без изменения состояния. | ✅ |
| 8 | Enter / Submit | Создать проект только когда оба поля непустые. | ✅ |

## Цепочная проверка PASS

Все внутренние пункты ✅ вручную прослежены от формы до trim/guard,
`AppState.createNewProject` и dismiss; полный `swift test` повторно прошёл.
`NSOpenPanel` остаётся live-QA. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
