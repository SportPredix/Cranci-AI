//
//  ContentView.swift
//  cranci-AI
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case cosmic
    case ember
    case lagoon
    case bloom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cosmic:
            return "Cosmico"
        case .ember:
            return "Vulcano"
        case .lagoon:
            return "Laguna"
        case .bloom:
            return "Bloom"
        }
    }

    var subtitle: String {
        switch self {
        case .cosmic:
            return "Neon viola, blu e ciano."
        case .ember:
            return "Caldo, acceso e piu energico."
        case .lagoon:
            return "Acqua profonda con tocchi tropicali."
        case .bloom:
            return "Rosa elettrico e tramonto morbido."
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .cosmic:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.18),
                Color(red: 0.08, green: 0.03, blue: 0.25),
                Color(red: 0.03, green: 0.10, blue: 0.22)
            ]
        case .ember:
            return [
                Color(red: 0.17, green: 0.04, blue: 0.03),
                Color(red: 0.26, green: 0.08, blue: 0.02),
                Color(red: 0.12, green: 0.04, blue: 0.15)
            ]
        case .lagoon:
            return [
                Color(red: 0.02, green: 0.11, blue: 0.14),
                Color(red: 0.03, green: 0.19, blue: 0.17),
                Color(red: 0.03, green: 0.08, blue: 0.22)
            ]
        case .bloom:
            return [
                Color(red: 0.15, green: 0.04, blue: 0.11),
                Color(red: 0.23, green: 0.05, blue: 0.17),
                Color(red: 0.09, green: 0.08, blue: 0.22)
            ]
        }
    }

    var accentColors: [Color] {
        switch self {
        case .cosmic:
            return [
                Color(red: 0.53, green: 0.24, blue: 1.00),
                Color(red: 0.24, green: 0.43, blue: 1.00),
                Color(red: 0.14, green: 0.86, blue: 0.95)
            ]
        case .ember:
            return [
                Color(red: 1.00, green: 0.41, blue: 0.14),
                Color(red: 1.00, green: 0.67, blue: 0.22),
                Color(red: 1.00, green: 0.22, blue: 0.38)
            ]
        case .lagoon:
            return [
                Color(red: 0.07, green: 0.82, blue: 0.70),
                Color(red: 0.16, green: 0.57, blue: 1.00),
                Color(red: 0.64, green: 0.96, blue: 0.89)
            ]
        case .bloom:
            return [
                Color(red: 1.00, green: 0.34, blue: 0.62),
                Color(red: 0.82, green: 0.33, blue: 1.00),
                Color(red: 1.00, green: 0.71, blue: 0.36)
            ]
        }
    }

    var headerLineColors: [Color] {
        [
            accentColors[0].opacity(0.62),
            accentColors[1].opacity(0.42),
            .clear
        ]
    }

    var selectionColors: [Color] {
        [
            accentColors[0].opacity(0.34),
            accentColors[1].opacity(0.24)
        ]
    }

    var inputBorderColors: [Color] {
        [
            accentColors[0].opacity(0.68),
            accentColors[1].opacity(0.46)
        ]
    }

    var userBubbleColors: [Color] {
        [accentColors[0], accentColors[1]]
    }

    var aiAvatarColors: [Color] {
        [
            accentColors[0].opacity(0.82),
            accentColors[1].opacity(0.82),
            accentColors[2].opacity(0.82)
        ]
    }

    var typingIndicatorColors: [Color] {
        [
            accentColors[0].opacity(0.56),
            accentColors[1].opacity(0.56)
        ]
    }

    var previewColors: [Color] {
        [
            backgroundColors[0],
            backgroundColors[1],
            accentColors[1],
            accentColors[2]
        ]
    }

    var primaryGlowColor: Color {
        accentColors[2]
    }

    var secondaryGlowColor: Color {
        accentColors[0]
    }

    var tertiaryGlowColor: Color {
        accentColors[1]
    }

    var tintColor: Color {
        accentColors[0]
    }

    var userShadowColor: Color {
        accentColors[0].opacity(0.38)
    }

    static func resolved(id: String) -> AppTheme {
        AppTheme(rawValue: id) ?? .cosmic
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @AppStorage("selected_theme_id") private var selectedThemeID = AppTheme.cosmic.rawValue
    @FocusState private var isFocused: Bool
    @State private var sidebarPresented = false
    @State private var sidebarMounted = false
    @State private var settingsPresented = false
    @GestureState private var sidebarDragOffset: CGFloat = 0

    private let sidebarWidth: CGFloat = 280
    private let sidebarHiddenOffset: CGFloat = 312
    private let sidebarUnmountDelay: Double = 0.38

    private var selectedTheme: AppTheme {
        AppTheme.resolved(id: selectedThemeID)
    }

    var body: some View {
        ZStack {
            Group {
                if settingsPresented || sidebarMounted {
                    SettingsBackgroundView(theme: selectedTheme)
                } else {
                    AnimatedBackgroundScene(theme: selectedTheme)
                }
            }
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GlassHeader(
                    theme: selectedTheme,
                    onNewChat: { viewModel.createNewChat() },
                    onSettingsTap: {
                        isFocused = false
                        settingsPresented = true
                    },
                    onMenuTap: { toggleSidebar() }
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, theme: selectedTheme)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isUser ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            if viewModel.isLoading {
                                TypingIndicator(theme: selectedTheme)
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

            VStack {
                Spacer()
                GlassInputBar(
                    theme: selectedTheme,
                    text: $viewModel.inputText,
                    isFocused: $isFocused,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        viewModel.sendMessage()
                        isFocused = false
                    }
                )
            }

            if sidebarMounted {
                ZStack(alignment: .topLeading) {
                    Color.black
                        .opacity(backdropOpacity(for: clampedSidebarDragOffset))
                        .ignoresSafeArea()
                        .allowsHitTesting(sidebarPresented)
                        .onTapGesture { dismissSidebar() }

                    ChatHistorySidebar(
                        theme: selectedTheme,
                        chatSessions: viewModel.chatSessions,
                        currentChatID: viewModel.currentChatID,
                        onSelectChat: { chatID in
                            viewModel.loadChat(chatID)
                            dismissSidebar()
                        },
                        onDeleteChat: { chatID in
                            viewModel.deleteChat(chatID)
                        },
                        onClose: { dismissSidebar() }
                    )
                    .offset(x: sidebarOffset)
                    .scaleEffect(sidebarPresented ? 1 : 0.96, anchor: .leading)
                    .opacity(sidebarPresented ? 1 : 0.9)
                    .allowsHitTesting(sidebarPresented)
                    .simultaneousGesture(sidebarCloseGesture)
                    .animation(sidebarAnimation, value: sidebarDragOffset)
                }
            }
        }
        .animation(sidebarAnimation, value: sidebarPresented)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.messages.count)
        .fullScreenCover(isPresented: $settingsPresented) {
            SettingsView(selectedThemeID: $selectedThemeID)
        }
    }

    private var sidebarAnimation: Animation {
        .interactiveSpring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.2)
    }

    private var clampedSidebarDragOffset: CGFloat {
        min(0, sidebarDragOffset)
    }

    private var sidebarOffset: CGFloat {
        (sidebarPresented ? 0 : -sidebarHiddenOffset) + (sidebarPresented ? clampedSidebarDragOffset : 0)
    }

    private var sidebarCloseGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .updating($sidebarDragOffset) { value, state, _ in
                guard sidebarPresented else { return }
                let isMostlyHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isMostlyHorizontal, value.translation.width < 0 else { return }
                state = value.translation.width
            }
            .onEnded { value in
                guard sidebarPresented else { return }
                let isMostlyHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isMostlyHorizontal else { return }

                let predictedOffset = min(0, value.predictedEndTranslation.width)
                let closeByDistance = value.translation.width < -(sidebarWidth * 0.28)
                let closeByVelocity = predictedOffset < -(sidebarWidth * 0.45)

                if closeByDistance || closeByVelocity {
                    dismissSidebar()
                }
            }
    }

    private func toggleSidebar() {
        sidebarPresented ? dismissSidebar() : presentSidebar()
    }

    private func presentSidebar() {
        if sidebarMounted {
            withAnimation(sidebarAnimation) {
                sidebarPresented = true
            }
            return
        }

        sidebarMounted = true
        DispatchQueue.main.async {
            withAnimation(sidebarAnimation) {
                sidebarPresented = true
            }
        }
    }

    private func dismissSidebar() {
        guard sidebarMounted else { return }

        withAnimation(sidebarAnimation) {
            sidebarPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + sidebarUnmountDelay) {
            guard !sidebarPresented else { return }
            sidebarMounted = false
        }
    }

    private func backdropOpacity(for dragOffset: CGFloat) -> Double {
        let baseOpacity = sidebarPresented ? 0.4 : 0
        let progress = min(max(abs(dragOffset) / sidebarWidth, 0), 1)
        return baseOpacity * (1 - progress * 0.75)
    }
}

