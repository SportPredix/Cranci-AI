//
//  MessageBubble.swift
//  cranci-AI
//
//  Redesigned for iOS 26 — Liquid Glass + Vibrant Colors
//

import SwiftUI

struct MessageBubble: View {
    let message: Message

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

    // MARK: User Bubble — vibrant gradient
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
                                colors: [
                                    Color(red: 0.5, green: 0.2, blue: 1.0),
                                    Color(red: 0.2, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                }

            Text(message.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.trailing, 4)
        }
    }

    // MARK: AI Bubble — liquid glass
    private var aiBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
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
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
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
