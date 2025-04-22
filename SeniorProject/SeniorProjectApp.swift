//
//  SeniorProjectApp.swift
//  SeniorProject
//
//  Created by William Quiroga on 1/14/25.
//

import SwiftUI

@main
struct SeniorProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var aiProfile = UserAIProfile()
    @StateObject private var aiManager = AIManager(chatType: .mainChat)
    
    // State to track splash screen visibility and app state
    @State private var isShowingSplash = true
    @State private var hasCompletedLaunch = false
    
    // Environment to detect app state changes
    @Environment(\.scenePhase) private var scenePhase
    
    // Comment out this property wrapper for testing
    @State private var useTestApp = false // Set back to false to use the real app
    // @State private var useTestApp = true // Temporarily set to true for testing
    
    var body: some Scene {
        WindowGroup {
            if useTestApp {
                // Use TestApp for debugging Firebase initialization
                TestApp()
            } else {
                ZStack {
                    // MainAppView
                    MainAppView()
                        .environmentObject(networkMonitor)
                        .environmentObject(aiProfile)
                        .environmentObject(aiManager)
                        .alert("Network Error", isPresented: $networkMonitor.showAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("Please check your internet connection and try again.")
                        }
                    
                    // Overlay with splash screen
                    if isShowingSplash {
                        Color(hex: "#F5F1E6") // Beige background
                            .ignoresSafeArea()
                            .overlay(
                                SplashView()
                            )
                            .transition(.opacity.animation(.easeOut(duration: 0.5)))
                            .zIndex(1)
                    }
                }
                .onAppear {
                    // Initial launch - always show splash
                    isShowingSplash = true
                    
                    // Show splash for a minimum time with animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowingSplash = false
                            hasCompletedLaunch = true
                        }
                    }
                }
                // Proper app lifecycle management
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        // App coming to foreground - only show splash if this is a true fresh start
                        // Do nothing here, as we don't want to show splash when returning from background
                        break
                        
                    case .background:
                        // App going to background
                        // No action needed
                        break
                        
                    case .inactive:
                        // Transitioning between states
                        break
                        
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

// Dedicated SplashView component with loading animation
struct SplashView: View {
    @State private var dotAnimation = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            // Loading dots
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimation ? 1.0 : 0.5)
                        .opacity(dotAnimation ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: dotAnimation
                        )
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            dotAnimation = true
        }
    }
}
