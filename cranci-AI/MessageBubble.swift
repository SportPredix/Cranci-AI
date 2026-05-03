//
//  MessageBubble.swift
//  cranci-AI
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let theme: AppTheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 48)
                userBubble
            } else {
                aiBubble
                Spacer(minLength: 48)
            }
        }
    }

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: theme.userBubbleColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.userShadowColor, radius: 8, x: 0, y: 4)
                }

            Text(message.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.trailing, 4)
        }
    }

    private var aiBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.aiAvatarColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                MarkdownText(content: message.content, isUser: false, theme: theme)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.leading, 4)
            }
        }
    }
}
