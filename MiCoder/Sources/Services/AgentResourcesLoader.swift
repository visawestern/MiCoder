import Foundation

struct MCPServerEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let command: String?
    let isEnabled: Bool
}

struct SkillEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
    let source: String
}

struct PluginEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let isEnabled: Bool
    let path: String
}

struct CommandEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
}

enum AgentResourcesLoader {
    static func loadMCPServers(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [MCPServerEntry] {
        let candidates = [
            homeDirectory.appendingPathComponent(".micoder/mcp.json")
        ]
        for url in candidates {
            if let servers = parseMCPConfig(at: url) {
                return servers
            }
        }
        return []
    }

    static func loadSkills(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [SkillEntry] {
        let roots = [
            (homeDirectory.appendingPathComponent(".micoder/skills"), "MiCoder")
        ]
        var results: [SkillEntry] = []
        for (root, source) in roots {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            for folder in contents where folder.hasDirectoryPath {
                let skillFile = folder.appendingPathComponent("SKILL.md")
                guard FileManager.default.fileExists(atPath: skillFile.path) else { continue }
                results.append(SkillEntry(
                    id: folder.lastPathComponent,
                    name: folder.lastPathComponent,
                    path: skillFile.path,
                    source: source
                ))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func loadPlugins(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [PluginEntry] {
        let root = homeDirectory.appendingPathComponent(".micoder/plugins")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.compactMap { folder -> PluginEntry? in
            guard folder.hasDirectoryPath else { return nil }
            let manifest = folder.appendingPathComponent("plugin.json")
            let name: String
            if let data = try? Data(contentsOf: manifest),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let manifestName = json["name"] as? String {
                name = manifestName
            } else {
                name = folder.lastPathComponent
            }
            let enabled = (try? manifest.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
            return PluginEntry(
                id: folder.lastPathComponent,
                name: name,
                isEnabled: enabled,
                path: folder.path
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func loadCommands(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [CommandEntry] {
        let roots = [
            homeDirectory.appendingPathComponent(".micoder/commands")
        ]
        var results: [CommandEntry] = []
        for root in roots {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            for file in files where file.pathExtension == "md" {
                let name = file.deletingPathExtension().lastPathComponent
                results.append(CommandEntry(id: file.path, name: name, path: file.path))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func filterSkills(_ skills: [SkillEntry], query: String) -> [SkillEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return skills }
        return skills.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.source.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static func filterEntries<T>(_ entries: [T], query: String, name: (T) -> String) -> [T] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter { name($0).localizedCaseInsensitiveContains(trimmed) }
    }

    private static func parseMCPConfig(at url: URL) -> [MCPServerEntry]? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let serversObject = (json["mcpServers"] as? [String: Any]) ?? json
        guard !serversObject.isEmpty else { return [] }

        return serversObject.compactMap { key, value -> MCPServerEntry? in
            guard let config = value as? [String: Any] else { return nil }
            let command = (config["command"] as? String)
                ?? (config["url"] as? String)
            let disabled = config["disabled"] as? Bool ?? false
            return MCPServerEntry(
                id: key,
                name: key,
                command: command,
                isEnabled: !disabled
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

enum PlusMenuCapabilityLogic {
    static func visibleItems(_ all: [PlusMenuItem], canUseTools: Bool) -> [PlusMenuItem] {
        guard canUseTools else {
            return all.filter { $0 == .addAttachment || $0 == .addPhoto }
        }
        return all
    }
}
