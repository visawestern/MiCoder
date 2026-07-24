import SwiftUI

struct MarkdownText: View {
    @Environment(\.interfaceFontScale) private var interfaceFontScale
    let text: String
    var fontSize: CGFloat = 14

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
                        .foregroundColor(Color.mimo.textPrimary)
                        .padding(.top, level == 1 ? 4 : 2)

                case .codeBlock(let language, let code):
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(language.isEmpty ? "CODE" : language.uppercased())
                                .font(.system(size: max(9, scaledFontSize - 4), weight: .semibold))
                                .foregroundColor(languageColor(language))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.mimo.codeHeaderBg)

                        Text(code)
                            .font(.system(size: max(10, scaledFontSize - 1), design: .monospaced))
                            .foregroundColor(Color.mimo.textPrimary)
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
                        .foregroundColor(Color.mimo.textPrimary)

                case .bulletItem(let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(Color.mimo.textMuted)
                        MarkdownInline(text: content, fontSize: scaledFontSize)
                    }

                case .numberedItem(let number, let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(number).")
                            .font(.system(size: scaledFontSize, weight: .medium))
                            .foregroundColor(Color.mimo.textMuted)
                            .frame(width: max(16, scaledFontSize + 6), alignment: .trailing)
                        MarkdownInline(text: content, fontSize: scaledFontSize)
                    }

                case .blockquote(let content):
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mimo.brand.opacity(0.4))
                            .frame(width: 3)
                        MarkdownInline(text: content, fontSize: scaledFontSize)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .padding(.leading, 4)

                case .horizontalRule:
                    Rectangle()
                        .fill(Color.mimo.border)
                        .frame(height: 1)
                        .padding(.vertical, 4)

                case .paragraph(let content):
                    MarkdownInline(text: content, fontSize: scaledFontSize)
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
}

struct MarkdownInline: View {
    let text: String
    var fontSize: CGFloat = 14

    var body: some View {
        let parts = parseInline(text)
        FlowLayout(parts: parts, fontSize: fontSize)
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

    var body: some View {
        parts.reduce(Text("")) { result, part in
            switch part {
            case .text(let t):
                return result + Text(t).foregroundColor(Color.mimo.textPrimary)
            case .bold(let t):
                return result + Text(t).bold().foregroundColor(Color.mimo.textPrimary)
            case .italic(let t):
                return result + Text(t).italic().foregroundColor(Color.mimo.textPrimary)
            case .code(let t):
                return result + Text(" \(t) ")
                    .font(.system(size: max(10, fontSize - 1), design: .monospaced))
                    .foregroundColor(Color.mimo.brand)
            }
        }
        .font(.system(size: fontSize))
    }
}
