//
//  MainAppView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/16/25.
//

import SwiftUI

struct MainAppView: View {
    @State private var selectedTab = 0
    @StateObject private var authService = AuthenticationService()
    @StateObject private var missionManager = AIMissionManager()
    @StateObject private var userProfile = UserAIProfile()
    @Environment(\.colorScheme) private var colorScheme
    
    // Ollama API Configuration
    private let ollamaAPIURL = "https://6740-4-43-60-6.ngrok-free.app/api/generate"
    @State private var selectedModel = "mistral:latest"
    private let availableModels = ["mistral:latest", "llama2", "gemma"]
    
    // MARK: - Layout Constants
    private struct LayoutMetrics {
        // Tab Bar
        static let tabBarHeightRatio: CGFloat = 0.055
        static let tabBarMaxHeight: CGFloat = 49
        
        // Indicators
        static let indicatorHeight: CGFloat = 3
        static let indicatorWidthRatio: CGFloat = 0.15
        static let maxIndicatorWidth: CGFloat = 55
        
        // Spacing
        static let tabSpacing: CGFloat = 0 // Spacing between tab buttons
        static let verticalSpacing: CGFloat = 0.001 // Spacing between indicator and buttons
        
        // Base sizes that will scale with dynamic type
        static let baseIconSize: CGFloat = 28
        static let baseHorizontalPadding: CGFloat = 0.08
        static let baseVerticalPadding: CGFloat = 8
    }
    
    // MARK: - Indicator Group
    struct TabIndicatorGroup: View {
        let selectedTab: Int
        let geometry: GeometryProxy
        @Environment(\.sizeCategory) var sizeCategory
        
        private var scaledHorizontalPadding: CGFloat {
            let baseScale = UIFontMetrics.default.scaledValue(for: 1.0)
            return geometry.size.width * LayoutMetrics.baseHorizontalPadding * min(baseScale, 1.2)
        }
        
        private func indicatorWidth() -> CGFloat {
            let baseWidth = min(LayoutMetrics.maxIndicatorWidth, geometry.size.width * LayoutMetrics.indicatorWidthRatio)
            let baseScale = UIFontMetrics.default.scaledValue(for: 1.0)
            return baseWidth * min(baseScale, 1.2)
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                Divider()
                    .background(Color.borderColor)
                
                HStack(spacing: 0) {
                    ForEach(0..<3) { index in
                        Rectangle()
                            .fill(selectedTab == index ? Color.primaryAccent : Color.clear)
                            .frame(width: indicatorWidth(), height: LayoutMetrics.indicatorHeight)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, scaledHorizontalPadding)
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Button Group
    struct TabButtonGroup: View {
        @Binding var selectedTab: Int
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.sizeCategory) var sizeCategory
        let geometry: GeometryProxy
        
        // Scale with dynamic type
        @ScaledMetric(relativeTo: .body) private var iconSize = LayoutMetrics.baseIconSize
        @ScaledMetric(relativeTo: .body) private var verticalPadding = LayoutMetrics.baseVerticalPadding
        
        private var scaledHorizontalPadding: CGFloat {
            let baseScale = UIFontMetrics.default.scaledValue(for: 1.0)
            return geometry.size.width * LayoutMetrics.baseHorizontalPadding * min(baseScale, 1.2)
        }
        
        var body: some View {
            HStack(spacing: LayoutMetrics.tabSpacing) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        Image(systemName: iconName(for: index))
                            .font(.system(size: iconSize))
                            .foregroundColor(selectedTab == index ? Color.primaryAccent : colorScheme == .dark ? Color.gray : Color.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, scaledHorizontalPadding)
                    }
                }
            }
            .padding(.vertical, verticalPadding)
        }
        
        private func iconName(for index: Int) -> String {
            switch index {
            case 0: return "house.fill"
            case 1: return "safari.fill"
            case 2: return "person.fill"
            default: return ""
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color
                Color.appBackground
                    .edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 0) {
                    // Tab content
                    ZStack {
                        TabView(selection: $selectedTab) {
                            HomeView(userProfile: userProfile)
                                .environmentObject(missionManager)
                                .tag(0)
                            
                            AIMissionsView(userId: authService.user?.id ?? "", userProfile: userProfile, authService: authService)
                                .environmentObject(missionManager)
                                .tag(1)
                            
                            ProfileView(authService: authService, userProfile: userProfile)
                                .tag(2)
                        }
                        .tabViewStyle(DefaultTabViewStyle())
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                        
                        // Custom tab bar - Now in a VStack inside the ZStack
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 0) {
                                // Indicators
                                TabIndicatorGroup(selectedTab: selectedTab, geometry: geometry)
                                
                                // Tab buttons
                                TabButtonGroup(selectedTab: $selectedTab, geometry: geometry)
                            }
                            .background(colorScheme == .dark ? Color(hex: "#262626") : Color(hex: "#F0EBE0"))
                        }
                        .ignoresSafeArea(.keyboard) // This ensures the tab bar ignores keyboard
                    }
                }
                
                // Loading overlay
                if authService.isLoading {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(min(1.3, geometry.size.width * 0.003))
                            .tint(Color.white)
                        Text("Connecting...")
                            .padding(.top, geometry.size.height * 0.02)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.appBackground.opacity(0.9))
                    .cornerRadius(10)
                }
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            // Just check authentication status without auto-authenticating
            authService.checkAuthState()
            
            // Set up notification observer for tab switching
            NotificationCenter.default.addObserver(forName: Notification.Name("SwitchToExplorerTab"), object: nil, queue: .main) { _ in
                selectedTab = 1 // Switch to Explorer tab
            }
        }
        .onDisappear {
            // Remove notification observer
            NotificationCenter.default.removeObserver(self, name: Notification.Name("SwitchToExplorerTab"), object: nil)
        }
    }
}

// MARK: - Preview
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainAppView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
                .previewDisplayName("iPhone 16 Pro")
            
            MainAppView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
                .previewDisplayName("iPhone 14 Pro")
            
            MainAppView()
                .environment(\.colorScheme, .dark)
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
                .previewDisplayName("iPhone 14 Pro (Dark)")
            
            MainAppView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE (small)")
        }
    }
}
