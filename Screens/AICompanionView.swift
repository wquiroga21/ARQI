//
//  AICompanionView.swift
//  SeniorProject
//
//  Created by William Quiroga on 5/29/25.
//

import SwiftUI

struct AICompanionView: View {
    var body: some View {
        ZStack {
            // Background
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with warm color scheme
                HStack {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                }
                .padding()
                .background(Color.appBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Main content with insights
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Stories section placeholder
                        // (Assuming this is where story icons would be)
                        storiesSection
                        
                        // Chat with AI button - Moved to top position
                        Button(action: {
                            // Navigate to chat
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .font(.headline)
                                
                                Text("Chat with AI Assistant")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.buttonColor)
                                    .shadow(color: Color.buttonColor.opacity(0.4), radius: 5, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Welcome message
                        welcomeSection
                        
                        // Active missions would be here
                        activeMissionsSection
                        
                        // Insights section
                        insightsSection
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    // Stories section placeholder
    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Placeholder for stories
                ForEach(0..<5) { _ in
                    Circle()
                        .stroke(Color.borderColor, lineWidth: 2)
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .fill(Color.secondaryCardBackground)
                                .frame(width: 56, height: 56)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .frame(height: 90)
    }
    
    // Active missions section
    private var activeMissionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Active Missions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryText)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to all missions
                }
                .foregroundColor(Color.primaryAccent)
            }
            .padding(.horizontal)
            
            // Placeholder for active missions
            Text("No active missions")
                .foregroundColor(Color.secondaryText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
        }
    }
    
    // Welcome section with personalized greeting
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome Back")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.primaryText)
            
            Text("Your AI companion is ready to help you with insights and conversation.")
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
                .padding(.bottom, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // Insights section with AI-generated insights
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Refresh insights
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(Color.buttonColor)
                }
            }
            .padding(.horizontal)
            
            // Placeholder for insights
            Text("Loading insights...")
                .foregroundColor(Color.secondaryText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
        }
    }
}

struct AICompanionView_Previews: PreviewProvider {
    static var previews: some View {
        AICompanionView()
    }
} 