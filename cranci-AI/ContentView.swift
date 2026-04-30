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
    @State private var sidebarPresented = false

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
                GlassHeader(
                    onNewChat: { viewModel.createNewChat() },
                    onMenuTap: { sidebarPresented.toggle() }
                )

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
            
            // — Sidebar —
            if sidebarPresented {
                ZStack(alignment: .topLeading) {
                    // Backdrop
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { sidebarPresented = false }
                    
                    // Sidebar
                    ChatHistorySidebar(
                        chatSessions: viewModel.chatSessions,
                        currentChatID: viewModel.currentChatID,
                        onSelectChat: { chatID in
                            viewModel.loadChat(chatID)
                            sidebarPresented = false
                        },
                        onDeleteChat: { chatID in
                            viewModel.deleteChat(chatID)
                        },
                        onClose: { sidebarPresented = false }
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sidebarPresented)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.messages.count)
    }
}

// MARK: - Glass Header

struct GlassHeader: View {
    let onNewChat: () -> Void
    let onMenuTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Hamburger Menu
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
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

            // New Chat Button
            Button(action: onNewChat) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
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

// MARK: - Chat History Sidebar

struct ChatHistorySidebar: View {
    let chatSessions: [ChatSession]
    let currentChatID: UUID?
    let onSelectChat: (UUID) -> Void
    let onDeleteChat: (UUID) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Cronologia Chat")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(.white.opacity(0.1))
            
            // Chat List
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chatSessions) { session in
                        ChatHistoryRow(
                            session: session,
                            isSelected: session.id == currentChatID,
                            onSelect: { onSelectChat(session.id) },
                            onDelete: { onDeleteChat(session.id) }
                        )
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            
            Spacer()
        }
        .frame(maxWidth: 280, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 0.5)
        }
    }
}

// MARK: - Chat History Row

struct ChatHistoryRow: View {
    let session: ChatSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onSelect) {
                HStack(alignment: .center, spacing: 10) {
                    Text(session.title)
                        .font(.system(.body, design: .default))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    isSelected
                        ? LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                        : LinearGradient(colors: [.clear, .clear],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                )
                .cornerRadius(10)
            }
            
            // Delete Button
            Button(action: { showDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(8)
            }
            .padding(.trailing, 4)
        }
        .confirmationDialog("Delete Chat", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this chat?")
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
    @State private var rotation: Double = 0

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

            // Center cyan accent - animato
            Ellipse()
                .fill(
                    RadialGradient(colors: [.cyan.opacity(0.15), .clear],
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 120)
                )
                .frame(width: 200, height: 200)
                .offset(x: 80, y: 0)
                .scaleEffect(1.0 + 0.15 * sin(rotation * .pi / 180))
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
