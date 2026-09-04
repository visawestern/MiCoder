# Activity 25 — Agent Resources (Skills & MCP)

Источники: `Sources/Views/Components/AgentResourceLibraryView.swift`, `Sources/Services/AgentResourceInstaller.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Skill library catalog | 52 skills from JSON catalog | Просмотр навыков | 95/100 | PASS |
| 2 | Skill installation | `AgentResourceInstaller` copies to ~/.micoder/skills | Установка навыков | 95/100 | PASS |
| 3 | MCP catalog | 26 MCP entries (4 browser, 4 design) | Просмотр MCP серверов | 95/100 | PASS |
| 4 | Catalog bundle resolution | `locateResource` probes multiple paths | Загрузка каталога | 95/100 | PASS |
| 5 | Skill enable/disable/remove | `SkillRegistryManager` toggle + remove | Управление навыками | 90/100 | PARTIAL |
| 6 | Skill update | `updateSkill` + Update badge | Обновление навыков | 90/100 | PARTIAL |
| 7 | Dependency resolver | One-click install with dependencies | Установка с зависимостями | 90/100 | PARTIAL |
| 8 | MCP health check | `MCPHealthCheckLogic` probe + HTTP prober | Проверка здоровья | 90/100 | PARTIAL |
| 9 | Runtime dependency detection | Dynamic "Requires Node 18+" badges | Обнаружение зависимостей | 90/100 | PARTIAL |

## User Story

As a user, I can browse and install agent skills and MCP servers from a catalog, enable/disable/remove them, and see health status for installed MCP servers.
