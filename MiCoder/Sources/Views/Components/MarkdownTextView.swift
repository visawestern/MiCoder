import SwiftUI

struct MarkdownText: View {
    @Environment(\.interfaceFontScale) private var interfaceFontScale
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = Color.mimo.textPrimary

    private var scaledFontSize: CGFloat {
        InterfaceTypography.scaled(fontSize, scale: interfaceFontScale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseMarkdown().enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let content):
                    Text(content)
                        .font(.system(size: headingSize(level), weight: .bold))
                        .foregroundColor(textColor)
                        .padding(.top, level == 1 ? 4 : 2)

                case .codeBlock(let language, let code):
                    VStack(alignment: .leading, spacing: 0) {
                        CodeBlockHeader(language: language, code: code)
                        Text(code)
                            .font(.system(size: max(10, scaledFontSize - 1), design: .monospaced))
                            .foregroundColor(textColor)
                            .textSelection(.enabled)
                            .padding(10)
                    }
                    .background(Color.mimo.codeBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                case .inlineCode(let code):
                    Text(code)
                        .font(.system(size: max(10, scaledFontSize - 1), design: .monospaced))
                        .foregroundColor(Color.mimo.brand)
                        .padding(.horizontal, 4)
                        .background(Color.mimo.brand.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                case .bold(let content):
                    Text(content)
                        .font(.system(size: scaledFontSize, weight: .bold))
                        .foregroundColor(textColor)

                case .bulletItem(let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(Color.mimo.textMuted)
                        MarkdownInline(text: content, fontSize: scaledFontSize, textColor: textColor)
                    }

                case .numberedItem(let number, let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(number).")
                            .font(.system(size: scaledFontSize, weight: .medium))
                            .foregroundColor(Color.mimo.thinking)
                            .frame(width: max(16, scaledFontSize + 6), alignment: .trailing)
                        MarkdownInline(text: content, fontSize: scaledFontSize, textColor: textColor)
                    }

                case .blockquote(let content):
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mimo.brand.opacity(0.4))
                            .frame(width: 3)
                        MarkdownInline(text: content, fontSize: scaledFontSize, textColor: textColor)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .padding(.leading, 4)

                case .horizontalRule:
                    Rectangle()
                        .fill(Color.mimo.border)
                        .frame(height: 1)
                        .padding(.vertical, 4)

                case .table(let rows):
                    tableBlock(rows)

                case .paragraph(let content):
                    MarkdownInline(text: content, fontSize: scaledFontSize, textColor: textColor)
                }
            }
        }
        .textSelection(.enabled)
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return scaledFontSize + 4
        case 2: return scaledFontSize + 2
        default: return scaledFontSize
        }
    }

    private func languageColor(_ lang: String) -> Color {
        MarkdownText.codeLanguageColor(lang)
    }

    static func codeLanguageColor(_ lang: String) -> Color {
        switch lang.lowercased() {
        case "swift": return Color(red: 0.94, green: 0.32, blue: 0.22)
        case "python", "py": return Color(red: 0.22, green: 0.47, blue: 0.67)
        case "javascript", "js": return Color(red: 1.0, green: 0.85, blue: 0.24)
        case "typescript", "ts": return Color(red: 0.19, green: 0.47, blue: 0.78)
        case "html", "htm": return Color(red: 1.0, green: 0.42, blue: 0.42)
        case "css": return Color(red: 0.29, green: 0.80, blue: 0.77)
        case "rust": return Color(red: 0.75, green: 0.35, blue: 0.22)
        case "go": return Color(red: 0.0, green: 0.74, blue: 0.84)
        default: return Color.mimo.textMuted
        }
    }

    enum Block {
        case heading(Int, String)
        case codeBlock(String, String)
        case inlineCode(String)
        case bold(String)
        case bulletItem(String)
        case numberedItem(Int, String)
        case blockquote(String)
        case horizontalRule
        case table([[String]])
        case paragraph(String)
    }

    func parseMarkdown() -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1
                blocks.append(.codeBlock(lang, code.joined(separator: "\n")))
            } else if line.hasPrefix("# ") {
                blocks.append(.heading(1, String(line.dropFirst(2))))
                i += 1
            } else if line.hasPrefix("## ") {
                blocks.append(.heading(2, String(line.dropFirst(3))))
                i += 1
            } else if line.hasPrefix("### ") {
                blocks.append(.heading(3, String(line.dropFirst(4))))
                i += 1
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                blocks.append(.bulletItem(String(line.dropFirst(2))))
                i += 1
            } else if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let numStr = String(line[..<match.upperBound]).trimmingCharacters(in: .whitespaces)
                let num = Int(numStr.replacingOccurrences(of: ".", with: "")) ?? 0
                let content = String(line[match.upperBound...])
                blocks.append(.numberedItem(num, content))
                i += 1
            } else if line.hasPrefix("> ") {
                blocks.append(.blockquote(String(line.dropFirst(2))))
                i += 1
            } else if line.trimmingCharacters(in: .whitespaces) == "---" || line.trimmingCharacters(in: .whitespaces) == "***" {
                blocks.append(.horizontalRule)
                i += 1
            } else if isTableStart(lines, at: i) {
                blocks.append(.table(parseTable(lines, at: &i)))
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
            } else {
                var paragraph = line
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty && !lines[i].hasPrefix("#") && !lines[i].hasPrefix("```") && !lines[i].hasPrefix("- ") && !lines[i].hasPrefix("* ") && !lines[i].hasPrefix("> ") {
                    paragraph += " " + lines[i]
                    i += 1
                }
                blocks.append(.paragraph(paragraph))
            }
        }

        return blocks
    }

    private func isTableStart(_ lines: [String], at i: Int) -> Bool {
        guard i + 1 < lines.count,
              splitTableRow(lines[i]).count > 1 else { return false }
        return isTableSeparatorRow(lines[i + 1])
    }

    private func parseTable(_ lines: [String], at i: inout Int) -> [[String]] {
        var rows: [[String]] = []
        while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
            let cells = splitTableRow(lines[i])
            // Skip the separator row (e.g. |---|---|).
            if !isTableSeparatorRow(lines[i]) {
                rows.append(cells)
            }
            i += 1
        }
        return rows
    }

    private func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var parts = trimmed.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        if parts.first?.trimmingCharacters(in: .whitespaces).isEmpty == true { parts.removeFirst() }
        if parts.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { parts.removeLast() }
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func isTableSeparatorRow(_ line: String) -> Bool {
        let cells = splitTableRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let core = cell.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
            return !core.isEmpty && core.allSatisfy { $0 == "-" }
        }
    }

    @ViewBuilder
    private func tableBlock(_ rows: [[String]]) -> some View {
        if let header = rows.first, rows.count > 1 {
            let columnCount = max(header.count, rows[1...].map(\.count).max() ?? header.count)
            let bodyRows = Array(rows.dropFirst())

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<max(columnCount, 1), id: \.self) { col in
                        tableCell(header, col: col, isHeader: true)
                    }
                }
                .background(Color.mimo.codeHeaderBg)

                ForEach(Array(bodyRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(0..<max(columnCount, 1), id: \.self) { col in
                            tableCell(row, col: col, isHeader: false)
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mimo.border.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func tableCell(_ row: [String], col: Int, isHeader: Bool) -> some View {
        let value = col < row.count ? row[col] : ""
        HStack(alignment: .top, spacing: 0) {
            if isHeader {
                Text(value)
                    .font(.system(size: scaledFontSize - 1, weight: .semibold))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            } else {
                MarkdownInline(text: value, fontSize: scaledFontSize - 1, textColor: textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
        }
        .background(
            col % 2 == 1 ? Color.mimo.codeBg.opacity(0.5) : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(Color.mimo.border.opacity(0.5))
                .frame(width: col == 0 ? 0 : 1),
            alignment: .leading
        )
    }
}

struct CodeBlockHeader: View {
    let language: String
    let code: String
    @State private var copied = false

    var body: some View {
        HStack(spacing: 6) {
            Text(language.isEmpty ? "CODE" : language.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(MarkdownText.codeLanguageColor(language))
                .lineLimit(1)
            Spacer(minLength: 0)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copied = false }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(
                        copied ? Color.mimo.success : Color.mimo.textMuted
                    )
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(copied ? L.t(AppLocalizationKey.locCopied) : L.t(AppLocalizationKey.locCopyAll))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.mimo.codeHeaderBg)
    }
}

struct MarkdownInline: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = Color.mimo.textPrimary

    var body: some View {
        let parts = parseInline(text)
        FlowLayout(parts: parts, fontSize: fontSize, textColor: textColor)
    }

    enum InlinePart {
        case text(String)
        case bold(String)
        case italic(String)
        case code(String)
    }

    private enum InlineToken {
        case bold, italic, code

        var pattern: String {
            switch self {
            case .bold: return #"\*\*(.+?)\*\*"#
            case .italic: return #"(?<!\*)\*([^*\n]+?)\*(?!\*)|(?<!_)_([^_\n]+?)_(?!_)"#
            case .code: return #"`(.+?)`"#
            }
        }

        func part(from matched: String) -> InlinePart {
            switch self {
            case .bold:
                return .bold(String(matched.dropFirst(2).dropLast(2)))
            case .italic:
                return .italic(String(matched.dropFirst().dropLast()))
            case .code:
                return .code(String(matched.dropFirst().dropLast()))
            }
        }
    }

    func parseInline(_ s: String) -> [InlinePart] {
        var parts: [InlinePart] = []
        var remaining = s

        while !remaining.isEmpty {
            // Pick the earliest match so parts come out in source order.
            var earliest: (token: InlineToken, range: Range<String.Index>)?
            for token in [InlineToken.code, .bold, .italic] {
                guard let range = remaining.range(of: token.pattern, options: .regularExpression) else { continue }
                if earliest == nil || range.lowerBound < earliest!.range.lowerBound {
                    earliest = (token, range)
                }
            }

            guard let match = earliest else {
                parts.append(.text(remaining))
                break
            }

            if match.range.lowerBound > remaining.startIndex {
                parts.append(.text(String(remaining[..<match.range.lowerBound])))
            }
            parts.append(match.token.part(from: String(remaining[match.range])))
            remaining = String(remaining[match.range.upperBound...])
        }

        return parts
    }
}

struct FlowLayout: View {
    let parts: [MarkdownInline.InlinePart]
    var fontSize: CGFloat = 14
    var textColor: Color = Color.mimo.textPrimary

    var body: some View {
        parts.reduce(Text("")) { result, part in
            switch part {
            case .text(let t):
                return result + Text(t).foregroundColor(textColor)
            case .bold(let t):
                return result + Text(t).bold().foregroundColor(textColor)
            case .italic(let t):
                return result + Text(t).italic().foregroundColor(textColor)
            case .code(let t):
                return result + Text(" \(t) ")
                    .font(.system(size: max(10, fontSize - 1), design: .monospaced))
                    .foregroundColor(Color.mimo.brand)
            }
        }
        .font(.system(size: fontSize))
    }
}
