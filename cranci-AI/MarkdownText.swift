//
//  MarkdownText.swift
//  cranci-AI
//
//  Custom markdown renderer — no dependencies, iOS 16+
//

import SwiftUI

// MARK: - Public Entry Point

struct MarkdownText: View {
    let content: String
    let isUser: Bool
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks(content).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    // MARK: Block Rendering

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let text, let level):
            inlineMarkdown(text)
                .font(headingFont(level))
                .fontWeight(.bold)
                .foregroundStyle(.white)

        case .paragraph(let text):
            inlineMarkdown(text)
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

        case .codeBlock(let code, let lang):
            CodeBlockView(code: code, language: lang)

        case .bulletItem(let text, let depth):
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.leading, CGFloat(depth) * 12)
                inlineMarkdown(text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .numberedItem(let text, let number, let depth):
            HStack(alignment: .top, spacing: 6) {
                Text("\(number).")
                    .foregroundStyle(.white.opacity(0.6))
                    .monospacedDigit()
                    .padding(.leading, CGFloat(depth) * 12)
                inlineMarkdown(text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .horizontalRule:
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 2)

        case .blockquote(let text):
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentColors[0], theme.accentColors[1]],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .cornerRadius(2)
                inlineMarkdown(text)
                    .font(.body.italic())
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Inline Markdown → AttributedString

    private func inlineMarkdown(_ text: String) -> Text {
        guard let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return Text(text)
        }
        return Text(attr)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        case 3: return .headline
        default: return .subheadline
        }
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                Text(language?.isEmpty == false ? language! : "code")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.lowercase)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation(.spring(response: 0.3)) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copiato" : "Copia",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(copied ? .green : .white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.35))

            Divider().overlay(.white.opacity(0.08))

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(12)
            }
        }
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

// MARK: - Parser

private enum MarkdownBlock {
    case heading(String, Int)
    case paragraph(String)
    case codeBlock(String, String?)
    case bulletItem(String, Int)
    case numberedItem(String, Int, Int)
    case horizontalRule
    case blockquote(String)
}

private func parseBlocks(_ input: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    let lines = input.components(separatedBy: "\n")
    var i = 0

    while i < lines.count {
        let line = lines[i]

        // Code block fence
        if line.hasPrefix("```") {
            let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            while i < lines.count && !lines[i].hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            blocks.append(.codeBlock(codeLines.joined(separator: "\n"), lang.isEmpty ? nil : lang))
            i += 1
            continue
        }

        // Horizontal rule
        if line.trimmingCharacters(in: .whitespaces).matches("^(---|\\*\\*\\*|___)$") {
            blocks.append(.horizontalRule)
            i += 1
            continue
        }

        // Heading
        if line.hasPrefix("#") {
            let level = line.prefix(while: { $0 == "#" }).count
            let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
            blocks.append(.heading(text, min(level, 4)))
            i += 1
            continue
        }

        // Blockquote
        if line.hasPrefix("> ") {
            let text = String(line.dropFirst(2))
            blocks.append(.blockquote(text))
            i += 1
            continue
        }

        // Bullet list
        let bulletMatch = line.bulletListMatch()
        if let (text, depth) = bulletMatch {
            blocks.append(.bulletItem(text, depth))
            i += 1
            continue
        }

        // Numbered list
        let numberedMatch = line.numberedListMatch()
        if let (text, num, depth) = numberedMatch {
            blocks.append(.numberedItem(text, num, depth))
            i += 1
            continue
        }

        // Paragraph (skip blank lines)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            // Collect continuation lines
            var paraLines = [trimmed]
            i += 1
            while i < lines.count {
                let next = lines[i].trimmingCharacters(in: .whitespaces)
                if next.isEmpty || next.hasPrefix("#") || next.hasPrefix("```")
                    || next.hasPrefix("> ") || next.bulletListMatch() != nil
                    || next.numberedListMatch() != nil { break }
                paraLines.append(next)
                i += 1
            }
            blocks.append(.paragraph(paraLines.joined(separator: " ")))
        } else {
            i += 1
        }
    }

    return blocks
}

// MARK: - String Helpers

private extension String {
    func matches(_ pattern: String) -> Bool {
        (try? NSRegularExpression(pattern: pattern))
            .map { $0.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)) != nil }
            ?? false
    }

    func bulletListMatch() -> (String, Int)? {
        let indent = prefix(while: { $0 == " " }).count
        let trimmed = trimmingCharacters(in: .init(charactersIn: " "))
        guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") else { return nil }
        return (String(trimmed.dropFirst(2)), indent / 2)
    }

    func numberedListMatch() -> (String, Int, Int)? {
        let indent = prefix(while: { $0 == " " }).count
        let trimmed = trimmingCharacters(in: .init(charactersIn: " "))
        guard let dotRange = trimmed.range(of: #"^\d+\."#, options: .regularExpression) else { return nil }
        let numStr = String(trimmed[dotRange].dropLast())
        let num = Int(numStr) ?? 1
        let rest = trimmed[dotRange.upperBound...].trimmingCharacters(in: .whitespaces)
        return (rest, num, indent / 2)
    }
}
