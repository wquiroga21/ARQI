//
//  FirstTimeSetupView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/22/25.
//

import SwiftUI
import Foundation
import Network

/// ✅ **Fix Missing Struct**
struct IntroText {
    let text: String
    let emoji: String?

    init(_ text: String, emoji: String? = nil) {
        self.text = text
        self.emoji = emoji
    }
}

struct FirstTimeSetupView: View {
    @ObservedObject var userProfile: UserAIProfile
    @State private var aiName: String = ""
    @State private var selectedPersonality: String = "Balanced"
    @State private var step = 1
    @State private var isSetupComplete = false
    
    private let personalities = ["Balanced", "Challenger", "Supportive"]
    
    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? Color.primaryAccent : Color.borderColor.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 30)
                
                // Content for current step
                ScrollView {
                    VStack(spacing: 30) {
                        switch step {
                        case 1:
                            welcomeView
                        case 2:
                            nameSelectionView
                        case 3:
                            personalitySelectionView
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
                
                // Navigation buttons
                bottomNavigationView
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
        .fullScreenCover(isPresented: $isSetupComplete) {
            MainAppView()
                .environmentObject(userProfile)
                .environmentObject(NetworkMonitor())
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(Color.primaryAccent)
                .padding(.bottom, 20)
            
            Text("Welcome to Your AI Companion")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Let's set up your personalized AI assistant that learns and evolves based on your interactions.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                featureRow(icon: "person.fill.viewfinder", title: "Customizable Personality", description: "Shape your AI's traits and perspectives")
                
                featureRow(icon: "bubble.left.and.bubble.right.fill", title: "Meaningful Conversations", description: "Engage in thoughtful discussions tailored to your preferences")
                
                featureRow(icon: "figure.walk.circle.fill", title: "AI Missions", description: "Send your AI to explore diverse perspectives and bring back insights")
            }
            .padding(.top, 20)
        }
    }
    
    private var nameSelectionView: some View {
        VStack(spacing: 20) {
            Text("Name Your AI")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Give your AI companion a name that feels right to you. This helps create a more personalized experience.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            TextField("AI Name", text: $aiName)
                .padding()
                .background(Color.primaryAccent.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 20)
            
            Text("You can always change this later in the Profile settings.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
    }
    
    private var personalitySelectionView: some View {
        VStack(spacing: 20) {
            Text("Choose a Starting Personality")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select how you'd like your AI to approach conversations initially. Don't worry, this can evolve over time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(personalities, id: \.self) { personality in
                    personalityButton(personality)
                }
            }
            .padding(.top, 20)
            
            Text("This is just a starting point. Your AI will adapt based on your feedback and the traits you select later.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
    }
    
    // MARK: - Helper Views
    
    private var bottomNavigationView: some View {
        VStack {
            if step > 1 {
                Button(action: {
                    if step > 1 {
                        step -= 1
                    }
                }) {
                    Text("Back")
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryAccent)
                }
                .padding(.bottom, 10)
            }
            
            Button(action: {
                if step < 3 {
                    step += 1
                } else {
                    completeSetup()
                }
            }) {
                Text(step == 3 ? "Complete Setup" : "Continue")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.buttonColor)
                    .cornerRadius(10)
            }
            .disabled(step == 2 && aiName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.primaryAccent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.primaryText)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func personalityButton(_ personality: String) -> some View {
        Button(action: {
            selectedPersonality = personality
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(personality)
                        .font(.headline)
                    
                    Text(personalityDescription(personality))
                        .font(.caption)
                        .foregroundColor(Color.primaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if selectedPersonality == personality {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.primaryAccent)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    private func personalityDescription(_ personality: String) -> String {
        switch personality {
        case "Balanced":
            return "Presents multiple perspectives equally without strong bias"
        case "Challenger":
            return "Challenges your thinking and plays devil's advocate to broaden your perspective"
        case "Supportive":
            return "Affirming and encouraging, focuses on building upon your ideas"
        default:
            return ""
        }
    }
    
    private func completeSetup() {
        // Save the user's preferences
        userProfile.aiName = aiName.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.perspectiveType = selectedPersonality
        userProfile.hasCompletedInitialSetup = true
        
        // If using Firestore, would save to backend here
        isSetupComplete = true
    }
}

// ✅ Ensure IntroView is Defined
struct IntroView: View {
    let text: IntroText
    @Binding var isWaving: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(text.text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color.primaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primaryAccent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                )
                .shadow(color: Color.primaryAccent.opacity(0.1), radius: 10)

            if let emoji = text.emoji {
                Text(emoji)
                    .font(.system(size: 32))
                    .rotationEffect(.degrees(isWaving ? 20 : 0))
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatCount(3, autoreverses: true),
                        value: isWaving
                    )
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
struct FirstTimeSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Group {
                // Welcome step
                FirstTimeSetupView(userProfile: UserAIProfile())
                    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                    .previewDisplayName("Welcome Step")
                
                // Name selection step
                FirstTimeSetupView(userProfile: UserAIProfile())
                    .onAppear {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SetSetupStep"),
                            object: 2
                        )
                    }
                    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                    .previewDisplayName("Name Selection")
                
                // Personality selection step
                FirstTimeSetupView(userProfile: UserAIProfile())
                    .onAppear {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SetSetupStep"),
                            object: 3
                        )
                    }
                    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                    .previewDisplayName("Personality Selection")
            }
        }
    }
}