struct GlassHeader: View {
    let theme: AppTheme
    let onNewChat: () -> Void
    let onSettingsTap: () -> Void
    let onMenuTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ChromeIconButton(systemName: "line.3.horizontal", action: onMenuTap)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.aiAvatarColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
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
                    Text("Powered by Formatiks")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            HStack(spacing: 10) {
                ChromeIconButton(systemName: "gearshape.fill", action: onSettingsTap)
                ChromeIconButton(systemName: "plus", action: onNewChat)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: theme.headerLineColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

struct ChromeIconButton: View {
    let systemName: String
    var size: CGFloat = 34
    var iconSize: CGFloat = 16
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint.opacity(0.92))
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct SettingsView: View {
    @Binding var selectedThemeID: String
    @Environment(\.dismiss) private var dismiss

    private var selectedTheme: AppTheme {
        AppTheme.resolved(id: selectedThemeID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SettingsBackgroundView(theme: selectedTheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Impostazioni")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Scegli una sezione per personalizzare l'app o vedere le informazioni principali.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        NavigationLink {
                            ThemeSettingsView(selectedThemeID: $selectedThemeID)
                        } label: {
                            SettingsMenuRow(
                                icon: "paintpalette.fill",
                                title: "Temi",
                                subtitle: "Cambia il look della chat e salva il tema attivo.",
                                accentColors: selectedTheme.userBubbleColors
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AppInfoView(theme: selectedTheme)
                        } label: {
                            SettingsMenuRow(
                                icon: "info.circle.fill",
                                title: "Informazioni App",
                                subtitle: "Versione, build e dettagli principali di Cranci AI.",
                                accentColors: [selectedTheme.accentColors[1], selectedTheme.accentColors[2]]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ChromeIconButton(systemName: "xmark", action: { dismiss() })
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColors: [Color]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColors[0].opacity(0.95), accentColors[1].opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

struct ThemeSettingsView: View {
    @Binding var selectedThemeID: String

    private var selectedTheme: AppTheme {
        AppTheme.resolved(id: selectedThemeID)
    }

    var body: some View {
        ZStack {
            SettingsBackgroundView(theme: selectedTheme)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Temi")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Scegli un look per la chat. Il tema viene salvato automaticamente e resta attivo quando riapri l'app.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(AppTheme.allCases) { theme in
                        ThemeOptionCard(
                            theme: theme,
                            isSelected: theme.rawValue == selectedThemeID,
                            onSelect: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    selectedThemeID = theme.rawValue
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Temi")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackToolbarButton()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct AppInfoView: View {
    let theme: AppTheme

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Cranci AI"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ZStack {
            SettingsBackgroundView(theme: theme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsInfoCard(title: "App", value: appName, accentColors: theme.userBubbleColors)
                    SettingsInfoCard(title: "Versione", value: version, accentColors: [theme.accentColors[1], theme.accentColors[2]])
                    SettingsInfoCard(title: "Build", value: build, accentColors: [theme.accentColors[0], theme.accentColors[2]])

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descrizione")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text("Cranci AI e una chat app con storico conversazioni, temi personalizzabili e interfaccia animata.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Informazioni App")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackToolbarButton()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct BackToolbarButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChromeIconButton(systemName: "chevron.left", action: { dismiss() })
    }
}

struct SettingsInfoCard: View {
    let title: String
    let value: String
    let accentColors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColors[0].opacity(0.95), accentColors[1].opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 46, height: 8)
            }

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text(theme.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if isSelected {
                        Label("Attivo", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: theme.userBubbleColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: theme.previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 88)
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 10) {
                            Capsule()
                                .fill(.white.opacity(0.18))
                                .frame(width: 96, height: 18)

                            Capsule()
                                .fill(.white.opacity(0.12))
                                .frame(width: 64, height: 18)

                            Spacer()

                            HStack(spacing: 8) {
                                ForEach(theme.accentColors.indices, id: \.self) { index in
                                    Circle()
                                        .fill(theme.accentColors[index])
                                        .frame(width: 14, height: 14)
                                        .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 0.6))
                                }
                            }
                        }
                        .padding(16)
                    }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                                ? [theme.accentColors[0].opacity(0.9), theme.accentColors[1].opacity(0.55)]
                                : [.white.opacity(0.12), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.3 : 1
                    )
            }
            .shadow(color: isSelected ? theme.userShadowColor : .clear, radius: 14, x: 0, y: 8)
            .scaleEffect(isSelected ? 1.01 : 1)
        }
        .buttonStyle(.plain)
    }
}

struct ChatHistorySidebar: View {
    let theme: AppTheme
    let chatSessions: [ChatSession]
    let currentChatID: UUID?
    let onSelectChat: (UUID) -> Void
    let onDeleteChat: (UUID) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Cronologia Chat")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                ChromeIconButton(systemName: "xmark", size: 30, iconSize: 14, action: onClose)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(.white.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chatSessions) { session in
                        ChatHistoryRow(
                            theme: theme,
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

struct ChatHistoryRow: View {
    let theme: AppTheme
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
                        ? LinearGradient(
                            colors: theme.selectionColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [.clear, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .cornerRadius(10)
            }

            ChromeIconButton(
                systemName: "trash",
                size: 28,
                iconSize: 12,
                tint: .red,
                action: { showDeleteConfirm = true }
            )
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

struct GlassInputBar: View {
    let theme: AppTheme
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
                .tint(theme.tintColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: theme.inputBorderColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                }

            Button(action: onSend) {
                Image(systemName: isLoading ? "ellipsis" : "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(canSend ? .white : .white.opacity(0.3))
                    .symbolEffect(.pulse, isActive: isLoading)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
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

struct TypingIndicator: View {
    let theme: AppTheme
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.typingIndicatorColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
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

struct SettingsBackgroundView: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundColors[0],
                    theme.backgroundColors[1],
                    theme.backgroundColors[2]
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(theme.primaryGlowColor.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 130, y: -220)

            Circle()
                .fill(theme.secondaryGlowColor.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 64)
                .offset(x: -140, y: 260)
        }
    }
}

struct AnimatedBackgroundScene: View {
    let theme: AppTheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MeshBackground(theme: theme)
                AmbientOrbs(theme: theme)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MeshBackground: View {
    let theme: AppTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let primaryWave = CGFloat(normalizedWave(sin(time * 0.42)))
            let secondaryWave = CGFloat(normalizedWave(cos(time * 0.34)))
            let tertiaryWave = CGFloat(normalizedWave(sin(time * 0.56)))
            let quaternaryWave = CGFloat(normalizedWave(cos(time * 0.48)))

            ZStack {
                LinearGradient(
                    colors: [
                        theme.backgroundColors[0],
                        theme.backgroundColors[1],
                        theme.backgroundColors[2],
                        theme.accentColors[1].opacity(0.92)
                    ],
                    startPoint: UnitPoint(
                        x: 0.02 + 0.92 * primaryWave,
                        y: 0.02 + 0.42 * secondaryWave
                    ),
                    endPoint: UnitPoint(
                        x: 1.02 - 0.82 * tertiaryWave,
                        y: 1.02 - 0.54 * quaternaryWave
                    )
                )
                .scaleEffect(1.30 + 0.16 * secondaryWave)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [theme.primaryGlowColor.opacity(0.50), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(
                        width: 540 + 180 * tertiaryWave,
                        height: 430 + 140 * primaryWave
                    )
                    .offset(
                        x: -260 + 360 * primaryWave,
                        y: -280 + 260 * secondaryWave
                    )
                    .blur(radius: 34)
                    .blendMode(.screen)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [theme.secondaryGlowColor.opacity(0.42), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 340
                        )
                    )
                    .frame(
                        width: 620 + 180 * quaternaryWave,
                        height: 470 + 150 * tertiaryWave
                    )
                    .offset(
                        x: 250 - 380 * secondaryWave,
                        y: 340 - 290 * tertiaryWave
                    )
                    .blur(radius: 36)
                    .blendMode(.plusLighter)

                AngularGradient(
                    colors: [
                        .clear,
                        theme.tertiaryGlowColor.opacity(0.30),
                        theme.primaryGlowColor.opacity(0.38),
                        .clear,
                        theme.secondaryGlowColor.opacity(0.30),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.50 + 0.28 * CGFloat(sin(time * 0.18)),
                        y: 0.48 + 0.20 * CGFloat(cos(time * 0.22))
                    )
                )
                .scaleEffect(1.55 + 0.12 * primaryWave)
                .blur(radius: 88)
                .opacity(1)
            }
            .offset(
                x: CGFloat(sin(time * 0.24)) * 28,
                y: CGFloat(cos(time * 0.19)) * 22
            )
            .hueRotation(.degrees(sin(time * 0.16) * 28))
            .saturation(1.30)
            .contrast(1.10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func normalizedWave(_ value: Double) -> Double {
        (value + 1) / 2
    }
}

struct AmbientOrbs: View {
    let theme: AppTheme
    @State private var rotation: Double = 0

    var body: some View {
        let orbitPhase = rotation * .pi / 180

        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.secondaryGlowColor.opacity(0.46), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .frame(width: 420, height: 420)
                .offset(
                    x: -120 + 72 * CGFloat(cos(orbitPhase)),
                    y: -200 + 56 * CGFloat(sin(orbitPhase))
                )
                .scaleEffect(1 + 0.16 * CGFloat(sin(orbitPhase)))

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.tertiaryGlowColor.opacity(0.42), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 380, height: 380)
                .offset(
                    x: 160 + 88 * CGFloat(sin(orbitPhase)),
                    y: 350 - 64 * CGFloat(cos(orbitPhase))
                )
                .scaleEffect(1 + 0.18 * CGFloat(cos(orbitPhase)))

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.primaryGlowColor.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 280, height: 280)
                .offset(
                    x: 80 + 54 * CGFloat(sin(orbitPhase)),
                    y: 26 * CGFloat(cos(orbitPhase))
                )
                .scaleEffect(1.05 + 0.28 * CGFloat(sin(orbitPhase)))
        }
        .onAppear {
            guard rotation == 0 else { return }
            withAnimation(.linear(duration: 6.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
