//
//  ContentView.swift
//  cranci-AI
//
//  Redesigned for iOS 26 — Liquid Glass + Vibrant Colors
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isFocused: Bool

    // Vibrant gradient background colors
    private let gradientColors: [Color] = [
        Color(red: 0.05, green: 0.05, blue: 0.18),
        Color(red: 0.08, green: 0.03, blue: 0.25),
        Color(red: 0.03, green: 0.10, blue: 0.22)
    ]

    var body: some View {
        ZStack {
            // — Background Mesh Gradient —
            MeshBackground(colors: gradientColors)
                .ignoresSafeArea()

            // Floating ambient orbs
            AmbientOrbs()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GlassHeader(onClear: { viewModel.clearChat() })

                // — Messages —
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            if viewModel.isLoading {
                                TypingIndicator()
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isLoading) { loading in
                        if loading {
                            withAnimation(.spring(response: 0.4)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // — Floating Input Bar —
            VStack {
                Spacer()
                GlassInputBar(
                    text: $viewModel.inputText,
                    isFocused: $isFocused,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        viewModel.sendMessage()
                        isFocused = false
                    }
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.messages.count)
    }
}

// MARK: - Glass Header

struct GlassHeader: View {
    let onClear: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .blue, .cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Cranci AI")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Powered by Mistral")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            Button(action: onClear) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.4), .clear],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .frame(height: 1)
        }
    }
}

// MARK: - Glass Input Bar

struct GlassInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Scrivi un messaggio...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .focused($isFocused)
                .foregroundStyle(.white)
                .tint(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
                                                   startPoint: .leading,
                                                   endPoint: .trailing),
                                    lineWidth: 1
                                )
                        }
                }

            // Send button
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            canSend
                            ? LinearGradient(colors: [.purple, .blue],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: isLoading ? "ellipsis" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(canSend ? .white : .white.opacity(0.3))
                        .symbolEffect(.pulse, isActive: isLoading)
                }
            }
            .disabled(!canSend)
            .scaleEffect(canSend ? 1 : 0.9)
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }

            Spacer()
        }
        .id("typing")
        .onAppear { phase = 2 }
    }
}

// MARK: - Ambient Background

struct MeshBackground: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AmbientOrbs: View {
    var body: some View {
        ZStack {
            // Top-left purple orb
            Ellipse()
                .fill(
                    RadialGradient(colors: [.purple.opacity(0.35), .clear],
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 200)
                )
                .frame(width: 350, height: 350)
                .offset(x: -120, y: -200)

            // Bottom-right blue orb
            Ellipse()
                .fill(
                    RadialGradient(colors: [.blue.opacity(0.3), .clear],
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 180)
                )
                .frame(width: 300, height: 300)
                .offset(x: 160, y: 350)

            // Center cyan accent
            Ellipse()
                .fill(
                    RadialGradient(colors: [.cyan.opacity(0.15), .clear],
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 120)
                )
                .frame(width: 200, height: 200)
                .offset(x: 80, y: 0)
        }
    }
}

#Preview {
    ContentView()
}
